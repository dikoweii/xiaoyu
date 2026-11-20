import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart' as domain;
import 'database.dart';

const ids = Uuid();

class LocalRepository {
  LocalRepository(this.db, this.root, {this._downloadClient});
  final Dio Function()? _downloadClient;
  final AppDatabase db;
  final Directory root;
  Future<String?> setting(String key) async => (await (db.select(
    db.settings,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;
  Future<void> setSetting(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  Future<void> deleteSetting(String key) async =>
      (db.delete(db.settings)..where((t) => t.key.equals(key))).go();
  Future<void> clearEditingSessions() async => (db.delete(
    db.settings,
  )..where((t) => t.key.like('characterEdit.%'))).go();
  Future<String> profileId() async {
    final existing = await setting('profileId');
    if (existing != null) return existing;
    final value = ids.v4();
    await setSetting('profileId', value);
    return value;
  }

  Stream<List<domain.Character>> watchCharacters() =>
      (db.select(
        db.characters,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch().map(
        (rows) => rows
            .map(
              (r) => domain.Character.fromJson(
                domain.jsonObject(jsonDecode(r.config)),
              ),
            )
            .toList(),
      );
  Future<domain.Character?> character(String id) async {
    final row = await (db.select(
      db.characters,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : domain.Character.fromJson(domain.jsonObject(jsonDecode(row.config)));
  }

  Future<void> saveCharacter(domain.Character c) async => db
      .into(db.characters)
      .insertOnConflictUpdate(
        CharactersCompanion.insert(
          id: c.id,
          credentialId: c.credentialId,
          name: c.name,
          config: jsonEncode(c.toJson()),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
  Future<void> deleteCharacter(String id) async =>
      (db.delete(db.characters)..where((t) => t.id.equals(id))).go();
  File image(String relative) => File(p.join(root.path, relative));
  Future<String> importRemoteImage(String url, String characterId) async {
    final uri = Uri.tryParse(url);
    if (uri?.scheme != 'https') throw const domain.AppFailure('imageInvalid');
    final client =
        _downloadClient?.call() ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
    final temporary = File(
      p.join(root.path, 'characters', characterId, '${ids.v4()}.tmp'),
    );
    final cancel = CancelToken();
    try {
      await temporary.parent.create(recursive: true);
      final response = await client.download(
        url,
        temporary.path,
        cancelToken: cancel,
        onReceiveProgress: (received, total) {
          if (received >= 20 * 1024 * 1024 || total >= 20 * 1024 * 1024) {
            cancel.cancel();
          }
        },
      );
      final mime = response.headers.value('content-type')?.split(';').first;
      final ext = switch (mime) {
        'image/png' => '.png',
        'image/webp' => '.webp',
        'image/jpeg' => '.jpg',
        _ => throw const domain.AppFailure('imageInvalid'),
      };
      final relative = p.join('characters', characterId, '${ids.v4()}$ext');
      await temporary.rename(image(relative).path);
      return relative;
    } on DioException {
      throw const domain.AppFailure('network');
    } finally {
      client.close();
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<String> importImage(XFile picked, String characterId) async {
    final ext = p.extension(picked.path).toLowerCase();
    if (!{'.jpg', '.jpeg', '.png', '.webp'}.contains(ext) ||
        await picked.length() >= 20 * 1024 * 1024) {
      throw const domain.AppFailure('imageInvalid');
    }
    final relative = p.join('characters', characterId, '${ids.v4()}$ext');
    final destination = image(relative);
    await destination.parent.create(recursive: true);
    final temporary = File('${destination.path}.tmp');
    await picked.saveTo(temporary.path);
    await temporary.rename(destination.path);
    return relative;
  }

  Stream<List<Call>> watchCalls() => (db.select(
    db.calls,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  Stream<List<Message>> watchMessages(String callId) =>
      (db.select(db.messages)
            ..where((t) => t.callId.equals(callId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();
  Future<void> addMessage(
    String callId,
    String id,
    String speaker,
    String text, {
    String delivery = 'received',
  }) async => db
      .into(db.messages)
      .insertOnConflictUpdate(
        MessagesCompanion.insert(
          id: id,
          callId: callId,
          speaker: speaker,
          content: text,
          delivery: delivery,
          createdAt: DateTime.now().toUtc(),
        ),
      );
  Future<void> deleteCall(String id) async => db.transaction(() async {
    final record = await (db.select(
      db.calls,
    )..where((t) => t.id.equals(id))).getSingle();
    if (!record.endConfirmed && record.phase != 'failed') {
      throw const domain.AppFailure('pendingCall');
    }
    await (db.delete(db.messages)..where((t) => t.callId.equals(id))).go();
    await (db.delete(db.calls)..where((t) => t.id.equals(id))).go();
  });
  static Future<LocalRepository> open() async {
    final root = await getApplicationSupportDirectory();
    final repo = LocalRepository(AppDatabase(), root);
    // Interrupted forms are temporary, never implicitly published as roles.
    await repo.clearEditingSessions();
    await repo.profileId();
    return repo;
  }
}

class CredentialRepository {
  CredentialRepository(this.local, {FlutterSecureStorage? secure})
    : secure = secure ?? const FlutterSecureStorage();
  final LocalRepository local;
  final FlutterSecureStorage secure;
  domain.Credential? current;
  String? currentId;
  bool remembered = false;
  Future<void> load() async {
    currentId = await local.setting('credentialId');
    remembered = await local.setting('rememberKey') == 'true';
    if (currentId != null && remembered) {
      final key = await secure.read(key: 'vidu.$currentId');
      if (key != null) current = domain.Credential(currentId!, key);
    }
  }

  Future<domain.Credential?> forId(String id) async {
    if (current?.id == id) return current;
    final key = await secure.read(key: 'vidu.$id');
    return key == null ? null : domain.Credential(id, key);
  }

  Future<void> save(
    String key, {
    required bool remember,
    required bool sameAccount,
  }) async {
    key = key.trim();
    if (key.isEmpty) throw const domain.AppFailure('missingKey');
    final oldId = currentId;
    final id = sameAccount && oldId != null ? oldId : ids.v4();
    // Persist a requested secret before advertising it as available in metadata.
    if (remember) {
      await secure.write(key: 'vidu.$id', value: key);
    } else {
      await secure.delete(key: 'vidu.$id');
    }
    await local.setSetting('credentialId', id);
    await local.setSetting('rememberKey', '$remember');
    currentId = id;
    current = domain.Credential(id, key);
    remembered = remember;
  }

  Future<void> clear() async {
    if (currentId != null) await secure.delete(key: 'vidu.$currentId');
    current = null;
    remembered = false;
    await local.setSetting('rememberKey', 'false');
  }
}
