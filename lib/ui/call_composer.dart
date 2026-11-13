import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../presentation/controllers.dart';
import '../presentation/quick_actions.dart';
import 'core/design.dart';
import 'core/widgets.dart';

/// Text chat and action commands share a panel, but use separate call commands.
class CallComposer extends ConsumerStatefulWidget {
  const CallComposer({super.key, required this.input});
  final TextEditingController input;

  @override
  ConsumerState<CallComposer> createState() => _CallComposerState();
}

class _CallComposerState extends ConsumerState<CallComposer> {
  bool sending = false, closing = false;
  String? sendError;
  QuickActionCategory category = QuickActionCategory.common;
  final actionScroll = ScrollController();

  @override
  void dispose() {
    actionScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final calls = ref.read(controllerProvider).calls;
    final call = ref.watch(callProvider).value ?? calls.snapshot;
    ref.listen(callProvider, (_, next) {
      if (next.hasValue &&
          !next.value!.interactive &&
          !closing &&
          ModalRoute.of(context)?.isCurrent == true) {
        closing = true;
        // The call can end remotely or in the background while the sheet is open.
        Navigator.of(context).pop();
      }
    });
    final actions = category.actions;
    final actionHeight = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(14) * 1.4 + 24,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: LiquidGlassLite(
        key: const Key('call-composer'),
        shape: const LiquidGlassShape(cornerRadius: 28),
        blur: 10,
        color: MediaQuery.highContrastOf(context)
            ? const Color(0xF517191F)
            : const Color(0xD917191F),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.quickActions,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('close-call-composer'),
                      onPressed: () {
                        closing = true;
                        Navigator.of(context).pop();
                      },
                      icon: Icon(
                        CupertinoIcons.xmark,
                        size: 18,
                        semanticLabel: MaterialLocalizations.of(context)
                            .closeButtonLabel,
                      ),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  key: const Key('quick-action-categories'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in QuickActionCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Semantics(
                            selected: category == item,
                            child: TextButton(
                              key: Key('quick-category-${item.name}'),
                              style: TextButton.styleFrom(
                                foregroundColor: category == item
                                    ? XiaoyuDesign.lavender
                                    : XiaoyuDesign.muted,
                                backgroundColor: category == item
                                    ? const Color(0x14C2B7FF)
                                    : Colors.transparent,
                                minimumSize: const Size(48, 48),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelLarge!
                                    .copyWith(
                                      fontSize: 14,
                                      fontWeight: category == item
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                              onPressed: () {
                                if (category == item) return;
                                if (actionScroll.hasClients) {
                                  actionScroll.jumpTo(0);
                                }
                                setState(() => category = item);
                              },
                              child: Text(s.quickActionCategory(item.name)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                gap(8),
                SizedBox(
                  height: actionHeight,
                  child: ListView.separated(
                    key: const Key('quick-actions-scroll'),
                    controller: actionScroll,
                    scrollDirection: Axis.horizontal,
                    itemCount: actions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final action = actions[index];
                      return TextButton(
                        key: Key('quick-action-${action.name}'),
                        style: TextButton.styleFrom(
                          foregroundColor: XiaoyuDesign.lavender,
                          backgroundColor: const Color(0x14C2B7FF),
                          minimumSize: const Size(64, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          textStyle: Theme.of(context).textTheme.labelLarge!
                              .copyWith(fontSize: 14, height: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: call.interactive && !sending
                            ? () => unawaited(
                                _send(action: s.quickActionPrompt(action.name)),
                              )
                            : null,
                        child: Text(
                          s.quickActionName(action.name),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      );
                    },
                  ),
                ),
                if (sendError != null) ...[
                  gap(12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      sendError!,
                      key: const Key('call-composer-error'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: XiaoyuDesign.muted,
                      ),
                    ),
                  ),
                ],
                gap(18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('chat-input'),
                        controller: widget.input,
                        enabled: call.interactive && !sending,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: s.chatHint,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.input,
                      builder: (_, value, _) => AppIconButton(
                        key: const Key('chat-send'),
                        icon: const Icon(CupertinoIcons.arrow_up),
                        label: s.send,
                        onPressed:
                            call.interactive &&
                                !sending &&
                                value.text.trim().isNotEmpty
                            ? () => unawaited(_send())
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send({String? action}) async {
    if (sending || closing) return;
    setState(() {
      sending = true;
      sendError = null;
    });
    final calls = ref.read(controllerProvider).calls;
    final text = widget.input.text;
    try {
      if (action == null) {
        await calls.sendText(text);
        // A dismissed sheet must not touch a controller disposed by its page.
        if (mounted) widget.input.clear();
      } else {
        calls.sendAction(action);
      }
    } on Object catch (e) {
      if (e is FlutterError) rethrow;
      if (mounted) {
        setState(
          () =>
              sendError = context.s.error(e is AppFailure ? e.code : 'unknown'),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}
