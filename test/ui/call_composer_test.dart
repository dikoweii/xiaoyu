import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/presentation/quick_actions.dart';
import 'package:xiaoyu/l10n/generated/app_localizations.dart';
import 'package:xiaoyu/ui/call_history.dart';
import 'package:xiaoyu/ui/core/controls.dart';

import '../support/fixture.dart';
import '../application/call_coordinator_test.dart' as fake;

class _Signal extends fake.FakeSignal {
  final commands = <({int type, Json payload})>[];
  @override
  void send(int type, Json payload) {
    super.send(type, payload);
    commands.add((type: type, payload: payload));
  }
}

void main() {
  Future<({Fixture fixture, _Signal signal, fake.FakeStore store})> open(
    WidgetTester tester,
  ) async {
    final signal = _Signal(), store = fake.FakeStore();
    final calls = CallCoordinator(
      api: fake.FakeApi(),
      store: store,
      signalFactory: (_, _) => signal,
      rtcFactory: () => fake.FakeRtc(),
      microphonePermission: () async => true,
      queryDelays: [],
    );
    final fixture = Fixture(callsOverride: calls);
    await fixture.open();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await fixture.close();
    });
    await calls.start(fake.character, fake.credential, 'offline');
    await fixture.pump(tester, route: '/call');
    return (fixture: fixture, signal: signal, store: store);
  }

  Future<void> panel(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open-call-composer')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'call has no transcript or inline input; keyboard opens dismissible draft',
    (tester) async {
      await open(tester);
      expect(find.byKey(const Key('call-live-indicator')), findsOneWidget);
      expect(find.text('很高兴遇见你。'), findsNothing);
      expect(find.byKey(const Key('call-subtitles')), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await panel(tester);
      expect(find.text('快捷动作'), findsOneWidget);
      for (final label in ['比心', '挥手', '点头', '微笑']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(
        tester
            .widget<AppIconButton>(find.byKey(const Key('chat-send')))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('chat-input')), 'Draft');
      await tester.tap(find.byKey(const Key('close-call-composer')));
      await tester.pumpAndSettle();
      await panel(tester);
      expect(find.text('Draft'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'text shortcuts stay in one horizontal row and scroll on small screens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final data = await open(tester);
      await panel(tester);
      final strip = find.byKey(const Key('quick-actions-scroll'));
      expect(
        find.descendant(of: strip, matching: find.byType(Icon)),
        findsNothing,
      );
      final first = find.byKey(const Key('quick-action-heart'));
      final last = find.byKey(const Key('quick-action-smile'));
      expect(tester.getTopLeft(first).dy, tester.getTopLeft(last).dy);
      expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
      final scroll = find.descendant(
        of: strip,
        matching: find.byType(Scrollable),
      );
      final state = tester.state<ScrollableState>(scroll);
      expect(state.position.pixels, 0);
      await tester.drag(strip, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(state.position.pixels, greaterThan(0));
      await tester.scrollUntilVisible(last, 120, scrollable: scroll);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(data.signal.commands.last.type, 101);
      expect(tester.takeException(), isNull);
    },
  );

  for (final category in QuickActionCategory.values.skip(1)) {
    testWidgets(
      '${category.name} category scrolls to final action and sends full prompt',
      (tester) async {
        final data = await open(tester);
        await panel(tester);
        await tester.enterText(
          find.byKey(const Key('chat-input')),
          'Keep category draft',
        );
        final categories = find.byKey(const Key('quick-action-categories'));
        final tab = find.byKey(Key('quick-category-${category.name}'));
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
        final strip = find.byKey(const Key('quick-actions-scroll'));
        final scroll = find.descendant(
          of: strip,
          matching: find.byType(Scrollable),
        );
        expect(tester.state<ScrollableState>(scroll).position.pixels, 0);
        final first = find.byKey(
          Key('quick-action-${category.actions.first.name}'),
        );
        expect(first.hitTestable(), findsOneWidget);
        final action = category.actions.last;
        final last = find.byKey(Key('quick-action-${action.name}'));
        await tester.scrollUntilVisible(
          last,
          220,
          scrollable: scroll,
          maxScrolls: 80,
        );
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
        expect(
          tester.getTopLeft(last).dy,
          tester.getBottomLeft(categories).dy + 8,
        );
        final s = AppLocalizations.of(tester.element(last));
        final prompt = s.quickActionPrompt(action.name);
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(data.signal.commands.last.type, 101);
        expect(
          jsonObject(
            data.signal.commands.last.payload['text_action'],
          )['content'],
          prompt,
        );
        expect(data.store.texts, isEmpty);
        expect(find.text('Keep category draft'), findsOneWidget);
        final common = find.byKey(const Key('quick-category-common'));
        await tester.ensureVisible(common);
        await tester.tap(common);
        await tester.pumpAndSettle();
        expect(tester.state<ScrollableState>(scroll).position.pixels, 0);
        expect(
          find.byKey(const Key('quick-action-heart')).hitTestable(),
          findsOneWidget,
        );
        expect(find.byKey(const Key('quick-action-watermelon')), findsNothing);
        await tester.tap(find.byKey(const Key('close-call-composer')));
        await tester.pumpAndSettle();
        await panel(tester);
        expect(
          find.byKey(const Key('quick-action-heart')).hitTestable(),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'chat sends 102 and persists; shortcuts send only 101 with cooldown',
    (tester) async {
      final data = await open(tester);
      await panel(tester);
      await tester.enterText(find.byKey(const Key('chat-input')), 'Hello');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(data.signal.commands.last.type, 102);
      expect(
        jsonObject(data.signal.commands.last.payload['text_dialog'])['content'],
        'Hello',
      );
      expect(data.store.texts.values.single['text'], 'Hello');
      expect(find.byKey(const Key('call-composer-error')), findsNothing);
      expect(find.text('Hello'), findsNothing);
      await tester.enterText(find.byKey(const Key('chat-input')), 'Keep draft');
      await tester.tap(find.byKey(const Key('quick-action-heart')));
      await tester.pumpAndSettle();
      expect(data.signal.commands.last.type, 101);
      expect(find.byKey(const Key('call-composer-error')), findsNothing);
      expect(
        jsonObject(data.signal.commands.last.payload['text_action'])['content'],
        contains('爱心'),
      );
      expect(data.store.texts.length, 1);
      expect(find.text('Keep draft'), findsOneWidget);
      final count = data.signal.commands.length;
      await tester.tap(find.byKey(const Key('quick-action-wave')));
      await tester.pumpAndSettle();
      expect(
        data.signal.commands.length,
        count,
        reason: 'Existing action cooldown still applies',
      );
      expect(find.byKey(const Key('call-composer-error')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final action in ['wave', 'nod', 'smile']) {
    testWidgets('$action shortcut sends distinct natural language action', (
      tester,
    ) async {
      final data = await open(tester);
      await panel(tester);
      await tester.ensureVisible(find.byKey(Key('quick-action-$action')));
      await tester.tap(find.byKey(Key('quick-action-$action')));
      await tester.pumpAndSettle();
      final prompt =
          jsonObject(
                data.signal.commands.last.payload['text_action'],
              )['content']
              as String;
      expect(data.signal.commands.last.type, 101);
      expect(
        prompt,
        contains(switch (action) {
          'wave' => '掌心朝向镜头',
          'nod' => '点头',
          _ => '微笑',
        }),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'failed text retains draft; ending closes sheet without popping call page',
    (tester) async {
      final data = await open(tester);
      await panel(tester);
      data.signal.failSend = true;
      await tester.enterText(
        find.byKey(const Key('chat-input')),
        'Keep on failure',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('chat-send')));
      await tester.pumpAndSettle();
      expect(find.text('Keep on failure'), findsOneWidget);
      expect(data.store.texts.values.single['delivery'], 'unknown');
      expect(find.byKey(const Key('call-composer-error')), findsOneWidget);
      await tester.runAsync(() => data.fixture.app.calls.end('remote'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('call-composer')), findsNothing);
      expect(find.byType(CallScreen), findsOneWidget);
      expect(find.byKey(const Key('call-live-indicator')), findsNothing);
      expect(
        tester
            .widget<AppIconButton>(find.byKey(const Key('open-call-composer')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final reduced in [false, true]) {
    testWidgets('live dot breathes unless reduced motion=$reduced', (
      tester,
    ) async {
      final fixture = Fixture(phase: CallPhase.connected);
      await fixture.open();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await fixture.close();
      });
      await tester.pumpWidget(
        fixture.widget(
          page: ProviderScope(
            overrides: [presenceAnimationProvider.overrideWithValue(true)],
            child: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: const CallScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      double opacity() => tester
          .widget<FadeTransition>(find.byKey(const Key('call-live-indicator')))
          .opacity
          .value;
      final first = opacity();
      await tester.pump(const Duration(milliseconds: 700));
      expect(opacity(), reduced ? first : isNot(first));
      await tester.pumpWidget(const SizedBox());
    });
  }
}
