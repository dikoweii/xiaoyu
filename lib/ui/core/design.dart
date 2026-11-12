import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

export 'package:liquid_glass_easy/liquid_glass_easy.dart';

abstract final class XiaoyuDesign {
  static const canvas = Color(0xFF08090D);
  static const surface = Color(0xFF17191F);
  static const text = Color(0xFFF5F5F7);
  static const muted = Color(0xFFA2A5AF);
  static const lavender = Color(0xFFC2B7FF);
  static const blush = Color(0xFFE4C5D4);
  static const contentWidth = 480.0;
  static const pressed = Color(0x18C2B7FF);
  static const glassPressed = Color(0x14FFFFFF);
  static const primaryPressed = Color(0x183D326E);
  static const dangerPressed = Color(0x20FF453A);
  static final buttonOverlay = WidgetStateProperty.resolveWith<Color?>((
    states,
  ) {
    if (states.contains(WidgetState.disabled)) return Colors.transparent;
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.focused)) {
      return pressed;
    }
    if (states.contains(WidgetState.hovered)) return const Color(0x0CC2B7FF);
    return Colors.transparent;
  });
  static final _buttonStyle = ButtonStyle(
    overlayColor: buttonOverlay,
    splashFactory: NoSplash.splashFactory,
  );

  // Fixed chrome samples the live scene. Content cards remain opaque.
  static LiquidGlassStyle glass(BuildContext context, {bool lite = false}) =>
      LiquidGlassButton.defaultStyle.copyWith(
        color: const Color(0x4017191F),
        liteGlass:
            lite ||
            MediaQuery.disableAnimationsOf(context) ||
            MediaQuery.highContrastOf(context),
      );
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: canvas,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: pressed,
    hoverColor: const Color(0x0CC2B7FF),
    colorScheme: const ColorScheme.dark(
      primary: lavender,
      secondary: blush,
      surface: surface,
      onSurface: text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(fontSize: 12, color: muted),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _buttonStyle.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
    iconButtonTheme: IconButtonThemeData(style: _buttonStyle),
    listTileTheme: const ListTileThemeData(
      textColor: text,
      iconColor: muted,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    popupMenuTheme: const PopupMenuThemeData(color: surface),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 17, height: 1.55),
      bodyMedium: TextStyle(fontSize: 13, height: 1.45),
      bodySmall: TextStyle(fontSize: 11, height: 1.4, color: muted),
    ).apply(bodyColor: text, displayColor: text),
  );
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.accent = false,
    this.radius = 26,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });
  final Widget child;
  final bool accent;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? (accent ? const Color(0xFF302B43) : XiaoyuDesign.surface),
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}
