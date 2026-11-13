import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/data/character_repository.dart';
import 'package:xiaoyu/data/local/database.dart';
import 'package:xiaoyu/data/local/repositories.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/domain/official_character.dart';

import '../support/fixture.dart' show officialCompanion;
import '../support/offline.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late LocalRepository local;
  late CredentialRepository credentials;
  late CharacterRepository repository;
  late ViduApi api;
  late MemoryAdapter adapter;
  var status = 11;
  setUp(() async {
    status = 11;
    dir = Directory.systemTemp.createTempSync('xiaoyu-character-submit-');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalRepository(
      db,
      dir,
      downloadClient: () => offlineDio(
        (_) => jsonBody({}, 200)..headers['content-type'] = ['image/png'],
      ),
    );
    credentials = CredentialRepository(local, secure: MemorySecure());
    await credentials.save(
      'test-only-key',
      remember: false,
      sameAccount: false,
    );
    final client = offlineDio((request) {
      expect(request.path, startsWith('/live/v1/avatars'));
      return jsonBody({
        'avatar': {'id': 'account-asset', 'status': status},
      });
    });
    adapter = client.httpClientAdapter as MemoryAdapter;
    api = ViduApi(client: client);
    repository = CharacterRepository(local, credentials, api);
  });
  tearDown(() async {
    api.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('recommended template submit creates a real account asset and saves metadata', () async {
    final draft = OfficialCharacter(officialCompanion).draft('recommended');
    final result = await repository.submit(draft);
    expect(result.ready, isTrue);
    expect(result.credentialId, credentials.currentId);
    expect(result.avatarId, 'account-asset');
    expect(result.avatarId, isNot(draft.officialRoleId));
    expect(result.persona, draft.persona);
    expect(result.summary, draft.summary);
    expect(local.image(result.imagePath).existsSync(), isTrue);
    expect((await local.character(draft.id))!.avatarId, result.avatarId);
    expect(adapter.requests.single.method, 'POST');
    expect(
      adapter.requests.single.data['image_uri'],
      startsWith('data:image/png;base64,'),
    );
    // A stale UI draft must reuse the previously saved ID instead of uploading again.
    final repeated = await repository.submit(draft.copyWith(name: 'Edited'));
    expect(repeated.name, 'Edited');
    expect(adapter.requests, hasLength(1));
  });

  test(
    'processing persists and next submit refreshes without duplicate creation',
    () async {
      status = 6;
      final draft = OfficialCharacter(officialCompanion).draft('processing');
      final pending = await repository.submit(draft);
      expect(pending.ready, isFalse);
      expect(pending.assetStatus, 'processing');
      status = 11;
      final result = await repository.submit(pending);
      expect(result.ready, isTrue);
      expect(adapter.requests.map((r) => r.method), ['POST', 'GET']);
      expect((await local.character(draft.id))!.assetStatus, 'success');
    },
  );

  test(
    'failed asset is queried without silently creating a replacement',
    () async {
      status = 12;
      final failed = await repository.submit(
        OfficialCharacter(officialCompanion).draft('failed'),
      );
      expect(failed.assetStatus, 'failed');
      await repository.submit(failed);
      expect(adapter.requests.map((r) => r.method), ['POST', 'GET']);
    },
  );

  test(
    'blank fields, missing key, missing image and wrong account remain blocked',
    () async {
      final draft = OfficialCharacter(officialCompanion).draft('invalid');
      for (final invalid in [
        draft.copyWith(name: ' '),
        draft.copyWith(persona: ' '),
        draft.copyWith(voice: ''),
      ]) {
        await expectLater(
          repository.submit(invalid),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.code,
              'code',
              'characterFieldsIncomplete',
            ),
          ),
        );
      }
      await expectLater(
        repository.submit(draft.copyWith(sourceImageUrl: '')),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'imageInvalid'),
        ),
      );
      final asset = draft.copyWith(
        avatarId: 'foreign',
        credentialId: 'other',
        assetStatus: 'success',
      );
      await expectLater(
        repository.submit(asset),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'wrongCredential'),
        ),
      );
      await local.saveCharacter(asset);
      await expectLater(
        repository.submit(draft),
        throwsA(
          isA<AppFailure>().having((e) => e.code, 'code', 'wrongCredential'),
        ),
      );
      await credentials.clear();
      await expectLater(
        repository.submit(draft),
        throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'missingKey')),
      );
      expect(adapter.requests, isEmpty);
    },
  );
}
