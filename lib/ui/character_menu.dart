import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

import 'core/design.dart';
import 'core/widgets.dart';

enum CharacterMenuAction { edit, delete }

/// A corner-anchored button that grows into the two character actions.
class CharacterMenu extends StatefulWidget {
  const CharacterMenu({super.key, required this.onSelected});
  final ValueChanged<CharacterMenuAction> onSelected;

  @override
  State<CharacterMenu> createState() => _CharacterMenuState();
}

class _CharacterMenuState extends State<CharacterMenu> {
  bool showing = false;

  Future<void> _open() async {
    if (showing) return;
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    final anchor = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    setState(() => showing = true);
    final action = await showGeneralDialog<CharacterMenuAction>(
      context: context,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => _MenuPanel(anchor: anchor),
    );
    if (!mounted) return;
    setState(() => showing = false);
    if (action != null) widget.onSelected(action);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: Visibility(
      visible: !showing,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: IconButton(
        key: const Key('character-menu'),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: _open,
        icon: Icon(
          CupertinoIcons.ellipsis,
          size: 20,
          semanticLabel: context.s.more,
        ),
      ),
    ),
  );
}

LiquidGlassStyle _style(BuildContext context, {bool expanded = false}) =>
    XiaoyuDesign.glass(context).copyWith(
      color: const Color(0x6617191F),
      blur: 10,
      shape: LiquidGlassShape(
        cornerStyle: expanded
            ? LiquidGlassCornerStyle.squircle
            : LiquidGlassCornerStyle.continuousRoundedRectangle,
        cornerRadius: 24,
      ),
    );

class _MenuPanel extends StatefulWidget {
  const _MenuPanel({required this.anchor});
  final Rect anchor;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  bool expanded = false;

  @override
  void initState() {
    super.initState();
    // Seed the same 48 pt shape before asking the official morph to expand.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => expanded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final textStyle = _textStyle(context);
    final labels = [context.s.edit, context.s.delete];
    var textWidth = 0.0, textHeight = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      textWidth = math.max(textWidth, painter.width);
      textHeight = math.max(textHeight, painter.height);
      painter.dispose();
    }
    final panelHeight = math.max(48.0, textHeight + 24) * 2 + 12;
    return LayoutBuilder(
      builder: (context, constraints) {
        final safe = Rect.fromLTRB(
          padding.left + 12,
          padding.top + 8,
          constraints.maxWidth - padding.right - 12,
          constraints.maxHeight - padding.bottom - 12,
        );
        final width = math.min(math.max(48.0, textWidth + 28) + 12, safe.width);
        final right = widget.anchor.right.clamp(safe.left + width, safe.right);
        final down = widget.anchor.top + panelHeight <= safe.bottom;
        return Stack(
          children: [
            Positioned(
              left: right - width,
              right: constraints.maxWidth - right,
              top: down
                  ? widget.anchor.top.clamp(safe.top, safe.bottom - 48)
                  : safe.top,
              bottom: down
                  ? constraints.maxHeight - safe.bottom
                  : constraints.maxHeight -
                        widget.anchor.bottom.clamp(safe.top + 48, safe.bottom),
              child: Align(
                alignment: down ? Alignment.topRight : Alignment.bottomRight,
                child: LiquidGlassMorph(
                  // A fresh final shape avoids motion when Reduce Motion is on.
                  key: reduced ? ValueKey(expanded) : null,
                  alignment: down ? Alignment.topRight : Alignment.bottomRight,
                  motion: LiquidGlassMorphMotion.plain,
                  style: _style(context, expanded: expanded),
                  child: expanded
                      ? SizedBox(
                          key: const ValueKey('menu-expanded-shape'),
                          width: width,
                          child: Material(
                            key: const Key('character-menu-panel'),
                            type: MaterialType.transparency,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _action(
                                    context,
                                    CharacterMenuAction.edit,
                                    context.s.edit,
                                  ),
                                  _action(
                                    context,
                                    CharacterMenuAction.delete,
                                    context.s.delete,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('menu-button'),
                          width: 48,
                          height: 48,
                          child: Icon(CupertinoIcons.ellipsis, size: 20),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _action(
    BuildContext context,
    CharacterMenuAction action,
    String label,
  ) => TextButton(
    key: Key('menu-${action.name}'),
    onPressed: () => Navigator.of(context).pop(action),
    style:
        TextButton.styleFrom(
          foregroundColor: action == CharacterMenuAction.delete
              ? Colors.redAccent
              : XiaoyuDesign.text,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: _textStyle(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ).copyWith(
          overlayColor: action == CharacterMenuAction.delete
              ? const WidgetStatePropertyAll(XiaoyuDesign.dangerPressed)
              : XiaoyuDesign.buttonOverlay,
        ),
    child: Align(alignment: Alignment.centerLeft, child: Text(label)),
  );
}

TextStyle _textStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontSize: 15, fontWeight: FontWeight.w500);
