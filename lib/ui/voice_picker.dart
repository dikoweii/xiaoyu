import 'dart:math' as math;
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/voice_preview.dart';
import '../domain/voice_catalog.dart';
import '../presentation/voice_preview.dart';
import 'core/design.dart';
import 'core/widgets.dart';

String voiceProviderLabel(BuildContext context, VoiceProvider provider) =>
    provider == VoiceProvider.qwenOmni
    ? context.s.voiceQwen
    : context.s.voiceDoubao;

String voiceSelectionLabel(
  BuildContext context,
  VoiceProvider provider,
  String id,
) =>
    '${voiceProviderLabel(context, provider)} · ${findVoice(provider, id)?.name ?? id}';

Future<VoiceSelection?> chooseVoice(
  BuildContext context,
  String selected, {
  VoiceProvider provider = VoiceProvider.qwenOmni,
}) => showModalBottomSheet<VoiceSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: XiaoyuDesign.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: math.min(480, box.maxHeight * .9),
        child: SafeArea(
          top: false,
          child: VoicePicker(selected: selected, provider: provider),
        ),
      ),
    ),
  ),
);

class VoicePicker extends ConsumerStatefulWidget {
  const VoicePicker({
    super.key,
    required this.selected,
    this.provider = VoiceProvider.qwenOmni,
  });
  final String selected;
  final VoiceProvider provider;

  @override
  ConsumerState<VoicePicker> createState() => _VoicePickerState();
}

class _VoicePickerState extends ConsumerState<VoicePicker>
    with WidgetsBindingObserver {
  late VoiceProvider provider = widget.provider;
  final scroll = ScrollController();
  late final VoicePreviewController preview;
  final previewKey = Object();

  @override
  void initState() {
    super.initState();
    preview = ref.read(voicePreviewProvider(previewKey));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(preview.stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(preview.dispose());
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    ref.watch(voicePreviewProvider(previewKey));
    final playback =
        ref.watch(voicePreviewStateProvider(previewKey)).value ?? preview.state;
    ref.listen(voicePreviewStateProvider(previewKey), (_, next) {
      if (next.value?.failed == true) notice(context, s.voicePreviewFailed);
    });
    final entries = officialVoices
        .where((voice) => voice.provider == provider)
        .toList();
    final selectedIndex = entries.indexWhere(
      (voice) =>
          voice.provider == widget.provider && voice.id == widget.selected,
    );
    if (selectedIndex > 0) entries.insert(0, entries.removeAt(selectedIndex));
    return CustomScrollView(
      key: const Key('voice-list'),
      controller: scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.voice,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final item in VoiceProvider.values)
                      Semantics(
                        selected: provider == item,
                        child: SizedBox(
                          width: MediaQuery.textScalerOf(context).scale(1) > 1.5
                              ? 132
                              : 84,
                          child: AppButton(
                            key: Key('voice-provider-${item.apiValue}'),
                            plain: provider != item,
                            accent: provider == item,
                            onPressed: () {
                              unawaited(preview.stop());
                              setState(() => provider = item);
                              scroll.jumpTo(0);
                            },
                            child: Text(voiceProviderLabel(context, item)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverList.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final voice = entries[index];
              final selected =
                  voice.provider == widget.provider &&
                  voice.id == widget.selected;
              const colors = [
                Color(0xFF89718D),
                Color(0xFF467B77),
                Color(0xFF9E585F),
                Color(0xFF556B99),
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppSurface(
                  accent: selected,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          key: Key('voice-preview-${voice.id}'),
                          padding: EdgeInsets.zero,
                          tooltip: playback.id == voice.id
                              ? s.voiceStopPreview(voice.name)
                              : s.voicePlayPreview(voice.name),
                          onPressed: voice.trialUrl.isEmpty
                              ? null
                              : () => unawaited(preview.toggle(voice)),
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  colors[index % colors.length],
                                  XiaoyuDesign.blush,
                                ],
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (voice.avatarUrl.isNotEmpty)
                                  Image(
                                    image: ref.read(voiceAvatarProvider)(
                                      voice.avatarUrl,
                                    ),
                                    fit: BoxFit.cover,
                                    excludeFromSemantics: true,
                                    errorBuilder: (_, _, _) => const SizedBox(),
                                  ),
                                if (voice.trialUrl.isNotEmpty)
                                  ColoredBox(
                                    color: const Color(0x55000000),
                                    child: Center(
                                      child:
                                          playback.id == voice.id &&
                                              playback.loading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              playback.id == voice.id
                                                  ? Icons.stop_rounded
                                                  : Icons.play_arrow_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                    ),
                                  )
                                else
                                  const Icon(Icons.graphic_eq, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          voice.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: MediaQuery.textScalerOf(context).scale(1) > 1.5
                            ? 140
                            : 80,
                        child: AppButton(
                          key: Key('voice-select-${voice.id}'),
                          accent: selected,
                          onPressed: () async {
                            await preview.stop();
                            if (context.mounted) {
                              Navigator.of(context).pop(voice.selection);
                            }
                          },
                          child: Text(selected ? s.chosen : s.choose),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
