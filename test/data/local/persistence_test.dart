import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xiaoyu/data/local/database.dart';
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/local/call_store.dart';
import 'package:xiaoyu/data/character_repository.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/domain/models.dart' as domain;
import 'package:xiaoyu/domain/voice_catalog.dart';

import '../../support/offline.dart';

const character = domain.Character(
  id: 'character',
  name: 'Offline',
  persona: 'Kind companion',
  credentialId: 'account',
  avatarId: 'avatar',
  assetStatus: 'success',
);
void main() {
  late Directory dir;
  late AppDatabase db;
  late LocalRepository local;
  late DriftCallStore calls;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('xiaoyu-storage-');
    db = AppDatabase.forTesting(
      NativeDatabase(File('${dir.path}/test.sqlite')),
    );
    local = LocalRepository(db, dir);
    calls = DriftCallStore(local);
  });
  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });
  test('Doubao voice and provider survive SQLite reopen and call snapshot persistence', () async {
    final doubao = character.copyWith(
      voiceProvider: VoiceProvider.doubao,
      voice: 'zh_female_vv_uranus_bigtts',
    );
    await local.saveCharacter(doubao);
    await calls.begin(
      'doubao-call',
      doubao,
      const domain.Credential('account', 'test-only-key'),
    );
    await db.close();
    db = AppDatabase.forTesting(
      NativeDatabase(File('${dir.path}/test.sqlite')),
    );
    local = LocalRepository(db, dir);
    final restored = (await local.character(character.id))!;
    expect(restored.voiceProvider, VoiceProvider.doubao);
    expect(restored.voice, doubao.voice);
    expect(restored.id, character.id);
    expect(
      restored.copyWith(name: 'Changed').voiceProvider,
      VoiceProvider.doubao,
    );
    final snapshot = (await local.watchCalls().first).single.characterSnapshot;
    expect(snapshot, contains('"voiceProvider":"doubao"'));
    expect(snapshot, contains(doubao.voice));
    expect(domain.buildSession(restored, 'profile')['voice_model'], {
      'provider': 'doubao',
    });
  });
  test('profile, character, message and usage survive closing and reopening SQLite', () async {
    final profile = await local.profileId();
    expect(await local.profileId(), profile);
    await local.saveCharacter(character);
    await calls.begin(
      'call',
      character,
      const domain.Credential('account', 'test-only-key'),
    );
    await calls.update('call', {
      'liveId': 'live',
      'phase': 'connected',
      'readyAt': DateTime.utc(2026),
      'releasedAt': DateTime.utc(2026, 1, 2),
      'endReason': 'user_end',
      'error': 'network',
      'billedSeconds': 12,
      'creditsCost': '18',
    });
    await calls.message('call', 'message', 'user', 'Hello', 'sending');
    await calls.message('call', 'message', 'user', 'Hello', 'sent');
    expect(await calls.hasUnresolved(), isTrue);
    await db.close();
    db = AppDatabase.forTesting(
      NativeDatabase(File('${dir.path}/test.sqlite')),
    );
    local = LocalRepository(db, dir);
    calls = DriftCallStore(local);
    expect(await local.profileId(), profile);
    expect((await local.character('character'))!.name, 'Offline');
    expect((await local.watchCharacters().first).single.id, character.id);
    expect((await local.watchCalls().first).single.creditsCost, '18');
    expect((await local.watchMessages('call').first).single.delivery, 'sent');
    expect(
      (await db.select(db.settings).get()).any(
        (r) => r.value.contains('test-only-key'),
      ),
      isFalse,
    );
    await expectLater(
      local.deleteCall('call'),
      throwsA(isA<domain.AppFailure>()),
    );
    await calls.update('call', {'phase': 'ended', 'endConfirmed': true});
    expect(await calls.hasUnresolved(), isFalse);
    await local.deleteCall('call');
    expect(await local.watchMessages('call').first, isEmpty);
    await local.deleteCharacter(character.id);
    expect(await local.character(character.id), isNull);
  });
  test(
    'credential profiles isolate resource references and secure persistence',
    () async {
      final secure = MemorySecure();
      final credentials = CredentialRepository(local, secure: secure);
      await credentials.save(
        '  test-only-key  ',
        remember: true,
        sameAccount: false,
      );
      final firstId = credentials.currentId!;
      final restored = CredentialRepository(local, secure: secure);
      await restored.load();
      expect(restored.current!.id, firstId);
      expect(restored.remembered, isTrue);
      await restored.save(
        'another-test-only-key',
        remember: false,
        sameAccount: true,
      );
      expect(restored.currentId, firstId);
      expect(secure.values.containsKey('vidu.$firstId'), isFalse);
      await restored.save(
        'third-test-only-key',
        remember: true,
        sameAccount: false,
      );
      expect(restored.currentId, isNot(firstId));
      expect(await restored.forId(firstId), isNull);
      expect(
        (await restored.forId(restored.currentId!))!.id,
        restored.currentId,
      );
      await restored.clear();
      expect(restored.current, isNull);
      await expectLater(
        restored.save(' ', remember: false, sameAccount: true),
        throwsA(isA<domain.AppFailure>()),
      );
    },
  );
  test('image import validates size/type and keeps relative paths', () async {
    final picked = File('${dir.path}/photo.png')..writeAsBytesSync([1, 2, 3]);
    final path = await local.importImage(XFile(picked.path), 'character');
    expect(path.startsWith('characters/character/'), isTrue);
    expect(local.image(path).existsSync(), isTrue);
    final invalid = File('${dir.path}/photo.txt')..writeAsStringSync('invalid');
    await expectLater(
      local.importImage(XFile(invalid.path), 'character'),
      throwsA(isA<domain.AppFailure>()),
    );
    await expectLater(
      local.importRemoteImage('http://example.invalid/a.png', 'character'),
      throwsA(isA<domain.AppFailure>()),
    );
  });
  test('remote images use a separate unauthenticated client and atomic file writes', () async {
    final client = offlineDio(
      (_) => jsonBody({}, 200)..headers['content-type'] = ['image/png'],
    );
    local = LocalRepository(db, dir, downloadClient: () => client);
    final path = await local.importRemoteImage(
      'https://example.invalid/photo.png',
      'character',
    );
    expect(local.image(path).existsSync(), isTrue);
    expect(
      (client.httpClientAdapter as MemoryAdapter).requests.single.headers
          .containsKey('Authorization'),
      isFalse,
    );
    expect(
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .any((f) => f.path.endsWith('.tmp')),
      isFalse,
    );
    final bad = offlineDio((_) => jsonBody({}, 500));
    local = LocalRepository(db, dir, downloadClient: () => bad);
    await expectLater(
      local.importRemoteImage('https://example.invalid/photo.png', 'character'),
      throwsA(isA<domain.AppFailure>()),
    );
  });
  test(
    'character operations preserve draft/persona and enforce account ownership',
    () async {
      final secure = MemorySecure(),
          credentials = CredentialRepository(local, secure: MemorySecure());
      await credentials.save(
        'test-only-key',
        remember: false,
        sameAccount: false,
      );
      final image = File('${dir.path}/original.png')
        ..writeAsBytesSync([1, 2, 3]);
      final client = offlineDio(
        (o) => jsonBody(
          o.path.endsWith('/avatars') && o.method == 'GET'
              ? {
                  'avatars': [
                    {'id': 'asset'},
                  ],
                }
              : {
                  'avatar': {'id': 'asset', 'status': 11},
                },
        ),
      );
      final api = ViduApi(client: client);
      addTearDown(api.dispose);
      final repo = CharacterRepository(local, credentials, api);
      final draft = character.copyWith(imagePath: image.path);
      final uploaded = await repo.upload(draft);
      expect(uploaded.credentialId, credentials.currentId);
      expect(uploaded.persona, draft.persona);
      expect((await repo.refresh(uploaded)).assetStatus, 'success');
      expect(await repo.existing(), hasLength(1));
      await repo.verifyOriginalAccount('test-only-key');
      await expectLater(
        repo.refresh(character),
        throwsA(isA<domain.AppFailure>()),
      );
      await expectLater(
        repo.upload(character),
        throwsA(isA<domain.AppFailure>()),
      );
      for (final pair in {
        '1': 'created',
        '6': 'processing',
        '11': 'success',
        '12': 'failed',
        '?': 'draft',
      }.entries) {
        expect(repo.assetStatus(pair.key), pair.value);
      }
      await credentials.clear();
      await expectLater(repo.existing(), throwsA(isA<domain.AppFailure>()));
      expect(secure.values, isEmpty);
    },
  );
}
