import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/data/services/voice_preview_audio.dart';
import 'package:xiaoyu/domain/voice_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native adapter uses supplied URL, reports completion and releases player',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const codec = StandardMethodCodec();
      final calls = <MethodCall>[];
      final channels = <String>[];
      const native = MethodChannel('xyz.luan/audioplayers');
      const global = MethodChannel('xyz.luan/audioplayers.global');
      Future<void> event(String id, Object payload) async {
        await messenger.handlePlatformMessage(
          'xyz.luan/audioplayers/events/$id',
          codec.encodeSuccessEnvelope(payload),
          (_) {},
        );
      }

      messenger.setMockMethodCallHandler(global, (_) async => null);
      messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global/events'),
        (_) async => null,
      );
      messenger.setMockMethodCallHandler(native, (call) async {
        calls.add(call);
        final args = call.arguments as Map<dynamic, dynamic>;
        final id = args['playerId'] as String;
        if (call.method == 'create') {
          final channel = 'xyz.luan/audioplayers/events/$id';
          channels.add(channel);
          messenger.setMockMethodCallHandler(
            MethodChannel(channel),
            (_) async => null,
          );
        }
        if (call.method == 'setSourceUrl') {
          scheduleMicrotask(
            () => event(id, {'event': 'audio.onPrepared', 'value': true}),
          );
        }
        if (call.method == 'getCurrentPosition' ||
            call.method == 'getDuration') {
          return 0;
        }
        return null;
      });
      addTearDown(() {
        for (final name in [
          ...channels,
          native.name,
          global.name,
          'xyz.luan/audioplayers.global/events',
        ]) {
          messenger.setMockMethodCallHandler(MethodChannel(name), null);
        }
      });
      final audio = VoicePreviewAudio();
      final events = <PreviewAudioEvent>[];
      final subscription = audio.events.listen(events.add);
      await audio.play('vivi', 'https://example.invalid/vivi.wav');
      final source =
          calls.singleWhere((c) => c.method == 'setSourceUrl').arguments
              as Map<dynamic, dynamic>;
      expect(source['url'], 'https://example.invalid/vivi.wav');
      expect(source['isLocal'], isFalse);
      final id = source['playerId'] as String;
      await event(id, {'event': 'audio.onComplete'});
      await Future<void>.delayed(Duration.zero);
      expect(events.single.id, 'vivi');
      await audio.stop();
      expect(
        calls.map((c) => c.method),
        containsAllInOrder([
          'create',
          'setAudioContext',
          'setSourceUrl',
          'resume',
          'stop',
          'release',
          'dispose',
        ]),
      );
      await audio.dispose();
      await subscription.cancel();
    },
  );
}
