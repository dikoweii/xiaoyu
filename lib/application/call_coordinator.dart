import 'dart:async';

import 'package:uuid/uuid.dart';

import '../domain/call_ports.dart';
import '../domain/models.dart';
import '../domain/voice_catalog.dart';

class _Attempt {
  _Attempt(this.character, this.credential, this.profileId);
  final String id = const Uuid().v4();
  final Character character;
  final Credential credential;
  final String profileId;
  bool cancelled = false,
      creating = false,
      knownFailure = false,
      preparing = true;
  String reason = 'user_end';
  String? liveId;
  Signaling? signal;
  RtcSession? rtc;
  StreamSubscription<Json>? signals;
  StreamSubscription<RtcUpdate>? media;
  Completer<void>? initialized;
  Completer<void>? voiceAck;
  bool voiceUnknown = false, playbackUpdating = false;
  Timer? preparationTimer;
  final clock = Stopwatch();
  Future<void>? finishing;
}

class CallCoordinator {
  CallCoordinator({
    required this.api,
    required this.store,
    required this.signalFactory,
    required this.rtcFactory,
    required this.microphonePermission,
    this.preparationTimeout = const Duration(seconds: 45),
    this.queryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
  });
  final LiveApi api;
  final CallPersistence store;
  final Signaling Function(Credential, String) signalFactory;
  final RtcSession Function() rtcFactory;
  final Future<bool> Function() microphonePermission;
  final Duration preparationTimeout;
  final List<Duration> queryDelays;
  final _changes = StreamController<CallSnapshot>.broadcast();
  CallSnapshot snapshot = const CallSnapshot();
  Stream<CallSnapshot> get changes => _changes.stream;
  _Attempt? _attempt;
  Future<void>? _starting;
  bool _releaseUncertain = false;
  DateTime? _lastAction;
  Duration get elapsed => _attempt?.clock.elapsed ?? Duration.zero;
  RtcSession? get rtc => _attempt?.rtc;
  void _emit(CallSnapshot state) {
    snapshot = state;
    _changes.add(state);
  }

  Future<void> start(
    Character character,
    Credential credential,
    String profileId,
  ) {
    if (_releaseUncertain) {
      _emit(snapshot.copyWith(phase: CallPhase.failed, error: 'rtcFailed'));
      return Future.value();
    }
    if (snapshot.active) return _starting ?? Future.value();
    final a = _Attempt(character, credential, profileId);
    _attempt = a;
    _lastAction = null;
    _emit(
      CallSnapshot(
        phase: CallPhase.creating,
        callId: a.id,
        character: character,
        voice: character.voice,
      ),
    );
    return _starting = _prepare(a);
  }

  Future<void> _prepare(_Attempt a) async {
    var persisted = false;
    try {
      final body = buildSession(a.character, a.profileId);
      if (a.character.credentialId != a.credential.id) {
        throw const AppFailure('wrongCredential');
      }
      if (await store.hasUnresolved()) throw const AppFailure('pendingCall');
      if (!await microphonePermission()) {
        throw const AppFailure('microphoneDenied');
      }
      if (a.cancelled) {
        _emit(snapshot.copyWith(phase: CallPhase.ended));
        return;
      }
      await store.begin(a.id, a.character, a.credential);
      persisted = true;
      if (a.cancelled) {
        a.knownFailure = true;
        await _finish(a);
        return;
      }
      a.preparationTimer = Timer(preparationTimeout, () {
        a.cancelled = true;
        a.reason = 'prepare_timeout';
        _emit(
          snapshot.copyWith(phase: CallPhase.ending, error: 'prepareTimeout'),
        );
        if (a.initialized?.isCompleted == false) {
          a.initialized!.completeError(const AppFailure('prepareTimeout'));
        }
        if (!a.preparing) unawaited(_finish(a));
      });
      a.creating = true;
      // Never cancel or automatically repeat this POST. Its late result is owned here.
      final response = await api.createLive(a.credential, body);
      a.creating = false;
      if (response['live'] is! Map) {
        throw const AppFailure('protocol', outcomeUnknown: true);
      }
      final live = jsonObject(response['live']);
      final liveId = live['id']?.toString();
      if (liveId == null || liveId.isEmpty) {
        throw const AppFailure('protocol', outcomeUnknown: true);
      }
      a.liveId = liveId;
      await store.update(a.id, {'liveId': liveId, 'phase': 'initializing'});
      _emit(
        snapshot.copyWith(
          liveId: liveId,
          phase: a.cancelled ? CallPhase.ending : CallPhase.initializing,
        ),
      );
      final signal = a.signal = signalFactory(a.credential, liveId);
      a.signals = signal.events.listen((event) => _onSignal(a, event));
      await signal.connect();
      if (a.cancelled) {
        await _finish(a);
        return;
      }
      await _initialize(a);
      if (a.cancelled) {
        await _finish(a);
        return;
      }
      final now = DateTime.now().toUtc();
      await store.update(a.id, {'phase': 'joining', 'readyAt': now});
      if (a.cancelled) {
        await _finish(a);
        return;
      }
      a.clock.start();
      _emit(
        snapshot.copyWith(
          phase: CallPhase.joining,
          controlReady: true,
          readyAt: now,
        ),
      );
      final rtc = a.rtc = rtcFactory();
      a.media = rtc.events.listen((event) => _onRtc(a, event));
      await rtc.join(jsonObject(response['rtc']));
      if (a.cancelled) await _finish(a);
    } on Object catch (e) {
      a.creating = false;
      final failure = e is AppFailure
          ? e
          : const AppFailure('connectionFailed', outcomeUnknown: true);
      a.knownFailure = a.liveId == null && !failure.outcomeUnknown;
      if (_attempt == a) _emit(snapshot.copyWith(error: failure.code));
      if (persisted) {
        await _finish(a);
      } else {
        _emit(snapshot.copyWith(phase: CallPhase.failed));
      }
    } finally {
      a.preparing = false;
    }
  }

  Future<void> _initialize(_Attempt a) async {
    for (var retry = 0; retry < 7 && !a.cancelled; retry++) {
      a.initialized = Completer<void>();
      a.signal!.send(1, {
        'conn_init': {'version': 1},
      });
      try {
        await a.initialized!.future.timeout(const Duration(seconds: 5));
        return;
      } on AppFailure catch (e) {
        if (e.code != 'NOT_READY') rethrow;
        await Future<void>.delayed(Duration(milliseconds: 500 * (retry + 1)));
      }
    }
    throw const AppFailure('prepareTimeout');
  }

  void _onSignal(_Attempt a, Json event) {
    if (_attempt != a || a.finishing != null) return;
    final payload = event['payload'] is Map
        ? jsonObject(event['payload'])
        : <String, dynamic>{};
    switch (event['type']) {
      case 2:
        final ack = payload['conn_init_ack'];
        if (ack is Map && a.initialized?.isCompleted == false) {
          if (ack['success'] == true) {
            a.initialized!.complete();
          } else {
            a.initialized!.completeError(
              AppFailure(
                ack['error_code'] == 'NOT_READY'
                    ? 'NOT_READY'
                    : 'initializationFailed',
              ),
            );
          }
        }
      case 6:
        a.cancelled = true;
        a.reason = 'platform_end';
        if (a.initialized?.isCompleted == false) {
          a.initialized!.completeError(const AppFailure('platformEnded'));
        }
        if (!a.preparing) unawaited(_finish(a));
      case -1:
        a.cancelled = true;
        a.reason = 'connection_lost';
        _emit(snapshot.copyWith(error: 'connectionLost'));
        if (a.initialized?.isCompleted == false) {
          a.initialized!.completeError(const AppFailure('connectionLost'));
        }
        if (!a.preparing) unawaited(_finish(a));
      case 98:
        final ack = payload['session_update_ack'];
        if (ack is Map && a.voiceAck?.isCompleted == false) {
          if (ack['success'] == true) {
            a.voiceAck!.complete();
          } else {
            a.voiceAck!.completeError(const AppFailure('voiceChangeFailed'));
          }
        }
      case 9 || 10:
        // Preserve observed frames; exact incremental/final semantics require M0 fixtures.
        final bodies = [
          payload,
          ...payload.values.whereType<Map<String, dynamic>>().map(jsonObject),
        ];
        for (final body in bodies) {
          final content = body['content'] ?? body['text'];
          if (content is String && content.isNotEmpty) {
            final speaker = event['type'] == 9 ? 'user' : 'assistant';
            final remoteId = body['msg_id'] ?? body['message_id'];
            final id = remoteId == null
                ? const Uuid().v4()
                : '${a.id}:$speaker:$remoteId';
            unawaited(store.message(a.id, id, speaker, content, 'observed'));
            break;
          }
        }
      case 103:
        _emit(snapshot.copyWith(error: 'commandRejected'));
    }
  }

  void _onRtc(_Attempt a, RtcUpdate event) {
    if (_attempt != a || a.cancelled || a.finishing != null) return;
    if (event.failure != null) {
      _emit(snapshot.copyWith(error: event.failure));
      a.reason = 'rtc_failure';
      a.cancelled = true;
      if (!a.preparing) unawaited(_finish(a));
      return;
    }
    var next = snapshot.copyWith(
      joined: event.joined,
      published: event.published,
      audioReady: event.audioReady,
      firstFrame: event.firstFrame,
      video: event.video,
      route: event.route,
    );
    if (next.controlReady &&
        next.joined &&
        next.published &&
        next.audioReady &&
        next.firstFrame) {
      a.preparationTimer?.cancel();
      next = next.copyWith(phase: CallPhase.connected);
      unawaited(store.update(a.id, {'phase': 'connected'}));
    }
    _emit(next);
  }

  Future<void> end([String reason = 'user_end']) {
    final a = _attempt;
    if (a == null || !snapshot.active) return Future.value();
    a.cancelled = true;
    a.reason = reason;
    _emit(snapshot.copyWith(phase: CallPhase.ending));
    if (a.initialized?.isCompleted == false) {
      a.initialized!.completeError(const AppFailure('cancelled'));
    }
    if (a.preparing) return _starting ?? Future.value();
    return _finish(a);
  }

  Future<void> _finish(_Attempt a) => a.finishing ??= _cleanup(a);
  Future<void> _cleanup(_Attempt a) async {
    a.cancelled = true;
    a.clock.stop();
    a.preparationTimer?.cancel();
    if (_attempt == a) _emit(snapshot.copyWith(phase: CallPhase.ending));
    Future<void> attempt(Future<void> Function() work) async {
      try {
        await work().timeout(const Duration(seconds: 3));
      } on Object {
        /* Continue remaining cleanup. */
      }
    }

    await attempt(() async {
      await a.rtc?.mute(true);
    });
    await attempt(() async {
      a.signal?.send(5, {
        'hangup': {'hangup_reason': 'user_end'},
      });
    });
    await attempt(() async {
      await a.signal?.close();
    });
    await attempt(() async {
      await a.media?.cancel();
    });
    // The RTC engine remains owned until its native teardown completes.
    // Timing this out would allow a new call to race the old engine release.
    try {
      await a.rtc?.dispose();
    } on Object {
      // A failed native release cannot establish that another engine is safe.
      _releaseUncertain = true;
      if (_attempt == a) _emit(snapshot.copyWith(error: 'rtcFailed'));
    }
    await attempt(() async {
      await a.signals?.cancel();
    });
    var confirmed = false;
    await store.update(a.id, {
      'phase': 'pending',
      'releasedAt': DateTime.now().toUtc(),
      'endReason': a.reason,
    });
    if (a.liveId != null) {
      for (final delay in [Duration.zero, ...queryDelays]) {
        if (delay != Duration.zero) await Future<void>.delayed(delay);
        try {
          confirmed = await reconcile(
            a.id,
            a.liveId!,
            a.credential,
          ).timeout(const Duration(seconds: 3));
          if (confirmed) break;
        } on Object {
          /* Preserve pending state on 403/404/network errors. */
        }
      }
    }
    final phase = confirmed
        ? CallPhase.ended
        : a.knownFailure
        ? CallPhase.failed
        : CallPhase.pending;
    await store.update(a.id, {
      'phase': phase.name,
      'endConfirmed': confirmed,
      if (snapshot.error != null) 'error': snapshot.error,
    });
    if (_attempt == a) _emit(snapshot.copyWith(phase: phase));
  }

  Future<bool> reconcile(
    String callId,
    String liveId,
    Credential credential,
  ) async {
    final response = await api.getLive(credential, liveId);
    final live = jsonObject(response['live']);
    final confirmed = live['status'] == 'ended';
    await store.update(callId, {
      'endConfirmed': confirmed,
      if (confirmed) 'phase': 'ended',
      if (live['billed_seconds'] != null)
        'billedSeconds': int.tryParse('${live['billed_seconds']}'),
      if (live['credits_cost'] != null)
        'creditsCost': '${live['credits_cost']}',
    });
    return confirmed;
  }

  Future<void> sendText(String text) async {
    final a = _interactive();
    if (a.character.voiceProvider == VoiceProvider.doubao) {
      throw const AppFailure('textChatUnsupported');
    }
    if (text.trim().isEmpty || text.runes.length > 1000) {
      throw const AppFailure('inputInvalid');
    }
    final id = const Uuid().v4();
    await store.message(a.id, id, 'user', text, 'sending');
    try {
      a.signal!.send(102, {
        'text_dialog': {'msg_id': id, 'content': text},
      });
      await store.message(a.id, id, 'user', text, 'sent');
    } on Object {
      await store.message(a.id, id, 'user', text, 'unknown');
      rethrow;
    }
  }

  void sendAction(String text) {
    final a = _interactive();
    if (text.trim().isEmpty || text.runes.length > 200) {
      throw const AppFailure('inputInvalid');
    }
    final now = DateTime.now();
    if (_lastAction != null &&
        now.difference(_lastAction!).inMilliseconds < 2000) {
      throw const AppFailure('actionCooldown');
    }
    a.signal!.send(101, {
      'text_action': {'msg_id': const Uuid().v4(), 'content': text},
    });
    _lastAction = now;
  }

  void interrupt() => _interactive().signal!.send(7, {});
  Future<void> mute() async {
    final a = _interactive();
    final value = !snapshot.muted;
    await a.rtc!.mute(value);
    _emit(snapshot.copyWith(muted: value));
  }

  Future<void> togglePlayback() async {
    final a = _interactive();
    if (a.playbackUpdating) return;
    a.playbackUpdating = true;
    final value = !snapshot.playbackMuted;
    try {
      await a.rtc!.mutePlayback(value);
      if (_attempt == a && !a.cancelled) {
        _emit(snapshot.copyWith(playbackMuted: value));
      }
    } finally {
      a.playbackUpdating = false;
    }
  }

  Future<void> setRoute(String route) => _interactive().rtc!.route(route);
  Future<void> changeVoice(String voice) async {
    final a = _interactive();
    if (a.character.voiceProvider == VoiceProvider.doubao) {
      throw const AppFailure('voiceChangeUnsupported');
    }
    if (!isCompatibleVoice(a.character.voiceProvider, voice)) {
      throw const AppFailure('voiceInvalid');
    }
    if (a.voiceAck != null || a.voiceUnknown) {
      throw const AppFailure('voicePending');
    }
    final ack = a.voiceAck = Completer<void>();
    try {
      a.signal!.send(97, {
        'session_update': {
          'avatar': {'voice': voice},
        },
      });
      await ack.future.timeout(const Duration(seconds: 8));
      if (_attempt == a && !a.cancelled) _emit(snapshot.copyWith(voice: voice));
    } on TimeoutException {
      a.voiceUnknown = true;
      throw const AppFailure('voiceUnknown');
    } finally {
      a.voiceAck = null;
    }
  }

  _Attempt _interactive() {
    if (!snapshot.interactive || _attempt?.cancelled != false) {
      throw const AppFailure('notConnected');
    }
    return _attempt!;
  }

  Future<void> dispose() async {
    await end('app_exit');
    await _changes.close();
  }
}
