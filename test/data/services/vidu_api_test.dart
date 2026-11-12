import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/data/services/official_catalog.dart';
import 'package:xiaoyu/domain/models.dart';

import '../../support/offline.dart';

void main() {
  const credential = Credential('offline-account', 'test-only-key');
  for (final status in [401, 403, 402, 503, 404, 500]) {
    test('HTTP $status maps errors and never repeats creation', () async {
      final client = offlineDio((_) => jsonBody({}, status));
      final api = ViduApi(client: client);
      addTearDown(api.dispose);
      await expectLater(
        api.createLive(credential, {}),
        throwsA(
          isA<AppFailure>()
              .having(
                (e) => e.code,
                'code',
                {
                  401: 'unauthorized',
                  403: 'forbidden',
                  402: 'insufficientCredit',
                  503: 'channelUnavailable',
                  404: 'notFound',
                  500: 'network',
                }[status],
              )
              .having((e) => e.outcomeUnknown, 'unknown', status >= 500),
        ),
      );
      expect(
        (client.httpClientAdapter as MemoryAdapter).requests,
        hasLength(1),
      );
    });
  }
  test(
    'transport timeout remains unknown without retry or leaked key',
    () async {
      final client = offlineDio(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      final api = ViduApi(client: client);
      addTearDown(api.dispose);
      await expectLater(
        api.createLive(credential, {}),
        throwsA(
          isA<AppFailure>().having((e) => e.outcomeUnknown, 'unknown', true),
        ),
      );
      expect((client.httpClientAdapter as MemoryAdapter).requests.length, 1);
      expect(credential.toString(), isNot(contains(credential.key)));
    },
  );
  test(
    'read-only auth and encoded asset/live paths preserve response envelope',
    () async {
      final client = offlineDio(
        (_) => jsonBody({
          'data': {
            'avatars': <Object?>[],
            'live': {'status': 'ended'},
            'avatar': {'id': 'one'},
          },
        }),
      );
      final api = ViduApi(client: client);
      addTearDown(api.dispose);
      await api.check(credential);
      await api.avatars(credential);
      await api.avatar(credential, 'a/b');
      await api.getLive(credential, 'a/b');
      final requests = (client.httpClientAdapter as MemoryAdapter).requests;
      expect(requests.every((r) => r.method == 'GET'), isTrue);
      expect(requests.every((r) => r.followRedirects == false), isTrue);
      expect(requests.first.queryParameters['pager.pagesz'], 1);
      expect(requests.last.path, endsWith('a%2Fb'));
      expect(
        requests.every(
          (r) => r.headers['Authorization'] == 'Token ${credential.key}',
        ),
        isTrue,
      );
    },
  );
  test('upload encodes local image and keeps request shape', () async {
    final dir = Directory.systemTemp.createTempSync('upload-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/photo.png')..writeAsBytesSync([1, 2, 3]);
    final client = offlineDio(
      (_) => jsonBody({
        'avatar': {'id': 'asset'},
      }),
    );
    final api = ViduApi(client: client);
    addTearDown(api.dispose);
    expect((await api.uploadAvatar(credential, file, 'Portrait'))['avatar'], {
      'id': 'asset',
    });
    final request = (client.httpClientAdapter as MemoryAdapter).requests.single;
    expect(
      (request.data as Map)['image_uri'],
      startsWith('data:image/png;base64,'),
    );
  });
  test('invalid JSON body reports protocol, not successful auth', () async {
    final api = ViduApi(client: offlineDio((_) => jsonBody('invalid')));
    addTearDown(api.dispose);
    await expectLater(api.check(credential), throwsA(isA<AppFailure>()));
  });
  test(
    'official catalog filters disabled/invalid assets, uses no API credentials',
    () async {
      final client = offlineDio(
        (_) => jsonBody({
          'roles': [
            {
              'id': 'official',
              'enabled': true,
              'image_uri': 'https://example.invalid/portrait.png',
            },
            {
              'enabled': false,
              'image_uri': 'https://example.invalid/portrait.png',
            },
            {'enabled': true},
          ],
        }),
      );
      final catalog = OfficialCatalog(client: client);
      addTearDown(catalog.dispose);
      expect(await catalog.load(), hasLength(1));
      expect(
        (client.httpClientAdapter as MemoryAdapter).requests.single.headers
            .containsKey('Authorization'),
        isFalse,
      );
    },
  );
  test('official catalog errors stay errors', () async {
    final catalog = OfficialCatalog(
      client: offlineDio((_) => jsonBody({}, 503)),
    );
    addTearDown(catalog.dispose);
    await expectLater(
      catalog.load(),
      throwsA(
        isA<AppFailure>().having((e) => e.code, 'code', 'catalogUnavailable'),
      ),
    );
  });
}
