import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/harness.dart' as harness;
import '../../tool/harness/skills.dart';

void main() {
  late Directory root;
  late Map<String, dynamic> config;

  void install(
    String name, {
    String body = 'Follow the installed instructions.',
  }) {
    final file = File(p.join(root.path, '.agents/skills', name, 'SKILL.md'));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('''---
name: $name
description: >-
  Installed skill for
  $name tasks.
---
$body
''');
  }

  Map<String, dynamic> plan({
    String kind = 'docs',
    List<String> topics = const [],
    List<String> names = const [],
    List<String> paths = const [],
  }) => planSkills(
    root,
    config,
    kind: kind,
    topics: topics,
    names: names,
    changedPaths: paths,
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('xiaoyu-skills-');
    config = {
      'skill_routing': {
        'kinds': {
          'ui': ['ui'],
          'docs': <String>[],
        },
        'topics': {
          'ui': ['responsive'],
          'cli': ['cli'],
        },
        'paths': [
          {
            'prefix': 'tool/',
            'topics': ['cli'],
          },
        ],
      },
    };
    install('responsive');
    install('cli', body: 'Use the actual installed CLI instructions.');
    install('xiaoyu-harness');
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('discovers newly installed skills and folded descriptions', () {
    expect(discoverSkills(root).map((s) => s.name), [
      'cli',
      'responsive',
      'xiaoyu-harness',
    ]);
    install('new-user-skill', body: 'New local instructions.');
    final skill = discoverSkills(root)
        .singleWhere((s) => s.name == 'new-user-skill');
    expect(skill.description, 'Installed skill for new-user-skill tasks.');
    expect(skill.content, contains('New local instructions.'));
    expect(skill.hash, harness.digest(utf8.encode(skill.content)));
    expect(plan(names: ['new-user-skill'])['errors'], isEmpty);
  });

  test('kind, changed paths and explicit topics select original skills', () {
    final selected =
        plan(kind: 'ui', paths: ['tool/harness.dart'])['selected'] as List;
    expect(selected.map((dynamic s) => (s as Map)['name']), [
      'responsive',
      'cli',
    ]);
    expect(plan(topics: ['cli'])['selected'], hasLength(1));
    expect(
      selected.every((dynamic s) => (s as Map)['name'] != 'xiaoyu-harness'),
      isTrue,
    );
  });

  test('unknown topics and missing skills fail instead of falling back', () {
    expect(plan(topics: ['typo'])['errors'], contains('Unknown topic: typo'));
    expect(plan(names: ['not-installed'])['errors'], isNotEmpty);
    File(p.join(root.path, '.agents/skills/responsive/SKILL.md')).deleteSync();
    expect(
      plan(kind: 'ui')['errors'],
      contains('Required skill is not installed: responsive'),
    );
  });

  test('malformed or duplicate installed skill metadata is rejected', () {
    final file = File(p.join(root.path, '.agents/skills/cli/SKILL.md'));
    file.writeAsStringSync('No frontmatter');
    expect(() => discoverSkills(root), throwsFormatException);
    install('cli');
    final duplicate = File(p.join(root.path, '.agents/skills/copy/SKILL.md'));
    duplicate.parent.createSync(recursive: true);
    duplicate.writeAsStringSync(file.readAsStringSync());
    expect(() => discoverSkills(root), throwsFormatException);
  });

  test('missing, stale and different-task loads cannot pass', () {
    final required = plan(kind: 'ui');
    final record = <String, dynamic>{
      'taskId': 'task-1',
      'loads': required['selected'],
    };
    expect(skillLoadStatus(required, null, 'task-1')['passed'], isFalse);
    expect(skillLoadStatus(required, record, 'task-1')['passed'], isTrue);
    expect(skillLoadStatus(required, record, 'task-2')['passed'], isFalse);
    install('responsive', body: 'Changed instructions must be read again.');
    expect(
      skillLoadStatus(plan(kind: 'ui'), record, 'task-1')['missingOrStale'],
      ['responsive'],
    );
    expect(
      skillLoadStatus(required, record, 'task-1')['applicationEvidence'],
      'unverified',
    );
  });

  test('loading coordinator alone cannot satisfy routed skills', () {
    final coordinator = plan(names: ['xiaoyu-harness']);
    final record = <String, dynamic>{
      'taskId': 'task',
      'loads': coordinator['selected'],
    };
    expect(
      skillLoadStatus(plan(kind: 'ui'), record, 'task')['passed'],
      isFalse,
    );
  });

  test(
    'CLI emits installed bodies, records task hashes and blocks unknown skills',
    () async {
      final git = await Process.run('git', [
        'init',
        '--quiet',
      ], workingDirectory: root.path);
      expect(git.exitCode, 0);
      File(p.join(root.path, '.gitignore')).writeAsStringSync('build/\n');
      File(p.join(root.path, 'harness.yaml'))
          .writeAsStringSync(jsonEncode(config));
      final task = File(p.join(root.path, 'build/harness/task.json'));
      task.parent.createSync(recursive: true);
      task.writeAsStringSync(
        jsonEncode({
          'kind': 'ui',
          'startedAt': 'task-cli',
          'snapshot': <String, String>{},
        }),
      );
      Future<ProcessResult> run(List<String> arguments) => Process.run('dart', [
        '--packages=${p.absolute('.dart_tool/package_config.json')}',
        p.absolute('tool/harness.dart'),
        'skills',
        ...arguments,
      ], workingDirectory: root.path);
      final dryRun = await run([]);
      expect(dryRun.exitCode, 0, reason: '${dryRun.stderr}');
      final loads = File(p.join(root.path, 'build/harness/skill-loads.json'));
      expect(loads.existsSync(), isFalse);
      final loaded = await run(['--load', '--topic', 'cli']);
      expect(loaded.exitCode, 0, reason: '${loaded.stderr}');
      expect(
        loaded.stdout,
        contains('Use the actual installed CLI instructions.'),
      );
      final record =
          jsonDecode(loads.readAsStringSync()) as Map<String, dynamic>;
      expect(record['taskId'], 'task-cli');
      expect(
        skillLoadStatus(
          plan(kind: 'ui', topics: ['cli']),
          record,
          'task-cli',
        )['passed'],
        isTrue,
      );
      expect(record['applicationEvidence'], 'unverified');
      final persisted = jsonDecode(task.readAsStringSync()) as Map;
      expect(persisted['topics'], ['cli']);
      final beforeFailure = loads.readAsStringSync();
      final failure = await run(['--load', '--skill', 'not-installed']);
      expect(failure.exitCode, isNonZero);
      expect(loads.readAsStringSync(), beforeFailure);
    },
  );

  test(
    'check report missing skill gate is invalid even with other passed steps',
    () {
      final log = File(p.join(root.path, 'passed.log'))
        ..writeAsStringSync('passed');
      final names = [
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
      ];
      final report = <String, dynamic>{
        'command': 'check',
        'sourceHash': 'current',
        'unchanged': true,
        'status': 'passed',
        'steps': [
          for (final name in names)
            {
              'name': name,
              'status': 'passed',
              'log': log.path,
              'sha256': harness.digest(log.readAsBytesSync()),
            },
        ],
      };
      expect(harness.verifiedReport(report, 'current'), isFalse);
    },
  );
}
