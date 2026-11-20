import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/data/services/vidu_api.dart';
import 'package:xiaoyu/domain/models.dart';

import '../support/fixture.dart';

class _Api extends ViduApi {
  String status = 'processing';
  int queries = 0;
  @override
  Future<Json> avatar(Credential c, String id) async {
    queries++;
    return {'id': id, 'status': status};
  }
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  Future<({Fixture fixture, _Api api, Character pending})> open(
    WidgetTester tester,
  ) async {
    final api = _Api();
    final fixture = Fixture(apiOverride: api);
    await fixture.open();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await fixture.close();
    });
    await fixture.app.credentials.save(
      'offline-only-key',
      remember: false,
      sameAccount: false,
    );
    final pending = companion.copyWith(
      name: 'Saved companion',
      summary: '',
      credentialId: fixture.app.credentials.currentId,
      assetStatus: 'processing',
    );
    await fixture.app.local.saveCharacter(pending);
    await fixture.pump(tester);
    await _flush(tester);
    return (fixture: fixture, api: api, pending: pending);
  }

  testWidgets(
    'home changes processing to ready without opening editor or submitting',
    (tester) async {
      final data = await open(tester);
      expect(find.text('形象处理中'), findsOneWidget);
      expect(data.api.queries, 1);
      data.api.status = 'success';
      await tester.pump(const Duration(seconds: 3));
      await _flush(tester);
      expect(find.text('形象已就绪'), findsOneWidget);
      expect(find.text('形象处理中'), findsNothing);
      expect(
        (await tester.runAsync(
          () => data.fixture.app.local.character(data.pending.id),
        ))!.ready,
        isTrue,
      );
      final queries = data.api.queries;
      await tester.pump(const Duration(seconds: 15));
      expect(data.api.queries, queries);
    },
  );

  testWidgets(
    'editor readiness reaches home even when unsaved text is discarded',
    (tester) async {
      final data = await open(tester);
      final router = data.fixture.container.read(routerProvider);
      router.push<void>('/edit/${data.pending.id}').ignore();
      await _flush(tester);
      await tester.enterText(
        find.byKey(const Key('character-name')),
        'Unsaved name',
      );
      data.api.status = 'success';
      await tester.pump(const Duration(seconds: 3));
      await _flush(tester);
      final saved = (await tester.runAsync(
        () => data.fixture.app.local.character(data.pending.id),
      ))!;
      expect(saved.assetStatus, 'success');
      expect(saved.name, 'Saved companion');
      await tester.binding.handlePopRoute();
      await _flush(tester);
      await tester.tap(find.byKey(const Key('edit-discard')));
      await _flush(tester);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect(find.text('形象已就绪'), findsOneWidget);
      expect(find.text('Saved companion'), findsOneWidget);
      expect(find.text('Unsaved name'), findsNothing);
    },
  );

  testWidgets(
    'route exit and app background stop GETs; home and resume recheck',
    (tester) async {
      final data = await open(tester);
      final router = data.fixture.container.read(routerProvider);
      router.push<void>('/settings').ignore();
      await _flush(tester);
      final queries = data.api.queries;
      await tester.pump(const Duration(seconds: 15));
      expect(data.api.queries, queries);
      router.pop();
      await _flush(tester);
      expect(data.api.queries, queries + 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _flush(tester);
      final beforeResume = data.api.queries;
      await tester.pump(const Duration(seconds: 15));
      expect(data.api.queries, beforeResume);
      data.api.status = 'success';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(data.api.queries, beforeResume + 1);
      expect(find.text('形象已就绪'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
      expect(data.api.queries, beforeResume + 1);
      expect(tester.takeException(), isNull);
    },
  );
}
