import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/harness.dart' as harness;
import '../../tool/harness/retention.dart';

void main() {
  late Directory root;
  late ArtifactRetention gc;
  const old = '1000000000000001', recent = '1000000000000002';
  File runFile(String id, String name) =>
      File(p.join(root.path, 'build/harness/runs', id, name));
  void create(
    String id, {
    String status = 'passed',
    String name = 'app-debug.apk',
    String command = 'build',
    String platform = 'android',
    List<Object?>? steps,
  }) {
    final artifact = runFile(id, name)..parent.createSync(recursive: true);
    artifact.writeAsStringSync('test artifact $id $name');
    final log = runFile(id, 'build.log')..writeAsStringSync('offline log');
    runFile(id, 'report.json').writeAsStringSync(
      jsonEncode({
        'id': id,
        'command': command,
        'platform': platform,
        'status': status,
        'sourceHash': 'hash',
        'unchanged': true,
        'finishedAt': id,
        'steps':
            steps ??
            [
              {
                'name': 'build-android',
                'status': 'passed',
                'log': log.path,
                'sha256': sha256.convert(log.readAsBytesSync()).toString(),
              },
              {
                'name': 'android-artifact',
                'status': 'passed',
                'log': artifact.path,
                'sha256': sha256.convert(artifact.readAsBytesSync()).toString(),
              },
            ],
      }),
    );
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('harness-retention-');
    gc = ArtifactRetention(root, keepPerPlatform: 1);
    create(old);
    create(recent);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test(
    'dry run lists sizes and reasons without deleting or changing reports',
    () async {
      final before = runFile(old, 'report.json').readAsStringSync();
      final plan = await gc.collect(dryRun: true);
      expect((plan['candidates'] as List).single['run'], old);
      expect(
        plan['candidateBytes'],
        runFile(old, 'app-debug.apk').lengthSync(),
      );
      expect(
        (plan['kept'] as List).single['reasons'],
        contains('recent: app-debug.apk'),
      );
      expect(runFile(old, 'report.json').readAsStringSync(), before);
      expect(runFile(old, 'app-debug.apk').existsSync(), isTrue);
      expect(
        File(p.join(gc.output.path, 'gc-last.json')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'collection expires evidence, preserves diagnostics, and is idempotent',
    () async {
      final report = ArtifactRetention.read(runFile(old, 'report.json'));
      expect(harness.verifiedReport(report, 'hash'), isTrue);
      final result = await gc.collect(dryRun: false);
      expect(result['removedBytes'], greaterThan(0));
      expect(runFile(old, 'app-debug.apk').existsSync(), isFalse);
      expect(runFile(old, 'build.log').readAsStringSync(), 'offline log');
      final expired = ArtifactRetention.read(runFile(old, 'report.json'));
      expect(
        expired['status'],
        'passed',
        reason: 'Historical command result retained',
      );
      expect(expired['evidenceState'], 'expired');
      expect(harness.verifiedReport(expired, 'hash'), isFalse);
      expect(
        harness.latestReportState([expired], 'hash', 'build', 'build-android'),
        'expired',
      );
      expect((await gc.collect(dryRun: false))['removedBytes'], 0);
      expect(runFile(recent, 'app-debug.apk').existsSync(), isTrue);
    },
  );

  test(
    'running jobs stay protected regardless of age or artifact count',
    () async {
      create(old, status: 'running');
      expect((await gc.collect(dryRun: true))['candidates'], isEmpty);
    },
  );

  test('unknown report states preserve their artifacts', () async {
    create(old, status: 'future-state');
    final plan = await gc.collect(dryRun: true);
    expect(plan['candidates'], isEmpty);
    expect((plan['protectedRuns'] as Map)[old], contains('unknown-status'));
  });

  test(
    'missing and malformed reports fail closed for their artifacts',
    () async {
      runFile(old, 'report.json').writeAsStringSync('{');
      var plan = await gc.collect(dryRun: true);
      expect(plan['candidates'], isEmpty);
      expect(plan['warnings'], isNotEmpty);
      runFile(old, 'report.json').deleteSync();
      plan = await gc.collect(dryRun: true);
      expect(plan['candidates'], isEmpty);
    },
  );

  test(
    'release pins override count policy; unpin enables collection',
    () async {
      await gc.pin(old, 'release v1');
      expect((await gc.collect(dryRun: true))['candidates'], isEmpty);
      await gc.pin(old, 'remove', remove: true);
      expect((await gc.collect(dryRun: true))['candidates'], hasLength(1));
      await expectLater(gc.pin('../outside', 'bad'), throwsArgumentError);
      await expectLater(gc.pin(recent, ''), throwsArgumentError);
    },
  );

  test('invalid pin data stops all deletion', () async {
    File(p.join(gc.output.path, 'pins.json'))
        .writeAsStringSync('{"../bad":"release"}');
    await expectLater(gc.collect(dryRun: false), throwsFormatException);
    expect(runFile(old, 'app-debug.apk').existsSync(), isTrue);
  });

  test(
    'summary and handoff references protect their original artifacts',
    () async {
      final reference = File(p.join(root.path, 'handoff.md'))
        ..writeAsStringSync('[evidence](build/harness/runs/$old/report.json)');
      final result = await gc.collect(
        dryRun: false,
        referenceFiles: [reference.path],
      );
      expect(result['removed'], isEmpty);
      expect(
        (result['protectedRuns'] as Map)[old],
        contains('reference: handoff.md'),
      );
    },
  );

  test(
    'all retained reports preserve cross-report dependency chains',
    () async {
      create('1000000000000003');
      final a = ArtifactRetention.read(runFile(recent, 'report.json'))
        ..['dependsOn'] = 'build/harness/runs/$old/report.json';
      runFile(recent, 'report.json').writeAsStringSync(jsonEncode(a));
      final result = await gc.collect(dryRun: true);
      final candidates = (result['candidates'] as List)
          .cast<Map<String, dynamic>>();
      expect(candidates.map((c) => c['run']), isNot(contains(old)));
    },
  );

  test('retains independent recent Android and iOS artifacts', () async {
    create('1000000000000000', name: 'Runner.app.zip');
    create(old, name: 'Runner.app.zip');
    final result = await gc.collect(dryRun: false);
    expect(result['removed'], hasLength(2));
    expect(runFile('1000000000000000', 'Runner.app.zip').existsSync(), isFalse);
    expect(runFile(old, 'app-debug.apk').existsSync(), isFalse);
    expect(runFile(old, 'Runner.app.zip').existsSync(), isTrue);
    expect(runFile(recent, 'app-debug.apk').existsSync(), isTrue);
  });

  test(
    'symlinked artifacts and directories never remove outside content',
    () async {
      final outside = File(p.join(root.path, 'keep.apk'))
        ..writeAsStringSync('untouched');
      runFile(old, 'app-debug.apk').deleteSync();
      Link(runFile(old, 'app-debug.apk').path).createSync(outside.path);
      final result = await gc.collect(dryRun: false);
      expect(result['removed'], isEmpty);
      expect(outside.readAsStringSync(), 'untouched');
      final other = Directory(p.join(root.path, 'other'))..createSync();
      Link(p.join(gc.runs.path, '1000000000000000')).createSync(other.path);
      expect((await gc.collect(dryRun: false))['removed'], isEmpty);
    },
  );

  test('symlinked output refuses collection', () async {
    final external = Directory.systemTemp.createTempSync('harness-external-');
    addTearDown(() => external.deleteSync(recursive: true));
    gc.output.deleteSync(recursive: true);
    Link(gc.output.path).createSync(external.path);
    await expectLater(gc.collect(dryRun: false), throwsStateError);
  });

  test('oversized reference cannot be silently bypassed', () async {
    final reference = File(p.join(root.path, 'huge.md'));
    final handle = reference.openSync(mode: FileMode.write)
      ..truncateSync(17 * 1024 * 1024);
    handle.closeSync();
    await expectLater(
      gc.collect(dryRun: false, referenceFiles: [reference.path]),
      throwsStateError,
    );
    expect(runFile(old, 'app-debug.apk').existsSync(), isTrue);
  });

  test('defaults retain exactly three recent copies per platform', () async {
    gc = ArtifactRetention(root);
    for (var i = 0; i < 6; i++) {
      final id = '100000000000000$i';
      create(id);
      create(id, name: 'Runner.app.zip');
    }
    final result = await gc.collect(dryRun: false);
    expect(result['removedHistory'], hasLength(3));
    for (final name in ArtifactRetention.artifacts) {
      final files = gc.runs.listSync().whereType<Directory>().where(
        (d) => File(p.join(d.path, name)).existsSync(),
      );
      expect(files, hasLength(3));
    }
  });

  test(
    'prunes old logs and screenshots but preview never deletes them',
    () async {
      gc = ArtifactRetention(root, keepPerPlatform: 1, keepRunsPerCommand: 1);
      runFile(old, 'screenshot.png').writeAsStringSync('old screenshot');
      final outside = File(p.join(root.path, 'outside.txt'))
        ..writeAsStringSync('keep');
      Link(runFile(old, 'outside-link').path).createSync(outside.path);
      final preview = await gc.collect(dryRun: true);
      expect(preview['historyCandidates'], hasLength(1));
      expect(runFile(old, 'build.log').existsSync(), isTrue);
      final result = await gc.collect(dryRun: false);
      expect(result['removedHistoryBytes'], greaterThan(0));
      expect(runFile(old, 'report.json').parent.existsSync(), isFalse);
      expect(outside.readAsStringSync(), 'keep');
      expect(runFile(recent, 'build.log').existsSync(), isTrue);
      expect((await gc.collect(dryRun: false))['removedHistory'], isEmpty);
    },
  );

  test(
    'discarded historical reports no longer pin obsolete dependencies',
    () async {
      gc = ArtifactRetention(root, keepPerPlatform: 1, keepRunsPerCommand: 1);
      const older = '1000000000000000';
      create(older);
      final report = ArtifactRetention.read(runFile(old, 'report.json'))
        ..['dependsOn'] = 'build/harness/runs/$older/report.json';
      runFile(old, 'report.json').writeAsStringSync(jsonEncode(report));
      final result = await gc.collect(dryRun: false);
      expect(result['removedHistory'], hasLength(2));
      expect(runFile(older, 'report.json').existsSync(), isFalse);
      expect(runFile(old, 'report.json').existsSync(), isFalse);
    },
  );

  test(
    'retained reports protect transitive history and artifact dependencies',
    () async {
      gc = ArtifactRetention(root, keepPerPlatform: 1, keepRunsPerCommand: 1);
      const older = '1000000000000000';
      create(older);
      for (final pair in [(recent, old), (old, older)]) {
        final report = ArtifactRetention.read(runFile(pair.$1, 'report.json'))
          ..['dependsOn'] = 'build/harness/runs/${pair.$2}/report.json';
        runFile(pair.$1, 'report.json').writeAsStringSync(jsonEncode(report));
      }
      final result = await gc.collect(dryRun: false);
      expect(result['removed'], isEmpty);
      expect(result['removedHistory'], isEmpty);
      expect(runFile(older, 'app-debug.apk').existsSync(), isTrue);
    },
  );

  test(
    'pinned success never hides a later failure when history is pruned',
    () async {
      gc = ArtifactRetention(root, keepPerPlatform: 1, keepRunsPerCommand: 1);
      create(recent, status: 'failed', platform: 'both');
      const latest = '1000000000000003';
      create(latest, platform: 'both');
      final report = ArtifactRetention.read(runFile(latest, 'report.json'))
        ..['sourceHash'] = 'different source';
      runFile(latest, 'report.json').writeAsStringSync(jsonEncode(report));
      await gc.pin(old, 'explicitly pinned success');
      await gc.collect(dryRun: false);
      expect(runFile(recent, 'report.json').existsSync(), isTrue);
      final reports = [
        for (final id in [old, recent, latest])
          ArtifactRetention.read(runFile(id, 'report.json')),
      ];
      expect(
        harness.latestReportState(reports, 'hash', 'build', 'build-android'),
        isNot('passed'),
      );
    },
  );
}
