import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../presentation/controllers.dart';
import 'design.dart';
import 'portrait_tile.dart';
export 'controls.dart';

extension Strings on BuildContext {
  AppLocalizations get s => AppLocalizations.of(this);
}

void notice(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

Future<void> guarded(
  BuildContext context,
  FutureOr<void> Function() work,
) async {
  try {
    await work();
  } on Object catch (e) {
    if (e is FlutterError) rethrow;
    if (context.mounted) {
      notice(context, context.s.error(e is AppFailure ? e.code : 'unknown'));
    }
  }
}

class ConfirmationPanel extends StatelessWidget {
  const ConfirmationPanel({
    super.key,
    required this.title,
    required this.body,
    this.destructive = false,
    this.actions,
  });
  final String title, body;
  final bool destructive;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withAlpha(220),
      fontSize: 14.5,
      height: 1.4,
    );
    final style = XiaoyuDesign.glass(context)
        .copyWith(color: const Color(0xCC17191F));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: actions != null
          ? LiquidGlassDialog(
              key: const Key('confirmation'),
              style: style,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(title, style: titleStyle),
                          gap(12),
                          Text(body, style: bodyStyle),
                          gap(16),
                        ],
                      ),
                    ),
                  ),
                  // Keep every exit choice visible even with large text.
                  for (final action in actions!) action,
                ],
              ),
            )
          : LiquidGlassAlertDialog(
              key: const Key('confirmation'),
              title: Text(title),
              titleTextStyle: titleStyle,
              content: Text(body),
              contentTextStyle: bodyStyle,
              scrollable: true,
              style: style,
              actions: [
                TextButton(
                  key: const Key('confirm-cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.s.cancel),
                ),
                TextButton(
                  key: const Key('confirm-accept'),
                  style:
                      TextButton.styleFrom(
                        foregroundColor: destructive
                            ? Colors.redAccent
                            : XiaoyuDesign.lavender,
                      ).copyWith(
                        overlayColor: destructive
                            ? const WidgetStatePropertyAll(
                                XiaoyuDesign.dangerPressed,
                              )
                            : XiaoyuDesign.buttonOverlay,
                      ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(context.s.confirm),
                ),
              ],
            ),
    );
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  bool destructive = false,
}) async =>
    await confirmation<bool>(context, title, body, destructive: destructive) ??
    false;

Future<T?> confirmation<T>(
  BuildContext context,
  String title,
  String body, {
  bool destructive = false,
  List<Widget> Function(BuildContext)? actions,
}) async {
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x80000000),
    transitionDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, _, _) => themes.wrap(
      SafeArea(
        child: ConfirmationPanel(
          title: title,
          body: body,
          destructive: destructive,
          actions: actions?.call(dialogContext),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: .9, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Cubic(.16, 1, .3, 1),
            reverseCurve: const Cubic(.7, 0, .84, 0),
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// Full window scroll viewport, with fixed glass chrome over the scene.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomBar,
    this.background,
  });
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomBar, background;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final barHeight = MediaQuery.textScalerOf(context).scale(17) > 26
        ? 76.0
        : 56.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: XiaoyuDesign.canvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ?background,
            title == null
                ? body
                : MediaQuery(
                    // Scroll the inset with the content, keeping its viewport
                    // full screen so it can pass beneath the pinned edge.
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.paddingOf(context)
                          .copyWith(top: top + barHeight + 8),
                    ),
                    child: body,
                  ),
            if (title != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: top + barHeight + 40,
                child: LiquidGlassScrollEdge(
                  key: const Key('page-scroll-edge'),
                  edge: LiquidGlassEdge.top,
                  blur: 6,
                  color: const Color(0xEB08090D),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12, top + 4, 12, 0),
                      child: SizedBox(
                        height: barHeight,
                        child: NavigationToolbar(
                          centerMiddle: true,
                          leading: Navigator.of(context).canPop()
                              ? SizedBox(
                                  width: 48,
                                  child: Center(
                                    child: IconButton(
                                      key: const Key('page-back'),
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                      icon: Icon(
                                        CupertinoIcons.back,
                                        semanticLabel: MaterialLocalizations.of(
                                          context,
                                        ).backButtonTooltip,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          middle: Semantics(
                            header: true,
                            child: Text(
                              title!,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          trailing: actions == null
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: actions!,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (bottomBar != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: bottomBar!,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.bottom = 32,
    this.horizontal = 20,
  });
  final List<Widget> children;
  final double bottom, horizontal;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: XiaoyuDesign.contentWidth),
        child: ListView(
          // Insets scroll with the content; they must not shrink the viewport.
          padding: EdgeInsets.fromLTRB(
            horizontal,
            8 + MediaQuery.paddingOf(context).top,
            horizontal,
            bottom + MediaQuery.paddingOf(context).bottom,
          ),
          children: children,
        ),
      ),
    ),
  );
}

Widget gap([double height = 16]) => SizedBox(height: height);
Widget section(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 20),
  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
);

ImageProvider<Object>? portraitImage(
  Character character,
  ScreenController controller,
) => character.imagePath.isNotEmpty
    ? FileImage(controller.image(character.imagePath))
    : character.sourceImageUrl.isNotEmpty
    ? NetworkImage(character.sourceImageUrl)
    : null;

class Portrait extends ConsumerWidget {
  const Portrait(this.character, {super.key, this.height = 260});
  final Character character;
  final double height;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = portraitImage(character, ref.read(controllerProvider));
    final image = provider == null
        ? const PortraitPlaceholder()
        : Image(
            image: provider,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const PortraitPlaceholder(),
          );
    return Semantics(
      label: context.s.portrait,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(height: height, width: double.infinity, child: image),
      ),
    );
  }
}

/// Large forms use Flutter's sheet, with keyboard insets and scroll access.
Future<T?> sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: XiaoyuDesign.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .84,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: child,
            ),
          ),
        ),
      ),
    );
