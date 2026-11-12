import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/ui/core/widgets.dart';
import 'package:xiaoyu/ui/screens.dart' show HomePanel, MePanel;
import 'package:flutter/foundation.dart';

import '../support/fixture.dart';
import 'layout_matrix_test.dart' show operation;
import '../application/call_coordinator_test.dart' as fake;

import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/domain/models.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('tab content scrolls to both screen edges on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        tester.view.resetPadding();
        debugDefaultTargetPlatformOverride = null;
      });
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(tester);
      await tester.pumpAndSettle();
      final homeList = find.descendant(
        of: find.byType(HomePanel),
        matching: find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.vertical,
        ),
      );
      const screen = Rect.fromLTWH(0, 0, 402, 874);
      expect(tester.getRect(homeList), screen);
      expect(tester.getRect(find.byType(Scaffold)), screen);
      final brand = find.text(tester.element(homeList).s.brandLine);
      expect(tester.getTopLeft(brand).dy, greaterThanOrEqualTo(59));
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: homeList, matching: find.byType(Scrollable)).first,
      );
      scroll.position.jumpTo(70);
      await tester.pump();
      expect(tester.getTopLeft(brand).dy, lessThan(59));
      expect(tester.getRect(homeList), screen);
      await tester.tap(find.byKey(const Key('tab-1')).hitTestable());
      await tester.pumpAndSettle();
      final meList = find.descendant(
        of: find.byType(MePanel),
        matching: find.byType(ListView),
      );
      expect(tester.getRect(meList), screen);
      final settings = find.byWidgetPredicate(
        (w) => w is AppIconButton && w.label == '设置',
      );
      expect(tester.getTopLeft(settings).dy, greaterThanOrEqualTo(59));
      expect(find.byKey(const Key('tab-0')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('tab-1')).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('Me exposes account settings only through Settings', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const Key('tab-1')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('账号设置'), findsNothing);
    await tester.tap(
      find.byWidgetPredicate((w) => w is AppIconButton && w.label == '设置'),
    );
    await tester.pumpAndSettle();
    expect(find.text('账号设置'), findsOneWidget);
    expect(find.text('语言'), findsNothing);
    expect(find.text('English'), findsNothing);
    await tester.tap(find.text('账号设置'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-save')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('role menu only edits or deletes; cancel keeps the role', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const Key('character-menu')));
    await tester.pumpAndSettle();
    final panel = find.byKey(const Key('character-menu-panel'));
    expect(panel, findsOneWidget);
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(
      tester
          .widgetList<TextButton>(
            find.descendant(of: panel, matching: find.byType(TextButton)),
          )
          .map((item) => item.key),
      [const Key('menu-edit'), const Key('menu-delete')],
    );
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    Future<void> openDelete() async {
      await tester.tap(find.byKey(const Key('character-menu')).hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').hitTestable());
      await tester.pumpAndSettle();
    }

    await openDelete();
    await tester.tap(operation(tester, 'confirm-cancel'));
    await tester.pumpAndSettle();
    expect(await fixture.app.local.character(companion.id), isNotNull);
    await openDelete();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(await fixture.app.local.character(companion.id), isNull);
    expect(find.byKey(Key('character-image-${companion.id}')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final ready in [false, true]) {
    testWidgets(
      'home chat routes to ${ready ? 'account' : 'editor'} when setup is missing',
      (tester) async {
        final fixture = Fixture();
        await fixture.open();
        addTearDown(fixture.close);
        if (!ready) {
          await fixture.app.credentials.save(
            'offline-only',
            remember: false,
            sameAccount: false,
          );
          await fixture.app.local.saveCharacter(
            companion.copyWith(assetStatus: 'draft'),
          );
        }
        await fixture.pump(tester);
        await tester.tap(find.byKey(Key('character-image-${companion.id}')));
        await tester.pumpAndSettle();
        expect(
          fixture.container
              .read(routerProvider)
              .routerDelegate
              .currentConfiguration
              .last
              .matchedLocation,
          ready ? '/account' : '/edit/${companion.id}',
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('home chat confirms once, starts directly and hangs up to home', (
    tester,
  ) async {
    final api = fake.FakeApi();
    final call = CallCoordinator(
      api: api,
      store: fake.FakeStore(),
      signalFactory: (_, _) => fake.FakeSignal(),
      rtcFactory: () => fake.FakeRtc(),
      microphonePermission: () async => true,
      queryDelays: [],
    );
    final fixture = Fixture(callsOverride: call);
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.app.credentials.save(
      'offline-only',
      remember: false,
      sameAccount: false,
    );
    await fixture.app.local.saveCharacter(
      companion.copyWith(credentialId: fixture.app.credentials.currentId),
    );
    await fixture.pump(tester);
    await tester.tap(find.byKey(Key('character-image-${companion.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassAlertDialog), findsOneWidget);
    expect(api.creates, 0);
    await tester.tap(operation(tester, 'confirm-cancel'));
    await tester.pumpAndSettle();
    expect(api.creates, 0);
    await tester.tap(find.byKey(Key('character-image-${companion.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(api.creates, 1);
    expect(call.snapshot.phase, CallPhase.connected);
    expect(
      fixture.container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/call',
    );
    await tester.tap(find.byKey(const Key('end-call')));
    await tester.pumpAndSettle();
    expect(
      fixture.container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/',
    );
    expect(find.byKey(Key('character-image-${companion.id}')), findsOneWidget);
    for (var i = 0; i < 20 && call.snapshot.active; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(call.snapshot.phase, CallPhase.ended);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('role pull-down menu opens the existing editor', (tester) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const Key('character-menu')).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑').hitTestable());
    await tester.pumpAndSettle();
    expect(
      fixture.container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/edit/fixture-character',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('native tab navigation and back preserve the selected tab', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const Key('tab-1')).hitTestable());
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LiquidGlassTabBar>(find.byType(LiquidGlassTabBar))
          .selectedIndex,
      1,
    );
    unawaited(fixture.container.read(routerProvider).push('/settings'));
    await tester.pumpAndSettle();
    final back = find.byKey(const Key('page-back')).hitTestable();
    expect(back, findsOneWidget);
    expect(tester.getSize(back), const Size(48, 48));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LiquidGlassTabBar>(find.byType(LiquidGlassTabBar))
          .selectedIndex,
      1,
    );
    expect(find.text('本地个人资料'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('library dialog returns cancellation and confirmation', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    bool? result;
    await fixture.pump(
      tester,
      page: AppPage(
        body: Builder(
          builder: (context) => AppButton(
            key: const Key('open'),
            onPressed: () async {
              result = await confirm(
                context,
                '删除',
                '删除此记录？',
                destructive: true,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    final accept = tester.widget<TextButton>(
      find.byKey(const Key('confirm-accept')),
    );
    expect(accept.style!.foregroundColor!.resolve({}), Colors.redAccent);
    await tester.tap(operation(tester, 'confirm-cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(LiquidGlassAlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
