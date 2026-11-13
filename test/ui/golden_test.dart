import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/domain/models.dart';

import '../support/fixture.dart';
import '../support/fonts.dart';

import 'package:xiaoyu/app/app.dart';

void main() {
  setUpAll(loadGoldenFont);
  final pages = {
    'home': '/',
    'home_scrolled': '/',
    'home_menu': '/',
    'me': '/',
    'history': '/history',
    'editor': '/edit/fixture-character',
    'voices': '/',
    'connecting': '/call',
    'call': '/call',
    'call_composer': '/call',
    'call_food': '/call',
  };
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final page in pages.keys) {
      testWidgets('golden $platform $page', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(402, 874);
        tester.view.padding = const FakeViewPadding(top: 48, bottom: 24);
        addTearDown(() {
          tester.view.resetPadding();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          debugDefaultTargetPlatformOverride = null;
        });
        final fixture = Fixture(
          historyCount: page == 'me' || page == 'history' ? 4 : 1,
          phase: page == 'connecting'
              ? CallPhase.creating
              : page.startsWith('call')
              ? CallPhase.connected
              : CallPhase.idle,
        );
        await fixture.open();
        addTearDown(fixture.close);
        await fixture.pump(tester, route: pages[page]!);
        await tester.pumpAndSettle();
        if (page == 'home_scrolled') {
          await tester.drag(
            find.byType(ListView).hitTestable().first,
            const Offset(0, -180),
          );
          await tester.pumpAndSettle();
        }
        if (page == 'me') {
          await tester.tap(find.byKey(const Key('tab-1')).hitTestable());
          await tester.pumpAndSettle();
        }
        if (page == 'home_menu') {
          await tester.tap(
            find.byKey(const Key('character-menu')).hitTestable(),
          );
          await tester.pumpAndSettle();
        }
        if (page == 'voices') {
          fixture.container.read(routerProvider).go('/edit/fixture-character');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.ensureVisible(find.byKey(const Key('choose-voice')));
          await tester.tap(find.byKey(const Key('choose-voice')));
          await tester.pumpAndSettle();
        }
        if (page == 'call_composer' || page == 'call_food') {
          await tester.tap(find.byKey(const Key('open-call-composer')));
          await tester.pumpAndSettle();
          if (page == 'call_food') {
            await tester.ensureVisible(
              find.byKey(const Key('quick-category-food')),
            );
            await tester.tap(find.byKey(const Key('quick-category-food')));
            await tester.pumpAndSettle();
          }
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${platform.name}_$page.png'),
        );
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      });
    }
    for (final page in ['editor', 'call', 'call_composer', 'call_food']) {
      testWidgets('golden small large text $platform $page', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.view.resetPadding();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          debugDefaultTargetPlatformOverride = null;
        });
        final fixture = Fixture(
          phase: page.startsWith('call') ? CallPhase.connected : CallPhase.idle,
        );
        await fixture.open();
        addTearDown(fixture.close);
        await fixture.pump(
          tester,
          route: page == 'editor' ? '/edit/fixture-character' : '/call',
        );
        await tester.pumpAndSettle();
        if (page == 'call_composer' || page == 'call_food') {
          await tester.tap(find.byKey(const Key('open-call-composer')));
          await tester.pumpAndSettle();
          if (page == 'call_food') {
            await tester.ensureVisible(
              find.byKey(const Key('quick-category-food')),
            );
            await tester.tap(find.byKey(const Key('quick-category-food')));
            await tester.pumpAndSettle();
          }
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/${platform.name}_${page}_small.png'),
        );
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}
