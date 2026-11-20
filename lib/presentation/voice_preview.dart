import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/painting.dart';

import '../application/voice_preview.dart';
import '../data/services/voice_preview_audio.dart';
import '../domain/voice_preview.dart';

final previewAudioFactoryProvider = Provider<PreviewAudio Function()>(
  (ref) => VoicePreviewAudio.new,
);
final voiceAvatarProvider = Provider<ImageProvider<Object> Function(String)>(
  (ref) => NetworkImage.new,
);
final voicePreviewProvider = Provider.autoDispose
    .family<VoicePreviewController, Object>((ref, key) {
      final controller = VoicePreviewController(
        ref.watch(previewAudioFactoryProvider)(),
      );
      ref.onDispose(() => unawaited(controller.dispose()));
      return controller;
    });
final voicePreviewStateProvider = StreamProvider.autoDispose
    .family<VoicePreviewState, Object>((ref, key) {
      return ref.watch(voicePreviewProvider(key)).changes;
    });
