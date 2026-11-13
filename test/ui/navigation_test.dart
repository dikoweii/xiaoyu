import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';

import '../support/fixture.dart';

void main() {
  testWidgets('Android keeps the SDK page transition and system back', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester, route: '/settings');
    await tester.pumpAndSettle();
    final route = ModalRoute.of(
      tester.element(find.byKey(const Key('page-back'))),
    )!;
    expect(route.settings, isA<MaterialPage<void>>());
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(fixture.container.read(routerProvider).state.uri.path, '/');
    expect(find.byKey(const Key('tab-0')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('tab-1')).hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });

  for (final path in [
    '/settings',
    '/account',
    '/edit/fixture-character',
    '/history',
    '/history/offline-history',
  ]) {
    testWidgets('iOS edge swipe returns from $path to its previous page', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(tester, route: '/settings');
      await tester.pumpAndSettle();
      final router = fixture.container.read(routerProvider);
      if (path != '/settings') {
        unawaited(router.push(path));
        await tester.pumpAndSettle();
      }
      final back = find.byKey(const Key('page-back')).hitTestable();
      final route = ModalRoute.of(tester.element(back))!;
      expect(route.popGestureEnabled, isTrue);
      await tester.dragFrom(
        Offset(
          1,
          (tester.view.physicalSize / tester.view.devicePixelRatio).height / 2,
        ),
        Offset(
          (tester.view.physicalSize / tester.view.devicePixelRatio).width * .8,
          0,
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, path == '/settings' ? '/' : '/settings');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('cancelled iOS edge gesture keeps the current route', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester, route: '/settings');
    await tester.pumpAndSettle();
    final back = find.byKey(const Key('page-back'));
    final before = tester.getTopLeft(back);
    final gesture = await tester.startGesture(const Offset(1, 250));
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(back).dx, greaterThan(before.dx));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(fixture.container.read(routerProvider).state.uri.path, '/settings');
    expect(tester.getTopLeft(back), before);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('dirty editor protects changes during swipe and back', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester, route: '/edit/fixture-character');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '尚未保存的名字');
    await tester.pump();
    final back = find.byKey(const Key('page-back'));
    expect(ModalRoute.of(tester.element(back))!.popGestureEnabled, isFalse);
    await tester.dragFrom(const Offset(1, 250), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('尚未保存的名字'), findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('尚未保存的名字'), findsOneWidget);
    await tester.tap(back);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-accept')));
    await tester.pumpAndSettle();
    expect(fixture.container.read(routerProvider).state.uri.path, '/');
    expect((await fixture.app.local.character(companion.id))!.name, '尚未保存的名字');
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
