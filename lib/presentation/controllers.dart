import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../app/runtime.dart' as runtime;
import '../application/call_coordinator.dart';
import '../data/character_repository.dart';
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

// The selected image is a stable key while text and voice continue to change.
// Disposing the page stops polling; a POST already sent can still persist its ID.
final avatarPreparationProvider = StreamProvider.autoDispose
    .family<Character, (Character, String)>((ref, selection) {
      var active = true;
      ref.onDispose(() => active = false);
      return ref
          .read(controllerProvider)
          .preparePhoto(selection.$1, () => active, editId: selection.$2);
    }, retry: (_, _) => null);
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
  ScreenController(this._runtime, {Future<XFile?> Function()? pickPhoto})
    : _pickPhoto =
          pickPhoto ??
          (() => ImagePicker().pickImage(source: ImageSource.gallery));
  final runtime.AppRuntime _runtime;
  final Future<XFile?> Function() _pickPhoto;
  final _edits = <String, CharacterRepository>{};
  final _templates = <String, Character>{};
  CharacterRepository _characters(String? editId) => editId == null
      ? _runtime.characters
      : _edits[editId] ?? (throw const AppFailure('avatarImageChanged'));
  CallCoordinator get calls => _runtime.calls;
  bool get hasCredential => _runtime.credentials.current != null;
  bool get remembered => _runtime.credentials.remembered;
  bool get hasCredentialProfile => _runtime.credentials.currentId != null;
  String get profileId => _runtime.profileId;
  File image(String path) => _runtime.local.image(path);
  Future<String?> nickname() => _runtime.local.setting('nickname');
  Future<Character?> character(String id, {String? editId}) async =>
      editId == null && _templates.containsKey(id)
      ? _templates[id]
      : _characters(editId).character(id);
  Future<String> beginCharacterEdit(Character value) async {
    final id = const Uuid().v4();
    _edits[id] = await _runtime.characters.edit(value, id);
    _templates.remove(value.id);
    return id;
  }

  Future<void> endCharacterEdit(String editId, {required bool saved}) async {
    await _edits.remove(editId)?.closeEdit(saved: saved);
  }

  Character newCharacter() =>
      Character(id: const Uuid().v4(), name: '', persona: '');
  Future<Character> createOfficialCharacter(Json role) async {
    final character = OfficialCharacter(role).draft(const Uuid().v4());
    _templates[character.id] = character;
    return character;
  }

  Future<void> saveCharacter(Character value, {String? editId}) async {
    await _characters(editId).publish(value);
  }

  Future<void> deleteCharacter(String id) => _runtime.local.deleteCharacter(id);
  Future<void> deleteCall(String id) => _runtime.local.deleteCall(id);
  Future<Character> upload(Character c, {String? editId}) =>
      _characters(editId).upload(c);
  Future<Character> submitCharacter(Character c, {String? editId}) async {
    final repository = _characters(editId);
    final result = await repository.submit(c);
    return repository.publish(result);
  }

  Future<Character> refresh(Character c, {String? editId}) =>
      _characters(editId).refresh(c);

  Stream<Character> preparePhoto(
    Character image,
    bool Function() active, {
    String? editId,
  }) async* {
    if (!hasCredential || !active()) return;
    final repository = _characters(editId);
    var current = await repository.character(image.id);
    if (!active() || current == null || current.imagePath != image.imagePath) {
      return;
    }
    if (current.assetStatus == 'uploadFailed') {
      throw const AppFailure('avatarUploadFailed');
    }
    if (current.avatarId.isEmpty) {
      current = await repository.upload(current, retry: false);
    }
    if (!active()) return;
    yield current;
    // Bound foreground polling; Submit can query again after the window ends.
    for (
      var i = 0;
      i < 40 && {'created', 'processing'}.contains(current!.assetStatus);
      i++
    ) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!active()) return;
      final saved = await repository.character(image.id);
      if (saved == null ||
          saved.imagePath != image.imagePath ||
          saved.avatarId != current.avatarId ||
          !hasCredential) {
        return;
      }
      current = await repository.refresh(saved);
      if (!active()) return;
      yield current;
    }
  }

  Future<List<Json>> existing() => _runtime.characters.existing();
  String assetStatus(Object? raw) => _runtime.characters.assetStatus(raw);
  Future<Character> selectAsset(
    Character c,
    Json asset, {
    String? editId,
  }) async {
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
    await _characters(editId).saveDraft(updated);
    return updated;
  }

  Future<Character> choosePhoto(Character c, {String? editId}) async {
    final file = await _pickPhoto();
    if (file == null) {
      final current = await character(c.id, editId: editId);
      return current == null || current.imagePath != c.imagePath
          ? c
          : c.copyWith(
              avatarId: current.avatarId,
              credentialId: current.credentialId,
              assetStatus: current.assetStatus,
            );
    }
    final path = await _runtime.local.importImage(file, c.id);
    final updated = c.copyWith(
      imagePath: path,
      sourceImageUrl: '',
      officialRoleId: '',
      avatarId: '',
      assetStatus: 'draft',
      credentialId: '',
    );
    await _characters(editId).saveDraft(updated);
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
