import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/application/voice_preview.dart';
import 'package:xiaoyu/domain/voice_catalog.dart';
import 'package:xiaoyu/domain/voice_preview.dart';

import '../support/preview_audio.dart';

void main() {
  late FakePreviewAudio audio;
  late VoicePreviewController preview;
  final voices = officialVoices
      .where((v) => v.provider == VoiceProvider.doubao)
      .toList();
  setUp(() {
    audio = FakePreviewAudio();
    preview = VoicePreviewController(audio);
  });
  tearDown(() => preview.dispose());
  test(
    'only matching trial plays; same button stops; completion resets',
    () async {
      await preview.toggle(voices.first);
      expect(audio.plays.single, (voices.first.id, voices.first.trialUrl));
      expect(preview.state.id, voices.first.id);
      expect(preview.state.loading, isFalse);
      await preview.toggle(voices.first);
      expect(preview.state.id, isNull);
      await preview.toggle(voices[1]);
      audio.controller.add(PreviewAudioEvent(voices.first.id));
      expect(preview.state.id, voices[1].id);
      audio.controller.add(PreviewAudioEvent(voices[1].id));
      expect(preview.state.id, isNull);
    },
  );
  test(
    'rapid choices discard queued work and late preparation after stop',
    () async {
      audio.pending = Completer<void>();
      final first = preview.toggle(voices.first);
      await Future<void>.delayed(Duration.zero);
      expect(preview.state.loading, isTrue);
      final second = preview.toggle(voices[1]);
      final third = preview.toggle(voices[2]);
      audio.pending!.complete();
      audio.pending = null;
      await Future.wait([first, second, third]);
      expect(audio.plays.map((v) => v.$1), [voices.first.id, voices[2].id]);
      expect(preview.state.id, voices[2].id);
      audio.pending = Completer<void>();
      final loading = preview.toggle(voices[1]);
      await Future<void>.delayed(Duration.zero);
      await preview.stop();
      audio.pending!.complete();
      audio.pending = null;
      await loading;
      expect(preview.state.id, isNull);
    },
  );
  test('failures reset and allow retry; missing URLs never play', () async {
    await preview.toggle(
      const VoiceOption(
        provider: VoiceProvider.qwenOmni,
        id: 'no-preview',
        name: 'No preview',
        description: '',
        languages: '',
        languageSummary: '',
      ),
    );
    expect(audio.plays, isEmpty);
    audio.fail = true;
    await preview.toggle(voices.first);
    expect(preview.state.failed, isTrue);
    audio.fail = false;
    await preview.toggle(voices.first);
    expect(preview.state.failed, isFalse);
    audio.controller.add(PreviewAudioEvent(voices.first.id, failed: true));
    expect(preview.state.failed, isTrue);
    audio.failStop = true;
    await preview.stop();
    expect(preview.state.failed, isTrue);
    await preview.toggle(voices.first);
    expect(preview.state.failed, isTrue);
  });
  test(
    'dispose cancels pending playback and ignores subsequent commands',
    () async {
      audio.pending = Completer<void>();
      final pending = preview.toggle(voices.first);
      await Future<void>.delayed(Duration.zero);
      await preview.dispose();
      await pending;
      await preview.toggle(voices[1]);
      expect(audio.disposed, isTrue);
      expect(audio.plays, hasLength(1));
    },
  );
}
