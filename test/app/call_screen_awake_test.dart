import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/domain/models.dart';

import '../application/call_coordinator_test.dart' as fake;
import '../support/fixture.dart';

class _Calls extends CallCoordinator {
  _Calls()
    : super(
        api: fake.FakeApi(),
        store: fake.FakeStore(),
        signalFactory: (_, _) => fake.FakeSignal(),
        rtcFactory: fake.FakeRtc.new,
        microphonePermission: () async => true,
      );

  final states = StreamController<CallSnapshot>.broadcast();
  String? endReason;
  @override
  Stream<CallSnapshot> get changes => states.stream;
  void phase(CallPhase value) {
    snapshot = CallSnapshot(phase: value);
    states.add(snapshot);
  }

  @override
  Future<void> end([String reason = 'user_end']) async {
    endReason = reason;
    phase(CallPhase.ended);
  }

  @override
  Future<void> dispose() => states.close();
}

void main() {
  late _Calls calls;
  late Fixture fixture;
  late List<bool> toggles;
  late Future<void> Function(bool) toggle;

  setUp(() async {
    calls = _Calls();
    toggles = [];
    toggle = (value) async => toggles.add(value);
    fixture = Fixture(
      callsOverride: calls,
      screenAwake: (value) => toggle(value),
    );
    await fixture.open();
  });
  tearDown(() => fixture.close());

  testWidgets('only preparation and connected phases keep the screen awake', (
    tester,
  ) async {
    await fixture.pump(tester);
    expect(toggles.last, isFalse);
    for (final phase in CallPhase.values) {
      calls.phase(phase);
      await tester.pumpAndSettle();
      expect(
        toggles.last,
        {
          CallPhase.creating,
          CallPhase.initializing,
          CallPhase.joining,
          CallPhase.connected,
        }.contains(phase),
        reason: phase.name,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'foreground idle call stays awake; background releases and ends',
    (tester) async {
      await fixture.pump(tester);
      calls.phase(CallPhase.connected);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 2));
      expect(toggles.last, isTrue);
      expect(calls.endReason, isNull);
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        toggles.last,
        isTrue,
      ); // Permission/notification overlays are transient.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(toggles.last, isFalse);
      expect(calls.endReason, 'app_background');
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(toggles.last, isFalse);
      calls.phase(CallPhase.connected);
      await tester.pumpAndSettle();
      final beforeResume = toggles.length;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(toggles.length, beforeResume + 1);
      expect(toggles.last, isTrue); // Reassert after a system overlay.
      await tester.pumpWidget(const SizedBox());
      expect(toggles.last, isFalse);
    },
  );

  testWidgets('a delayed enable cannot outlive hangup or app disposal', (
    tester,
  ) async {
    final pending = Completer<void>();
    final completed = <bool>[];
    toggle = (value) async {
      toggles.add(value);
      if (value) await pending.future;
      completed.add(value);
    };
    await fixture.pump(tester);
    calls.phase(CallPhase.joining);
    await tester.pump();
    calls.phase(CallPhase.ending);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(toggles, [false, true]);
    pending.complete();
    await tester.pump();
    expect(completed, [false, true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native failure is reported and a later resume can recover', (
    tester,
  ) async {
    var fail = true;
    toggle = (value) async {
      if (value && fail) throw StateError('Offline native failure');
      toggles.add(value);
    };
    await fixture.pump(tester);
    calls.phase(CallPhase.connected);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());
    fail = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(toggles.last, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(toggles.last, isFalse);
  });
}
