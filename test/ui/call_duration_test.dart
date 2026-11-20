import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/presentation/controllers.dart';
import 'package:xiaoyu/ui/call_history.dart';
import 'package:xiaoyu/ui/integrations/rtc_video_surface.dart';

import '../application/call_coordinator_test.dart' as fake;
import '../support/fixture.dart';

class _ClockCalls extends CallCoordinator {
  _ClockCalls()
    : super(
        api: fake.FakeApi(),
        store: fake.FakeStore(),
        signalFactory: (_, _) => fake.FakeSignal(),
        rtcFactory: () => fake.FakeRtc(),
        microphonePermission: () async => true,
      );

  Duration time = Duration.zero;
  int reads = 0;

  @override
  Duration get elapsed {
    reads++;
    return time;
  }
}

void main() {
  Future<
    ({
      Fixture fixture,
      _ClockCalls calls,
      StreamController<CallSnapshot> states,
    })
  >
  open(WidgetTester tester, {CallPhase phase = CallPhase.connected}) async {
    final calls = _ClockCalls();
    final fixture = Fixture(phase: phase, callsOverride: calls);
    await fixture.open();
    calls.snapshot = calls.snapshot.copyWith(
      video: const RemoteVideo('offline-room', 7),
    );
    final states = StreamController<CallSnapshot>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await states.close();
      await fixture.close();
    });
    await tester.pumpWidget(
      fixture.widget(
        page: ProviderScope(
          overrides: [callProvider.overrideWith((ref) => states.stream)],
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: CallScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    return (fixture: fixture, calls: calls, states: states);
  }

  String duration(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('call-duration'))).data!;

  Future<Map<String, int>> countBuilds(Future<void> Function() action) async {
    final counts = <String, int>{};
    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, _) {
      final name = element.widget.runtimeType.toString();
      counts.update(name, (n) => n + 1, ifAbsent: () => 1);
    };
    try {
      await action();
    } finally {
      debugOnRebuildDirtyWidget = previous;
    }
    return counts;
  }

  testWidgets(
    'seconds refresh only the time label, including minute rollover',
    (tester) async {
      final data = await open(tester);
      final video = tester.state(find.byType(RtcVideoSurface));
      expect(duration(tester), '0:00');
      final counts = await countBuilds(() async {
        for (final seconds in [59, 60, 125]) {
          data.calls.time = Duration(seconds: seconds);
          await tester.pump(const Duration(seconds: 1));
          expect(duration(tester), switch (seconds) {
            59 => '0:59',
            60 => '1:00',
            _ => '2:05',
          });
        }
      });
      expect(counts['Text'], 3);
      for (final name in [
        'CallScreen',
        'AppPage',
        '_CallBackdrop',
        'RtcVideoSurface',
        'AppIconButton',
        'LiquidGlassLens',
      ]) {
        expect(counts[name] ?? 0, 0, reason: '$name must not rebuild for time');
      }
      expect(tester.state(find.byType(RtcVideoSurface)), same(video));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unchanged whole seconds do not rebuild the label', (
    tester,
  ) async {
    await open(tester);
    final counts = await countBuilds(() async {
      await tester.pump(const Duration(seconds: 3));
    });
    expect(counts, isEmpty);
    expect(duration(tester), '0:00');
  });

  testWidgets('ending stops reads and preserves the final elapsed time', (
    tester,
  ) async {
    final data = await open(tester);
    data.calls.time = const Duration(seconds: 7);
    data.calls.snapshot = data.calls.snapshot.copyWith(phase: CallPhase.ending);
    data.states.add(data.calls.snapshot);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(duration(tester), '0:07');
    final reads = data.calls.reads;
    data.calls.time = const Duration(seconds: 20);
    final counts = await countBuilds(() async {
      await tester.pump(const Duration(seconds: 3));
    });
    expect(data.calls.reads, reads);
    expect(counts, isEmpty);
    expect(duration(tester), '0:07');
  });

  testWidgets('connecting has no clock polling and unmount cancels the timer', (
    tester,
  ) async {
    final data = await open(tester, phase: CallPhase.creating);
    expect(find.byKey(const Key('call-duration')), findsNothing);
    final before = data.calls.reads;
    await tester.pump(const Duration(seconds: 3));
    expect(data.calls.reads, before);
    data.calls.snapshot = data.calls.snapshot.copyWith(
      phase: CallPhase.connected,
      controlReady: true,
    );
    data.states.add(data.calls.snapshot);
    await tester.pump();
    await tester.pump();
    data.calls.time = const Duration(seconds: 3);
    await tester.pump(const Duration(seconds: 1));
    expect(duration(tester), '0:03');
    await tester.pumpWidget(const SizedBox());
    final reads = data.calls.reads;
    await tester.pump(const Duration(seconds: 3));
    expect(data.calls.reads, reads);
    expect(tester.takeException(), isNull);
  });
}
