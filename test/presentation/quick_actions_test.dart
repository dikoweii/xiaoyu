import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaoyu/l10n/generated/app_localizations.dart';
import 'package:xiaoyu/presentation/quick_actions.dart';

void main() {
  test('catalog preserves all actions, with one canonical full category per action', () {
    final all = QuickActionCategory.values
        .skip(1)
        .expand((c) => c.actions)
        .toList();
    expect(QuickAction.values, hasLength(106));
    expect(all.toSet(), QuickAction.values.toSet());
    expect(all, hasLength(all.toSet().length));
    expect(QuickActionCategory.common.actions, [
      QuickAction.heart,
      QuickAction.wave,
      QuickAction.smile,
      QuickAction.nod,
      QuickAction.hug,
      QuickAction.blowKiss,
      QuickAction.peace,
      QuickAction.clap,
    ]);
    expect(QuickActionCategory.food.actions, hasLength(14));
    expect(
      QuickActionCategory.appearance.actions,
      contains(QuickAction.tuckHair),
    );
    expect(
      QuickActionCategory.expressions.actions,
      containsAll([
        QuickAction.wink,
        QuickAction.winkPeace,
        QuickAction.oneHandCheek,
        QuickAction.twoHandCheeks,
      ]),
    );
  });

  for (final locale in ['zh', 'en']) {
    test(
      'every $locale action has a unique label and compatible full command',
      () async {
        final s = await AppLocalizations.delegate.load(Locale(locale));
        final labels = <String>{};
        final prompts = <String>{};
        for (final action in QuickAction.values) {
          final label = s.quickActionName(action.name);
          final prompt = s.quickActionPrompt(action.name);
          expect(label.trim(), isNotEmpty, reason: action.name);
          expect(
            labels.add(label),
            isTrue,
            reason: 'Duplicate label: ${action.name}',
          );
          expect(prompt.trim(), isNotEmpty, reason: action.name);
          expect(
            prompt.runes.length,
            lessThanOrEqualTo(200),
            reason: action.name,
          );
          expect(
            prompts.add(prompt),
            isTrue,
            reason: 'Duplicate prompt: ${action.name}',
          );
        }
        for (final category in QuickActionCategory.values) {
          expect(s.quickActionCategory(category.name).trim(), isNotEmpty);
        }
        if (locale == 'zh') {
          expect(s.quickActionPrompt('milkTea'), '双手捧着奶茶杯，低头用吸管喝一口，再抬头微笑。');
          expect(s.quickActionPrompt('heart'), '双手在胸前比出爱心，面带微笑，注视镜头。');
          expect(
            s.quickActionPrompt('cuteSequence'),
            '依次做出歪头、眨眼、抿嘴笑、捧脸、轻耸肩、比心、伸手求抱和挥手八个撒娇小动作。',
          );
        }
      },
    );
  }
}
