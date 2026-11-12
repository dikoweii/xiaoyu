import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../app/runtime.dart' as runtime;
import '../application/call_coordinator.dart';
import '../domain/models.dart';
import '../domain/official_character.dart';

export '../app/runtime.dart'
    show callProvider, charactersProvider, officialCatalogProvider;

class CallRecord {
  const CallRecord({
    required this.id,
    required this.character,
    required this.phase,
    required this.createdAt,
    required this.endConfirmed,
    required this.credentialId,
    this.liveId,
    this.billedSeconds,
    this.creditsCost,
  });
  final String id, phase, credentialId;
  final Character character;
  final DateTime createdAt;
  final bool endConfirmed;
  final String? liveId, creditsCost;
  final int? billedSeconds;
}

class ChatMessage {
  const ChatMessage(this.speaker, this.content, this.delivery);
  final String speaker, content, delivery;
}

final controllerProvider = Provider(
  (ref) => ScreenController(ref.watch(runtime.runtimeProvider)),
);
final historyProvider = StreamProvider(
  (ref) => ref
      .watch(runtime.runtimeProvider)
      .local
      .watchCalls()
      .map(
        (rows) => rows
            .map(
              (r) => CallRecord(
                id: r.id,
                character: Character.fromJson(
                  jsonObject(jsonDecode(r.characterSnapshot)),
                ),
                phase: r.phase,
                createdAt: r.createdAt,
                endConfirmed: r.endConfirmed,
                credentialId: r.credentialId,
                liveId: r.liveId,
                billedSeconds: r.billedSeconds,
                creditsCost: r.creditsCost,
              ),
            )
            .toList(),
      ),
);
final messagesProvider = StreamProvider.family(
  (ref, String id) => ref
      .watch(runtime.runtimeProvider)
      .local
      .watchMessages(id)
      .map(
        (rows) => rows
            .map((r) => ChatMessage(r.speaker, r.content, r.delivery))
            .toList(),
      ),
);

/// Presentation commands are the only entry to business operations from pages.
class ScreenController {
  ScreenController(this._runtime);
  final runtime.AppRuntime _runtime;
  CallCoordinator get calls => _runtime.calls;
  bool get hasCredential => _runtime.credentials.current != null;
  bool get remembered => _runtime.credentials.remembered;
  bool get hasCredentialProfile => _runtime.credentials.currentId != null;
  String get profileId => _runtime.profileId;
  File image(String path) => _runtime.local.image(path);
  Future<String?> nickname() => _runtime.local.setting('nickname');
  Future<Character?> character(String id) => _runtime.local.character(id);
  Character newCharacter() =>
      Character(id: const Uuid().v4(), name: '', persona: '');
  Future<Character> createOfficialCharacter(Json role) async {
    final character = OfficialCharacter(role).draft(const Uuid().v4());
    await saveCharacter(character);
    return character;
  }

  Future<void> saveCharacter(Character value, {bool validate = false}) async {
    if (validate) buildSession(value, profileId);
    await _runtime.local.saveCharacter(value);
  }

  Future<void> deleteCharacter(String id) => _runtime.local.deleteCharacter(id);
  Future<void> deleteCall(String id) => _runtime.local.deleteCall(id);
  Future<Character> upload(Character c) => _runtime.characters.upload(c);
  Future<Character> refresh(Character c) => _runtime.characters.refresh(c);
  Future<List<Json>> existing() => _runtime.characters.existing();
  String assetStatus(Object? raw) => _runtime.characters.assetStatus(raw);
  Future<Character> selectAsset(Character c, Json asset) async {
    final credential = _runtime.credentials.current;
    if (credential == null) throw const AppFailure('missingKey');
    final updated = c.copyWith(
      avatarId: '${asset['id']}',
      assetStatus: assetStatus(asset['status']),
      credentialId: credential.id,
      imagePath: '',
      sourceImageUrl: '${asset['image_uri'] ?? ''}',
      officialRoleId: '',
    );
    await saveCharacter(updated);
    return updated;
  }

  Future<Character> choosePhoto(Character c) async {
    await saveCharacter(c);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return c;
    final path = await _runtime.local.importImage(file, c.id);
    final updated = c.copyWith(
      imagePath: path,
      sourceImageUrl: '',
      officialRoleId: '',
      avatarId: '',
      assetStatus: 'draft',
      credentialId: '',
    );
    await saveCharacter(updated);
    return updated;
  }

  Future<void> checkKey(String input) async {
    final value = input.trim().isEmpty
        ? _runtime.credentials.current?.key
        : input.trim();
    if (value == null) throw const AppFailure('missingKey');
    await _runtime.api.check(Credential('check', value));
  }

  Future<void> saveAccount(
    String name,
    String input, {
    required bool remember,
    required bool sameAccount,
  }) async {
    if (calls.snapshot.active) throw const AppFailure('pendingCall');
    await _runtime.local.setSetting('nickname', name.trim());
    final value = input.trim();
    final credentials = _runtime.credentials;
    if (value.isNotEmpty) {
      await checkKey(value);
      if (sameAccount) await _runtime.characters.verifyOriginalAccount(value);
      await credentials.save(
        value,
        remember: remember,
        sameAccount: sameAccount,
      );
      await _runtime.reconcileKnownCalls();
    } else if (credentials.current != null) {
      await credentials.save(
        credentials.current!.key,
        remember: remember,
        sameAccount: true,
      );
    }
  }

  Future<void> clearKey() async {
    if (calls.snapshot.active) throw const AppFailure('pendingCall');
    await _runtime.credentials.clear();
  }

  Future<void> start(Character c) {
    final credential = _runtime.credentials.current;
    if (credential == null) throw const AppFailure('missingKey');
    return calls.start(c, credential, profileId);
  }

  Future<void> reconcile(CallRecord record) async {
    final credential = await _runtime.credentials.forId(record.credentialId);
    if (credential == null) throw const AppFailure('missingKey');
    if (record.liveId != null) {
      await calls.reconcile(record.id, record.liveId!, credential);
    }
  }
}
