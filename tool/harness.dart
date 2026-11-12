import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'harness/policy.dart';
import 'harness/comparison.dart';
import 'harness/skills.dart';

final root = Directory.current;
final output = Directory(p.join(root.path, 'build/harness'));
final encoder = const JsonEncoder.withIndent('  ');
late Map<String, dynamic> config;
late String runId;
late Directory runDir;
bool runCreated = false;
final steps = <Map<String, dynamic>>[];

String digest(List<int> bytes) => sha256.convert(bytes).toString();
Map<String, dynamic> readJson(File f) =>
    jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
void writeJson(File f, Object value) {
  f.parent.createSync(recursive: true);
  f.writeAsStringSync('${encoder.convert(value)}\n');
}

Future<Map<String, String>> snapshot() async {
  final git = await Process.run('git', [
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
    '-z',
  ]);
  if (git.exitCode != 0) {
    throw StateError('Harness must run inside the project Git repository');
  }
  final files =
      (git.stdout as String).split('\u0000').where((f) => f.isNotEmpty).toList()
        ..sort();
  return {
    for (final name in files)
      if (File(name).existsSync()) name: digest(File(name).readAsBytesSync()),
  };
}

String treeHash(Map<String, String> files) =>
    digest(utf8.encode(jsonEncode(files)));
String redact(String value) => value
    .replaceAllMapped(
      RegExp(r'(Token|Bearer)\s+[^\s"\x27,}]+', caseSensitive: false),
      (m) => '${m[1]} [redacted]',
    )
    .replaceAll(
      RegExp(
        r'((?:api[_-]?key|token|authorization)\s*[=:]\s*)[^\s,}]+',
        caseSensitive: false,
      ),
      '[credential redacted]',
    );

Future<Map<String, dynamic>> command(
  String name,
  String executable,
  List<String> args, {
  String? cwd,
  int? timeout,
}) async {
  final began = DateTime.now().toUtc();
  var status = 'failed', code = -1;
  var text = '';
  Process? process;
  Future<String>? capturedOut, capturedError;
  try {
    process = await Process.start(
      executable,
      args,
      workingDirectory: cwd ?? root.path,
    );
    capturedOut = process.stdout.transform(utf8.decoder).join();
    capturedError = process.stderr.transform(utf8.decoder).join();
    code = await process.exitCode.timeout(
      Duration(seconds: timeout ?? configTimeout('command')),
    );
    text = '${await capturedOut}\n${await capturedError}';
    status = code == 0 ? 'passed' : 'failed';
  } on TimeoutException {
    if (process != null) await terminateProcessTree(process);
    status = 'blocked';
    text =
        'Command timed out; no success evidence was produced.\n${await capturedOut?.timeout(const Duration(seconds: 3), onTimeout: () => 'Output stream did not close')}\n${await capturedError?.timeout(const Duration(seconds: 3), onTimeout: () => 'Error stream did not close')}';
  } on ProcessException catch (e) {
    status = 'blocked';
    text = 'Command unavailable: ${e.executable}';
  }
  final log = File(p.join(runDir.path, '$name.log'))
    ..writeAsStringSync(redact(text));
  final result = <String, dynamic>{
    'name': name,
    'status': status,
    'command': [executable, ...args],
    'exitCode': code,
    'startedAt': began.toIso8601String(),
    'finishedAt': DateTime.now().toUtc().toIso8601String(),
    'log': p.relative(log.path, from: root.path),
    'sha256': digest(log.readAsBytesSync()),
  };
  steps.add(result);
  stdout.writeln('$name: $status ($code)');
  return result;
}

Future<void> terminateProcessTree(Process process) async {
  if (!Platform.isWindows) {
    final listing = await Process.run('ps', ['-axo', 'pid=,ppid=']);
    final parents = <int, int>{};
    for (final line in (listing.stdout as String).split('\n')) {
      final columns = line.trim().split(RegExp(r'\s+'));
      if (columns.length == 2) {
        parents[int.parse(columns[0])] = int.parse(columns[1]);
      }
    }
    void killChildren(int parent) {
      for (final entry in parents.entries.where((e) => e.value == parent)) {
        killChildren(entry.key);
        Process.killPid(entry.key, ProcessSignal.sigterm);
      }
    }

    killChildren(process.pid);
  }
  process.kill();
}

int configTimeout(String key) =>
    ((config['timeouts_seconds'] as Map)[key] as num).toInt();
void result(String name, bool ok, Object details) {
  final file = File(p.join(runDir.path, '$name.json'));
  writeJson(file, details);
  steps.add({
    'name': name,
    'status': ok ? 'passed' : 'failed',
    'log': p.relative(file.path, from: root.path),
    'sha256': digest(file.readAsBytesSync()),
  });
  stdout.writeln('$name: ${ok ? 'passed' : 'failed'}');
}

Future<void> generated() async {
  final temp = await Directory.systemTemp.createTemp('xiaoyu-generated-');
  try {
    final files = await snapshot();
    for (final name in files.keys.where(
      (f) =>
          f.startsWith('lib/') ||
          [
            'pubspec.yaml',
            'pubspec.lock',
            'l10n.yaml',
            'build.yaml',
          ].contains(f),
    )) {
      final dest = File(p.join(temp.path, name));
      dest.parent.createSync(recursive: true);
      File(name).copySync(dest.path);
    }
    final pub = await command('generated-pub', 'flutter', [
      'pub',
      'get',
      '--offline',
    ], cwd: temp.path);
    if (pub['status'] != 'passed') return;
    await command('generated-l10n', 'flutter', ['gen-l10n'], cwd: temp.path);
    await command('generated-drift', 'dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], cwd: temp.path);
    final different = <String>[];
    final expected = files.keys
        .where(
          (f) => f.endsWith('.g.dart') || f.startsWith('lib/l10n/generated/'),
        )
        .toSet();
    for (final f in Directory(
      p.join(temp.path, 'lib'),
    ).listSync(recursive: true).whereType<File>()) {
      final relative = p.relative(f.path, from: temp.path);
      if (relative.endsWith('.g.dart') ||
          relative.startsWith('lib/l10n/generated/')) {
        expected.add(relative);
      }
    }
    for (final name in expected) {
      final actual = File(p.join(temp.path, name));
      if (!actual.existsSync() ||
          !File(name).existsSync() ||
          digest(actual.readAsBytesSync()) !=
              digest(File(name).readAsBytesSync())) {
        different.add(name);
      }
    }
    result('generated-consistency', different.isEmpty, {
      'different': different,
    });
  } finally {
    await temp.delete(recursive: true);
  }
}

Future<Map<String, dynamic>> currentSkillPlan({
  String? kind,
  List<String> topics = const [],
  List<String> names = const [],
}) async {
  final task = activeTask();
  final paths = task == null
      ? <String>{}
      : changedPaths(task, await snapshot());
  return planSkills(
    root,
    config,
    kind: kind ?? task?['kind'] as String? ?? 'logic',
    topics: {...?((task?['topics'] as List?)?.cast<String>()), ...topics},
    names: {...?((task?['skills'] as List?)?.cast<String>()), ...names},
    changedPaths: paths,
  );
}

Future<Map<String, dynamic>> currentSkillStatus() async {
  final task = activeTask();
  final file = File(p.join(output.path, 'skill-loads.json'));
  return skillLoadStatus(
    await currentSkillPlan(),
    file.existsSync() ? readJson(file) : null,
    task?['startedAt'] as String? ?? 'no-active-task',
  );
}

Future<void> showSkills({
  String? kind,
  List<String> topics = const [],
  List<String> names = const [],
  bool load = false,
  bool catalogOnly = false,
}) async {
  final plan = await currentSkillPlan(kind: kind, topics: topics, names: names);
  writeJson(File(p.join(output.path, 'skill-plan.json')), plan);
  if (catalogOnly) {
    for (final item in plan['catalog'] as List) {
      final row = item as Map;
      stdout.writeln(
        '${row['name']} — ${row['description']}\n  ${row['path']}',
      );
    }
    return;
  }
  stdout.writeln(encoder.convert(plan));
  if ((plan['errors'] as List).isNotEmpty) {
    throw StateError('Cannot load required skills; see skill-plan.json');
  }
  if (!load) {
    stdout.writeln(
      'Next: dart run tool/harness.dart skills --load (outputs selected installed SKILL.md bodies).',
    );
    return;
  }
  final task = activeTask();
  if (task == null) {
    throw StateError('Loading requires an active task; start one first.');
  }
  final taskId = task['startedAt'] as String;
  final file = File(p.join(output.path, 'skill-loads.json'));
  final previous = file.existsSync() ? readJson(file) : null;
  final entries = <Map<String, dynamic>>[
    if (previous?['taskId'] == taskId)
      ...(previous!['loads'] as List).map(
        (e) => Map<String, dynamic>.from(e as Map),
      ),
  ];
  final bodies = <String>[];
  for (final raw in plan['selected'] as List) {
    final row = Map<String, dynamic>.from(raw as Map);
    final content = File(row['path'] as String).readAsStringSync();
    if (digest(utf8.encode(content)) != row['sha256']) {
      throw StateError('Skill changed during loading: ${row['name']}');
    }
    bodies.add(
      '\n# Installed skill: ${row['name']}\nSource: ${row['path']}\n$content',
    );
    entries.removeWhere((e) => e['name'] == row['name']);
    entries.add({
      ...row,
      'loadedAt': DateTime.now().toUtc().toIso8601String(),
      'evidence': 'local_cli_file_read',
    });
  }
  final bundle = bodies.join('\n');
  File(p.join(output.path, 'loaded-skills.md')).writeAsStringSync(bundle);
  stdout.writeln(bundle);
  await stdout.flush();
  // Record only after the actual contents were read and emitted to the agent.
  writeJson(file, {
    'taskId': taskId,
    'loads': entries,
    'applicationEvidence': 'unverified',
  });
  if (topics.isNotEmpty || names.isNotEmpty) {
    task['topics'] = {
      ...?((task['topics'] as List?)?.cast<String>()),
      ...topics,
    }.toList();
    task['skills'] = {
      ...?((task['skills'] as List?)?.cast<String>()),
      ...names,
    }.toList();
    writeJson(File(p.join(output.path, 'task.json')), task);
  }
}

Future<void> check() async {
  final skillStatus = await currentSkillStatus();
  result('skill-routing', skillStatus['passed'] == true, skillStatus);
  final findings = inspectProject(root, config);
  final task = activeTask();
  if (task != null) {
    final current = await snapshot();
    final changed = changedPaths(task, current);
    if (changed.any(
          (f) => [
            'pubspec.yaml',
            'pubspec.lock',
            'harness.yaml',
            'analysis_options.yaml',
          ].contains(f),
        ) &&
        !changed.contains('docs/DECISIONS.md')) {
      findings.add((
        file: 'docs/DECISIONS.md',
        rule: 'change-justification',
        message: 'Dependency or policy changes need sources, reasons and alternatives recorded',
      ));
    }
  }

  final versions = await command('sdk', 'flutter', ['--version', '--machine']);
  if (versions['status'] == 'passed') {
    final sdk = jsonDecode(
      File(versions['log'] as String).readAsStringSync(),
    ) as Map<String, dynamic>;
    result(
      'sdk-versions',
      sdk['frameworkVersion'] == (config['sdk'] as Map)['flutter'] &&
          '${sdk['dartSdkVersion']}'.split(' ').first ==
              (config['sdk'] as Map)['dart'],
      sdk,
    );
  }
  result(
    'policy',
    findings.isEmpty,
    findings
        .map((f) => {'file': f.file, 'rule': f.rule, 'message': f.message})
        .toList(),
  );
  await command('format', 'dart', [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    'lib',
    'test',
    'tool',
    'integration_test',
  ]);
  await command('analyze', 'flutter', ['analyze', '--no-pub', '--fatal-infos']);
  await generated();
  final coverage = File('coverage/lcov.info');
  if (coverage.existsSync()) coverage.deleteSync();
  final tests = await command('tests', 'flutter', [
    'test',
    '--no-pub',
    '--coverage',
    '--machine',
  ], timeout: configTimeout('check_tests'));
  if (tests['status'] == 'passed' && coverage.existsSync()) {
    final counts = coverageResult(
      coverage.readAsStringSync(),
      root,
      Map<String, dynamic>.from(config['coverage'] as Map),
    );
    result('coverage', counts['passed'] == true, counts);
    coverage.copySync(p.join(runDir.path, 'lcov.info'));
    final log = File(tests['log'] as String).readAsStringSync();
    final execution = executionResult(log, root, config);
    result('test-execution', execution['passed'] == true, execution);
  } else {
    result('coverage', false, {
      'reason': 'No coverage from a successful current test run',
    });
  }
}

Future<void> build(String platform) async {
  if (platform != 'ios') {
    await command('build-android', 'flutter', [
      'build',
      'apk',
      '--debug',
      '--no-pub',
    ], timeout: configTimeout('build'));
  }
  if (platform != 'ios') {
    final apk = File('build/app/outputs/flutter-apk/app-debug.apk');
    if (steps.any(
          (s) => s['name'] == 'build-android' && s['status'] == 'passed',
        ) &&
        apk.existsSync()) {
      final saved = apk.copySync(p.join(runDir.path, 'app-debug.apk'));
      steps.add({
        'name': 'android-artifact',
        'status': 'passed',
        'log': saved.path,
        'sha256': digest(saved.readAsBytesSync()),
      });
    } else {
      result('android-artifact', false, {
        'reason': 'No successful current APK',
      });
    }
  }
  if (platform != 'android') {
    await command('build-ios', 'flutter', [
      'build',
      'ios',
      '--debug',
      '--no-codesign',
      '--no-pub',
    ], timeout: configTimeout('build'));
    final flags = <String>[];
    final derived = Directory(
      p.join(
        Platform.environment['HOME'] ?? '',
        'Library/Developer/Xcode/DerivedData',
      ),
    );
    if (derived.existsSync()) {
      for (final d in derived.listSync().whereType<Directory>().where(
        (d) => p.basename(d.path).startsWith('Runner-'),
      )) {
        final info = File(p.join(d.path, 'info.plist'));
        if (!info.existsSync()) continue;
        final plist = await Process.run('/usr/bin/plutil', [
          '-extract',
          'WorkspacePath',
          'raw',
          '-o',
          '-',
          info.path,
        ]);
        if (plist.exitCode != 0 ||
            (plist.stdout as String).trim() !=
                p.join(root.path, 'ios/Runner.xcworkspace')) {
          continue;
        }
        final folder = Directory(
          p.join(
            d.path,
            'Build/Intermediates.noindex/permission_handler_apple.build/Debug-iphoneos/permission_handler_apple.build/Objects-normal/arm64',
          ),
        );
        if (folder.existsSync()) {
          for (final f in folder.listSync().whereType<File>().where(
            (f) => f.path.endsWith('common-args.resp'),
          )) {
            flags.addAll(
              RegExp(r'PERMISSION_(?:MICROPHONE|CAMERA|PHOTOS)=\d')
                  .allMatches(f.readAsStringSync())
                  .map((m) => m[0]!),
            );
          }
        }
      }
    }
    result(
      'ios-permissions',
      flags.contains('PERMISSION_MICROPHONE=1') &&
          flags.contains('PERMISSION_CAMERA=0') &&
          !flags.contains('PERMISSION_MICROPHONE=0') &&
          !flags.contains('PERMISSION_CAMERA=1'),
      {'definitions': flags.toSet().toList()},
    );
    final bundle = Directory('build/ios/iphoneos/Runner.app');
    final forbidden = bundle.existsSync()
        ? bundle
              .listSync(recursive: true)
              .where((f) => RegExp('Volc|ByteRTC').hasMatch(p.basename(f.path)))
              .map((f) => p.basename(f.path))
              .toList()
        : ['Missing bundle'];
    result('native-dependencies', forbidden.isEmpty, {'forbidden': forbidden});
    final executable = File(p.join(bundle.path, 'Runner'));
    if (steps.any((s) => s['name'] == 'build-ios' && s['status'] == 'passed') &&
        executable.existsSync()) {
      final archive = File(p.join(runDir.path, 'Runner.app.zip'));
      final packaged = await command('ios-package', '/usr/bin/ditto', [
        '-c',
        '-k',
        '--sequesterRsrc',
        '--keepParent',
        bundle.path,
        archive.path,
      ]);
      if (packaged['status'] == 'passed' && archive.existsSync()) {
        steps.add({
          'name': 'ios-artifact',
          'status': 'passed',
          'log': archive.path,
          'sha256': digest(archive.readAsBytesSync()),
        });
      } else {
        result('ios-artifact', false, {'reason': 'No complete iOS archive'});
      }
    } else {
      result('ios-artifact', false, {
        'reason': 'No successful current iOS executable',
      });
    }
  }
}

Future<void> doctor() async {
  await command('flutter', 'flutter', ['--version', '--machine']);
  await command('dart', 'dart', ['--version']);
  await command('xcode', 'xcodebuild', ['-version']);
  await command('java', 'java', ['-version']);
  final connected = await command('devices', 'flutter', [
    'devices',
    '--machine',
  ]);
  if (connected['status'] == 'passed') {
    final devices = (jsonDecode(
      File(connected['log'] as String).readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    final missing = ['android', 'ios']
        .where(
          (platform) => !devices.any(
            (d) => '${d['targetPlatform']}'.startsWith(platform),
          ),
        )
        .toList();
    result('device-availability', missing.isEmpty, {
      'missingPlatforms': missing,
      'devices': devices,
    });
    if (missing.isNotEmpty) steps.last['status'] = 'unverified';
  }
  final skillPlan = await currentSkillPlan();
  result('skills', (skillPlan['errors'] as List).isEmpty, skillPlan);
  result(
    'locks',
    File('pubspec.lock').existsSync() &&
        File('ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved')
            .existsSync(),
    {
      'pub': 'pubspec.lock',
      'spm': 'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved',
    },
  );
}

Map<String, dynamic>? activeTask() {
  final file = File(p.join(output.path, 'task.json'));
  return file.existsSync() ? readJson(file) : null;
}

Set<String> changedPaths(Map<String, dynamic> task, Map<String, String> now) {
  final before = Map<String, dynamic>.from(task['snapshot'] as Map);
  return {
    ...before.keys,
    ...now.keys,
  }.where((f) => before[f] != now[f]).toSet();
}

bool verifiedReport(
  Map<String, dynamic> report,
  String hash, {
  String? platform,
}) {
  if (report['sourceHash'] != hash ||
      report['unchanged'] != true ||
      (platform == null && report['status'] != 'passed')) {
    return false;
  }
  final rawSteps = report['steps'];
  if (rawSteps is! List || rawSteps.isEmpty) return false;
  final scope = platform ?? report['platform'];
  final required = switch (report['command']) {
    'check' => {
      'skill-routing',
      'sdk',
      'sdk-versions',
      'policy',
      'format',
      'analyze',
      'generated-pub',
      'generated-l10n',
      'generated-drift',
      'generated-consistency',
      'tests',
      'coverage',
      'test-execution',
    },
    'build' => {
      if (scope != 'ios') ...['build-android', 'android-artifact'],
      if (scope != 'android') ...[
        'build-ios',
        'ios-permissions',
        'native-dependencies',
        'ios-artifact',
      ],
    },
    'device' => {'device-${report['platform']}', 'device-identity'},
    'self-test' => {'self-test'},
    _ => <String>{},
  };
  if (required.isEmpty ||
      !required.every(
        (name) => rawSteps.any((s) => s is Map && s['name'] == name),
      )) {
    return false;
  }
  final selected = platform == null
      ? rawSteps
      : rawSteps.where((s) => s is Map && required.contains(s['name']));
  return selected.every((raw) {
    if (raw is! Map ||
        raw['status'] != 'passed' ||
        raw['log'] is! String ||
        (raw.containsKey('exitCode') && raw['exitCode'] != 0)) {
      return false;
    }
    final file = File(raw['log'] as String);
    return file.existsSync() && digest(file.readAsBytesSync()) == raw['sha256'];
  });
}

String latestReportState(
  Iterable<Map<String, dynamic>> reports,
  String hash,
  String cmd, [
  String? step,
]) {
  final platform = step?.split('-').last;
  final candidates =
      reports
          .where(
            (r) =>
                r['command'] == cmd &&
                r['sourceHash'] == hash &&
                (step == null || ['both', platform].contains(r['platform'])),
          )
          .toList()
        ..sort((a, b) => '${b['finishedAt']}'.compareTo('${a['finishedAt']}'));
  if (candidates.isEmpty) return 'unverified';
  final latest = candidates.first;
  if (latest['status'] == 'running') return 'unverified';
  if (verifiedReport(
    latest,
    hash,
    platform: cmd == 'build' ? platform : null,
  )) {
    return 'passed';
  }
  return latest['status'] == 'blocked' ? 'blocked' : 'failed';
}

Future<bool> report({bool finish = false}) async {
  final now = await snapshot(), hash = treeHash(await snapshot());
  final task = activeTask();
  final head = await Process.run('git', ['rev-parse', '--verify', 'HEAD']);
  final paths = task == null || head.exitCode != 0
      ? now.keys.toSet()
      : changedPaths(task, now);
  final kinds = <String>{if (task != null) task['kind'] as String};
  if (paths.any(
    (f) => f.startsWith('lib/ui/') || f == 'design.html' || f == 'DESIGN.md',
  )) {
    kinds.add('ui');
  }
  if (paths.any((f) => f.startsWith('ios/') || f.startsWith('android/'))) {
    kinds.add('native');
  }
  if (paths.any((f) => f == 'pubspec.yaml' || f == 'pubspec.lock')) {
    kinds.add('dependency');
  }
  final reports = <Map<String, dynamic>>[];
  final runs = Directory(p.join(output.path, 'runs'));
  if (runs.existsSync()) {
    for (final d in runs.listSync().whereType<Directory>()) {
      final file = File(p.join(d.path, 'report.json'));
      if (file.existsSync()) {
        reports.add({...readJson(file), 'reportPath': p.relative(file.path)});
      }
    }
  }
  reports.sort((a, b) => '${b['finishedAt']}'.compareTo('${a['finishedAt']}'));
  String state(String cmd, [String? step]) =>
      latestReportState(reports, hash, cmd, step);

  final native = kinds.any(['ui', 'native', 'dependency'].contains);
  final states = <String, String>{
    'code': state('check'),
    'build.android': native
        ? state('build', 'build-android')
        : 'not_applicable',
    'build.ios': native ? state('build', 'build-ios') : 'not_applicable',
    'device.android': native
        ? state('device', 'device-android')
        : 'not_applicable',
    'device.ios': native ? state('device', 'device-ios') : 'not_applicable',
    'visualReview': kinds.contains('ui') ? 'unverified' : 'not_applicable',
    'glassRefraction': kinds.contains('ui') ? 'unverified' : 'not_applicable',
    'realVideoComposition': kinds.contains('ui')
        ? 'unverified'
        : 'not_applicable',
    'mcpEvidence': 'unverified',
    'skillLoading': (await currentSkillStatus())['passed'] == true
        ? 'passed'
        : 'unverified',
    'skillApplication': 'unverified',
  };
  final ready =
      task != null &&
      states.entries
          .where((e) => !['mcpEvidence', 'skillApplication'].contains(e.key))
          .every((e) => ['passed', 'not_applicable'].contains(e.value));
  final summary = {
    'task': task?['goal'],
    'sourceHash': hash,
    'changedPaths': paths.toList()..sort(),
    'states': states,
    'ready': ready,
    'acceptance': task?['acceptance'],
    'skills': await currentSkillStatus(),
    'risk': task?['risk'],
    'evidence': reports
        .take(20)
        .map(
          (r) => {
            'command': r['command'],
            'platform': r['platform'],
            'status': r['status'],
            'currentSource': r['sourceHash'] == hash,
            'unchanged': r['unchanged'],
            'report': r['reportPath'],
            'failures': (r['steps'] as List)
                .where((s) => (s as Map)['status'] != 'passed')
                .toList(),
          },
        )
        .toList(),
    'uncovered': [
      ...states.entries
          .where((e) => !['passed', 'not_applicable'].contains(e.value))
          .map((e) => e.key),
      'Knowledge import and voice preview are not implemented; UI marks them unavailable.',
      'Real RTC media and billing were not exercised by this offline harness.',
    ],
    'limitations': [
      'Repository artifacts are inspectable evidence, not a tamper-proof audit.',
      'Self-authored MCP claims and visual approvals are not trusted automatically.',
      'Device tests use simulated media; paid live RTC acceptance is separate.',
    ],
  };
  writeComparison(output);
  writeJson(File(p.join(output.path, 'summary.json')), summary);
  File(p.join(output.path, 'summary.md')).writeAsStringSync(
    '# 小遇验证报告\n\n任务：${task?['goal'] ?? '尚未开始'}\n\n验收条件：${task?['acceptance'] ?? '无'}\n\n${states.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}\n\n可完成：$ready\n\n证据（currentSource=false 或 unchanged=false 的旧结果不用于通过）：\n\n${reports.take(20).map((r) => '- ${r['command']} ${r['platform'] ?? ''}: ${r['status']}; currentSource=${r['sourceHash'] == hash}; unchanged=${r['unchanged']} — [报告](${p.relative(r['reportPath'] as String, from: output.path)})').join('\n')}\n\n各报告 steps 包含命令、退出码、时间、日志与摘要，失败原因见对应日志。设计对照见 [六屏对照](design-comparison.html)。\n\n未覆盖：知识库导入、音色试听未实现；真实 RTC 媒体和计费未在本次离线检查中验收。视觉审查须在宿主由用户确认，CLI 不接受自填 passed。MCP 调用在宿主记录中审计；本报告不伪造可信记录。\n',
  );
  stdout.writeln(encoder.convert(summary));
  if (finish && ready) {
    task['completedAt'] = DateTime.now().toUtc().toIso8601String();
    writeJson(File(p.join(output.path, 'task.json')), task);
  }
  return ready;
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'kind',
      allowed: ['ui', 'logic', 'dependency', 'native', 'docs'],
    )
    ..addOption('goal')
    ..addOption('accept')
    ..addOption(
      'risk',
      defaultsTo: 'No new paid calls; existing behavior must remain.',
    )
    ..addOption(
      'platform',
      allowed: ['android', 'ios', 'both'],
      defaultsTo: 'both',
    )
    ..addMultiOption('topic')
    ..addMultiOption('skill')
    ..addFlag('load', negatable: false)
    ..addFlag('catalog', negatable: false)
    ..addOption('device-id');
  try {
    config = jsonDecode(
      jsonEncode(loadYaml(File('harness.yaml').readAsStringSync())),
    ) as Map<String, dynamic>;
    final args = parser.parse(arguments);
    if (args.rest.length != 1) {
      throw ArgumentError(
        'Use doctor|start|skills|check|build|device|report|finish|self-test|install-hooks|golden-update',
      );
    }
    final cmd = args.rest.single;
    output.createSync(recursive: true);
    if (cmd == 'skills') {
      await showSkills(
        kind: args['kind'] as String?,
        topics: (args['topic'] as List).cast<String>(),
        names: (args['skill'] as List).cast<String>(),
        load: args['load'] as bool,
        catalogOnly: args['catalog'] as bool,
      );
      return;
    }
    if (cmd == 'start') {
      if (activeTask() case final task? when task['completedAt'] == null) {
        throw StateError(
          'An unfinished task exists; read report before starting another.',
        );
      }
      if (args['kind'] == null ||
          args['goal'] == null ||
          args['accept'] == null) {
        throw ArgumentError('start requires --kind, --goal and --accept');
      }
      writeJson(File(p.join(output.path, 'task.json')), {
        'kind': args['kind'],
        'topics': (args['topic'] as List).cast<String>(),
        'skills': (args['skill'] as List).cast<String>(),
        'goal': args['goal'],
        'acceptance': args['accept'],
        'risk': args['risk'],
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'snapshot': await snapshot(),
      });
      stdout.writeln(
        'Task recorded. Load the routed installed skills before implementing.',
      );
      await showSkills();
      return;
    }
    if (cmd == 'report' || cmd == 'finish') {
      final ok = await report(finish: cmd == 'finish');
      if (cmd == 'finish' && !ok) exitCode = 1;
      return;
    }
    if (cmd == 'install-hooks') {
      final git = await Process.run('git', [
        'rev-parse',
        '--git-path',
        'hooks',
      ]);
      if (git.exitCode != 0) throw StateError('Cannot locate hooks');
      for (final entry in {
        'pre-commit': 'check',
        'pre-push': 'finish',
      }.entries) {
        final f = File(p.join((git.stdout as String).trim(), entry.key));
        if (f.existsSync()) {
          throw StateError('Existing hook preserved: ${entry.key}');
        }
      }
      for (final entry in {
        'pre-commit': 'check',
        'pre-push': 'finish',
      }.entries) {
        final f = File(p.join((git.stdout as String).trim(), entry.key));
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(
          '#!/bin/sh\nset -eu\ncd "\$(git rev-parse --show-toplevel)"\nexec dart run tool/harness.dart ${entry.value}\n',
        );
        await Process.run('chmod', ['+x', f.path]);
      }
      return;
    }
    runId = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
    runDir = Directory(p.join(output.path, 'runs', runId))
      ..createSync(recursive: true);
    final before = await snapshot();
    final startedAt = DateTime.now().toUtc().toIso8601String();
    writeJson(File(p.join(runDir.path, 'report.json')), {
      'id': runId,
      'command': cmd,
      'platform': args['platform'],
      'sourceHash': treeHash(before),
      'unchanged': false,
      'status': 'running',
      'steps': <Object?>[],
      'startedAt': startedAt,
      'finishedAt': startedAt,
    });
    runCreated = true;
    switch (cmd) {
      case 'doctor':
        await doctor();
      case 'check':
        await check();
      case 'build':
        await build(args['platform'] as String);
      case 'device':
        final id = args['device-id'] as String?;
        if (id == null) throw ArgumentError('device requires --device-id');
        final devices = await Process.run('flutter', ['devices', '--machine']);
        final list = jsonDecode(devices.stdout as String) as List;
        final device = list
            .cast<Map<String, dynamic>>()
            .where((d) => d['id'] == id)
            .firstOrNull;
        if (device == null) {
          result('device-lookup', false, {
            'reason': 'Requested device unavailable',
            'requestedId': id,
          });
          steps.last['status'] = 'blocked';
          break;
        }
        result('device-identity', true, device);
        final platform = '${device['targetPlatform']}'.startsWith('android')
            ? 'android'
            : '${device['targetPlatform']}' == 'ios'
            ? 'ios'
            : null;
        if (platform == null) {
          throw StateError('Only Android/iOS devices are supported');
        }
        final response = File('build/harness/device-response.json');
        if (response.existsSync()) response.deleteSync();
        await command(
          'device-$platform',
          'flutter',
          platform == 'ios'
              ? [
                  'drive',
                  '--no-pub',
                  '--driver=tool/harness/offline_driver.dart',
                  '--target=integration_test/offline_smoke_test.dart',
                  '--publish-port',
                  '--no-dds',
                  '--no-start-paused',
                  '--host-vmservice-port=55981',
                  '--no-uninstall-first',
                  '-d',
                  id,
                ]
              : [
                  'test',
                  'integration_test/offline_smoke_test.dart',
                  '--no-uninstall',
                  '-d',
                  id,
                ],
          timeout: configTimeout('device'),
        );
        if (response.existsSync()) {
          final artifact = File(p.join(runDir.path, 'device-response.json'));
          response.copySync(artifact.path);
          final captures = readJson(response)['screenshots'];
          if (captures is List) {
            for (final raw in captures) {
              final image = raw as Map;
              final file = File(image['path'] as String);
              if (!file.existsSync()) {
                result('device-screenshot', false, {
                  'reason': 'Missing screenshot',
                });
                continue;
              }
              final saved = file.copySync(
                p.join(runDir.path, p.basename(file.path)),
              );
              steps.add({
                'name': 'device-screenshot',
                'status': 'passed',
                'log': saved.path,
                'sha256': digest(saved.readAsBytesSync()),
              });
            }
          }
          steps.add({
            'name': 'device-response',
            'status': 'passed',
            'log': artifact.path,
            'sha256': digest(artifact.readAsBytesSync()),
          });
        }
      case 'self-test':
        await command('self-test', 'flutter', [
          'test',
          '--no-pub',
          'test/harness',
        ]);
      case 'golden-update':
        await command('golden-update', 'flutter', [
          'test',
          '--no-pub',
          '--update-goldens',
          'test/ui/golden_test.dart',
        ]);
        writeComparison(output);
        stdout.writeln(
          'Baselines changed; review screenshots against design.html. All earlier code evidence is stale.',
        );
      default:
        throw ArgumentError('Unknown command: $cmd');
    }
    final after = await snapshot();
    final unchanged = treeHash(before) == treeHash(after);
    final ok =
        steps.isNotEmpty &&
        steps.every((s) => s['status'] == 'passed') &&
        unchanged;
    writeJson(File(p.join(runDir.path, 'report.json')), {
      'id': runId,
      'startedAt': startedAt,
      'command': cmd,
      'platform': cmd == 'device'
          ? steps
                .where(
                  (s) => ['device-android', 'device-ios'].contains(s['name']),
                )
                .map((s) => '${s['name']}'.substring(7))
                .firstOrNull
          : args['platform'],
      'sourceHash': treeHash(before),
      'unchanged': unchanged,
      'status': ok
          ? 'passed'
          : steps.any((s) => ['blocked', 'unverified'].contains(s['status']))
          ? 'blocked'
          : 'failed',
      'configuredSdk': config['sdk'],
      'toolVersions': {
        'dart': Platform.version,
        'os': Platform.operatingSystemVersion,
      },
      'steps': steps,
      'finishedAt': DateTime.now().toUtc().toIso8601String(),
    });
    stdout.writeln('Report: ${p.relative(runDir.path)}/report.json');
    if (!ok &&
        !(cmd == 'golden-update' &&
            steps.isNotEmpty &&
            steps.every((s) => s['status'] == 'passed'))) {
      exitCode = 1;
    }
  } on Object catch (e) {
    if (runCreated) {
      final file = File(p.join(runDir.path, 'report.json'));
      final record = readJson(file);
      writeJson(file, {
        ...record,
        'status': 'failed',
        'unchanged': false,
        'steps': steps,
        'failure': e.runtimeType.toString(),
        'finishedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
    stderr.writeln(redact('Harness stopped: $e'));
    exitCode = 1;
  }
}
