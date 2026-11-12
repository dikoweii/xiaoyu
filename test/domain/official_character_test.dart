import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/domain/official_character.dart';

import '../support/fixture.dart';

void main() {
  test(
    'selected profile supplies photo and description, with a local draft ID',
    () {
      final role = OfficialCharacter(officialCompanion);
      final draft = role.draft('local-draft');
      expect(draft.id, 'local-draft');
      expect(draft.officialRoleId, 'offline-role-1');
      expect(draft.name, '离线角色 A');
      expect(draft.sourceImageUrl, 'https://example.invalid/profile.png');
      expect(draft.summary, '一起分享生活的小事。');
      expect(draft.persona, contains('温柔耐心的朋友。'));
      for (final value in ['温柔；耐心', '喜欢阅读', '自然亲切', '耐心倾听', '生活小技巧']) {
        expect(draft.persona, contains(value));
      }
      expect(draft.avatarId, isEmpty);
      expect(draft.ready, isFalse);
      expect(draft.voice, 'Serena');
    },
  );
  test(
    'explicit prompt fields take precedence over derived character details',
    () {
      for (final key in [
        'persona',
        'system_prompt',
        'system_prompt_override',
      ]) {
        final data = <String, dynamic>{...officialCompanion, key: ' 原始提示词 '};
        expect(OfficialCharacter(data).persona, '原始提示词');
      }
      expect(
        OfficialCharacter({
          'persona': 'p',
          'system_prompt': 's',
          'system_prompt_override': 'o',
        }).persona,
        'o',
      );
    },
  );
  test(
    'missing and malformed optional website data never invent user details',
    () {
      final role = OfficialCharacter({
        'image_uri': 'https://example.invalid/original.png',
        'profile_photos': [
          null,
          {'uri': ''},
        ],
        'attrs': {
          'identity_and_occupation': '老师',
          'language_style': [null, '简明'],
        },
      });
      expect(role.id, isEmpty);
      expect(role.name, isEmpty);
      expect(role.description, isEmpty);
      expect(role.imageUrl, 'https://example.invalid/original.png');
      expect(role.persona, '身份与职业：老师\n\n说话风格：简明');
      expect(
        OfficialCharacter({'attrs': 'invalid', 'profile_photos': 'invalid'})
            .persona,
        isEmpty,
      );
      expect(OfficialCharacter({}).imageUrl, isEmpty);
    },
  );
}
