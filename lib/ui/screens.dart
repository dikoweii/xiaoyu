import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import '../domain/official_character.dart';
import '../presentation/controllers.dart';
import 'core/design.dart';
import 'core/widgets.dart';
import 'core/portrait_tile.dart';
import 'call_history.dart';
import 'character_menu.dart';

export 'account_editor.dart';
export 'call_history.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final call =
        ref.watch(callProvider).value ??
        ref.read(controllerProvider).calls.snapshot;
    return AppPage(
      body: IndexedStack(index: tab, children: const [HomePanel(), MePanel()]),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (call.active)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AppButton(
                plain: true,
                onPressed: () => context.push('/call'),
                child: Text(context.s.returnToCall),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(1) > 1.5;
              final width = large ? constraints.maxWidth - 40 : 270.0;
              final reduced = MediaQuery.disableAnimationsOf(context);
              final height = large ? 88.0 : 60.0;
              return SizedBox(
                height: height,
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      child: LiquidGlassTabBar(
                        key: const Key('home-tabs'),
                        width: width,
                        height: height,
                        margin: EdgeInsets.zero,
                        selectedIndex: tab,
                        onChanged: (index) => setState(() => tab = index),
                        style: LiquidGlassTabBar.defaultStyle.copyWith(
                          color: const Color(0x6617191F),
                          liteGlass:
                              reduced || MediaQuery.highContrastOf(context),
                        ),
                        swell: reduced ? null : const LiquidGlassTabBarSwell(),
                        pillStyle: LiquidGlassTabPillStyle(
                          mode: reduced
                              ? LiquidGlassPillMode.none
                              : LiquidGlassPillMode.impellerOnly,
                          color: const Color(0x30C2B7FF),
                        ),
                        itemStyle: const LiquidGlassTabItemStyle(
                          selectedColor: XiaoyuDesign.lavender,
                          unselectedColor: XiaoyuDesign.muted,
                          iconSize: 22,
                          labelFontSize: 12,
                        ),
                        items: [
                          LiquidGlassTabBarItem(
                            icon: CupertinoIcons.house,
                            selectedIcon: CupertinoIcons.house_fill,
                            label: context.s.home,
                          ),
                          LiquidGlassTabBarItem(
                            icon: CupertinoIcons.person,
                            selectedIcon: CupertinoIcons.person_fill,
                            label: context.s.me,
                          ),
                        ],
                      ),
                    ),
                    // One accessible target per tab; optical layers may draw labels twice.
                    Align(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: Row(
                          children: [
                            for (var index = 0; index < 2; index++)
                              Expanded(
                                child: Semantics(
                                  key: Key('tab-accessibility-$index'),
                                  container: true,
                                  button: true,
                                  selected: tab == index,
                                  label: index == 0
                                      ? context.s.home
                                      : context.s.me,
                                  onTap: () => setState(() => tab = index),
                                  child: Listener(
                                    key: Key('tab-$index'),
                                    behavior: HitTestBehavior.translucent,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomePanel extends ConsumerWidget {
  const HomePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final characters = ref.watch(charactersProvider);
    return PageBody(
      bottom: 120,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    s.brandLine,
                    style: const TextStyle(
                      fontSize: 12,
                      color: XiaoyuDesign.muted,
                    ),
                  ),
                ],
              ),
            ),
            AppIconButton(
              key: const Key('create-character'),
              icon: const Icon(Icons.add, size: 24),
              label: s.createCharacter,
              onPressed: () => context.push('/edit/new'),
            ),
          ],
        ),
        gap(16),
        AppSurface(
          color: const Color(0xFF1A1C24),
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSurface(
                      accent: true,
                      radius: 999,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        s.bannerBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          color: XiaoyuDesign.lavender,
                        ),
                      ),
                    ),
                    gap(5),
                    Text(
                      s.bannerTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    gap(3),
                    Text(
                      s.bannerBody,
                      style: const TextStyle(
                        fontSize: 12,
                        color: XiaoyuDesign.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                child: characters.value?.firstOrNull != null
                    ? Portrait(characters.value!.first, height: 80)
                    : const Icon(
                        Icons.auto_awesome,
                        size: 44,
                        color: XiaoyuDesign.lavender,
                      ),
              ),
            ],
          ),
        ),
        gap(20),
        _SectionHeading(
          s.myCharacters,
          trailing: Text(
            s.characterCount(characters.value?.length ?? 0),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        gap(12),
        characters.when(
          loading: () => const Center(child: AppLoading()),
          error: (_, _) => Text(s.error('storage')),
          data: (items) => items.isEmpty
              ? Text(
                  s.noCharacters,
                  style: const TextStyle(color: XiaoyuDesign.muted),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: 300,
                      child: ListView.separated(
                        key: const PageStorageKey('my-characters-carousel'),
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: (constraints.maxWidth * .64).clamp(
                              180.0,
                              240.0,
                            ),
                          ),
                          child: _CharacterCard(items[index]),
                        ),
                      ),
                    );
                  },
                ),
        ),
        gap(24),
        _SectionHeading(s.recommended),
        gap(8),
        ref
            .watch(officialCatalogProvider)
            .when(
              loading: () => const Center(child: AppLoading()),
              error: (_, _) => Text(s.error('network')),
              data: (roles) => roles.isEmpty
                  ? AppSurface(
                      child: Text(
                        s.noAvatars,
                        style: const TextStyle(color: XiaoyuDesign.muted),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 340 &&
                                MediaQuery.textScalerOf(context).scale(1) < 1.5
                            ? 2
                            : 1;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final role in roles)
                              SizedBox(
                                width:
                                    (constraints.maxWidth -
                                        14 * (columns - 1)) /
                                    columns,
                                child: _OfficialRoleCard(role),
                              ),
                          ],
                        );
                      },
                    ),
            ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      ?trailing,
    ],
  );
}

class _OfficialRoleCard extends ConsumerWidget {
  const _OfficialRoleCard(this.role);
  final Json role;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = OfficialCharacter(role);
    return PortraitTile(
      key: Key('official-${template.id}'),
      image: template.imageUrl.isEmpty ? null : NetworkImage(template.imageUrl),
      name: template.name,
      description: template.description,
      onTap: () => guarded(context, () async {
        final character = await ref
            .read(controllerProvider)
            .createOfficialCharacter(role);
        if (context.mounted) unawaited(context.push('/edit/${character.id}'));
      }),
    );
  }
}

class _CharacterCard extends ConsumerWidget {
  const _CharacterCard(this.character);
  final Character character;

  Future<void> _chat(BuildContext context, WidgetRef ref) =>
      guarded(context, () async {
        final controller = ref.read(controllerProvider);
        if (controller.calls.snapshot.active) {
          unawaited(context.push('/call'));
          return;
        }
        if (!controller.hasCredential) {
          unawaited(context.push('/account'));
          return;
        }
        if (!character.ready) {
          unawaited(context.push('/edit/${character.id}'));
          return;
        }
        if (!await confirm(
          context,
          context.s.callCostTitle,
          context.s.callCostBody,
        )) {
          return;
        }
        if (!context.mounted) return;
        unawaited(controller.start(character));
        unawaited(context.push('/call'));
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) => PortraitTile(
    key: Key('character-image-${character.id}'),
    actionLabel: '${context.s.chat} · ${character.name}',
    image: portraitImage(character, ref.read(controllerProvider)),
    name: character.name,
    description: character.summary.isEmpty
        ? context.s.status(character.assetStatus)
        : character.summary,
    onTap: () => _chat(context, ref),
    menu: CharacterMenu(
      onSelected: (action) {
        if (action == CharacterMenuAction.edit) {
          unawaited(context.push('/edit/${character.id}'));
        } else {
          unawaited(
            guarded(context, () async {
              if (!await confirm(
                context,
                context.s.delete,
                context.s.localDeleteHint,
                destructive: true,
              )) {
                return;
              }
              await ref.read(controllerProvider).deleteCharacter(character.id);
            }),
          );
        }
      },
    ),
  );
}

final _nicknameProvider = FutureProvider(
  (ref) => ref.watch(controllerProvider).nickname(),
);

class MePanel extends ConsumerWidget {
  const MePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return PageBody(
      bottom: 120,
      horizontal: 16,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppIconButton(
            icon: const Icon(Icons.settings_outlined, size: 21),
            label: s.settings,
            onPressed: () => context.push('/settings'),
          ),
        ),
        Center(
          child: SizedBox(
            width: 88,
            height: 88,
            child: AppSurface(
              accent: true,
              radius: 999,
              child: const Center(
                child: Text(
                  '遇',
                  style: TextStyle(fontSize: 28, color: XiaoyuDesign.lavender),
                ),
              ),
            ),
          ),
        ),
        gap(12),
        Text(
          ref.watch(_nicknameProvider).value ?? s.localProfile,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        gap(4),
        Text(
          s.profileSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: XiaoyuDesign.muted),
        ),
        gap(24),
        Row(
          children: [
            Expanded(
              child: Text(
                s.history,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              key: const Key('view-all-history'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () => context.push('/history'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.viewAll,
                    style: const TextStyle(
                      fontSize: 12,
                      color: XiaoyuDesign.muted,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 12,
                    color: XiaoyuDesign.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        ref
            .watch(historyProvider)
            .when(
              data: (records) => Column(
                children: [
                  if (records.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        s.noHistory,
                        style: const TextStyle(color: XiaoyuDesign.muted),
                      ),
                    ),
                  for (final record in records.take(4)) CallTile(record),
                ],
              ),
              loading: () => const Center(child: AppLoading()),
              error: (_, _) => Text(s.error('storage')),
            ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppPage(
    title: context.s.settings,
    body: PageBody(
      children: [
        AppSurface(
          padding: EdgeInsets.zero,
          child: ListTile(
            title: Text(context.s.account),
            leading: const Icon(Icons.key_outlined, size: 22),
            trailing: const Icon(Icons.chevron_right),
            subtitle: Text(
              ref.watch(controllerProvider).hasCredential
                  ? context.s.keyConfigured
                  : context.s.keyMissing,
            ),
            onTap: () => context.push('/account'),
          ),
        ),
        section(context, context.s.privacy),
        Text(context.s.privacyBody),
        gap(28),
        Text(context.s.about),
      ],
    ),
  );
}
