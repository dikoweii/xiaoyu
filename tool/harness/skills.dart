import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Discovered from the user's installed files, never a copied skill body.
class InstalledSkill {
  InstalledSkill(this.name, this.description, this.path, this.content);
  final String name, description, path, content;
  String get hash => sha256.convert(utf8.encode(content)).toString();
  Map<String, String> get metadata => {
    'name': name,
    'description': description,
    'path': path,
    'sha256': hash,
  };
}

List<InstalledSkill> discoverSkills(Directory root) {
  final directory = Directory(p.join(root.path, '.agents/skills'));
  if (!directory.existsSync()) return [];
  final skills = <InstalledSkill>[];
  for (final folder in directory.listSync().whereType<Directory>()) {
    final file = File(p.join(folder.path, 'SKILL.md'));
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty || lines.first != '---') {
      throw FormatException(
        'Missing skill frontmatter: ${p.relative(file.path, from: root.path)}',
      );
    }
    final end = lines.indexOf('---', 1);
    if (end < 0) {
      throw FormatException('Unclosed skill frontmatter: ${file.path}');
    }
    final header = loadYaml(lines.sublist(1, end).join('\n'));
    if (header is! Map ||
        header['name'] is! String ||
        header['description'] is! String) {
      throw FormatException(
        'Skill requires name and description: ${file.path}',
      );
    }
    final name = header['name'] as String;
    if (skills.any((s) => s.name == name)) {
      throw FormatException('Duplicate skill name: $name');
    }
    skills.add(
      InstalledSkill(
        name,
        header['description'] as String,
        p.relative(file.path, from: root.path),
        content,
      ),
    );
  }
  return skills..sort((a, b) => a.name.compareTo(b.name));
}

/// Deterministic routing is explainable; extra skills can be selected explicitly.
Map<String, dynamic> planSkills(
  Directory root,
  Map<String, dynamic> config, {
  required String kind,
  Iterable<String> topics = const [],
  Iterable<String> names = const [],
  Iterable<String> changedPaths = const [],
}) {
  final catalog = discoverSkills(root);
  final routing = config['skill_routing'] as Map;
  final rules = routing['topics'] as Map;
  final chosenTopics = <String>{
    ...(((routing['kinds'] as Map)[kind] as List?) ?? <String>[])
        .cast<String>(),
    ...topics,
  };
  for (final raw in routing['paths'] as List) {
    final rule = raw as Map;
    if (changedPaths.any((path) => path.startsWith(rule['prefix'] as String))) {
      chosenTopics.addAll((rule['topics'] as List).cast<String>());
    }
  }
  final reasons = <String, List<String>>{};
  final errors = <String>[];
  for (final topic in chosenTopics) {
    if (!rules.containsKey(topic)) {
      errors.add('Unknown topic: $topic');
      continue;
    }
    for (final name in (rules[topic] as List).cast<String>()) {
      reasons.putIfAbsent(name, () => []).add('topic:$topic');
    }
  }
  for (final name in names) {
    reasons.putIfAbsent(name, () => []).add('explicit selection');
  }
  final selected = <Map<String, dynamic>>[];
  for (final entry in reasons.entries) {
    final skill = catalog.where((s) => s.name == entry.key).firstOrNull;
    if (skill == null) {
      errors.add('Required skill is not installed: ${entry.key}');
      continue;
    }
    selected.add({...skill.metadata, 'reasons': entry.value});
  }
  return {
    'kind': kind,
    'topics': chosenTopics.toList()..sort(),
    'catalog': catalog.map((s) => s.metadata).toList(),
    'selected': selected,
    'errors': errors,
    'applicationEvidence': 'unverified',
    'boundary': 'Loading SKILL.md provides instructions to the current agent. It does not execute a model or prove the agent followed them.',
  };
}

Map<String, dynamic> skillLoadStatus(
  Map<String, dynamic> plan,
  Map<String, dynamic>? record,
  String taskId,
) {
  final loaded = record?['loads'];
  final entries = record?['taskId'] == taskId && loaded is List
      ? loaded.whereType<Map<dynamic, dynamic>>()
      : const <Map<dynamic, dynamic>>[];
  final missing = <String>[];
  for (final raw in plan['selected'] as List) {
    final required = raw as Map;
    if (!entries.any(
      (l) =>
          l['name'] == required['name'] &&
          l['path'] == required['path'] &&
          l['sha256'] == required['sha256'],
    )) {
      missing.add(required['name'] as String);
    }
  }
  return {
    'passed': missing.isEmpty && (plan['errors'] as List).isEmpty,
    'required': plan['selected'],
    'missingOrStale': missing,
    'errors': plan['errors'],
    'taskId': taskId,
    'loadingEvidence': 'local_cli_file_read',
    'applicationEvidence': 'unverified',
    'boundary': plan['boundary'],
  };
}
