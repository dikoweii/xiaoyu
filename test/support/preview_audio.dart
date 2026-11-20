import 'dart:async';

import 'package:xiaoyu/domain/voice_preview.dart';

class FakePreviewAudio implements PreviewAudio {
  final controller = StreamController<PreviewAudioEvent>.broadcast(sync: true);
  final plays = <(String, String)>[];
  int stops = 0;
  bool disposed = false, fail = false, failStop = false;
  Completer<void>? pending;
  @override
  Stream<PreviewAudioEvent> get events => controller.stream;
  @override
  Future<void> play(String id, String url) async {
    plays.add((id, url));
    if (fail) throw Exception('Offline playback failed');
    await pending?.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (failStop) throw Exception('Offline stop failed');
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    pending?.complete();
    pending = null;
    await controller.close();
  }
}
