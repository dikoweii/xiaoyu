import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/application/call_coordinator.dart';
import 'package:xiaoyu/domain/call_ports.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/domain/voice_catalog.dart';

const character = Character(
  id: 'character-one',
  credentialId: 'account-one',
  name: 'Test',
  persona: 'Test persona',
  avatarId: 'asset-one',
  assetStatus: 'success',
);
const credential = Credential('account-one', 'test-only-key');
final created = <String, dynamic>{
  'live': {'id': 'live-one'},
  'rtc': {'provider': 'agora'},
};

class FakeApi implements LiveApi {
  int creates = 0;
  Json? lastBody;
  Completer<Json>? pending;
  bool queryFails = false;
  String status = 'ended';
  @override
  Future<Json> createLive(Credential c, Json body) async {
    creates++;
    lastBody = body;
    return pending == null ? created : pending!.future;
  }

  @override
  Future<Json> getLive(Credential c, String id) async {
    if (queryFails) throw const AppFailure('forbidden');
    return {
      'live': {'status': status, 'billed_seconds': 3, 'credits_cost': '5'},
    };
  }
}

class FakeStore implements CallPersistence {
  final rows = <String, Json>{};
  final texts = <String, Json>{};
  bool unresolved = false;
  @override
  Future<void> begin(String id, Character c, Credential key) async {
    rows[id] = {'phase': 'creating'};
  }

  @override
  Future<bool> hasUnresolved() async => unresolved;
  @override
  Future<void> update(String id, Json fields) async {
    rows[id]!.addAll(fields);
  }

  @override
  Future<void> message(
    String callId,
    String id,
    String speaker,
    String text,
    String delivery,
  ) async {
    texts[id] = {'callId': callId, 'text': text, 'delivery': delivery};
  }
}

class FakeSignal implements Signaling {
  final controller = StreamController<Json>.broadcast(sync: true);
  final sent = <int>[];
  int notReady = 0;
  bool closed = false, failSend = false, voiceSuccess = true;
  @override
  Stream<Json> get events => controller.stream;
  @override
  Future<void> connect() async {}
  @override
  void send(int type, Json payload) {
    if (failSend && type == 102) throw const AppFailure('network');
    sent.add(type);
    if (type == 1) {
      controller.add({
        'type': 2,
        'payload': {
          'conn_init_ack': {
            'success': notReady-- <= 0,
            'error_code': 'NOT_READY',
          },
        },
      });
    }
    if (type == 97) {
      controller.add({
        'type': 98,
        'payload': {
          'session_update_ack': {'success': voiceSuccess},
        },
      });
    }
  }

  @override
  Future<void> close() async {
    closed = true;
    await controller.close();
  }
}

class FakeRtc implements RtcSession {
  final controller = StreamController<RtcUpdate>.broadcast(sync: true);
  int joins = 0, disposals = 0;
  bool firstFrame = true, muted = false, releaseFails = false;
  Completer<void>? releaseGate, playbackGate;
  bool playbackMuted = false, playbackFails = false;
  int playbackChanges = 0;
  @override
  Stream<RtcUpdate> get events => controller.stream;
  @override
  Future<void> join(Json info) async {
    joins++;
    controller.add(
      RtcUpdate(
        joined: true,
        published: true,
        audioReady: true,
        firstFrame: firstFrame,
      ),
    );
  }

  @override
  Future<void> mute(bool value) async {
    muted = value;
  }

  @override
  Future<void> mutePlayback(bool value) async {
    playbackChanges++;
    await playbackGate?.future;
    if (playbackFails) throw const AppFailure('rtcFailed');
    playbackMuted = value;
  }

  @override
  Future<void> route(String route) async {}
  @override
  Future<void> dispose() async {
    disposals++;
    await releaseGate?.future;
    await controller.close();
    if (releaseFails) throw StateError('release failure');
  }
}

void main() {
  late FakeApi api;
  late FakeStore store;
  late FakeSignal signal;
  late FakeRtc rtc;
  late CallCoordinator call;
  setUp(() {
    api = FakeApi();
    store = FakeStore();
    signal = FakeSignal();
    rtc = FakeRtc();
    call = CallCoordinator(
      api: api,
      store: store,
      signalFactory: (_, _) => signal,
      rtcFactory: () => rtc,
      microphonePermission: () async => true,
      queryDelays: [],
    );
  });
  tearDown(() async {
    await call.dispose();
  });

  testWidgets(
    'session duration is owned by the platform, including its limit',
    (tester) async {
      // Create streams in the same fake-time zone as the session timers.
      final api = FakeApi();
      final store = FakeStore();
      final signal = FakeSignal();
      final rtc = FakeRtc();
      final call = CallCoordinator(
        api: api,
        store: store,
        signalFactory: (_, _) => signal,
        rtcFactory: () => rtc,
        microphonePermission: () async => true,
        queryDelays: [],
      );
      addTearDown(call.dispose);
      await call.start(character, credential, 'profile');
      await tester.pump(const Duration(minutes: 10));
      expect(call.snapshot.phase, CallPhase.connected);
      expect(rtc.disposals, 0);
      expect(signal.sent, isNot(contains(5)));

      // Advancing the client clock does not synthesize a server time limit.
      await tester.pump(const Duration(minutes: 110));
      expect(call.snapshot.phase, CallPhase.connected);
      expect(api.creates, 1);
      expect(rtc.disposals, 0);

      signal.controller.add({'type': 6});
      // Stream teardown also schedules work outside the virtual clock.
      for (var step = 0; step < 10 && call.snapshot.active; step++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      expect(call.snapshot.phase, CallPhase.ended);
      expect(store.rows.values.single['endReason'], 'platform_end');
      expect(store.rows.values.single['endConfirmed'], isTrue);
      expect(rtc.disposals, 1);
      expect(signal.closed, isTrue);
      expect(api.creates, 1);
      await tester.pump(const Duration(hours: 1));
      expect(rtc.disposals, 1);
      expect(api.creates, 1);
    },
  );

  test('Doubao request uses matching provider and voice, with unsupported commands blocked', () async {
    const voice = 'zh_female_vv_uranus_bigtts';
    await call.start(
      character.copyWith(voiceProvider: VoiceProvider.doubao, voice: voice),
      credential,
      'profile',
    );
    expect(call.snapshot.interactive, isTrue);
    expect(api.lastBody!['voice_model'], {'provider': 'doubao'});
    expect(api.lastBody!['avatar']['voice'], voice);
    final before = signal.sent.toList();
    await expectLater(
      call.sendText('Hello'),
      throwsA(
        isA<AppFailure>().having((e) => e.code, 'code', 'textChatUnsupported'),
      ),
    );
    await expectLater(
      call.changeVoice(voice),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          'voiceChangeUnsupported',
        ),
      ),
    );
    expect(signal.sent, before);
    expect(store.texts, isEmpty);
    expect(call.snapshot.voice, voice);
    call.sendAction('Wave');
    expect(signal.sent.last, 101);
  });

  test(
    'wrong-provider voices are rejected before paid creation or update',
    () async {
      await call.start(
        character.copyWith(voice: 'zh_female_vv_uranus_bigtts'),
        credential,
        'profile',
      );
      expect(api.creates, 0);
      expect(call.snapshot.error, 'voiceInvalid');
      await call.start(character, credential, 'profile');
      expect(api.creates, 1);
      final before = signal.sent.toList();
      await expectLater(
        call.changeVoice('zh_female_vv_uranus_bigtts'),
        throwsA(isA<AppFailure>()),
      );
      expect(signal.sent, before);
      expect(call.snapshot.voice, character.voice);
    },
  );

  test(
    'playback mute is independent of microphone and preserves readiness',
    () async {
      await call.start(character, credential, 'profile');
      await call.togglePlayback();
      expect(rtc.playbackMuted, isTrue);
      expect(call.snapshot.playbackMuted, isTrue);
      expect(call.snapshot.muted, isFalse);
      expect(call.snapshot.audioReady, isTrue);
      expect(call.snapshot.interactive, isTrue);
      await call.mute();
      await call.togglePlayback();
      expect(call.snapshot.playbackMuted, isFalse);
      expect(call.snapshot.muted, isTrue);
      expect(rtc.muted, isTrue);
    },
  );

  test('playback failure leaves state unchanged and permits retry', () async {
    await call.start(character, credential, 'profile');
    rtc.playbackFails = true;
    await expectLater(call.togglePlayback(), throwsA(isA<AppFailure>()));
    expect(call.snapshot.playbackMuted, isFalse);
    rtc.playbackFails = false;
    await call.togglePlayback();
    expect(call.snapshot.playbackMuted, isTrue);
  });

  test('deduplicates playback taps and ignores result after ending', () async {
    await call.start(character, credential, 'profile');
    rtc.playbackGate = Completer<void>();
    final toggling = call.togglePlayback();
    await call.togglePlayback();
    expect(rtc.playbackChanges, 1);
    expect(call.snapshot.playbackMuted, isFalse);
    await call.end();
    rtc.playbackGate!.complete();
    await toggling;
    expect(call.snapshot.playbackMuted, isFalse);
    expect(call.snapshot.phase, CallPhase.ended);
  });

  test('repeated start shares one creation and one RTC room', () async {
    api.pending = Completer<Json>();
    final first = call.start(character, credential, 'profile');
    final duplicate = call.start(character, credential, 'profile');
    expect(identical(first, duplicate), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(api.creates, 1);
    api.pending!.complete(created);
    await first;
    expect(rtc.joins, 1);
    expect(call.snapshot.phase, CallPhase.connected);
  });

  test('cancelled creation persists a late live ID and hangs up without init or RTC', () async {
    api.pending = Completer<Json>();
    final start = call.start(character, credential, 'profile');
    await Future<void>.delayed(Duration.zero);
    final end = call.end();
    api.pending!.complete(created);
    await Future.wait([start, end]);
    expect(api.creates, 1);
    expect(store.rows.values.single['liveId'], 'live-one');
    expect(signal.sent, [5]);
    expect(rtc.joins, 0);
    expect(call.snapshot.phase, CallPhase.ended);
  });

  test('NOT_READY retries init on the existing live', () async {
    signal.notReady = 1;
    await call.start(character, credential, 'profile');
    expect(api.creates, 1);
    expect(signal.sent.where((t) => t == 1).length, 2);
    expect(call.snapshot.phase, CallPhase.connected);
  });

  test('ready requires media callbacks and a real first frame', () async {
    rtc.firstFrame = false;
    await call.start(character, credential, 'profile');
    expect(call.snapshot.phase, CallPhase.joining);
    expect(call.snapshot.interactive, isFalse);
    rtc.controller.add(const RtcUpdate(firstFrame: true));
    expect(call.snapshot.phase, CallPhase.connected);
  });

  test('missing microphone permission never creates a billable live', () async {
    await call.dispose();
    call = CallCoordinator(
      api: api,
      store: store,
      signalFactory: (_, _) => signal,
      rtcFactory: () => rtc,
      microphonePermission: () async => false,
      queryDelays: [],
    );
    await call.start(character, credential, 'profile');
    expect(api.creates, 0);
    expect(call.snapshot.error, 'microphoneDenied');
    expect(call.snapshot.phase, CallPhase.failed);
  });

  test('pending previous calls block creation', () async {
    store.unresolved = true;
    await call.start(character, credential, 'profile');
    expect(api.creates, 0);
    expect(call.snapshot.error, 'pendingCall');
  });

  test(
    'malformed create responses remain unknown and are never retried',
    () async {
      api.pending = Completer<Json>()
        ..complete({
          'rtc': {'provider': 'agora'},
        });
      await call.start(character, credential, 'profile');
      expect(api.creates, 1);
      expect(call.snapshot.phase, CallPhase.pending);
      expect(store.rows.values.single['endConfirmed'], isFalse);
      expect(signal.sent, isEmpty);
      expect(rtc.joins, 0);
    },
  );

  test(
    'new calls remain blocked until the old native engine is released',
    () async {
      await call.start(character, credential, 'profile');
      rtc.releaseGate = Completer<void>();
      final ending = call.end();
      await Future<void>.delayed(Duration.zero);
      expect(call.snapshot.phase, CallPhase.ending);
      await call.start(character, credential, 'profile');
      expect(api.creates, 1);
      rtc.releaseGate!.complete();
      await ending;
      expect(call.snapshot.phase, CallPhase.ended);
    },
  );

  test(
    '403 while checking end never confirms ending or loses local cleanup',
    () async {
      await call.start(character, credential, 'profile');
      api.queryFails = true;
      final first = call.end(), second = call.end();
      await Future.wait([first, second]);
      expect(call.snapshot.phase, CallPhase.pending);
      expect(store.rows.values.single['endConfirmed'], isFalse);
      expect(rtc.muted, isTrue);
      expect(rtc.disposals, 1);
      expect(signal.sent.where((t) => t == 5).length, 1);
    },
  );

  test('text and action use separate signals, without a fabricated success receipt', () async {
    await call.start(character, credential, 'profile');
    await call.sendText('Hello');
    call.sendAction('Wave');
    expect(signal.sent, containsAllInOrder([102, 101]));
    expect(store.texts.values.single['delivery'], 'sent');
    expect(() => call.sendAction('Wave'), throwsA(isA<AppFailure>()));
    await call.changeVoice('Cherry');
    expect(call.snapshot.voice, 'Cherry');
  });

  test('observed transcripts upsert, controls and delivery failure remain explicit', () async {
    expect(() => call.interrupt(), throwsA(isA<AppFailure>()));
    await call.start(character, credential, 'profile');
    signal.controller.add({
      'type': 10,
      'payload': {
        'message': {'msg_id': 'one', 'content': 'partial'},
      },
    });
    signal.controller.add({
      'type': 10,
      'payload': {'msg_id': 'one', 'text': 'final'},
    });
    expect(store.texts.values.single['text'], 'final');
    expect(store.texts.values.single['delivery'], 'observed');
    await call.mute();
    expect(call.snapshot.muted, isTrue);
    await call.setRoute('earpiece');
    call.interrupt();
    expect(signal.sent, contains(7));
    await expectLater(call.sendText(''), throwsA(isA<AppFailure>()));
    expect(() => call.sendAction(''), throwsA(isA<AppFailure>()));
    signal.failSend = true;
    await expectLater(call.sendText('hello'), throwsA(isA<AppFailure>()));
    expect(store.texts.values.last['delivery'], 'unknown');
    signal.voiceSuccess = false;
    await expectLater(call.changeVoice('Cherry'), throwsA(isA<AppFailure>()));
    expect(call.snapshot.voice, isNot('Cherry'));
    signal.controller.add({'type': 103});
    expect(call.snapshot.error, 'commandRejected');
  });
  test(
    'RTC failure releases resources while billing remains pending',
    () async {
      await call.start(character, credential, 'profile');
      api.status = 'running';
      rtc.controller.add(const RtcUpdate(failure: 'audioInterrupted'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(call.snapshot.phase, CallPhase.pending);
      expect(store.rows.values.single['endReason'], 'rtc_failure');
      expect(store.rows.values.single['endConfirmed'], isFalse);
    },
  );
  test('release failure does not skip platform reconciliation', () async {
    await call.start(character, credential, 'profile');
    rtc.releaseFails = true;
    await call.end('app_background');
    expect(call.snapshot.phase, CallPhase.ended);
    expect(call.snapshot.error, 'rtcFailed');
    expect(store.rows.values.single['endReason'], 'app_background');
    expect(store.rows.values.single['billedSeconds'], 3);
    await call.start(character, credential, 'profile');
    expect(api.creates, 1);
    expect(call.snapshot.error, 'rtcFailed');
    expect(call.snapshot.phase, CallPhase.failed);
  });
  for (final type in [6, -1]) {
    test('signal $type ends the local session safely', () async {
      await call.start(character, credential, 'profile');
      signal.controller.add({'type': type});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(call.snapshot.phase, CallPhase.ended);
      expect(rtc.disposals, 1);
    });
  }
  test('wrong credential cannot create a live', () async {
    await call.start(character, const Credential('other', 'fake'), 'profile');
    expect(api.creates, 0);
    expect(call.snapshot.error, 'wrongCredential');
  });
  test('memory IDs are stable and optional resources are omitted', () {
    final body = buildSession(
      character.copyWith(memory: true),
      'stable-profile',
    );
    expect(body['memory_retrieval']['user_id'], 'stable-profile');
    expect(body['memory_retrieval']['agent_id'], character.id);
    expect(body['enable_recording'], isFalse);
    expect(body['rtc']['provider'], 'agora');
    expect(body.containsKey('knowledge_retrieval'), isFalse);
    expect(
      buildSession(character, 'stable-profile').containsKey('memory_retrieval'),
      isFalse,
    );
    expect(body['avatar']['persona'], character.persona);
  });
}
