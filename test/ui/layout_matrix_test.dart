import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/ui/screens.dart';
import 'package:xiaoyu/ui/core/widgets.dart';

import '../support/fixture.dart';
import '../support/fonts.dart';

const routes = {
  'home': '/',
  'account': '/account',
  'editor': '/edit/fixture-character',
  'settings': '/settings',
  'history': '/history',
  'history_detail': '/history/offline-history',
  'connecting': '/call',
  'call': '/call',
  'call_muted': '/call',
  'call_composer': '/call',
  'call_food': '/call',
  'pending': '/call',
};
const operations = {
  'account': 'account-save',
  'editor': 'editor-save',
  'connecting': 'end-call',
  'call': 'end-call',
  'voices': 'voice-select-Serena',
  'call_muted': 'toggle-playback',
  'call_composer': 'close-call-composer',
  'call_food': 'close-call-composer',
  'confirm': 'confirm-cancel',
};
Widget? panel(String page) => switch (page) {
  'me' => const AppPage(body: MePanel()),
  'voices' => const AppPage(
    body: SingleChildScrollView(child: VoicePicker(selected: 'Serena')),
  ),
  'assets' => const AppPage(
    body: SingleChildScrollView(
      child: AssetPicker(
        assets: [
          {'name': 'Offline portrait', 'id': 'asset', 'status': 'success'},
        ],
      ),
    ),
  ),
  'confirm' => Builder(
    builder: (context) => AppPage(
      body: ConfirmationPanel(
        title: context.s.callCostTitle,
        body: context.s.callCostBody,
      ),
    ),
  ),
  _ => null,
};

Finder operation(WidgetTester tester, String key) {
  final target = find.byKey(Key(key));
  if (target.evaluate().isNotEmpty && tester.widget(target) is AppButton) {
    return find.descendant(of: target, matching: find.byType(Semantics)).first;
  }
  return target;
}

Future<void> assertReachable(WidgetTester tester, String key, Size size) async {
  final finder = operation(tester, key);
  if (finder.evaluate().isEmpty || finder.hitTestable().evaluate().isEmpty) {
    final scroll = find.byType(Scrollable).hitTestable().first;
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: scroll,
      maxScrolls: 80,
    );
  }
  // Top alignment can put a control behind pinned navigation. Centre it in
  // the viewport and verify it clears the toolbar as well as the keyboard.
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  expect(
    finder.hitTestable(),
    findsOneWidget,
    reason: '$key must remain reachable',
  );
  final semantics = tester.ensureSemantics();
  await tester.pump();
  try {
    final data = tester.getSemantics(finder).getSemanticsData();
    expect('${data.label}${data.tooltip}'.trim(), isNotEmpty);
  } finally {
    semantics.dispose();
  }
  final rect = tester.getRect(finder);
  final toolbar = find.byType(NavigationToolbar).hitTestable();
  if (toolbar.evaluate().isNotEmpty) {
    expect(rect.top, greaterThanOrEqualTo(tester.getBottomLeft(toolbar).dy));
  }
  expect(rect.top, greaterThanOrEqualTo(-.1));
  expect(
    rect.bottom,
    lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom + .1),
  );
  expect(rect.left, greaterThanOrEqualTo(-.1));
  expect(rect.right, lessThanOrEqualTo(size.width + .1));
  // Coordinate subtraction may produce 47.99999999999994 for a 48 pt target.
  expect(rect.height, greaterThanOrEqualTo(48 - precisionErrorTolerance));
  expect(rect.width, greaterThanOrEqualTo(48 - precisionErrorTolerance));
}

void main() {
  setUpAll(loadGoldenFont);
  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() {
    WidgetController.hitTestWarningShouldBeFatal = false;
  });
  final config = jsonDecode(
    jsonEncode(loadYaml(File('harness.yaml').readAsStringSync())),
  ) as Map;
  final matrix = config['matrix'] as Map;
  for (final raw in matrix['sizes'] as List) {
    for (final orientation in matrix['orientations'] as List) {
      final dims = (raw as List).cast<num>();
      final size = orientation == 'portrait'
          ? Size(dims[0].toDouble(), dims[1].toDouble())
          : Size(dims[1].toDouble(), dims[0].toDouble());
      for (final platform in matrix['platforms'] as List) {
        for (final locale in matrix['locales'] as List) {
          for (final scale in matrix['scales'] as List) {
            for (final page in matrix['pages'] as List) {
              testWidgets('$page $size $platform $locale scale=$scale', (
                tester,
              ) async {
                debugDefaultTargetPlatformOverride = platform == 'ios'
                    ? TargetPlatform.iOS
                    : TargetPlatform.android;
                tester.view.devicePixelRatio = 1;
                tester.view.physicalSize = size;
                tester.platformDispatcher.textScaleFactorTestValue =
                    (scale as num).toDouble();
                tester.view.padding = const FakeViewPadding(
                  top: 24,
                  bottom: 24,
                );
                addTearDown(() {
                  tester.view.resetPhysicalSize();
                  tester.view.resetDevicePixelRatio();
                  tester.view.resetPadding();
                  tester.platformDispatcher.clearTextScaleFactorTestValue();
                  debugDefaultTargetPlatformOverride = null;
                });
                final fixture = Fixture(
                  locale: locale as String,
                  longContent: true,
                  phase: page == 'connecting'
                      ? CallPhase.creating
                      : (page == 'call' ||
                            page == 'call_muted' ||
                            page == 'call_composer' ||
                            page == 'call_food')
                      ? CallPhase.connected
                      : page == 'pending'
                      ? CallPhase.pending
                      : CallPhase.idle,
                );
                await fixture.open();
                if (page == 'call_muted') {
                  fixture.app.calls.snapshot = fixture.app.calls.snapshot
                      .copyWith(playbackMuted: true);
                }
                addTearDown(fixture.close);
                await fixture.pump(
                  tester,
                  route: routes[page] ?? '/',
                  page: panel(page as String),
                );
                if (page == 'call_composer' || page == 'call_food') {
                  await tester.tap(find.byKey(const Key('open-call-composer')));
                  await tester.pumpAndSettle();
                  if (page == 'call_food') {
                    await tester.ensureVisible(
                      find.byKey(const Key('quick-category-food')),
                    );
                    await tester.tap(
                      find.byKey(const Key('quick-category-food')),
                    );
                    await tester.pumpAndSettle();
                  }
                }
                expect(tester.takeException(), isNull);
                if (operations[page] case final key?) {
                  await assertReachable(tester, key, size);
                }
                expect(tester.takeException(), isNull);
                await tester.pumpWidget(const SizedBox());
                debugDefaultTargetPlatformOverride = null;
              });
            }
          }
        }
      }
    }
  }
  for (final state in matrix['states'] as List) {
    testWidgets('home renders $state without live services', (tester) async {
      final fixture = Fixture(
        state: state as String,
        empty: state == 'empty',
        longContent: state == 'long_content',
      );
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    });
  }
  for (final page in matrix['keyboard'] as List) {
    for (final landscape in [false]) {
      testWidgets(
        'keyboard keeps $page actions reachable landscape=$landscape',
        (tester) async {
          final size = landscape ? const Size(568, 320) : const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.viewInsets = FakeViewPadding(
            bottom: landscape ? 140 : 240,
          );
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            tester.view.resetViewInsets();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final fixture = Fixture(
            locale: 'en',
            phase: page == 'call' ? CallPhase.connected : CallPhase.idle,
          );
          await fixture.open();
          addTearDown(fixture.close);
          await fixture.pump(tester, route: routes[page]!);
          final key = page == 'call' ? 'end-call' : operations[page]!;
          await assertReachable(tester, key, size);
          if (page == 'call') {
            await tester.tap(find.byKey(const Key('open-call-composer')));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const Key('chat-input')),
              'Hello',
            );
            await assertReachable(tester, 'chat-send', size);
            await assertReachable(tester, 'close-call-composer', size);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }
}
