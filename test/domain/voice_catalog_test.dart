import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/domain/models.dart';
import 'package:xiaoyu/domain/voice_catalog.dart';

void main() {
  test('media exactly matches each supplied provider mapping', () {
    final media = jsonDecode(
      File('tool/voice_catalog/doubao_media.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final ali = jsonDecode(
      File('tool/voice_catalog/ali_media.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(ali, hasLength(56));
    for (final voice in officialVoices) {
      if (voice.provider == VoiceProvider.qwenOmni) {
        expect(
          voice.trialUrl,
          (ali[voice.id] as Map<String, dynamic>)['TrialURL'],
        );
        expect(Uri.parse(voice.trialUrl).scheme, 'https');
        expect(voice.avatarUrl, isEmpty);
      } else {
        final match = media[voice.id] as Map<String, dynamic>;
        expect(voice.trialUrl, match['TrialURL']);
        expect(voice.avatarUrl, match['Avatar']);
        expect(Uri.parse(voice.trialUrl).scheme, 'https');
        expect(Uri.parse(voice.avatarUrl).scheme, 'https');
      }
    }
  });
  const character = Character(
    id: 'role',
    name: 'Role',
    persona: 'Persona',
    avatarId: 'asset',
    assetStatus: 'success',
  );

  test(
    'every official realtime voice has a unique compatible request mapping',
    () {
      expect(
        officialVoices.where((v) => v.provider == VoiceProvider.qwenOmni),
        hasLength(56),
      );
      expect(
        officialVoices.where((v) => v.provider == VoiceProvider.doubao),
        hasLength(293),
      );
      final ids = <String>{};
      for (final voice in officialVoices) {
        expect(ids.add('${voice.provider.apiValue}:${voice.id}'), isTrue);
        expect(voice.name, isNotEmpty);
        expect(voice.description, isNotEmpty);
        expect(voice.languages, contains(voice.languageSummary));
        final c = character.copyWith(
          voice: voice.id,
          voiceProvider: voice.provider,
        );
        final restored = Character.fromJson(c.toJson());
        expect(restored.voiceProvider, voice.provider);
        final body = buildSession(restored, 'profile');
        expect(body['voice_model'], {'provider': voice.provider.apiValue});
        expect(body['avatar']['voice'], voice.id);
        expect(voice.selection.id, voice.id);
        expect(voice.selection.provider, voice.provider);
      }
      expect(voiceCatalogDate, '2026-11-17');
      expect(voiceCatalogSource, contains('/voice-list'));
      expect(voiceCatalogDigest, hasLength(64));
    },
  );

  test(
    'legacy saved roles retain Qwen, stable IDs and their original voice',
    () {
      final old = character.copyWith(voice: 'Cherry').toJson()
        ..remove('voiceProvider');
      final restored = Character.fromJson(old);
      expect(restored.voice, 'Cherry');
      expect(restored.voiceProvider, VoiceProvider.qwenOmni);
      expect(buildSession(restored, 'profile')['voice_model'], {
        'provider': 'qwen_omni',
      });
      expect(isCompatibleVoice(VoiceProvider.qwenOmni, 'Chelsie'), isTrue);
      expect(findVoice(VoiceProvider.qwenOmni, 'Cherry'), isNull);
      expect(
        restored.copyWith(summary: 'Changed').voiceProvider,
        VoiceProvider.qwenOmni,
      );
    },
  );

  test(
    'unknown, wrong-provider and non-realtime voices are rejected locally',
    () {
      for (final bad in [
        character.copyWith(voice: 'zh_female_vv_uranus_bigtts'),
        character.copyWith(voiceProvider: VoiceProvider.doubao),
        character.copyWith(voice: 'male-qn-qingse'),
        character.copyWith(voice: 'not-a-voice'),
      ]) {
        expect(() => buildSession(bad, 'profile'), throwsA(isA<AppFailure>()));
      }
      expect(
        () => Character.fromJson({
          ...character.toJson(),
          'voiceProvider': 'unknown',
        }),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test(
    'search matches original names, exact IDs, languages and multiple keywords',
    () {
      final qwen = findVoice(VoiceProvider.qwenOmni, 'Serena')!;
      expect(qwen.matches('苏瑶'), isTrue);
      expect(qwen.matches(' SERENA 中文 '), isTrue);
      expect(qwen.matches('温柔'), isTrue);
      expect(qwen.matches('unlikely-keyword'), isFalse);
      expect(qwen.matches(''), isTrue);
      final doubao = findVoice(
        VoiceProvider.doubao,
        'zh_female_vv_uranus_bigtts',
      )!;
      expect(doubao.matches('vivi 日文'), isTrue);
    },
  );
}
