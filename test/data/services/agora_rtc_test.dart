import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/data/services/agora_rtc.dart';
import 'package:xiaoyu/domain/call_ports.dart';
import 'package:xiaoyu/domain/models.dart';

const info = <String, dynamic>{
  'provider': 'agora',
  'app_id': 'app',
  'channel_id': 'channel',
  'user_id': '000123',
  'token': 'test-token',
};

class FakeEngine implements RtcEngine {
  final operations = <String>[];
  RtcEngineEventHandler? handler;
  RtcEngineContext? context;
  String? account, token, channel;
  ChannelMediaOptions? options;
  Completer<void>? releaseGate;

  @override
  Future<void> initialize(RtcEngineContext context) async {
    this.context = context;
    operations.add('initialize');
  }

  @override
  void registerEventHandler(RtcEngineEventHandler eventHandler) {
    handler = eventHandler;
  }

  @override
  void unregisterEventHandler(RtcEngineEventHandler eventHandler) {
    operations.add('unregister');
  }

  @override
  Future<void> enableVideo() async => operations.add('enableVideo');

  @override
  Future<void> enableLocalVideo(bool enabled) async =>
      operations.add('camera:$enabled');

  @override
  Future<void> setDefaultAudioRouteToSpeakerphone(
    bool defaultToSpeaker,
  ) async {}

  @override
  Future<void> joinChannelWithUserAccount({
    required String token,
    required String channelId,
    required String userAccount,
    ChannelMediaOptions? options,
  }) async {
    this.token = token;
    channel = channelId;
    account = userAccount;
    this.options = options;
    operations.add('join');
  }

  @override
  Future<void> muteLocalAudioStream(bool mute) async =>
      operations.add('mute:$mute');

  @override
  Future<void> adjustPlaybackSignalVolume(int volume) async =>
      operations.add('playback:$volume');

  @override
  Future<void> enableLocalAudio(bool enabled) async =>
      operations.add('microphone:$enabled');

  @override
  Future<void> leaveChannel({LeaveChannelOptions? options}) async {
    operations.add('leave');
    handler?.onLeaveChannel?.call(
      const RtcConnection(channelId: 'channel'),
      const RtcStats(),
    );
  }

  @override
  Future<void> release({bool sync = false}) async {
    operations.add('release:$sync');
    await releaseGate?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeEngine engine;
  late AgoraRtcSession session;
  setUp(() {
    engine = FakeEngine();
    session = AgoraRtcSession(engineFactory: () => engine);
  });
  tearDown(() => session.dispose());

  test(
    'local playback uses volume without changing capture or subscriptions',
    () async {
      await session.join(info);
      engine.operations.clear();
      await session.mutePlayback(true);
      await session.mutePlayback(false);
      expect(engine.operations, ['playback:0', 'playback:100']);
      expect(engine.options!.autoSubscribeAudio, isTrue);
      expect(engine.options!.publishMicrophoneTrack, isTrue);
      await session.dispose();
      await expectLater(session.mutePlayback(true), throwsA(isA<AppFailure>()));
    },
  );

  test(
    'preserves the signed string account and disables camera before join',
    () async {
      await session.join(info);
      expect(engine.account, '000123');
      expect(engine.channel, 'channel');
      expect(engine.token, 'test-token');
      expect(engine.operations, [
        'initialize',
        'enableVideo',
        'camera:false',
        'join',
      ]);
      expect(engine.options!.publishCameraTrack, isFalse);
      expect(engine.options!.publishMicrophoneTrack, isTrue);
      expect(engine.options!.autoSubscribeAudio, isTrue);
      expect(engine.options!.autoSubscribeVideo, isTrue);
      expect(engine.context!.logConfig!.level, LogLevel.logLevelNone);
    },
  );

  test(
    'requires a rendered frame and audio from the same remote user',
    () async {
      final updates = <RtcUpdate>[];
      final subscription = session.events.listen(updates.add);
      await session.join(info);
      final handler = engine.handler!;
      handler.onAudioSubscribeStateChanged!(
        'channel',
        3,
        StreamSubscribeState.subStateIdle,
        StreamSubscribeState.subStateSubscribed,
        0,
      );
      handler.onVideoSubscribeStateChanged!(
        'channel',
        4,
        StreamSubscribeState.subStateIdle,
        StreamSubscribeState.subStateSubscribed,
        0,
      );
      await Future<void>.delayed(Duration.zero);
      expect(updates.last.video!.uid, 4);
      expect(updates.last.audioReady, isFalse);
      expect(updates.any((u) => u.firstFrame == true), isFalse);
      handler.onAudioSubscribeStateChanged!(
        'channel',
        4,
        StreamSubscribeState.subStateIdle,
        StreamSubscribeState.subStateSubscribed,
        0,
      );
      handler.onFirstRemoteVideoFrame!(
        const RtcConnection(channelId: 'channel'),
        4,
        720,
        1280,
        0,
      );
      await Future<void>.delayed(Duration.zero);
      expect(updates.any((u) => u.audioReady == true), isTrue);
      expect(updates.last.firstFrame, isTrue);
      await subscription.cancel();
    },
  );

  test(
    'rejects an unexpected RTC provider before creating a native engine',
    () async {
      await expectLater(
        session.join({...info, 'provider': 'volcengine'}),
        throwsA(isA<AppFailure>()),
      );
      expect(engine.operations, isEmpty);
    },
  );

  test(
    'teardown owns the engine until synchronous native release completes',
    () async {
      await session.join(info);
      engine.releaseGate = Completer<void>();
      var released = false;
      final first = session.dispose();
      final repeated = session.dispose();
      expect(identical(first, repeated), isTrue);
      unawaited(first.then((_) => released = true));
      await Future<void>.delayed(Duration.zero);
      expect(
        engine.operations,
        containsAllInOrder([
          'mute:true',
          'microphone:false',
          'leave',
          'unregister',
          'release:true',
        ]),
      );
      expect(released, isFalse);
      expect(session.engine, isNull);
      engine.releaseGate!.complete();
      await first;
      expect(released, isTrue);
    },
  );
}
