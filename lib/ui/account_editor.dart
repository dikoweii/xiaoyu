import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import '../presentation/controllers.dart';
import 'core/design.dart';
import 'core/widgets.dart';
import 'voice_picker.dart';

export 'voice_picker.dart';

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

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  Character? character;
  Character? _preparingImage;
  String? _editId;
  ScreenController? _controller;
  bool _closed = false, _leaving = false, _confirming = false;
  bool _assetSelectionChanged = false;
  Character? _savedForm;
  bool _foreground = true;
  final name = TextEditingController(),
      persona = TextEditingController(),
      summary = TextEditingController(),
      greeting = TextEditingController();
  bool busy = false, dirty = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  Future<void> _load() async {
    await guarded(context, () async {
      final controller = ref.read(controllerProvider);
      _controller = controller;
      final c = widget.id == 'new'
          ? controller.newCharacter()
          : await controller.character(widget.id);
      if (!mounted || c == null) return;
      final editId = await controller.beginCharacterEdit(c);
      if (!mounted) {
        await controller.endCharacterEdit(editId, saved: false);
        return;
      }
      _editId = editId;
      _savedForm = c;
      name.text = c.name;
      persona.text = c.persona;
      summary.text = c.summary;
      greeting.text = c.greeting;
      setState(() => character = c);
      if (c.imagePath.isNotEmpty &&
          (c.assetStatus == 'uploading' ||
              c.avatarId.isNotEmpty &&
                  {'created', 'processing'}.contains(c.assetStatus))) {
        setState(() => _preparingImage = c);
      }
    });
  }

  Character get draft => character!.copyWith(
    name: name.text.trim(),
    persona: persona.text,
    summary: summary.text.trim(),
    greeting: greeting.text.trim(),
  );
  Future<void> _closeSaved() async {
    if (!mounted) return;
    await _endEdit(saved: true);
    if (!mounted) return;
    setState(() {
      dirty = false;
      busy = false;
      _leaving = true;
    });
    // Let PopScope observe the saved state before requesting navigation.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) context.pop();
  }

  Future<void> _endEdit({required bool saved}) async {
    if (_closed || _editId == null) return;
    _closed = true;
    await _controller!.endCharacterEdit(_editId!, saved: saved);
  }

  bool get _hasChanges {
    if (!dirty || character == null || _savedForm == null) return false;
    if (_assetSelectionChanged) return true;
    final current = draft.toJson(), saved = _savedForm!.toJson();
    // Remote preparation is progress, not an unsaved form change.
    for (final key in ['avatarId', 'assetStatus', 'credentialId']) {
      current.remove(key);
      saved.remove(key);
    }
    return !mapEquals(current, saved);
  }

  Future<void> _back() async {
    if (busy || _confirming || character == null) return;
    if (!_hasChanges) {
      await _endEdit(saved: false);
    } else {
      _confirming = true;
      FocusManager.instance.primaryFocus?.unfocus();
      final s = context.s;
      final choice = await confirmation<String>(
        context,
        s.unsavedChanges,
        s.unsavedDraft,
        actions: (dialogContext) => [
          TextButton(
            key: const Key('edit-continue'),
            onPressed: () => Navigator.of(dialogContext).pop('continue'),
            child: Text(s.continueEditing),
          ),
          TextButton(
            key: const Key('edit-discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: Text(s.discardChanges),
          ),
          TextButton(
            key: const Key('edit-save'),
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(s.saveDraft),
          ),
        ],
      );
      _confirming = false;
      if (!mounted || choice == null || choice == 'continue') return;
      if (choice == 'save') {
        await _work(() async {
          await _controller!.saveCharacter(draft, editId: _editId);
          await _closeSaved();
        });
        return;
      }
      await _endEdit(saved: false);
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) context.pop();
  }

  Future<void> _work(Future<void> Function() work) async {
    setState(() => busy = true);
    await guarded(context, work);
    if (mounted) setState(() => busy = false);
  }

  @override
  void dispose() {
    unawaited(_endEdit(saved: false));
    WidgetsBinding.instance.removeObserver(this);
    name.dispose();
    persona.dispose();
    summary.dispose();
    greeting.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      setState(() => _foreground = state == AppLifecycleState.resumed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s,
        controller = ref.read(controllerProvider),
        c = character;
    AsyncValue<Character>? preparation;
    if (_foreground && _preparingImage != null) {
      final provider = avatarPreparationProvider((_preparingImage!, _editId!));
      preparation = ref.watch(provider);
      ref.listen(provider, (_, next) {
        final asset = next.asData?.value;
        if (asset == null || character?.imagePath != asset.imagePath) return;
        setState(
          () => character = character!.copyWith(
            avatarId: asset.avatarId,
            credentialId: asset.credentialId,
            assetStatus: asset.assetStatus,
          ),
        );
      });
    }
    return PopScope(
      canPop: _leaving || !_hasChanges && !busy,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _back();
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
                            key: const Key('upload-photo'),
                            plain: true,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 18,
                            ),
                            onPressed: busy
                                ? null
                                : () => _work(() async {
                                    final updated = await controller
                                        .choosePhoto(draft, editId: _editId);
                                    if (mounted) {
                                      setState(() {
                                        if (updated.imagePath !=
                                            character?.imagePath) {
                                          _preparingImage = updated;
                                          dirty = true;
                                        }
                                        character = updated;
                                      });
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
                  if (preparation != null && controller.hasCredential) ...[
                    gap(6),
                    Text(
                      preparation.when(
                        loading: () => s.status('uploading'),
                        error: (error, _) => s.error(
                          error is AppFailure ? error.code : 'network',
                        ),
                        data: (asset) => asset.assetStatus == 'failed'
                            ? s.error('avatarFailed')
                            : s.status(asset.assetStatus),
                      ),
                      key: const Key('photo-preparation-status'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                      subtitle: Text(
                        voiceSelectionLabel(context, c.voiceProvider, c.voice),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: busy
                          ? null
                          : () async {
                              final voice = await chooseVoice(
                                context,
                                c.voice,
                                provider: c.voiceProvider,
                              );
                              if (voice != null && mounted) {
                                setState(() {
                                  character = character!.copyWith(
                                    voice: voice.id,
                                    voiceProvider: voice.provider,
                                  );
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
                            final updated = await controller.submitCharacter(
                              draft,
                              editId: _editId,
                            );
                            if (context.mounted) {
                              setState(() {
                                character = updated;
                                dirty = false;
                                _savedForm = draft;
                                _assetSelectionChanged = false;
                              });
                              if (updated.ready) {
                                await _closeSaved();
                              } else {
                                notice(
                                  context,
                                  s.error(
                                    updated.assetStatus == 'failed'
                                        ? 'avatarFailed'
                                        : 'avatarProcessing',
                                  ),
                                );
                              }
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
              Text(
                s.advancedSettings,
                style: Theme.of(panelContext).textTheme.titleLarge,
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
                          final v = await controller.upload(
                            draft,
                            editId: _editId,
                          );
                          if (mounted) {
                            setState(() {
                              character = v;
                              _preparingImage = v;
                              dirty = true;
                              _assetSelectionChanged = true;
                            });
                          }
                        }),
                  child: Text(s.uploadAvatar),
                ),
              if (c.avatarId.isNotEmpty)
                AppButton(
                  onPressed: busy
                      ? null
                      : () => work(() async {
                          final v = await controller.refresh(
                            draft,
                            editId: _editId,
                          );
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
                        await controller.saveCharacter(draft, editId: _editId);
                        if (mounted) setState(() => dirty = false);
                        if (panelContext.mounted) {
                          Navigator.of(panelContext).pop();
                        }
                        await _closeSaved();
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
    final updated = await controller.selectAsset(
      draft,
      selected,
      editId: _editId,
    );
    if (mounted) {
      setState(() {
        character = updated;
        _preparingImage = null;
        dirty = true;
        _assetSelectionChanged = true;
      });
    }
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
