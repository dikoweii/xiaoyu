import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';
import '../../l10n/generated/app_localizations.dart';

/// Only floating actions use glass; opaque and text actions use Flutter buttons.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.child,
    this.onPressed,
    this.primary = false,
    this.accent = false,
    this.destructive = false,
    this.plain = false,
    this.icon,
    this.semanticLabel,
  });
  final Widget child;
  final Widget? icon;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final bool primary, accent, destructive, plain;
  @override
  Widget build(BuildContext context) {
    final content = icon == null
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              const SizedBox(width: 8),
              Flexible(child: child),
            ],
          );
    final color = destructive ? Colors.redAccent : XiaoyuDesign.text;
    final style =
        TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: Theme.of(context).textTheme.labelLarge!
              .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ).copyWith(
          overlayColor: destructive
              ? const WidgetStatePropertyAll(XiaoyuDesign.dangerPressed)
              : XiaoyuDesign.buttonOverlay,
        );
    if (plain) {
      return TextButton(onPressed: onPressed, style: style, child: content);
    }
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style:
            FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5E5EA),
              foregroundColor: const Color(0xFF121317),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                XiaoyuDesign.primaryPressed,
              ),
            ),
        child: content,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final label =
            semanticLabel ?? (child is Text ? (child as Text).data : null);
        // The package's child doesn't size its lens. Measure text before laying it out.
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 160.0;
        final buttonTextStyle = Theme.of(context).textTheme.bodyMedium!
            .copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4);
        final painter =
            TextPainter(
              text: TextSpan(
                text: label ?? '',
                style: buttonTextStyle.merge(
                  child is Text ? (child as Text).style : null,
                ),
              ),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout(
              maxWidth: (width - (icon == null ? 32 : 64)).clamp(
                1,
                double.infinity,
              ),
            );
        final height = (painter.height + 24).clamp(48.0, double.infinity);
        painter.dispose();
        return Semantics(
          button: true,
          enabled: onPressed != null,
          label: label,
          excludeSemantics: true,
          onTap: onPressed,
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: destructive
                  ? XiaoyuDesign.dangerPressed
                  : XiaoyuDesign.glassPressed,
            ),
            child: LiquidGlassButton(
              width: width,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onPressed,
              foregroundColor: color,
              fontSize: 13,
              touch: MediaQuery.disableAnimationsOf(context)
                  ? const LiquidGlassTouch()
                  : null,
              style: XiaoyuDesign.glass(context).copyWith(
                color: destructive
                    ? const Color(0xAA9F2327)
                    : accent
                    ? const Color(0x66C2B7FF)
                    : null,
              ),
              child: DefaultTextStyle(style: buttonTextStyle, child: content),
            ),
          ),
        );
      },
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.destructive = false,
    this.lite = false,
  });
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive, lite;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    onTap: onPressed,
    excludeSemantics: true,
    child: Theme(
      data: Theme.of(context).copyWith(
        highlightColor: destructive
            ? XiaoyuDesign.dangerPressed
            : XiaoyuDesign.glassPressed,
      ),
      child: LiquidGlassButton(
        width: 48,
        height: 48,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        touch: MediaQuery.disableAnimationsOf(context)
            ? const LiquidGlassTouch()
            : null,
        style: XiaoyuDesign.glass(
          context,
          lite: lite,
        ).copyWith(color: destructive ? const Color(0xCCB92832) : null),
        child: icon,
      ),
    ),
  );
}

class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLength,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
    this.password = false,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final int minLines, maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled, password, autofocus;
  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  bool revealed = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: widget.controller,
        // Keep the focused field below pinned chrome when the keyboard moves
        // the caret into view. AppPage includes its toolbar in this inset.
        scrollPadding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 20,
          20,
          20,
        ),
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        obscureText: widget.password && !revealed,
        autocorrect: !widget.password,
        enableIMEPersonalizedLearning: !widget.password,
        enableSuggestions: !widget.password,
        maxLength: widget.maxLength,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        inputFormatters: [
          if (widget.maxLength != null)
            LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: widget.hint ?? widget.label,
          suffixIcon: widget.password
              ? IconButton(
                  onPressed: () => setState(() => revealed = !revealed),
                  icon: Icon(
                    revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    semanticLabel: revealed
                        ? AppLocalizations.of(context).hidePassword
                        : AppLocalizations.of(context).showPassword,
                  ),
                )
              : null,
        ),
      ),
    ],
  );
}

class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, ?subtitle],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          label: title is Text ? (title as Text).data : null,
          toggled: value,
          enabled: onChanged != null,
          excludeSemantics: true,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: SizedBox(
              width: 72,
              height: 48,
              child: Center(
                child: IgnorePointer(
                  ignoring: onChanged == null,
                  child: LiquidGlassSwitch(
                    value: value,
                    onChanged: onChanged ?? (_) {},
                    activeColor: XiaoyuDesign.lavender,
                    reserveSwellRoom: false,
                    style: XiaoyuDesign.glass(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(12),
    child: CircularProgressIndicator(color: XiaoyuDesign.lavender),
  );
}
