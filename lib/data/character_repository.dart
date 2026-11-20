import 'dart:async';
import 'dart:convert';

import '../domain/models.dart';
import 'local/repositories.dart';
import 'services/vidu_api.dart';

class CharacterRepository {
  CharacterRepository(this.local, this.credentials, this.api)
    : _editId = null,
      _publishedUploads = {},
      _assetQueries = {};
  CharacterRepository._editing(CharacterRepository parent, this._editId)
    : local = parent.local,
      credentials = parent.credentials,
      api = parent.api,
      _publishedUploads = parent._publishedUploads,
      _assetQueries = parent._assetQueries;
  final LocalRepository local;
  final CredentialRepository credentials;
  final ViduApi api;
  final _uploads = <(String, String, String, String), Future<Character>>{};
  final Map<(String, String, String, String), Future<Character>>
  _publishedUploads;
  // Shared by editors and the saved-role synchronizer. Keys never leave memory.
  final Map<(String, String, String), Future<Json>> _assetQueries;
  (String, String, String, String) _uploadKey(
    Character c,
    String credentialId,
  ) => (c.id, c.imagePath, c.sourceImageUrl, credentialId);
  final String? _editId;
  int _operations = 0;
  bool _closed = false;
  String get _editKey => 'characterEdit.$_editId';

  Future<CharacterRepository> edit(Character value, String editId) async {
    final editor = CharacterRepository._editing(this, editId);
    await local.setSetting(
      editor._editKey,
      jsonEncode({'character': value.toJson(), 'published': false}),
    );
    return editor;
  }

  Future<Json?> _editRecord() async {
    final raw = await local.setting(_editKey);
    return raw == null ? null : jsonObject(jsonDecode(raw));
  }

  Future<Character?> character(String id) async {
    if (_editId == null) return local.character(id);
    final record = await _editRecord();
    if (record == null) return null;
    final value = Character.fromJson(jsonObject(record['character']));
    return value.id == id ? value : null;
  }

  Future<void> _write(Character value) async {
    if (_editId == null) return local.saveCharacter(value);
    final record = await _editRecord();
    if (record == null) throw const AppFailure('avatarImageChanged');
    record['character'] = value.toJson();
    await local.setSetting(_editKey, jsonEncode(record));
  }

  /// Only an explicit save publishes a working copy to the home list.
  Future<Character> publish(Character value) => local.db.transaction(() async {
    final saved = await saveDraft(value);
    await local.saveCharacter(saved);
    final key = _uploadKey(saved, saved.credentialId);
    final pending = _uploads[key];
    if (pending != null) _publishedUploads[key] = pending;
    if (_editId != null) {
      final record = (await _editRecord())!;
      record['published'] = true;
      await local.setSetting(_editKey, jsonEncode(record));
    }
    return saved;
  });

  Future<void> closeEdit({required bool saved}) =>
      local.db.transaction(() async {
        _closed = true;
        if (!saved || _operations == 0) await local.deleteSetting(_editKey);
      });

  Future<T> _operation<T>(Future<T> Function() work) async {
    _operations++;
    try {
      return await work();
    } finally {
      _operations--;
      if (_closed && _operations == 0) await local.deleteSetting(_editKey);
    }
  }

  Credential get _credential =>
      credentials.current ?? (throw const AppFailure('missingKey'));
  String assetStatus(Object? raw) => switch ('$raw') {
    '1' || 'created' => 'created',
    '6' || 'processing' => 'processing',
    '11' || 'success' => 'success',
    '12' || 'failed' => 'failed',
    _ => 'draft',
  };

  bool _sameImage(Character a, Character b) => a.imagePath.isNotEmpty
      ? a.imagePath == b.imagePath
      : a.sourceImageUrl == b.sourceImageUrl &&
            (a.sourceImageUrl.isNotEmpty || b.imagePath.isEmpty);

  Character _withAsset(Character draft, Character asset) => draft.copyWith(
    avatarId: asset.avatarId,
    assetStatus: asset.assetStatus,
    credentialId: asset.credentialId,
    imagePath: asset.imagePath,
  );

  bool _matchesAsset(Character a, Character b) =>
      a.avatarId.isNotEmpty &&
      a.avatarId == b.avatarId &&
      a.credentialId == b.credentialId &&
      _sameImage(a, b);

  bool _terminal(Character c) => {'success', 'failed'}.contains(c.assetStatus);

  // A text-only draft save must not erase an ID received in the background.
  Future<Character> saveDraft(Character c, {bool requireImage = false}) =>
      local.db.transaction(() async {
        if (_closed) throw const AppFailure('avatarImageChanged');
        final saved = await character(c.id);
        if (_editId != null && saved == null) {
          throw const AppFailure('avatarImageChanged');
        }
        if (requireImage && saved != null && !_sameImage(c, saved)) {
          throw const AppFailure('avatarImageChanged');
        }
        if (saved != null &&
            _sameImage(c, saved) &&
            (c.avatarId.isEmpty || c.avatarId == saved.avatarId) &&
            saved.credentialId.isNotEmpty) {
          c = _withAsset(c, saved);
        }
        if (_editId != null) {
          final published = await local.character(c.id);
          if (published != null &&
              _matchesAsset(c, published) &&
              _terminal(published)) {
            c = c.copyWith(assetStatus: published.assetStatus);
          }
        }
        await _write(c);
        return c;
      });

  Future<Character> _mergeIfCurrent(
    Character source,
    Credential credential,
    Character Function(Character) update, {
    String? expectedAvatar,
    bool statusOnly = false,
  }) => local.db.transaction(() async {
    final saved = await character(source.id);
    if (saved == null ||
        !_sameImage(source, saved) ||
        credentials.current?.id != credential.id ||
        credentials.current?.key != credential.key ||
        (statusOnly && saved.credentialId != credential.id) ||
        (expectedAvatar != null && saved.avatarId != expectedAvatar)) {
      throw const AppFailure('avatarImageChanged');
    }
    var result = update(saved);
    final published = _editId == null ? null : await local.character(source.id);
    if (statusOnly &&
        published != null &&
        _matchesAsset(result, published) &&
        _terminal(published)) {
      result = result.copyWith(assetStatus: published.assetStatus);
    }
    if (!statusOnly || saved.assetStatus != result.assetStatus) {
      await _write(result);
    }
    if (_editId != null &&
        (statusOnly || (await _editRecord())?['published'] == true)) {
      if (published != null &&
          _sameImage(published, source) &&
          published.credentialId == credential.id &&
          (expectedAvatar == null || published.avatarId == expectedAvatar)) {
        // Background asset progress never publishes unsaved form fields.
        if (!statusOnly || published.assetStatus != result.assetStatus) {
          await local.saveCharacter(
            statusOnly
                ? published.copyWith(assetStatus: result.assetStatus)
                : _withAsset(published, result),
          );
        }
      }
    }
    return result;
  });

  /// Submission reuses preparation for this image; it never creates a live.
  Future<Character> submit(Character c) async {
    validateCharacterDetails(c);
    final credential = _credential;
    if (c.avatarId.isNotEmpty && c.credentialId != credential.id) {
      throw const AppFailure('wrongCredential');
    }
    // An earlier attempt may have persisted an ID before the UI received it.
    final saved = await character(c.id);
    if (saved != null && !_sameImage(c, saved)) {
      throw const AppFailure('avatarImageChanged');
    }
    if (saved != null &&
        _sameImage(c, saved) &&
        saved.credentialId.isNotEmpty) {
      if (saved.credentialId != credential.id) {
        throw const AppFailure('wrongCredential');
      }
      c = _withAsset(c, saved);
    }
    c = await saveDraft(c);
    if (c.avatarId.isEmpty) return upload(c, retry: false);
    return c.assetStatus == 'success' ? c : refresh(c);
  }

  Future<Character> upload(Character c, {bool retry = true}) async {
    final credential = _credential;
    final key = _uploadKey(c, credential.id);
    final pending = _uploads[key];
    if (pending != null) return pending;
    final published = _publishedUploads[key];
    final operation = _operation(() async {
      // A saved upload may finish between opening the form and starting its
      // provider. Recover its ID without issuing a new POST or losing edits.
      if (_editId != null &&
          published == null &&
          c.assetStatus == 'uploading') {
        final completed = await local.character(c.id);
        if (completed != null &&
            _sameImage(c, completed) &&
            completed.credentialId == credential.id &&
            completed.avatarId.isNotEmpty) {
          return _mergeIfCurrent(
            c,
            credential,
            (saved) => _withAsset(saved, completed),
            expectedAvatar: c.avatarId,
          );
        }
      }
      if (published == null) return _upload(c, credential, retry: retry);
      final asset = await published;
      return _mergeIfCurrent(
        c,
        credential,
        (saved) => _withAsset(saved, asset),
        expectedAvatar: c.avatarId,
      );
    });
    _uploads[key] = operation;
    if (_editId == null) _publishedUploads[key] = operation;
    try {
      return await operation;
    } finally {
      unawaited(_uploads.remove(key));
      if (identical(_publishedUploads[key], operation)) {
        unawaited(_publishedUploads.remove(key));
      }
    }
  }

  Future<Character> _upload(
    Character c,
    Credential credential, {
    required bool retry,
  }) async {
    if (!retry && {'uploading', 'uploadUnknown'}.contains(c.assetStatus)) {
      throw const AppFailure('avatarUploadUnknown', outcomeUnknown: true);
    }
    c = await saveDraft(c, requireImage: !retry);
    if (!retry && {'uploading', 'uploadUnknown'}.contains(c.assetStatus)) {
      throw const AppFailure('avatarUploadUnknown', outcomeUnknown: true);
    }
    if (!retry && c.avatarId.isNotEmpty) {
      return c.assetStatus == 'success' ? c : refresh(c);
    }
    if (c.imagePath.isEmpty && c.sourceImageUrl.isEmpty) {
      throw const AppFailure('imageInvalid');
    }
    if (c.imagePath.isEmpty) {
      final path = await local.importRemoteImage(c.sourceImageUrl, c.id);
      c = await _mergeIfCurrent(
        c,
        credential,
        (saved) => saved.copyWith(imagePath: path),
      );
    }
    c = await _mergeIfCurrent(
      c,
      credential,
      (saved) => saved.copyWith(
        credentialId: credential.id,
        avatarId: '',
        assetStatus: 'uploading',
      ),
    );
    final source = c;
    try {
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
      return await _mergeIfCurrent(
        source,
        credential,
        (saved) => saved.copyWith(
          credentialId: credential.id,
          avatarId: id,
          assetStatus: assetStatus(asset['status']),
        ),
        expectedAvatar: '',
      );
    } on AppFailure catch (error) {
      await _mergeIfCurrent(
        source,
        credential,
        (saved) => saved.copyWith(
          assetStatus: error.outcomeUnknown ? 'uploadUnknown' : 'uploadFailed',
        ),
        expectedAvatar: '',
      );
      rethrow;
    }
  }

  Future<Character> refresh(Character c) => _operation(() async {
    final credential = _credential;
    if (c.credentialId != credential.id) {
      throw const AppFailure('wrongCredential');
    }
    final response = await _queryAsset(credential, c.avatarId);
    final asset = response['avatar'] is Map
        ? jsonObject(response['avatar'])
        : response;
    return _mergeIfCurrent(
      c,
      credential,
      (saved) => _terminal(saved)
          ? saved
          : saved.copyWith(assetStatus: assetStatus(asset['status'])),
      expectedAvatar: c.avatarId,
      statusOnly: true,
    );
  });

  Future<Json> _queryAsset(Credential credential, String id) async {
    final key = (credential.id, credential.key, id);
    final pending = _assetQueries[key];
    if (pending != null) return pending;
    final query = api.avatar(credential, id);
    _assetQueries[key] = query;
    try {
      return await query;
    } finally {
      unawaited(_assetQueries.remove(key));
    }
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
