import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/presentation/avatar_status_sync.dart';

const pending = Character(
  id: 'role',
  name: 'Saved',
  persona: 'Persona',
  imagePath: 'photo.png',
  avatarId: 'asset',
  credentialId: 'offline-account',
  assetStatus: 'processing',
);

class _Fixture {
  _Fixture() {
    sync = AvatarStatusSync(
      credential: () => credential,
      refresh: (c) {
        queries.add(c);
        return query(c);
      },
    );
  }
  Credential? credential = const Credential('offline-account', 'offline-key');
  final queries = <Character>[];
  Future<Character> Function(Character) query = (c) async => c;
  late final AvatarStatusSync sync;
  Future<void> close() async {
    sync.dispose();
  }
}

void main() {
  _Fixture open() {
    final fixture = _Fixture();
    addTearDown(fixture.close);
    return fixture;
  }

  testWidgets(
    'home polls saved processing assets and stops at success or failure',
    (tester) async {
      final f = open();
      f.sync.update([
        pending,
        pending.copyWith(
          id: 'second',
          avatarId: 'second-asset',
          assetStatus: 'created',
        ),
      ]);
      await tester.pump();
      expect(f.queries, isEmpty);
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries, hasLength(2));
      f.query = (c) async =>
          c.copyWith(assetStatus: c.id == 'role' ? 'success' : 'failed');
      await tester.pump(const Duration(seconds: 3));
      expect(f.queries, hasLength(4));
      await tester.pump(const Duration(minutes: 3));
      expect(f.queries, hasLength(4));
    },
  );

  testWidgets(
    'background cancels polling and returning home queries immediately',
    (tester) async {
      final f = open();
      f.sync.update([pending]);
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries, hasLength(1));
      f.sync.setActive(false);
      await tester.pump(const Duration(seconds: 30));
      expect(f.queries, hasLength(1));
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries, hasLength(2));
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries, hasLength(2));
    },
  );

  testWidgets(
    'slow GETs never overlap and repeated stream updates do not restart them',
    (tester) async {
      final f = open();
      final response = Completer<Character>();
      f.query = (_) => response.future;
      f.sync.update([pending]);
      f.sync.setActive(true);
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        f.sync.update([pending.copyWith(name: 'Changed $i')]);
        await tester.pump(const Duration(seconds: 3));
      }
      expect(f.queries, hasLength(1));
      response.complete(pending);
      await tester.pump();
      f.query = (c) async => c.copyWith(assetStatus: 'success');
      await tester.pump(const Duration(seconds: 3));
      expect(f.queries, hasLength(2));
    },
  );

  testWidgets(
    'forty failed GETs exhaust the window; resume starts a new window',
    (tester) async {
      final f = open();
      f.query = (_) async => throw const AppFailure('network');
      f.sync.update([pending]);
      f.sync.setActive(true);
      await tester.pump();
      for (var i = 1; i < 40; i++) {
        f.sync.update([pending.copyWith(name: 'Edit $i')]);
        await tester.pump(const Duration(seconds: 3));
      }
      expect(f.queries, hasLength(40));
      await tester.pump(const Duration(minutes: 10));
      expect(f.queries, hasLength(40));
      f.sync.setActive(false);
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries, hasLength(41));
    },
  );

  testWidgets(
    'only current-account pending assets with known IDs are queried',
    (tester) async {
      final f = open();
      f.sync.update([
        pending.copyWith(assetStatus: 'draft', avatarId: ''),
        pending.copyWith(id: 'ready', assetStatus: 'success'),
        pending.copyWith(id: 'failed', assetStatus: 'failed'),
        pending.copyWith(id: 'upload', assetStatus: 'uploading', avatarId: ''),
        pending.copyWith(id: 'other', credentialId: 'other-account'),
        pending,
      ]);
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries.map((c) => c.id), ['role']);
      f.credential = null;
      await tester.pump(const Duration(seconds: 3));
      expect(f.queries, hasLength(1));
      f.credential = const Credential('other-account', 'other-offline-key');
      f.sync.setActive(false);
      f.sync.setActive(true);
      await tester.pump();
      expect(f.queries.last.id, 'other');
    },
  );

  testWidgets(
    'deletion and photo replacement ignore late progress and stop old polling',
    (tester) async {
      final f = open();
      final response = Completer<Character>();
      f.query = (_) => response.future;
      f.sync.update([pending]);
      f.sync.setActive(true);
      await tester.pump();
      f.sync.update([
        pending.copyWith(
          imagePath: 'new.png',
          avatarId: '',
          assetStatus: 'draft',
        ),
      ]);
      response.complete(pending.copyWith(assetStatus: 'success'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      expect(f.queries, hasLength(1));
      f.query = (c) async => c;
      f.sync.update([
        pending.copyWith(avatarId: 'new-asset', imagePath: 'new.png'),
      ]);
      await tester.pump();
      expect(f.queries, hasLength(2));
      expect(f.queries.last.avatarId, 'new-asset');
      f.sync.update([]);
      await tester.pump(const Duration(seconds: 9));
      expect(f.queries, hasLength(2));
    },
  );

  testWidgets('disposal during GET cancels all future activity', (
    tester,
  ) async {
    final f = open();
    final response = Completer<Character>();
    f.query = (_) => response.future;
    f.sync.update([pending]);
    f.sync.setActive(true);
    await tester.pump();
    f.sync.dispose();
    response.complete(pending);
    f.sync.update([pending.copyWith(id: 'new')]);
    f.sync.setActive(true);
    await tester.pump(const Duration(minutes: 5));
    expect(f.queries, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a new saved role wakes the loop; repeated processing does not spin',
    (tester) async {
      final f = open();
      f.sync.setActive(true);
      await tester.pump();
      f.sync.update([pending]);
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        f.sync.update([pending]);
        await tester.pump();
      }
      expect(f.queries, hasLength(1));
      await tester.pump(const Duration(seconds: 3));
      expect(f.queries, hasLength(2));
    },
  );
}
