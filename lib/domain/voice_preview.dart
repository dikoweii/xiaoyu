class PreviewAudioEvent {
  const PreviewAudioEvent(this.id, {this.failed = false});
  final String id;
  final bool failed;
}

abstract interface class PreviewAudio {
  Stream<PreviewAudioEvent> get events;
  Future<void> play(String id, String url);
  Future<void> stop();
  Future<void> dispose();
}
