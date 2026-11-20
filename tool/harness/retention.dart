import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

typedef Record = Map<String, dynamic>;

/// Bounds build copies and unreferenced historical run diagnostics.
class ArtifactRetention {
  ArtifactRetention(
    this.root, {
    this.keepPerPlatform = 3,
    this.keepRunsPerCommand = 3,
  }) {
    if (keepPerPlatform < 1 || keepRunsPerCommand < 1) {
      throw ArgumentError('Retention must keep at least one artifact');
    }
  }
  final Directory root;
  final int keepPerPlatform;
  final int keepRunsPerCommand;
  Directory get output => Directory(p.join(root.path, 'build/harness'));
  Directory get runs => Directory(p.join(output.path, 'runs'));
  static const artifacts = ['app-debug.apk', 'Runner.app.zip'];
  static final _id = RegExp(r'^\d+$');
  static final _reference = RegExp(r'runs[/\\](\d{10,})');

  static Record read(File file) =>
      Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map);
  static void atomicWrite(File file, Object data) {
    final temporary = File('${file.path}.tmp');
    temporary.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
      flush: true,
    );
    temporary.renameSync(file.path);
  }

  bool _regular(String path, FileSystemEntityType type) =>
      FileSystemEntity.typeSync(path, followLinks: false) == type;

  int _directoryBytes(Directory directory) => directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .fold(0, (bytes, file) => bytes + file.lengthSync());

  String _reportDigest(String id) => sha256
      .convert(File(p.join(runs.path, id, 'report.json')).readAsBytesSync())
      .toString();

  Future<T> locked<T>(Future<T> Function() action) async {
    output.createSync(recursive: true);
    // Never follow user-supplied symlinks into another tree.
    if (output.resolveSymbolicLinksSync() !=
            p.join(root.resolveSymbolicLinksSync(), 'build', 'harness') ||
        FileSystemEntity.isLinkSync(p.join(output.path, '.gc.lock'))) {
      throw StateError('GC refuses a symlinked output or lock');
    }
    final lock = File(p.join(output.path, '.gc.lock'))
        .openSync(mode: FileMode.append);
    try {
      await lock.lock(FileLock.blockingExclusive);
      return await action();
    } finally {
      await lock.close();
    }
  }

  Future<void> pin(String id, String reason, {bool remove = false}) =>
      locked(() async {
        if (!_id.hasMatch(id) ||
            reason.trim().isEmpty ||
            !_regular(p.join(runs.path, id), FileSystemEntityType.directory)) {
          throw ArgumentError(
            'pin requires an existing numeric run ID and a reason',
          );
        }
        final file = File(p.join(output.path, 'pins.json'));
        if (FileSystemEntity.isLinkSync(file.path)) {
          throw StateError('Symlinked pins');
        }
        final pins = file.existsSync() ? read(file) : <String, dynamic>{};
        if (remove) {
          pins.remove(id);
        } else {
          pins[id] = reason.trim();
        }
        atomicWrite(file, pins);
      });

  Record plan({List<String> referenceFiles = const []}) {
    if (FileSystemEntity.isLinkSync(runs.path)) {
      throw StateError('Symlinked runs');
    }
    final records = <String, Record>{};
    final protected = <String, Set<String>>{};
    final warnings = <String>[];
    void protect(String id, String reason) =>
        protected.putIfAbsent(id, () => {}).add(reason);
    if (runs.existsSync()) {
      for (final dir
          in runs.listSync(followLinks: false).whereType<Directory>()) {
        final id = p.basename(dir.path);
        if (!_id.hasMatch(id)) continue;
        final file = File(p.join(dir.path, 'report.json'));
        try {
          if (!_regular(file.path, FileSystemEntityType.file)) {
            throw const FormatException();
          }
          records[id] = read(file);
          final status = records[id]!['status'];
          if (status == 'running') {
            protect(id, 'running');
          } else if (!['passed', 'failed', 'blocked'].contains(status)) {
            protect(id, 'unknown-status');
          }
        } on FormatException {
          protect(id, 'missing-or-invalid-report');
          warnings.add('Preserved $id: missing or invalid report');
        }
      }
    }
    final pinsFile = File(p.join(output.path, 'pins.json'));
    if (FileSystemEntity.isLinkSync(pinsFile.path)) {
      throw StateError('Symlinked pins');
    }
    final pins = pinsFile.existsSync() ? read(pinsFile) : <String, dynamic>{};
    for (final entry in pins.entries) {
      if (!_id.hasMatch(entry.key) ||
          entry.value is! String ||
          '${entry.value}'.trim().isEmpty) {
        throw const FormatException(
          'Invalid pins.json; no artifacts collected',
        );
      }
      protect(entry.key, 'pin: ${entry.value}');
    }
    final ordered = records.keys.toList()..sort((a, b) => b.compareTo(a));
    final recentArtifacts = <String>{};
    final diagnostics = <String>{};
    for (final filename in artifacts) {
      final available = ordered.where(
        (id) => _regular(
          p.join(runs.path, id, filename),
          FileSystemEntityType.file,
        ),
      );
      for (final id in available.take(keepPerPlatform)) {
        recentArtifacts.add('$id/$filename');
        diagnostics.add(id);
      }
    }
    // Diagnostics have their own ring; keeping a log does not pin its binary.
    final groups = <String, int>{};
    for (final id in ordered) {
      final record = records[id]!;
      final group = '${record['command']}/${record['platform']}';
      final count = groups.update(group, (n) => n + 1, ifAbsent: () => 1);
      if (count <= keepRunsPerCommand) {
        diagnostics.add(id);
      }
    }
    final texts = <String, String>{};
    for (final path in referenceFiles.toSet()) {
      final file = File(path);
      if (!_regular(file.path, FileSystemEntityType.file)) continue;
      // Reference scan is text only. Oversized documents block GC instead of
      // silently bypassing their references; binaries aren't supplied here.
      if (file.lengthSync() > 16 * 1024 * 1024) {
        throw StateError('Reference file too large: $path');
      }
      texts[path] = file.readAsStringSync();
    }
    for (final entry in texts.entries) {
      for (final match in _reference.allMatches(entry.value)) {
        protect(
          match[1]!,
          'reference: ${p.relative(entry.key, from: root.path)}',
        );
      }
    }
    // Only retained reports own live dependencies. Discarded historical reports
    // must not keep their own obsolete dependency trees alive forever.
    var changed = true;
    String resultGroup(Record record) =>
        '${record['sourceHash']}/${record['command']}/'
        '${record['command'] == 'build' ? 'all-platforms' : record['platform']}';
    while (changed) {
      final before = {...protected.keys, ...diagnostics};
      final retainedResults = before
          .map((id) => records[id])
          .whereType<Record>()
          .map(resultGroup)
          .toSet();
      final latest = <String>{};
      for (final id in ordered) {
        final record = records[id]!;
        final group =
            '${record['sourceHash']}/${record['command']}/${record['platform']}';
        // Preserve the latest result for every retained source. A pinned older
        // success can never replace a later failed/expired result after GC.
        if (retainedResults.contains(resultGroup(record)) &&
            latest.add(group)) {
          diagnostics.add(id);
        }
      }
      for (final id in {...protected.keys, ...diagnostics}) {
        final record = records[id];
        if (record == null) continue;
        for (final match in _reference.allMatches(jsonEncode(record))) {
          final target = match[1]!;
          if (target != id) {
            protect(target, 'report-reference: $id');
          }
        }
      }
      changed = {...protected.keys, ...diagnostics}.length != before.length;
    }
    final historyCandidates = <Record>[];
    for (final id in ordered) {
      if (protected.containsKey(id) || diagnostics.contains(id)) continue;
      historyCandidates.add({
        'run': id,
        'path': p.relative(p.join(runs.path, id), from: root.path),
        'bytes': _directoryBytes(Directory(p.join(runs.path, id))),
        'reportSha256': _reportDigest(id),
        'artifactFiles': artifacts
            .where(
              (name) => _regular(
                p.join(runs.path, id, name),
                FileSystemEntityType.file,
              ),
            )
            .length,
      });
    }
    final collectedRuns = historyCandidates.map((r) => r['run']).toSet();
    final candidates = <Record>[], kept = <Record>[];
    for (final id in ordered) {
      if (collectedRuns.contains(id)) continue;
      for (final name in artifacts) {
        final file = File(p.join(runs.path, id, name));
        if (!_regular(file.path, FileSystemEntityType.file)) continue;
        final item = <String, dynamic>{
          'run': id,
          'path': p.relative(file.path, from: root.path),
          'bytes': file.lengthSync(),
        };
        if (protected.containsKey(id) ||
            recentArtifacts.contains('$id/$name')) {
          kept.add({
            ...item,
            'reasons': [
              ...?protected[id],
              if (recentArtifacts.contains('$id/$name')) 'recent: $name',
            ]..sort(),
          });
        } else {
          candidates.add(item);
        }
      }
    }
    return {
      'dryRun': true,
      'keepPerPlatform': keepPerPlatform,
      'keepRunsPerCommand': keepRunsPerCommand,
      'historyCandidates': historyCandidates,
      'historyBytes': historyCandidates.fold<int>(
        0,
        (n, r) => n + (r['bytes'] as int),
      ),
      'candidateBytes': candidates.fold<int>(
        0,
        (n, c) => n + (c['bytes'] as int),
      ),
      'candidates': candidates,
      'kept': kept,
      'pins': pins,
      'protectedRuns': {
        for (final id in protected.keys) id: protected[id]!.toList()..sort(),
      },
      'referenceFilesScanned': texts.length,
      'warnings': warnings,
      'scope': 'Old run APK/ZIP copies and unreferenced historical run directories; source and Flutter caches retained.',
    };
  }

  Future<Record> collect({
    required bool dryRun,
    List<String> referenceFiles = const [],
  }) => locked(() async {
    final result = plan(referenceFiles: referenceFiles);
    if (dryRun) return result;
    final removed = <Record>[];
    final removedHistory = <Record>[];
    final now = DateTime.now().toUtc().toIso8601String();
    for (final item in (result['candidates'] as List).cast<Record>()) {
      final file = File(p.join(root.path, item['path'] as String));
      final reportFile = File(
        p.join(runs.path, item['run'] as String, 'report.json'),
      );
      // Mark evidence expired durably BEFORE unlink. Interruption is conservative:
      // the next pass can retry deletion, never certify a removed artifact.
      final record = read(reportFile);
      if (record['status'] == 'running' ||
          !_regular(file.path, FileSystemEntityType.file) ||
          file.lengthSync() != item['bytes']) {
        throw StateError(
          'GC candidate changed; stopped before deleting ${item['path']}',
        );
      }
      record['evidenceState'] = 'expired';
      final expired = Map<String, dynamic>.from(
        record['collectedArtifacts'] as Map? ?? {},
      );
      expired[p.basename(file.path)] = {
        'at': now,
        'bytes': item['bytes'],
        'reason': 'artifact-retention',
      };
      record['collectedArtifacts'] = expired;
      atomicWrite(reportFile, record);
      file.deleteSync();
      removed.add(item);
    }
    for (final item in (result['historyCandidates'] as List).cast<Record>()) {
      final id = item['run'] as String;
      final directory = Directory(p.join(runs.path, id));
      if (!_regular(directory.path, FileSystemEntityType.directory) ||
          _reportDigest(id) != item['reportSha256']) {
        throw StateError('Historical run changed; stopped before deleting $id');
      }
      final reportFile = File(p.join(directory.path, 'report.json'));
      final record = read(reportFile)..['evidenceState'] = 'expired';
      atomicWrite(reportFile, record);
      directory.deleteSync(recursive: true);
      removedHistory.add(item);
    }
    final receipt = {
      ...result,
      'dryRun': false,
      'removed': removed,
      'removedBytes': removed.fold<int>(0, (n, c) => n + (c['bytes'] as int)),
      'removedHistory': removedHistory,
      'removedHistoryBytes': removedHistory.fold<int>(
        0,
        (n, r) => n + (r['bytes'] as int),
      ),
      'finishedAt': now,
    };
    // Bounded receipt; embedding a receipt as a reference must not pin all history.
    atomicWrite(File(p.join(output.path, 'gc-last.json')), receipt);
    return receipt;
  });
}
