import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

typedef Finding = ({String file, String rule, String message});

List<Finding> inspectDart(String path, String source) {
  final findings = <Finding>[];
  void fail(String rule, String message) =>
      findings.add((file: path, rule: rule, message: message));
  final unit = parseString(
    content: source,
    path: path,
    throwIfDiagnostics: false,
  );
  if (unit.errors.isNotEmpty) fail('syntax', 'Invalid Dart syntax');
  final ui = path.startsWith('lib/ui/');
  final integration = path == 'lib/ui/integrations/rtc_video_surface.dart';
  for (final d in unit.unit.directives) {
    if (ui && (d is PartDirective || d is PartOfDirective)) {
      fail('ui-library', 'Use separate page libraries and shared widgets');
    }
    if (d is! UriBasedDirective) continue;
    final uri = d.uri.stringValue ?? '';
    if (path.startsWith('lib/') &&
        uri.startsWith('package:liquid_glass_widgets/')) {
      fail('glass-dependency', 'The old glass package is no longer supported');
    }
    if (path.startsWith('lib/') &&
        uri.startsWith('package:liquid_glass_easy/src/')) {
      fail('glass-public-api', 'Import the documented public library');
    }
    final target = uri.startsWith('package:xiaoyu/')
        ? 'lib/${uri.substring('package:xiaoyu/'.length)}'
        : uri.contains(':')
        ? uri
        : p.posix.normalize(p.posix.join(p.posix.dirname(path), uri));
    if (path.startsWith('lib/domain/') &&
        (['dart:ui', 'dart:io', 'dart:ffi'].contains(uri) ||
            target.startsWith('lib/') && !target.startsWith('lib/domain/') ||
            uri.startsWith('package:') &&
                !uri.startsWith('package:xiaoyu/') &&
                !uri.startsWith('package:uuid/'))) {
      fail(
        'domain-boundary',
        'Domain must not depend on platform or implementation',
      );
    }
    if (path.startsWith('lib/application/') &&
        (target.startsWith('lib/') &&
                !target.startsWith('lib/domain/') &&
                !target.startsWith('lib/application/') ||
            RegExp(r'^package:(dio|drift|agora_rtc_engine|flutter)/')
                .hasMatch(uri))) {
      fail('application-boundary', 'Application must depend on domain ports');
    }
    if (path.startsWith('lib/data/') &&
        (target.startsWith('lib/ui/') ||
            target.startsWith('lib/app/') ||
            target.startsWith('lib/presentation/'))) {
      fail('data-boundary', 'Data must not depend on presentation/composition');
    }
    if (ui &&
        !integration &&
        (target.startsWith('lib/data/') ||
            target == 'lib/app/runtime.dart' ||
            RegExp(
              r'^package:(dio|drift|agora_rtc_engine|image_picker|flutter_secure_storage)/',
            ).hasMatch(uri))) {
      fail(
        'ui-boundary',
        'Use presentation controllers; no SDK/data imports in pages',
      );
    }
  }
  unit.unit.accept(_Rules(path, fail));
  // Comments are checked separately: disabling checks is a policy change.
  if (RegExp(r'//\s*ignore(?:_for_file)?:').hasMatch(source)) {
    fail(
      'lint-suppression',
      'Do not suppress lints without a reviewed policy change',
    );
  }
  return findings;
}

class _Rules extends RecursiveAstVisitor<void> {
  _Rules(this.path, this.fail);
  final String path;
  final void Function(String, String) fail;
  // Syntax-level constructor checks include prefixed and named invocations.
  // They supplement dependency boundaries; this is not a resolved type proof.
  void control(String name, ArgumentList arguments) {
    if (!path.startsWith('lib/ui/') && path != 'lib/app/app.dart') return;
    if (name == 'BackdropFilter' || name == 'ImageFiltered') {
      fail('glass-renderer', 'Use the official liquid_glass_easy renderer');
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    control(name, node.argumentList);
    final target = node.target;
    if (target is SimpleIdentifier) control(target.name, node.argumentList);
    if (target is PrefixedIdentifier) {
      control(target.identifier.name, node.argumentList);
    }
    for (final a in node.argumentList.arguments.whereType<NamedArgument>()) {
      if (path.startsWith('lib/') &&
          ['textScaleFactor', 'textScaler'].contains(a.name.lexeme) &&
          (a.argumentExpression.toSource().contains('noScaling') ||
              ['1', '1.0'].contains(a.argumentExpression.toSource()))) {
        fail('text-scaling', 'Do not defeat accessibility scaling');
      }
    }

    if (path.startsWith('test/') || path.startsWith('integration_test/')) {
      if (['test', 'testWidgets', 'group'].contains(name)) {
        for (final a
            in node.argumentList.arguments.whereType<NamedArgument>()) {
          if (a.name.lexeme == 'skip' &&
              a.argumentExpression.toSource() != 'false') {
            fail('skipped-test', 'Skipped tests cannot satisfy a gate');
          }
        }
      }
    }
    if (path.startsWith('lib/ui/') &&
        path != 'lib/ui/integrations/rtc_video_surface.dart' &&
        [
          'customStatement',
          'into',
          'update',
          'delete',
          'createLive',
          'joinChannelWithUserAccount',
          'setPreferredOrientations',
        ].contains(name)) {
      fail(
        'ui-operation',
        'Business, SQL and platform operations belong behind a controller',
      );
    }
    if (path.startsWith('lib/') && ['print', 'debugPrint'].contains(name)) {
      fail(
        'unsafe-log',
        'Use explicit redacted diagnostics instead of raw logging',
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    control(node.constructorName.type.name.lexeme, node.argumentList);
    if (path.startsWith('lib/ui/') &&
        path != 'lib/ui/integrations/rtc_video_surface.dart' &&
        [
          'Dio',
          'NativeDatabase',
          'AppDatabase',
        ].contains(node.constructorName.type.name.lexeme)) {
      fail(
        'ui-operation',
        'Do not construct implementation services in a view',
      );
    }
    for (final a in node.argumentList.arguments.whereType<NamedArgument>()) {
      if (path.startsWith('lib/') &&
          ['textScaleFactor', 'textScaler'].contains(a.name.lexeme) &&
          (a.argumentExpression.toSource().contains('noScaling') ||
              a.argumentExpression.toSource() == '1.0')) {
        fail('text-scaling', 'Do not defeat accessibility scaling');
      }
    }
    super.visitInstanceCreationExpression(node);
  }
}

List<Finding> inspectProject(Directory root, Map<String, dynamic> config) {
  final findings = <Finding>[];
  void fail(String file, String rule, String message) =>
      findings.add((file: file, rule: rule, message: message));
  for (final dir in ['lib', 'test', 'integration_test']) {
    final folder = Directory(p.join(root.path, dir));
    if (!folder.existsSync()) continue;
    for (final f in folder.listSync(recursive: true).whereType<File>()) {
      final path = p.relative(f.path, from: root.path).replaceAll('\\', '/');
      if (!path.endsWith('.dart') ||
          path.endsWith('.g.dart') ||
          path.contains('/generated/')) {
        continue;
      }
      findings.addAll(inspectDart(path, f.readAsStringSync()));
    }
  }
  final options = loadYaml(
    File(p.join(root.path, 'analysis_options.yaml')).readAsStringSync(),
  ) as YamlMap;
  final language = (options['analyzer'] as Map)['language'] as Map;
  if ([
    'strict-casts',
    'strict-inference',
    'strict-raw-types',
  ].any((key) => language[key] != true)) {
    fail(
      'analysis_options.yaml',
      'analysis-policy',
      'Strict type analysis must remain enabled',
    );
  }
  final coverage = config['coverage'] as Map;
  if (![
        'lib/domain/',
        'lib/application/',
        'lib/data/',
      ].every((root) => (coverage['roots'] as List).contains(root)) ||
      (coverage['exclude'] as List).any(
        (file) => file != 'lib/data/services/microphone_permission.dart',
      )) {
    fail(
      'harness.yaml',
      'coverage-scope',
      'Keep critical logic roots and reviewed exclusions',
    );
  }
  if ((coverage['aggregate'] as num) < 80 ||
      (coverage['per_file'] as num) < 60) {
    fail(
      'harness.yaml',
      'coverage-policy',
      'Threshold changes require an explicit reviewed policy change',
    );
  }
  for (final path in ['ios/Runner/AppDelegate.swift', 'lib/main.dart']) {
    final file = File(p.join(root.path, path));
    if (file.existsSync() &&
        RegExp(r'FlutterMethodChannel|MethodChannel\(')
            .hasMatch(file.readAsStringSync())) {
      fail(
        path,
        'native-bridge',
        'Use official plugin capabilities before introducing a custom bridge',
      );
    }
  }
  final spec = loadYaml(
    File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
  ) as YamlMap;
  if (spec.containsKey('dependency_overrides')) {
    fail(
      'pubspec.yaml',
      'dependency-override',
      'Use hosted official dependencies',
    );
  }
  final dependencies = spec['dependencies'] as YamlMap;
  if (dependencies.containsKey('liquid_glass_widgets')) {
    fail(
      'pubspec.yaml',
      'glass-dependency',
      'Use the approved liquid_glass_easy dependency',
    );
  }
  for (final entry in dependencies.entries) {
    if (entry.value is YamlMap &&
        ((entry.value as YamlMap).containsKey('path') ||
            (entry.value as YamlMap).containsKey('git'))) {
      fail(
        'pubspec.yaml',
        'non-hosted-dependency',
        'Source overrides require an explicit policy decision',
      );
    }
  }
  if (dependencies.keys.any(
    (k) =>
        RegExp(r'volc|bytertc|volcengine', caseSensitive: false).hasMatch('$k'),
  )) {
    fail('pubspec.yaml', 'rtc-stack', 'Agora is the approved RTC');
  }
  for (final dependency in [
    'flutter_riverpod',
    'drift',
    'drift_flutter',
    'agora_rtc_engine',
    'permission_handler',
    'liquid_glass_easy',
  ]) {
    if (!dependencies.containsKey(dependency)) {
      fail('pubspec.yaml', 'stack', 'Missing required dependency: $dependency');
    }
  }
  for (final path in [
    'third_party/permission_handler_apple',
    'ios/Podfile',
    'ios/Pods',
  ]) {
    if (FileSystemEntity.typeSync(p.join(root.path, path)) !=
        FileSystemEntityType.notFound) {
      fail(
        path,
        'native-stack',
        'Local permission copies and CocoaPods are not part of this project',
      );
    }
  }
  for (final path in (config['required_tests'] as List).cast<String>()) {
    final file = File(p.join(root.path, path));
    if (!file.existsSync() ||
        !RegExp(r'\b(test|testWidgets)\(').hasMatch(file.readAsStringSync())) {
      fail(path, 'required-test', 'Required behavior test is missing or empty');
    }
  }
  final en = jsonDecode(
    File(p.join(root.path, 'lib/l10n/app_en.arb')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final zh = jsonDecode(
    File(p.join(root.path, 'lib/l10n/app_zh.arb')).readAsStringSync(),
  ) as Map<String, dynamic>;
  final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
  if (keys.difference(zh.keys.toSet()).isNotEmpty ||
      zh.keys
          .where((k) => !k.startsWith('@'))
          .toSet()
          .difference(keys)
          .isNotEmpty) {
    fail('lib/l10n', 'localization', 'ARB keys differ');
  }
  for (final key in keys) {
    Set<String> placeholders(Map<String, dynamic> arb) {
      final metadata = arb['@$key'];
      final declared = metadata is Map ? metadata['placeholders'] : null;
      return declared is Map
          ? declared.keys.cast<String>().toSet()
          : <String>{};
    }

    final english = placeholders(en), chinese = placeholders(zh);
    if (english.difference(chinese).isNotEmpty ||
        chinese.difference(english).isNotEmpty ||
        english.any(
          (name) =>
              !'${en[key]}'.contains('{$name') ||
              !'${zh[key]}'.contains('{$name'),
        )) {
      fail('lib/l10n', 'localization', 'Placeholders differ for $key');
    }
  }

  for (final path in [
    'ios/Runner/en.lproj/InfoPlist.strings',
    'ios/Runner/zh-Hans.lproj/InfoPlist.strings',
  ]) {
    final file = File(p.join(root.path, path));
    if (!file.existsSync() ||
        !file.readAsStringSync().contains('NSMicrophoneUsageDescription')) {
      fail(
        path,
        'permission-localization',
        'Localized microphone usage description is required',
      );
    }
  }
  final ios = File(p.join(root.path, 'ios/Runner/Info.plist'))
      .readAsStringSync();
  if (!ios.contains('NSMicrophoneUsageDescription') ||
      ios.contains('NSCameraUsageDescription')) {
    fail(
      'ios/Runner/Info.plist',
      'permissions',
      'Declare microphone, not local camera',
    );
  }
  final android = File(
    p.join(root.path, 'android/app/src/main/AndroidManifest.xml'),
  ).readAsStringSync();
  if (!android.contains('android.permission.RECORD_AUDIO') ||
      android.contains('android.permission.CAMERA') ||
      android.contains('screenOrientation=')) {
    fail(
      'android/app/src/main/AndroidManifest.xml',
      'permissions',
      'Microphone required; camera and orientation lock forbidden',
    );
  }
  return findings;
}

Map<String, dynamic> coverageResult(
  String lcov,
  Directory root,
  Map<String, dynamic> policy,
) {
  final rows = <String, Map<int, int>>{};
  String? current;
  for (final line in const LineSplitter().convert(lcov)) {
    if (line.startsWith('SF:')) {
      current = p
          .relative(
            p.isAbsolute(line.substring(3))
                ? line.substring(3)
                : p.join(root.path, line.substring(3)),
            from: root.path,
          )
          .replaceAll('\\', '/');
      rows.putIfAbsent(current, () => {});
    } else if (line.startsWith('DA:') && current != null) {
      final values = line.substring(3).split(',');
      final number = int.parse(values[0]);
      final hits = int.parse(values[1]);
      rows[current]![number] = (rows[current]![number] ?? 0) + hits;
    }
  }
  final roots = (policy['roots'] as List).cast<String>();
  final exclude = (policy['exclude'] as List).cast<String>();
  bool included(String f) =>
      roots.any(f.startsWith) && !exclude.contains(f) && !f.endsWith('.g.dart');
  final missing = <String>[];
  for (final dir in roots) {
    for (final file in Directory(
      p.join(root.path, dir),
    ).listSync(recursive: true).whereType<File>()) {
      final relative = p
          .relative(file.path, from: root.path)
          .replaceAll('\\', '/');
      if (relative.endsWith('.dart') &&
          included(relative) &&
          !rows.containsKey(relative) &&
          hasExecutableCode(file.readAsStringSync())) {
        missing.add(relative);
      }
    }
  }
  final files = <String, double>{};
  var total = 0, hit = 0;
  for (final entry in rows.entries.where((e) => included(e.key))) {
    if (entry.value.isEmpty) continue;
    final source = File(p.join(root.path, entry.key));
    final declarative = <int>{};
    if (source.existsSync()) {
      final parsed = parseString(content: source.readAsStringSync());
      for (final declaration
          in parsed.unit.declarations.whereType<ClassDeclaration>()) {
        if (declaration.extendsClause?.superclass.toSource() == 'Table') {
          declarative.addAll(
            List.generate(
              parsed.lineInfo.getLocation(declaration.end).lineNumber -
                  parsed.lineInfo.getLocation(declaration.offset).lineNumber +
                  1,
              (i) =>
                  parsed.lineInfo.getLocation(declaration.offset).lineNumber +
                  i,
            ),
          );
        }
      }
    }
    final effective = entry.value.entries
        .where((e) => !declarative.contains(e.key))
        .map((e) => e.value)
        .toList();
    if (effective.isEmpty) continue;
    final covered = effective.where((v) => v > 0).length;
    total += effective.length;
    hit += covered;
    files[entry.key] = 100 * covered / effective.length;
  }
  final aggregate = total == 0 ? 0.0 : 100 * hit / total;
  return {
    'aggregate': aggregate,
    'files': files,
    'missing': missing,
    'passed':
        missing.isEmpty &&
        files.isNotEmpty &&
        aggregate >= (policy['aggregate'] as num) &&
        files.values.every((v) => v >= (policy['per_file'] as num)),
  };
}

bool hasExecutableCode(String source) {
  final visitor = _ExecutableCode();
  parseString(content: source).unit.accept(visitor);
  return visitor.found;
}

class _ExecutableCode extends RecursiveAstVisitor<void> {
  bool found = false;
  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    found = true;
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    found = true;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null) found = true;
    super.visitVariableDeclaration(node);
  }
}

Map<String, dynamic> executionResult(
  String output,
  Directory root,
  Map<String, dynamic> config,
) {
  final suites = <int, String>{}, tests = <int, int>{};
  final counts = <int, int>{};
  var skipped = 0, failed = 0;
  var completed = false;
  for (final line
      in const LineSplitter().convert(output).where((s) => s.startsWith('{'))) {
    final event = jsonDecode(line) as Map<String, dynamic>;
    if (event['type'] == 'suite') {
      final suite = event['suite'] as Map;
      suites[suite['id'] as int] = p.relative(
        suite['path'] as String,
        from: root.path,
      );
    }
    if (event['type'] == 'testStart') {
      final test = event['test'] as Map;
      if (test['line'] != null) {
        tests[test['id'] as int] = test['suiteID'] as int;
      }
    }
    if (event['type'] == 'testDone') {
      if (event['skipped'] == true) skipped++;
      if (event['result'] != 'success') failed++;
      final suite = tests[event['testID']];
      if (suite != null &&
          event['result'] == 'success' &&
          event['skipped'] != true) {
        counts[suite] = (counts[suite] ?? 0) + 1;
      }
    }
    if (event['type'] == 'done') completed = event['success'] == true;
  }
  final missing = (config['required_tests'] as List)
      .cast<String>()
      .where(
        (path) => !suites.entries.any(
          (s) => s.value == path && (counts[s.key] ?? 0) > 0,
        ),
      )
      .toList();
  final matrix = config['matrix'] as Map;
  final minimumMatrix = [
    'sizes',
    'orientations',
    'platforms',
    'locales',
    'scales',
    'pages',
  ].fold(1, (int n, key) => n * (matrix[key] as List).length);
  final matrixId = suites.entries
      .where((s) => s.value == 'test/ui/layout_matrix_test.dart')
      .firstOrNull
      ?.key;
  final rendered = counts[matrixId] ?? 0;
  return {
    'passed':
        completed &&
        skipped == 0 &&
        failed == 0 &&
        missing.isEmpty &&
        rendered >= minimumMatrix,
    'completed': completed,
    'skipped': skipped,
    'failed': failed,
    'missingSuites': missing,
    'matrixCases': rendered,
    'requiredMatrixCases': minimumMatrix,
    'executed': counts.values.fold(0, (int a, b) => a + b),
  };
}
