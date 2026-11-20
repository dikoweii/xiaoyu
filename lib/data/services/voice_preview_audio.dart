import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../domain/voice_preview.dart';

class VoicePreviewAudio implements PreviewAudio {
  final _events = StreamController<PreviewAudioEvent>.broadcast(sync: true);
  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  @override
  Stream<PreviewAudioEvent> get events => _events.stream;

  @override
  Future<void> play(String id, String url) async {
    final player = AudioPlayer();
    _player = player;
    _completion = player.onPlayerComplete.listen(
      (_) => _events.add(PreviewAudioEvent(id)),
      onError: (Object _) => _events.add(PreviewAudioEvent(id, failed: true)),
    );
    await player.play(
      UrlSource(url),
      ctx: AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.speech,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
      ),
    );
  }

  @override
  Future<void> stop() async {
    final player = _player;
    _player = null;
    final completion = _completion;
    _completion = null;
    await completion?.cancel();
    await player?.dispose();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
