import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../domain/call_ports.dart';
import '../../domain/models.dart';

class AgoraRtcSession implements RtcSession {
  AgoraRtcSession({RtcEngine Function()? engineFactory})
    : _engineFactory = engineFactory ?? createAgoraRtcEngine;

  final RtcEngine Function() _engineFactory;
  final _events = StreamController<RtcUpdate>.broadcast();
  RtcEngine? _engine;
  RtcEngine? get engine => _disposed ? null : _engine;
  bool _disposed = false, _initialized = false;
  Future<void>? _joining, _disposing;
  RtcEngineEventHandler? _handler;
  String _channel = '';
  int? _remoteUid;
  final _audio = <int>{};
  final _left = Completer<void>();

  @override
  Stream<RtcUpdate> get events => _events.stream;

  void _emit(RtcUpdate event) {
    if (!_disposed) _events.add(event);
  }

  bool _matches(RtcConnection connection) => connection.channelId == _channel;

  bool _selectVideo(int uid) {
    if (_remoteUid != null && _remoteUid != uid) {
      _emit(const RtcUpdate(failure: 'ambiguousRemote'));
      return false;
    }
    _remoteUid = uid;
    _emit(
      RtcUpdate(
        video: RemoteVideo(_channel, uid),
        audioReady: _audio.contains(uid),
      ),
    );
    return true;
  }

  @override
  Future<void> join(Json info) => _joining ??= _join(info);

  Future<void> _join(Json info) async {
    if (_disposed) throw const AppFailure('notConnected');
    if (info['provider'] != 'agora') {
      throw const AppFailure('channelUnavailable');
    }
    for (final key in ['app_id', 'channel_id', 'user_id', 'token']) {
      if (info[key] is! String || (info[key] as String).isEmpty) {
        throw const AppFailure('protocol');
      }
    }
    _channel = info['channel_id'] as String;
    final engine = _engine = _engineFactory();
    await engine.initialize(
      RtcEngineContext(
        appId: info['app_id'] as String,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        logConfig: const LogConfig(level: LogLevel.logLevelNone),
      ),
    );
    _initialized = true;
    if (_disposed) return;
    final handler = _handler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, _) {
        if (_matches(connection)) _emit(const RtcUpdate(joined: true));
      },
      onLeaveChannel: (_, _) {
        if (!_left.isCompleted) _left.complete();
      },
      onError: (_, _) => _emit(const RtcUpdate(failure: 'rtcFailed')),
      onConnectionLost: (_) =>
          _emit(const RtcUpdate(failure: 'connectionLost')),
      onConnectionStateChanged: (_, state, _) {
        if (state == ConnectionStateType.connectionStateFailed) {
          _emit(const RtcUpdate(failure: 'connectionLost'));
        }
      },
      onRequestToken: (_) => _emit(const RtcUpdate(failure: 'connectionLost')),
      onAudioPublishStateChanged: (channel, _, state, _) {
        if (channel == _channel) {
          _emit(
            RtcUpdate(published: state == StreamPublishState.pubStatePublished),
          );
        }
      },
      onAudioSubscribeStateChanged: (channel, uid, _, state, _) {
        if (channel != _channel) return;
        if (state == StreamSubscribeState.subStateSubscribed) {
          _audio.add(uid);
        } else {
          _audio.remove(uid);
        }
        _emit(RtcUpdate(audioReady: _audio.contains(_remoteUid)));
      },
      onVideoSubscribeStateChanged: (channel, uid, _, state, _) {
        if (channel == _channel &&
            state == StreamSubscribeState.subStateSubscribed) {
          _selectVideo(uid);
        }
      },
      onRemoteVideoStateChanged: (connection, uid, state, _, _) {
        if (_matches(connection) &&
            state == RemoteVideoState.remoteVideoStateDecoding) {
          _selectVideo(uid);
        }
      },
      onFirstRemoteVideoFrame: (connection, uid, _, _, _) {
        if (_matches(connection) && _selectVideo(uid)) {
          _emit(const RtcUpdate(firstFrame: true));
        }
      },
      onUserOffline: (connection, uid, _) {
        if (_matches(connection) && uid == _remoteUid) {
          _emit(const RtcUpdate(failure: 'connectionLost'));
        }
      },
      onLocalAudioStateChanged: (_, state, reason) {
        if (state == LocalAudioStreamState.localAudioStreamStateFailed ||
            reason ==
                LocalAudioStreamReason.localAudioStreamReasonInterrupted) {
          _emit(const RtcUpdate(failure: 'audioInterrupted'));
        }
      },
      onAudioRoutingChanged: (route) {
        _emit(
          RtcUpdate(
            route: switch (route) {
              3 => 'speakerphone',
              1 => 'earpiece',
              _ => 'routeDefault',
            },
          ),
        );
      },
    );
    engine.registerEventHandler(handler);
    // Enable receiving video, then explicitly disable local camera capture
    // before joining. No preview or camera publication is requested.
    await engine.enableVideo();
    if (_disposed) return;
    await engine.enableLocalVideo(false);
    if (_disposed) return;
    await engine.setDefaultAudioRouteToSpeakerphone(true);
    if (_disposed) return;
    // Vidu signs the token against this exact string account. Never parse it
    // as a numeric Agora UID, even when it contains only digits.
    await engine.joinChannelWithUserAccount(
      token: info['token'] as String,
      channelId: _channel,
      userAccount: info['user_id'] as String,
      options: const ChannelMediaOptions(
        publishMicrophoneTrack: true,
        publishCameraTrack: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        enableAudioRecordingOrPlayout: true,
      ),
    );
  }

  @override
  Future<void> mute(bool muted) async {
    if (_initialized && !_disposed) {
      await _engine!.muteLocalAudioStream(muted);
    }
  }

  @override
  Future<void> mutePlayback(bool muted) async {
    if (!_initialized || _disposed) throw const AppFailure('notConnected');
    // Keep subscriptions and microphone capture intact; only local playout changes.
    await _engine!.adjustPlaybackSignalVolume(muted ? 0 : 100);
  }

  @override
  Future<void> route(String route) async {
    if (!_initialized || _disposed) return;
    final value = switch (route) {
      'speakerphone' => 3,
      'earpiece' => 1,
      _ => -1,
    };
    if (Platform.isAndroid) {
      await _engine!.setRouteInCommunicationMode(value);
    } else {
      await _engine!.setEnableSpeakerphone(value == 3);
    }
  }

  @override
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    try {
      await _joining;
    } on Object {
      // A partially initialized engine still belongs to this session.
    }
    final engine = _engine;
    if (engine == null) {
      await _events.close();
      return;
    }
    Future<void> attempt(Future<void> Function() work) async {
      try {
        await work().timeout(const Duration(seconds: 2));
      } on Object {
        // Continue the other release operations.
      }
    }

    if (_initialized) {
      await attempt(() => engine.muteLocalAudioStream(true));
      await attempt(() => engine.enableLocalAudio(false));
      await attempt(() => engine.leaveChannel());
      await attempt(() => _left.future);
      if (_handler != null) engine.unregisterEventHandler(_handler!);
    }
    try {
      // Keep ownership until native teardown completes; do not race a new
      // engine against an earlier asynchronous release.
      await engine.release(sync: true);
    } finally {
      _engine = null;
      await _events.close();
    }
  }
}
