import 'package:flutter/material.dart';

/// Colours used by the redesigned screens (taken from the mockup boards).
///
/// Most of them change with the theme: set [dark] (the ThemeController does)
/// and every getter answers with the dark value. Brand colours and the dark
/// red bars stay the same in both modes.
class BL {
  /// True while the app is in dark mode.
  static bool dark = false;

  static T _pick<T>(T light, T night) => dark ? night : light;

  // Same in both modes.
  static const crimson = Color(0xFFBA181B);
  static const crimsonDark = Color(0xFF660708);

  /// Text and icons that sit on a crimson or dark red bar.
  static const onCrimson = Color(0xFFFBE3E4);

  // Change with the mode.
  /// Crimson for text and icons: a lighter red on the dark background.
  /// Dark red for text and icons on a blush tint: a pale red on the dark background.
  static Color get deep => _pick(crimsonDark, const Color(0xFFF4A5A8));
  static Color get link => _pick(crimson, const Color(0xFFFF6B6E));
  static Color get surface => _pick(Colors.white, const Color(0xFF181314));
  static Color get fill =>
      _pick(const Color(0xFFF5F3F4), const Color(0xFF221C1D));
  static Color get blush =>
      _pick(const Color(0xFFFBE3E4), const Color(0xFF3B1A1C));
  static Color get tint =>
      _pick(const Color(0xFFFDEEEE), const Color(0xFF301719));
  static Color get ink =>
      _pick(const Color(0xFF0B090A), const Color(0xFFF6F1F1));
  static Color get inkSoft =>
      _pick(const Color(0xFF3A2F31), const Color(0xFFDDD2D3));
  static Color get muted =>
      _pick(const Color(0xFF4A5560), const Color(0xFFB9AEB0));
  static Color get faint =>
      _pick(const Color(0xFF6B7480), const Color(0xFF9C9193));
  static Color get border =>
      _pick(const Color(0xFFCFC4C5), const Color(0xFF45393B));
  static Color get hairline =>
      _pick(const Color(0xFFE8E0E1), const Color(0xFF2E2527));
  static Color get success =>
      _pick(const Color(0xFF1B6B35), const Color(0xFF5FCB86));
  static Color get successInk =>
      _pick(const Color(0xFF14532D), const Color(0xFF86DDA5));
  static Color get dangerInk =>
      _pick(const Color(0xFF7F1D14), const Color(0xFFF4A59C));
  static Color get warnInk =>
      _pick(const Color(0xFF7A4300), const Color(0xFFF2C07A));
  static Color get successTint =>
      _pick(const Color(0xFFDDF1E3), const Color(0xFF16301F));
  static Color get warnTint =>
      _pick(const Color(0xFFFFF1DB), const Color(0xFF362711));
}
