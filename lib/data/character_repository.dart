import 'dart:convert';

import '../domain/models.dart';
import 'local/repositories.dart';
import 'services/vidu_api.dart';

class CharacterRepository {
  CharacterRepository(this.local, this.credentials, this.api);
  final LocalRepository local;
  final CredentialRepository credentials;
  final ViduApi api;
  Credential get _credential =>
      credentials.current ?? (throw const AppFailure('missingKey'));
  String assetStatus(Object? raw) => switch ('$raw') {
    '1' || 'created' => 'created',
    '6' || 'processing' => 'processing',
    '11' || 'success' => 'success',
    '12' || 'failed' => 'failed',
    _ => 'draft',
  };

  /// Explicit submission prepares an account asset; it never creates a live.
  Future<Character> submit(Character c) async {
    validateCharacterDetails(c);
    final credential = _credential;
    if (c.avatarId.isNotEmpty && c.credentialId != credential.id) {
      throw const AppFailure('wrongCredential');
    }
    // An earlier attempt may have persisted an ID before the UI received it.
    final saved = await local.character(c.id);
    if (c.avatarId.isEmpty && saved != null && saved.avatarId.isNotEmpty) {
      if (saved.credentialId != credential.id) {
        throw const AppFailure('wrongCredential');
      }
      c = c.copyWith(
        avatarId: saved.avatarId,
        assetStatus: saved.assetStatus,
        credentialId: saved.credentialId,
        imagePath: saved.imagePath,
      );
    }
    if (c.avatarId.isEmpty) return upload(c);
    await local.saveCharacter(c);
    return c.assetStatus == 'success' ? c : refresh(c);
  }

  Future<Character> upload(Character c) async {
    final credential = _credential;
    await local.saveCharacter(c);
    if (c.imagePath.isEmpty && c.sourceImageUrl.isEmpty) {
      throw const AppFailure('imageInvalid');
    }
    if (c.imagePath.isEmpty) {
      final path = await local.importRemoteImage(c.sourceImageUrl, c.id);
      c = c.copyWith(imagePath: path);
      await local.saveCharacter(c);
    }
    final response = await api.uploadAvatar(
      credential,
      local.image(c.imagePath),
      c.name,
    );
    final asset = response['avatar'] is Map
        ? jsonObject(response['avatar'])
        : response;
    final id = asset['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const AppFailure('protocol', outcomeUnknown: true);
    }
    final updated = c.copyWith(
      credentialId: credential.id,
      avatarId: id,
      assetStatus: assetStatus(asset['status']),
    );
    await local.saveCharacter(updated);
    return updated;
  }

  Future<Character> refresh(Character c) async {
    final credential = _credential;
    if (c.credentialId != credential.id) {
      throw const AppFailure('wrongCredential');
    }
    final response = await api.avatar(credential, c.avatarId);
    final asset = response['avatar'] is Map
        ? jsonObject(response['avatar'])
        : response;
    final updated = c.copyWith(assetStatus: assetStatus(asset['status']));
    await local.saveCharacter(updated);
    return updated;
  }

  Future<List<Json>> existing() async {
    final response = await api.avatars(_credential);
    final values = response['avatars'] ?? response['items'];
    if (values is! List) throw const AppFailure('protocol');
    return values.map(jsonObject).toList();
  }

  Future<void> verifyOriginalAccount(String key) async {
    final id = credentials.currentId;
    if (id == null) return;
    final rows = await (local.db.select(local.db.characters)).get();
    for (final row in rows.where((r) => r.credentialId == id)) {
      final c = Character.fromJson(jsonObject(jsonDecode(row.config)));
      if (c.avatarId.isNotEmpty) {
        await api.avatar(Credential(id, key), c.avatarId);
        return;
      }
    }
  }
}
