import 'dart:async';

import '../domain/voice_catalog.dart';
import '../domain/voice_preview.dart';

class VoicePreviewState {
  const VoicePreviewState({this.id, this.loading = false, this.failed = false});
  final String? id;
  final bool loading, failed;
}

class VoicePreviewController {
  VoicePreviewController(this._audio) {
    _subscription = _audio.events.listen((event) {
      if (!_disposed && event.id == state.id) {
        _emit(VoicePreviewState(failed: event.failed));
      }
    });
  }
  final PreviewAudio _audio;
  late final StreamSubscription<PreviewAudioEvent> _subscription;
  final _changes = StreamController<VoicePreviewState>.broadcast(sync: true);
  Stream<VoicePreviewState> get changes => _changes.stream;
  VoicePreviewState state = const VoicePreviewState();
  Future<void> _queue = Future.value();
  int _revision = 0;
  bool _disposed = false;

  void _emit(VoicePreviewState next) {
    if (_disposed) return;
    state = next;
    _changes.add(next);
  }

  Future<void> toggle(VoiceOption voice) {
    if (_disposed || voice.trialUrl.isEmpty) return Future.value();
    if (state.id == voice.id) return stop();
    final revision = ++_revision;
    _emit(VoicePreviewState(id: voice.id, loading: true));
    // Cancel a pending network preparation immediately, before the next play.
    final cancelled = _audio.stop().then<Exception?>(
      (_) => null,
      onError: (Object e) {
        if (e is Exception) return e;
        throw e;
      },
    );
    _queue = _queue.then((_) async {
      try {
        final failure = await cancelled;
        if (failure != null) throw failure;
        if (_disposed || revision != _revision) return;
        await _audio.play(voice.id, voice.trialUrl);
        if (!_disposed && revision == _revision && state.id == voice.id) {
          _emit(VoicePreviewState(id: voice.id));
        }
      } on Exception {
        if (!_disposed && revision == _revision) {
          try {
            await _audio.stop();
          } on Exception {
            // The original playback failure is what the user needs to see.
          }
          if (!_disposed && revision == _revision) {
            _emit(const VoicePreviewState(failed: true));
          }
        }
      }
    });
    return _queue;
  }

  Future<void> stop() async {
    ++_revision;
    _emit(const VoicePreviewState());
    try {
      await _audio.stop();
    } on Exception {
      _emit(const VoicePreviewState(failed: true));
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_revision;
    try {
      await Future.wait([_subscription.cancel(), _audio.dispose(), _queue]);
    } on Exception {
      // Disposal cannot show an error after the picker is gone.
    } finally {
      await _changes.close();
    }
  }
}
