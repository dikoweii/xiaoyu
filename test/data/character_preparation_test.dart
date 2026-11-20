import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/data/character_repository.dart';
import 'package:xiaoyu/data/local/database.dart' show AppDatabase;
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/domain/models.dart';

import '../support/offline.dart';

class _AvatarApi extends ViduApi {
  final uploads = <Completer<Json>>[];
  final queries = <Completer<Json>>[];
  final names = <String>[];
  @override
  Future<Json> uploadAvatar(Credential c, File image, String name) {
    expect(image.existsSync(), isTrue);
    names.add(name);
    final result = Completer<Json>();
    uploads.add(result);
    return result.future;
  }

  @override
  Future<Json> avatar(Credential c, String id) {
    final result = Completer<Json>();
    queries.add(result);
    return result.future;
  }
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 1000 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(ready(), isTrue);
}

void main() {
  late Directory dir;
  late AppDatabase db;
  late LocalRepository local;
  late CredentialRepository credentials;
  late CharacterRepository repository;
  late _AvatarApi api;
  late Character image;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('xiaoyu-prepare-');
    File('${dir.path}/a.png').writeAsBytesSync([1]);
    File('${dir.path}/b.png').writeAsBytesSync([2]);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalRepository(db, dir);
    credentials = CredentialRepository(local, secure: MemorySecure());
    await credentials.save('offline-key', remember: false, sameAccount: false);
    api = _AvatarApi();
    repository = CharacterRepository(local, credentials, api);
    image = const Character(
      id: 'stable-memory-id',
      name: '',
      persona: '',
      imagePath: 'a.png',
    );
    await local.saveCharacter(image);
  });
  tearDown(() async {
    api.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'prepares before text is entered, preserves edits, and fills avatar.id',
    () async {
      final pending = repository.upload(image, retry: false);
      await _until(() => api.uploads.isNotEmpty);
      expect(api.names.single, '');
      final edited = image.copyWith(
        name: 'Edited',
        persona: 'New persona',
        voice: 'Tina',
        memory: true,
      );
      await repository.saveDraft(edited);
      api.uploads.single.complete({'id': 'prepared-a', 'status': 11});
      final result = await pending;
      expect(result.name, 'Edited');
      expect(result.persona, 'New persona');
      expect(result.voice, 'Tina');
      await repository.saveDraft(
        edited,
      ); // stale form state cannot erase the ID
      final submitted = await repository.submit(edited);
      expect(api.uploads, hasLength(1));
      final session = buildSession(submitted, 'offline-user');
      expect((session['avatar'] as Json)['id'], 'prepared-a');
      expect((session['avatar'] as Json)['persona'], 'New persona');
      expect((session['avatar'] as Json)['voice'], 'Tina');
      expect((session['memory_retrieval'] as Json)['agent_id'], image.id);
    },
  );

  test(
    'submit during upload waits for the same POST and keeps latest text',
    () async {
      final upload = repository.upload(image, retry: false);
      await _until(() => api.uploads.isNotEmpty);
      final submit = repository.submit(
        image.copyWith(name: 'Ready', persona: 'Persona'),
      );
      await _until(() => api.uploads.length == 1);
      api.uploads.single.complete({'id': 'one-post', 'status': 'success'});
      await upload;
      expect((await submit).avatarId, 'one-post');
      expect((await local.character(image.id))!.name, 'Ready');
      expect(api.uploads, hasLength(1));
    },
  );

  test('A response cannot overwrite B even when it completes last', () async {
    final a = repository.upload(image, retry: false);
    final rejected = expectLater(a, throwsA(isA<AppFailure>()));
    await _until(() => api.uploads.length == 1);
    final b = image.copyWith(imagePath: 'b.png');
    await repository.saveDraft(b);
    final bUpload = repository.upload(b, retry: false);
    await _until(() => api.uploads.length == 2);
    api.uploads.last.complete({'id': 'asset-b', 'status': 11});
    await bUpload;
    api.uploads.first.complete({'id': 'asset-a', 'status': 11});
    await rejected;
    final saved = (await local.character(image.id))!;
    expect(saved.avatarId, 'asset-b');
    expect(saved.imagePath, 'b.png');
    expect(saved.id, image.id);
    await expectLater(
      repository.submit(image.copyWith(name: 'Old', persona: 'Old')),
      throwsA(isA<AppFailure>()),
    );
    expect(api.uploads, hasLength(2));
  });

  test('late status query cannot replace a selected different asset', () async {
    final a = image.copyWith(
      avatarId: 'asset-a',
      credentialId: credentials.currentId,
      assetStatus: 'processing',
    );
    await local.saveCharacter(a);
    final query = repository.refresh(a);
    final rejected = expectLater(query, throwsA(isA<AppFailure>()));
    await _until(() => api.queries.isNotEmpty);
    final selected = a.copyWith(avatarId: 'asset-b', assetStatus: 'success');
    await local.saveCharacter(selected);
    api.queries.single.complete({'id': 'asset-a', 'status': 12});
    await rejected;
    expect((await local.character(image.id))!.assetStatus, 'success');
    expect((await local.character(image.id))!.avatarId, 'asset-b');
  });

  test(
    'out of order status queries cannot regress a terminal result',
    () async {
      final pending = image.copyWith(
        avatarId: 'asset-a',
        credentialId: credentials.currentId,
        assetStatus: 'processing',
      );
      await local.saveCharacter(pending);
      final first = repository.refresh(pending);
      // Independent owners can still have requests from different moments.
      final second = CharacterRepository(
        local,
        credentials,
        api,
      ).refresh(pending);
      await _until(() => api.queries.length == 2);
      api.queries.last.complete({'status': 'success'});
      await second;
      api.queries.first.complete({'status': 'processing'});
      expect((await first).assetStatus, 'success');
      expect((await local.character(image.id))!.assetStatus, 'success');
    },
  );

  for (final status in ['success', 'failed']) {
    test(
      'editor syncs $status without publishing unsaved form fields',
      () async {
        final pending = image.copyWith(
          name: 'Saved name',
          persona: 'Saved persona',
          avatarId: 'asset-a',
          credentialId: credentials.currentId,
          assetStatus: 'processing',
        );
        await local.saveCharacter(pending);
        final editor = await repository.edit(pending, 'reopened');
        await editor.saveDraft(
          pending.copyWith(name: 'Unsaved name', voice: 'Tina'),
        );
        final query = editor.refresh(pending);
        await _until(() => api.queries.isNotEmpty);
        api.queries.single.complete({'status': status});
        expect((await query).name, 'Unsaved name');
        final saved = (await local.watchCharacters().first).single;
        expect(saved.assetStatus, status);
        expect(saved.name, 'Saved name');
        expect(saved.voice, pending.voice);
        await editor.closeEdit(saved: false);
        expect((await local.character(image.id))!.assetStatus, status);
        expect(api.uploads, isEmpty);
      },
    );
  }

  test(
    'home and editor share a GET, then later attempts can query again',
    () async {
      final pending = image.copyWith(
        avatarId: 'asset-a',
        credentialId: credentials.currentId,
        assetStatus: 'processing',
      );
      await local.saveCharacter(pending);
      final editor = await repository.edit(pending, 'shared');
      final home = repository.refresh(pending);
      final form = editor.refresh(pending);
      await _until(() => api.queries.isNotEmpty);
      expect(api.queries, hasLength(1));
      api.queries.single.complete({'status': 'processing'});
      await Future.wait([home, form]);
      final next = editor.refresh(pending);
      await _until(() => api.queries.length == 2);
      api.queries.last.complete({'status': 'success'});
      await next;
      expect((await local.character(image.id))!.assetStatus, 'success');
      await editor.closeEdit(saved: false);
    },
  );

  test(
    'two saved roles referencing one asset share a query and both update',
    () async {
      final first = image.copyWith(
        avatarId: 'shared-asset',
        credentialId: credentials.currentId,
        assetStatus: 'processing',
      );
      final second = Character(
        id: 'another-role',
        name: 'Another',
        persona: 'Another persona',
        imagePath: 'b.png',
        avatarId: first.avatarId,
        credentialId: first.credentialId,
        assetStatus: 'processing',
      );
      await local.saveCharacter(first);
      await local.saveCharacter(second);
      final results = Future.wait([
        repository.refresh(first),
        repository.refresh(second),
      ]);
      await _until(() => api.queries.isNotEmpty);
      expect(api.queries, hasLength(1));
      api.queries.single.complete({'status': 'success'});
      await results;
      expect(
        (await local.watchCharacters().first).every(
          (c) => c.assetStatus == 'success',
        ),
        isTrue,
      );
      expect(api.uploads, isEmpty);
    },
  );

  test(
    'failed shared GET is removed and can be retried without POST',
    () async {
      final pending = image.copyWith(
        avatarId: 'asset-a',
        credentialId: credentials.currentId,
        assetStatus: 'processing',
      );
      await local.saveCharacter(pending);
      final editor = await repository.edit(pending, 'shared-error');
      final home = repository.refresh(pending);
      final form = editor.refresh(pending);
      final errors = [
        expectLater(home, throwsA(isA<AppFailure>())),
        expectLater(form, throwsA(isA<AppFailure>())),
      ];
      await _until(() => api.queries.isNotEmpty);
      api.queries.single.completeError(const AppFailure('network'));
      await Future.wait(errors);
      final next = repository.refresh(pending);
      await _until(() => api.queries.length == 2);
      api.queries.last.complete({'status': 'success'});
      await next;
      expect(api.uploads, isEmpty);
      await editor.closeEdit(saved: false);
    },
  );

  for (final change in ['photo', 'asset', 'account', 'deleted']) {
    test('editor GET cannot update a $change saved role', () async {
      final pending = image.copyWith(
        avatarId: 'asset-a',
        credentialId: credentials.currentId,
        assetStatus: 'processing',
      );
      await local.saveCharacter(pending);
      final editor = await repository.edit(pending, 'stale-$change');
      final query = editor.refresh(pending);
      final completed = change == 'account'
          ? expectLater(query, throwsA(isA<AppFailure>()))
          : query.then<void>((_) {});
      await _until(() => api.queries.isNotEmpty);
      if (change == 'account') {
        await credentials.save(
          'another-offline-key',
          remember: false,
          sameAccount: false,
        );
      } else if (change == 'deleted') {
        await local.deleteCharacter(image.id);
      } else {
        await local.saveCharacter(
          pending.copyWith(
            imagePath: change == 'photo' ? 'b.png' : null,
            avatarId: change == 'asset' ? 'asset-b' : null,
          ),
        );
      }
      api.queries.single.complete({'status': 'success'});
      await completed;
      expect(
        (await local.character(image.id))?.assetStatus,
        change == 'deleted' ? null : 'processing',
      );
      await editor.closeEdit(saved: false);
    });
  }

  test(
    'stale editor save adopts terminal home status without losing new text',
    () async {
      final pending = image.copyWith(
        avatarId: 'asset-a',
        credentialId: credentials.currentId,
        assetStatus: 'processing',
      );
      await local.saveCharacter(pending);
      final editor = await repository.edit(pending, 'stale-save');
      await local.saveCharacter(pending.copyWith(assetStatus: 'success'));
      final published = await editor.publish(
        pending.copyWith(name: 'New saved name'),
      );
      expect(published.assetStatus, 'success');
      expect((await local.character(image.id))!.name, 'New saved name');
      await editor.closeEdit(saved: true);
    },
  );

  for (final change in ['account', 'deleted']) {
    test('late POST does not update a $change character', () async {
      final upload = repository.upload(image, retry: false);
      final rejected = expectLater(upload, throwsA(isA<AppFailure>()));
      await _until(() => api.uploads.isNotEmpty);
      if (change == 'account') {
        await credentials.save(
          'another-offline-key',
          remember: false,
          sameAccount: false,
        );
      } else {
        await local.deleteCharacter(image.id);
      }
      api.uploads.single.complete({'id': 'late', 'status': 11});
      await rejected;
      final saved = await local.character(image.id);
      expect(saved?.avatarId ?? '', isEmpty);
      if (change == 'deleted') expect(saved, isNull);
    });
  }

  test('uncertain POST is persisted and never automatically retried', () async {
    final upload = repository.upload(image, retry: false);
    final failed = expectLater(upload, throwsA(isA<AppFailure>()));
    await _until(() => api.uploads.isNotEmpty);
    api.uploads.single.completeError(
      const AppFailure('network', outcomeUnknown: true),
    );
    await failed;
    final saved = (await local.character(image.id))!;
    expect(saved.assetStatus, 'uploadUnknown');
    await expectLater(
      repository.submit(saved.copyWith(name: 'Name', persona: 'Persona')),
      throwsA(
        isA<AppFailure>().having((e) => e.code, 'code', 'avatarUploadUnknown'),
      ),
    );
    await expectLater(
      repository.upload(saved, retry: false),
      throwsA(isA<AppFailure>()),
    );
    expect(api.uploads, hasLength(1));
    final explicitRetry = repository.upload(saved);
    await _until(() => api.uploads.length == 2);
    api.uploads.last.complete({'id': 'manual-retry', 'status': 11});
    expect((await explicitRetry).avatarId, 'manual-retry');
  });
  test(
    'temporary edits and image preparation stay out of the home list',
    () async {
      await local.deleteCharacter(image.id);
      final editor = await repository.edit(image, 'new-edit');
      await editor.saveDraft(image.copyWith(name: 'Unsaved'));
      final upload = editor.upload(image, retry: false);
      await _until(() => api.uploads.isNotEmpty);
      api.uploads.single.complete({'id': 'hidden-asset', 'status': 11});
      final prepared = await upload;
      expect(await local.watchCharacters().first, isEmpty);
      expect(await local.character(image.id), isNull);
      final saved = await editor.publish(prepared.copyWith(name: 'Saved'));
      expect((await local.watchCharacters().first).single.name, 'Saved');
      expect(saved.id, image.id);
      expect(saved.avatarId, 'hidden-asset');
      await editor.closeEdit(saved: true);
      expect(await local.setting('characterEdit.new-edit'), isNull);
    },
  );

  for (final existing in [false, true]) {
    test(
      'discard $existing edit ignores a late upload and preserves saved role',
      () async {
        if (!existing) await local.deleteCharacter(image.id);
        final editor = await repository.edit(image, 'discard-edit');
        final changed = image.copyWith(name: 'Unsaved', imagePath: 'b.png');
        await editor.saveDraft(changed);
        final upload = editor.upload(changed, retry: false);
        final rejected = expectLater(upload, throwsA(isA<AppFailure>()));
        await _until(() => api.uploads.isNotEmpty);
        await editor.closeEdit(saved: false);
        api.uploads.single.complete({'id': 'discarded', 'status': 11});
        await rejected;
        expect(
          (await local.character(image.id))?.toJson(),
          existing ? image.toJson() : null,
        );
        expect(await local.setting('characterEdit.discard-edit'), isNull);
        await expectLater(
          editor.saveDraft(changed),
          throwsA(isA<AppFailure>()),
        );
      },
    );
  }

  test(
    'saving during upload accepts late ID without losing saved text',
    () async {
      await local.deleteCharacter(image.id);
      final editor = await repository.edit(image, 'saved-edit');
      final upload = editor.upload(image, retry: false);
      await _until(() => api.uploads.isNotEmpty);
      final saved = await editor.publish(
        image.copyWith(name: 'Saved text', persona: 'Saved persona'),
      );
      expect(saved.assetStatus, 'uploading');
      await editor.closeEdit(saved: true);
      api.uploads.single.complete({'id': 'late-saved', 'status': 11});
      await upload;
      final result = (await local.character(image.id))!;
      expect(result.name, 'Saved text');
      expect(result.persona, 'Saved persona');
      expect(result.avatarId, 'late-saved');
      expect(await local.setting('characterEdit.saved-edit'), isNull);
    },
  );

  test(
    'discard after publishing retains last saved version, not newer edits',
    () async {
      final editor = await repository.edit(image, 'existing-edit');
      await editor.publish(image.copyWith(name: 'Saved'));
      await editor.saveDraft(
        image.copyWith(name: 'Not saved', imagePath: 'b.png'),
      );
      await editor.closeEdit(saved: false);
      expect((await local.character(image.id))!.name, 'Saved');
      expect((await local.character(image.id))!.imagePath, 'a.png');
    },
  );

  test(
    'late saved upload cannot resurrect a deleted role or replace a new photo',
    () async {
      for (final deleted in [false, true]) {
        final editor = await repository.edit(image, 'saved-$deleted');
        final upload = editor.upload(image, retry: false);
        final index = api.uploads.length;
        await _until(() => api.uploads.length > index);
        await editor.publish(image);
        await editor.closeEdit(saved: true);
        if (deleted) {
          await local.deleteCharacter(image.id);
        } else {
          await local.saveCharacter(
            image.copyWith(imagePath: 'b.png', name: 'New photo'),
          );
        }
        api.uploads.last.complete({'id': 'old-upload', 'status': 11});
        await upload;
        expect((await local.character(image.id))?.avatarId ?? '', isEmpty);
        if (deleted) expect(await local.character(image.id), isNull);
      }
    },
  );

  test(
    'startup cleanup removes temporary sessions and preserves saved roles',
    () async {
      final editor = await repository.edit(image, 'interrupted');
      await editor.saveDraft(image.copyWith(name: 'Interrupted edit'));
      await local.clearEditingSessions();
      expect(await editor.character(image.id), isNull);
      expect((await local.character(image.id))!.toJson(), image.toJson());
    },
  );
  test(
    'reopening a saved uploading draft waits for the same request',
    () async {
      final first = await repository.edit(image, 'first-editor');
      final upload = first.upload(image, retry: false);
      await _until(() => api.uploads.isNotEmpty);
      final saved = await first.publish(image.copyWith(name: 'Saved'));
      await first.closeEdit(saved: true);
      final second = await repository.edit(saved, 'second-editor');
      final waiting = second.upload(saved, retry: false);
      api.uploads.single.complete({'id': 'shared-upload', 'status': 11});
      await upload;
      expect((await waiting).avatarId, 'shared-upload');
      expect((await second.character(image.id))!.name, 'Saved');
      expect(api.uploads, hasLength(1));
      await second.closeEdit(saved: false);
    },
  );
  test(
    'reopening with a stale uploading snapshot recovers the completed ID',
    () async {
      final first = await repository.edit(image, 'completed-first');
      final upload = first.upload(image, retry: false);
      await _until(() => api.uploads.isNotEmpty);
      final stale = await first.publish(image.copyWith(name: 'Saved'));
      await first.closeEdit(saved: true);
      api.uploads.single.complete({
        'id': 'completed-before-provider',
        'status': 11,
      });
      await upload;
      final second = await repository.edit(stale, 'completed-second');
      await second.saveDraft(stale.copyWith(name: 'Still editing'));
      final recovered = await second.upload(stale, retry: false);
      expect(recovered.avatarId, 'completed-before-provider');
      expect(recovered.name, 'Still editing');
      expect(api.uploads, hasLength(1));
      await second.closeEdit(saved: false);
    },
  );
}
