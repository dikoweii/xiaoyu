import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import '../presentation/controllers.dart';
import 'core/design.dart';
import 'core/widgets.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final keyInput = TextEditingController(), nickname = TextEditingController();
  bool remember = true, sameAccount = false, obscure = true, busy = false;
  @override
  void initState() {
    super.initState();
    final controller = ref.read(controllerProvider);
    remember = controller.hasCredential ? controller.remembered : true;
    unawaited(
      controller.nickname().then((v) {
        if (mounted) nickname.text = v ?? '';
      }),
    );
  }

  @override
  void dispose() {
    keyInput.clear();
    keyInput.dispose();
    nickname.dispose();
    super.dispose();
  }

  Future<void> _work(Future<void> Function() work) async {
    setState(() => busy = true);
    await guarded(context, work);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, controller = ref.read(controllerProvider);
    return AppPage(
      title: s.account,
      body: PageBody(
        children: [
          AppField(
            key: const Key('nickname-input'),
            controller: nickname,
            label: s.nickname,
          ),
          gap(20),
          Text(controller.hasCredential ? s.keyConfigured : s.keyMissing),
          gap(12),
          AppField(
            key: const Key('key-input'),
            controller: keyInput,
            label: s.key,
            hint: s.keyHint,
            password: true,
          ),
          gap(12),
          AppToggle(
            title: Text(s.rememberKey),
            value: remember,
            onChanged: busy ? null : (v) => setState(() => remember = v),
          ),
          if (controller.hasCredentialProfile)
            AppToggle(
              title: Text(s.sameAccount),
              subtitle: Text(s.sameAccountHint),
              value: sameAccount,
              onChanged: busy ? null : (v) => setState(() => sameAccount = v),
            ),
          gap(12),
          AppButton(
            onPressed: busy
                ? null
                : () => _work(() async {
                    await controller.checkKey(keyInput.text);
                    if (context.mounted) notice(context, s.keyChecked);
                  }),
            child: Text(s.checkKey),
          ),
          gap(12),
          AppButton(
            key: const Key('account-save'),
            primary: true,
            onPressed: busy
                ? null
                : () => _work(() async {
                    await controller.saveAccount(
                      nickname.text,
                      keyInput.text,
                      remember: remember,
                      sameAccount: sameAccount,
                    );
                    keyInput.clear();
                    if (mounted) {
                      setState(() {});
                      if (context.mounted) notice(context, s.saved);
                    }
                  }),
            child: Text(s.save),
          ),
          if (busy) const AppLoading(),
          gap(24),
          Text(s.clearKeyHint),
          gap(12),
          AppButton(
            destructive: true,
            onPressed: busy
                ? null
                : () => _work(() async {
                    if (!await confirm(
                      context,
                      s.clearKey,
                      s.clearKeyHint,
                      destructive: true,
                    )) {
                      return;
                    }
                    await controller.clearKey();
                    if (mounted) setState(() {});
                  }),
            child: Text(s.clearKey),
          ),
        ],
      ),
    );
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  Character? character;
  final name = TextEditingController(),
      persona = TextEditingController(),
      summary = TextEditingController(),
      greeting = TextEditingController();
  bool busy = false, dirty = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await guarded(context, () async {
      final controller = ref.read(controllerProvider);
      final c = widget.id == 'new'
          ? controller.newCharacter()
          : await controller.character(widget.id);
      if (!mounted || c == null) return;
      name.text = c.name;
      persona.text = c.persona;
      summary.text = c.summary;
      greeting.text = c.greeting;
      setState(() => character = c);
      if (widget.id == 'new') await controller.saveCharacter(c);
    });
  }

  Character get draft => character!.copyWith(
    name: name.text.trim(),
    persona: persona.text,
    summary: summary.text.trim(),
    greeting: greeting.text.trim(),
  );
  Future<void> _work(Future<void> Function() work) async {
    setState(() => busy = true);
    await guarded(context, work);
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() {
    name.dispose();
    persona.dispose();
    summary.dispose();
    greeting.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s,
        controller = ref.read(controllerProvider),
        c = character;
    return PopScope(
      canPop: !dirty && !busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || busy || c == null) return;
        if (await confirm(context, s.saveDraft, s.unsavedDraft)) {
          await controller.saveCharacter(draft);
          if (context.mounted) {
            setState(() => dirty = false);
            context.pop();
          }
        }
      },
      child: AppPage(
        title: s.createTitle,
        body: c == null
            ? const Center(child: AppLoading())
            : PageBody(
                children: [
                  AppSurface(
                    color: XiaoyuDesign.surface,
                    radius: 24,
                    padding: const EdgeInsets.all(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 154),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 64,
                            width: 64,
                            child: Portrait(c, height: 64),
                          ),
                          gap(6),
                          AppButton(
                            plain: true,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 18,
                            ),
                            onPressed: busy
                                ? null
                                : () => _work(() async {
                                    final updated = await controller
                                        .choosePhoto(draft);
                                    if (mounted) {
                                      setState(() => character = updated);
                                    }
                                  }),
                            child: Text(s.uploadPhoto),
                          ),
                        ],
                      ),
                    ),
                  ),
                  gap(6),
                  Text(
                    s.photoHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  gap(18),
                  AppField(
                    key: const Key('character-name'),
                    controller: name,
                    label: '${s.characterName} *',
                    maxLength: 30,
                    onChanged: (_) => setState(() => dirty = true),
                  ),
                  gap(16),
                  _personaField(),
                  gap(16),
                  Row(
                    children: [
                      Expanded(child: Text(s.knowledge)),
                      const Text(
                        'Beta',
                        style: TextStyle(
                          fontSize: 10,
                          color: XiaoyuDesign.lavender,
                        ),
                      ),
                    ],
                  ),
                  gap(6),
                  AppButton(
                    key: const Key('knowledge-entry'),
                    onPressed: () => notice(context, s.knowledgeUnavailable),
                    icon: const Icon(Icons.upload_file, size: 18),
                    child: Text(s.chooseDocument),
                  ),
                  gap(4),
                  Text(
                    s.knowledgeUnavailable,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  gap(16),
                  AppSurface(
                    radius: 16,
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      key: const Key('choose-voice'),
                      title: Text(s.voice),
                      subtitle: Text(c.voice),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: busy
                          ? null
                          : () async {
                              final voice = await chooseVoice(context, c.voice);
                              if (voice != null && mounted) {
                                setState(() {
                                  character = character!.copyWith(voice: voice);
                                  dirty = true;
                                });
                              }
                            },
                    ),
                  ),
                  gap(16),
                  AppButton(
                    key: const Key('editor-save'),
                    primary: true,
                    onPressed: busy
                        ? null
                        : () => _work(() async {
                            await controller.saveCharacter(
                              draft,
                              validate: true,
                            );
                            if (context.mounted) {
                              setState(() => dirty = false);
                              context.pop();
                            }
                          }),
                    child: Text(s.submit),
                  ),
                  gap(8),
                  AppButton(
                    key: const Key('advanced-settings'),
                    plain: true,
                    onPressed: busy ? null : _advanced,
                    child: Text(s.advancedSettings),
                  ),
                  if (busy) const AppLoading(),
                ],
              ),
      ),
    );
  }

  Widget _personaField() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              context.s.persona,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: persona,
            builder: (_, value, _) => Text(
              '${value.text.characters.length}/50000',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      gap(6),
      TextField(
        key: const Key('persona-input'),
        controller: persona,
        minLines: 4,
        maxLines: 8,
        inputFormatters: [LengthLimitingTextInputFormatter(50000)],
        onChanged: (_) => setState(() => dirty = true),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(hintText: context.s.personaHint),
      ),
    ],
  );

  Future<void> _advanced() async {
    final controller = ref.read(controllerProvider);
    await sheet<void>(
      context,
      StatefulBuilder(
        builder: (panelContext, refreshPanel) {
          final s = panelContext.s, c = character!;
          Future<void> work(Future<void> Function() command) async {
            final pending = _work(command);
            refreshPanel(() {});
            await pending;
            if (panelContext.mounted) refreshPanel(() {});
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.advancedSettings,
                      style: Theme.of(panelContext).textTheme.titleLarge,
                    ),
                  ),
                  AppIconButton(
                    key: const Key('advanced-close'),
                    icon: const Icon(Icons.close),
                    label: s.close,
                    onPressed: busy
                        ? null
                        : () => Navigator.of(panelContext).pop(),
                  ),
                ],
              ),
              gap(16),
              AppField(
                key: const Key('summary-input'),
                controller: summary,
                label: s.summary,
                maxLength: 180,
                onChanged: (_) => setState(() => dirty = true),
              ),
              gap(16),
              AppField(
                key: const Key('greeting-input'),
                controller: greeting,
                label: s.greeting,
                maxLength: 200,
                onChanged: (_) => setState(() => dirty = true),
              ),
              AppToggle(
                title: Text(s.memory),
                subtitle: Text(s.memoryHint),
                value: c.memory,
                onChanged: busy
                    ? null
                    : (v) {
                        setState(() {
                          character = c.copyWith(memory: v);
                          dirty = true;
                        });
                        refreshPanel(() {});
                      },
              ),
              Text(s.status(c.assetStatus)),
              gap(12),
              AppButton(
                onPressed: busy ? null : () => work(_existing),
                child: Text(s.existingAvatars),
              ),
              gap(8),
              if (c.avatarId.isEmpty || c.assetStatus == 'failed')
                AppButton(
                  onPressed: busy
                      ? null
                      : () => work(() async {
                          final v = await controller.upload(draft);
                          if (mounted) setState(() => character = v);
                        }),
                  child: Text(s.uploadAvatar),
                ),
              if (c.avatarId.isNotEmpty)
                AppButton(
                  onPressed: busy
                      ? null
                      : () => work(() async {
                          final v = await controller.refresh(draft);
                          if (mounted) setState(() => character = v);
                        }),
                  child: Text(s.refresh),
                ),
              gap(16),
              AppButton(
                key: const Key('draft-save'),
                primary: true,
                onPressed: busy
                    ? null
                    : () => work(() async {
                        await controller.saveCharacter(draft);
                        if (mounted) setState(() => dirty = false);
                        if (panelContext.mounted) {
                          Navigator.of(panelContext).pop();
                        }
                        if (mounted) context.pop();
                      }),
                child: Text(s.saveDraft),
              ),
              if (busy) const AppLoading(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _existing() async {
    final controller = ref.read(controllerProvider);
    final assets = await controller.existing();
    if (!mounted) return;
    final selected = await sheet<Json>(context, AssetPicker(assets: assets));
    if (selected == null) return;
    final updated = await controller.selectAsset(draft, selected);
    if (mounted) setState(() => character = updated);
  }
}

class AssetPicker extends ConsumerWidget {
  const AssetPicker({super.key, required this.assets});
  final List<Json> assets;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      section(context, context.s.existingAvatars),
      if (assets.isEmpty) Text(context.s.noAvatars),
      for (final a in assets)
        ListTile(
          title: Text('${a['name'] ?? a['id']}'),
          subtitle: Text(
            context.s.status(
              ref.read(controllerProvider).assetStatus(a['status']),
            ),
          ),
          onTap: () => Navigator.of(context).pop(a),
        ),
    ],
  );
}

Future<String?> chooseVoice(BuildContext context, String selected) =>
    sheet<String>(context, VoicePicker(selected: selected));

class VoicePicker extends StatefulWidget {
  const VoicePicker({super.key, required this.selected});
  final String selected;
  @override
  State<VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends State<VoicePicker> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.voice,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppIconButton(
              key: const Key('voice-close'),
              icon: const Icon(Icons.close, size: 18),
              label: s.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        gap(8),
        Wrap(
          spacing: 8,
          children: [
            for (final label in [
              s.voiceMine,
              s.voiceAll,
              s.voiceMale,
              s.voiceFemale,
            ])
              SizedBox(
                width: 68,
                child: AppButton(
                  plain: label != s.voiceAll,
                  accent: label == s.voiceAll,
                  onPressed: label == s.voiceAll
                      ? () {}
                      : () => notice(context, s.comingSoon),
                  child: Text(label),
                ),
              ),
          ],
        ),
        gap(12),
        for (final entry in const [
          ('Serena', Color(0xFF89718D)),
          ('Cherry', Color(0xFF467B77)),
          ('Chelsie', Color(0xFF9E585F)),
          ('Ethan', Color(0xFF556B99)),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppSurface(
              accent: entry.$1 == widget.selected,
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Voice preview is unavailable; this is decorative artwork.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [entry.$2, XiaoyuDesign.blush],
                      ),
                    ),
                    child: const Icon(Icons.graphic_eq, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.$1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          s.voiceStyle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: MediaQuery.textScalerOf(context).scale(1) > 1.5
                        ? 100
                        : 80,
                    child: AppButton(
                      accent: entry.$1 == widget.selected,
                      onPressed: () => Navigator.of(context).pop(entry.$1),
                      child: Text(
                        entry.$1 == widget.selected ? s.chosen : s.choose,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Text(
          s.voicePreviewUnavailable,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
