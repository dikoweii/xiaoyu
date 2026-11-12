import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/presentation/controllers.dart';
import 'package:xiaoyu/ui/call_history.dart';
import 'package:xiaoyu/ui/integrations/rtc_video_surface.dart';
import 'package:xiaoyu/app/app.dart';
import 'package:xiaoyu/ui/core/design.dart';
import 'package:xiaoyu/ui/core/controls.dart';

import '../support/fixture.dart';
import '../application/call_coordinator_test.dart' as fake;

Future<void> reach(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: find.byType(Scrollable).hitTestable().first,
    maxScrolls: 50,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final source in ['/', '/settings', 'root']) {
    testWidgets('end returns to $source while native release is pending', (
      tester,
    ) async {
      final rtc = fake.FakeRtc()..releaseGate = Completer<void>();
      final api = fake.FakeApi()..queryFails = true;
      final signal = fake.FakeSignal();
      final call = CallCoordinator(
        api: api,
        store: fake.FakeStore(),
        signalFactory: (_, _) => signal,
        rtcFactory: () => rtc,
        microphonePermission: () async => true,
        queryDelays: [],
      );
      final fixture = Fixture(callsOverride: call);
      await fixture.open();
      addTearDown(() async {
        if (!rtc.releaseGate!.isCompleted) rtc.releaseGate!.complete();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await fixture.close();
      });
      await call.start(fake.character, fake.credential, 'offline');
      await fixture.pump(tester, route: source == 'root' ? '/' : source);
      final router = fixture.container.read(routerProvider);
      if (source == 'root') {
        router.go('/call');
      } else {
        unawaited(router.push('/call'));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('end-call')));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        source == 'root' ? '/' : source,
      );
      expect(find.byType(CallScreen), findsNothing);
      expect(call.snapshot.phase, CallPhase.ending);
      rtc.releaseGate!.complete();
      for (var i = 0; i < 20 && call.snapshot.active; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(
        call.snapshot.phase,
        CallPhase.pending,
        reason: 'Returning does not claim billing was confirmed',
      );
      expect(signal.sent.where((type) => type == 5), hasLength(1));
      expect(api.creates, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'cancel returns while a late creation still belongs to the coordinator',
    (tester) async {
      final api = fake.FakeApi()..pending = Completer<Json>();
      final signal = fake.FakeSignal();
      final rtc = fake.FakeRtc();
      final call = CallCoordinator(
        api: api,
        store: fake.FakeStore(),
        signalFactory: (_, _) => signal,
        rtcFactory: () => rtc,
        microphonePermission: () async => true,
        queryDelays: [],
      );
      final fixture = Fixture(callsOverride: call);
      await fixture.open();
      addTearDown(() async {
        if (!api.pending!.isCompleted) api.pending!.complete(fake.created);
        await fixture.close();
      });
      await fixture.pump(tester);
      final starting = call.start(fake.character, fake.credential, 'offline');
      unawaited(fixture.container.read(routerProvider).push('/call'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('call-loading')), findsOneWidget);
      await tester.tap(find.byKey(const Key('end-call')));
      await tester.pumpAndSettle();
      expect(find.byType(CallScreen), findsNothing);
      expect(call.snapshot.phase, CallPhase.ending);
      api.pending!.complete(fake.created);
      for (var i = 0; i < 20 && call.snapshot.active; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await starting;
      expect(call.snapshot.phase, CallPhase.ended);
      expect(rtc.joins, 0);
      expect(signal.sent, [5]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'mounts video while connecting and preserves it when loading closes',
    (tester) async {
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      final states = StreamController<CallSnapshot>();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await states.close();
      });
      await tester.pumpWidget(
        fixture.widget(
          page: ProviderScope(
            overrides: [callProvider.overrideWith((ref) => states.stream)],
            child: const CallScreen(),
          ),
        ),
      );
      const joining = CallSnapshot(
        phase: CallPhase.joining,
        character: companion,
        controlReady: true,
        joined: true,
        published: true,
        audioReady: true,
        video: RemoteVideo('offline-room', 7),
      );
      states.add(joining);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('call-loading')), findsOneWidget);
      expect(find.byKey(const Key('chat-input')), findsNothing);
      expect(
        find.byType(RtcVideoSurface),
        findsOneWidget,
        reason: 'First-frame callbacks require the remote video view before loading can finish',
      );
      final surface = tester.state(find.byType(RtcVideoSurface));
      states.add(
        joining.copyWith(phase: CallPhase.connected, firstFrame: true),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('call-loading')), findsNothing);
      expect(find.byKey(const Key('chat-input')), findsOneWidget);
      expect(
        tester.state(find.byType(RtcVideoSurface)),
        same(surface),
        reason: 'Closing loading must retain the live native video controller',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'advanced fields and real voice choice survive draft save/reopen',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = Fixture();
      await fixture.open();
      addTearDown(fixture.close);
      await fixture.pump(tester);
      unawaited(
        fixture.container.read(routerProvider).push('/edit/fixture-character'),
      );
      await tester.pumpAndSettle();
      await reach(tester, 'advanced-settings');
      await tester.tap(find.byKey(const Key('advanced-settings')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('summary-input')),
          matching: find.byType(EditableText),
        ),
        'Saved summary',
      );
      await reach(tester, 'advanced-close');
      await tester.tap(find.byKey(const Key('advanced-close')));
      await tester.pumpAndSettle();
      await reach(tester, 'choose-voice');
      await tester.tap(find.byKey(const Key('choose-voice')));
      await tester.pumpAndSettle();
      final cherry = find.ancestor(
        of: find.text('Cherry'),
        matching: find.byType(AppSurface),
      );
      final choose = find.descendant(
        of: cherry,
        matching: find.byType(AppButton),
      );
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pumpAndSettle();
      await reach(tester, 'advanced-settings');
      await tester.tap(find.byKey(const Key('advanced-settings')));
      await tester.pumpAndSettle();
      await reach(tester, 'draft-save');
      await tester.tap(find.byKey(const Key('draft-save')));
      await tester.pumpAndSettle();
      final saved = await fixture.app.local.character('fixture-character');
      expect(saved!.summary, 'Saved summary');
      expect(saved.voice, 'Cherry');
      unawaited(
        fixture.container.read(routerProvider).push('/edit/fixture-character'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cherry'), findsOneWidget);
      await reach(tester, 'advanced-settings');
      await tester.tap(find.byKey(const Key('advanced-settings')));
      await tester.pumpAndSettle();
      expect(find.text('Saved summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('header add opens creation; tabs keep selected state', (
    tester,
  ) async {
    final fixture = Fixture();
    await fixture.open();
    addTearDown(fixture.close);
    await fixture.pump(tester);
    await tester.tap(find.byKey(const Key('tab-1')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('本地个人资料'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-0')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.search), findsNothing);
    await tester.tap(find.byKey(const Key('create-character')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('character-name')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
