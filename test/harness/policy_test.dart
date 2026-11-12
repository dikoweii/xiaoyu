import 'dart:io';
import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../../tool/harness/policy.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/harness.dart' as harness;

void main() {
  for (final directive in [
    "import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';",
    "import 'package:liquid_glass_easy/src/widgets/liquid_glass_style.dart';",
    "export 'package:liquid_glass_easy/src/widgets/liquid_glass_style.dart';",
  ]) {
    test('rejects obsolete or private glass API $directive', () {
      expect(inspectDart('lib/ui/example.dart', directive), isNotEmpty);
    });
  }
  for (final expression in [
    'BackdropFilter(filter: filter, child: child)',
    'ImageFiltered(imageFilter: filter, child: child)',
  ]) {
    test('rejects custom glass renderer $expression', () {
      expect(
        inspectDart('lib/ui/example.dart', 'Widget build() => $expression;'),
        isNotEmpty,
      );
    });
  }
  test('permits Flutter controls with public easy components', () {
    expect(
      inspectDart(
        'lib/ui/example.dart',
        "import 'package:liquid_glass_easy/liquid_glass_easy.dart'; Widget build() => Scaffold(body: Column(children: [TextField(), Card(child: ListTile(title: Text('x'))), LiquidGlassButton(label: 'ok', onPressed: action)]));",
      ),
      isEmpty,
    );
  });
  test(
    'new incomplete run blocks older results before platform steps exist',
    () {
      final base = <String, dynamic>{
        'sourceHash': 'current',
        'command': 'build',
        'platform': 'both',
        'unchanged': true,
        'steps': <Object?>[],
      };
      final records = [
        {...base, 'status': 'passed', 'finishedAt': '2026-01-01'},
        {...base, 'status': 'running', 'finishedAt': '2026-01-02'},
      ];
      expect(
        harness.latestReportState(records, 'current', 'build', 'build-ios'),
        'unverified',
      );
      records.last['status'] = 'blocked';
      expect(
        harness.latestReportState(records, 'current', 'build', 'build-ios'),
        'blocked',
      );
      records.last['status'] = 'failed';
      expect(
        harness.latestReportState(records, 'current', 'build', 'build-ios'),
        'failed',
      );
      expect(
        harness.latestReportState(records, 'different', 'build', 'build-ios'),
        'unverified',
      );
    },
  );
  for (final entry in <String, String>{
    'lib/domain/native.dart': "import 'dart:ui';",
    'lib/data/presentation.dart': "import '../presentation/controllers.dart';",
    'lib/domain/illegal.dart': "import 'package:dio/dio.dart';",
    'lib/application/illegal.dart': "import '../data/services/vidu_api.dart';",
    'lib/data/illegal.dart': "import '../ui/screens.dart';",
    'lib/ui/illegal.dart': "import '../data/local/database.dart'; void action(dynamic db) {db.select(1);}",
    'test/illegal_test.dart':
        "void main() {test('skipped', () {}, skip: true);}",
  }.entries) {
    test('rejects ${entry.key}', () {
      expect(inspectDart(entry.key, entry.value), isNotEmpty);
    });
  }
  test('permits domain interfaces and presentation controller imports', () {
    expect(
      inspectDart(
        'lib/domain/ports.dart',
        "import 'models.dart'; abstract interface class Port {}",
      ),
      isEmpty,
    );
    expect(
      inspectDart(
        'lib/ui/page.dart',
        "import '../presentation/controllers.dart';",
      ),
      isEmpty,
    );
  });
  test(
    'stale reports, missing artifacts and changed artifact content never pass',
    () {
      expect(
        harness.verifiedReport({
          'sourceHash': 'old',
          'status': 'passed',
          'unchanged': true,
        }, 'new'),
        isFalse,
      );
      expect(
        harness.verifiedReport({
          'sourceHash': 'new',
          'status': 'passed',
          'unchanged': false,
        }, 'new'),
        isFalse,
      );
      final dir = Directory.systemTemp.createTempSync('harness-evidence-');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/result.log')..writeAsStringSync('passed');
      final report = <String, dynamic>{
        'sourceHash': 'new',
        'status': 'passed',
        'unchanged': true,
        'command': 'self-test',
        'steps': [
          {
            'name': 'self-test',
            'status': 'passed',
            'log': file.path,
            'sha256': harness.digest(file.readAsBytesSync()),
          },
        ],
      };
      expect(harness.verifiedReport(report, 'new'), isTrue);
      file.writeAsStringSync('tampered');
      expect(harness.verifiedReport(report, 'new'), isFalse);
      file.deleteSync();
      expect(harness.verifiedReport(report, 'new'), isFalse);
    },
  );
  test('empty, incomplete and failed steps cannot forge success', () {
    final base = <String, dynamic>{
      'sourceHash': 'new',
      'status': 'passed',
      'unchanged': true,
      'command': 'check',
    };
    expect(
      harness.verifiedReport({...base, 'steps': <Object?>[]}, 'new'),
      isFalse,
    );
    expect(
      harness.verifiedReport({
        ...base,
        'steps': [
          {'name': 'tests', 'status': 'passed'},
        ],
      }, 'new'),
      isFalse,
    );
    expect(
      harness.verifiedReport({
        ...base,
        'command': 'device',
        'platform': 'ios',
        'steps': <Object?>[],
      }, 'new'),
      isFalse,
    );
  });
  test('accessibility scaling and hidden skipped tests are violations', () {
    expect(
      inspectDart(
        'lib/ui/a.dart',
        'void build() {MediaQuery(textScaler: TextScaler.noScaling, child: child);}',
      ),
      isNotEmpty,
    );
    expect(
      inspectDart(
        'test/a.dart',
        "void main(){group('x', (){}, skip: 'later');}",
      ),
      isNotEmpty,
    );
  });
  test('local overrides, missing required tests and Pods are rejected', () {
    final dir = Directory.systemTemp.createTempSync('harness-policy-');
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final name in [
      'analysis_options.yaml',
      'pubspec.yaml',
      'lib/l10n/app_en.arb',
      'lib/l10n/app_zh.arb',
      'ios/Runner/Info.plist',
      'ios/Runner/en.lproj/InfoPlist.strings',
      'ios/Runner/zh-Hans.lproj/InfoPlist.strings',
      'android/app/src/main/AndroidManifest.xml',
    ]) {
      final target = File('${dir.path}/$name');
      target.parent.createSync(recursive: true);
      File(name).copySync(target.path);
    }
    File('${dir.path}/pubspec.yaml').writeAsStringSync(
      '\ndependency_overrides:\n  permission_handler_apple:\n    path: third_party/permission_handler_apple\n',
      mode: FileMode.append,
    );
    File('${dir.path}/ios/Podfile').writeAsStringSync('platform :ios');
    final config = jsonDecode(
      jsonEncode(loadYaml(File('harness.yaml').readAsStringSync())),
    ) as Map<String, dynamic>;
    final findings = inspectProject(dir, config).map((f) => f.rule).toSet();
    expect(
      findings,
      containsAll(['dependency-override', 'native-stack', 'required-test']),
    );
  });
  test('empty machine output cannot claim tests or matrix execution', () {
    final config = jsonDecode(
      jsonEncode(loadYaml(File('harness.yaml').readAsStringSync())),
    ) as Map<String, dynamic>;
    final result = executionResult(
      '{"type":"done","success":true}',
      Directory.current,
      config,
    );
    expect(result['passed'], isFalse);
    expect(result['matrixCases'], 0);
    expect(result['missingSuites'], isNotEmpty);
  });
  test('missing coverage is a failure, not zero executable lines', () {
    final dir = Directory.systemTemp.createTempSync('harness-coverage-');
    addTearDown(() => dir.deleteSync(recursive: true));
    Directory('${dir.path}/lib/domain').createSync(recursive: true);
    File('${dir.path}/lib/domain/f.dart')
        .writeAsStringSync('int value() => 1;');
    final result = coverageResult('', dir, {
      'roots': ['lib/domain/'],
      'exclude': <String>[],
      'aggregate': 80,
      'per_file': 60,
    });
    expect(result['passed'], isFalse);
    expect(result['missing'], contains('lib/domain/f.dart'));
  });
}
