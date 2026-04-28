import 'package:flutter/material.dart';

class TDashTheme {
  const TDashTheme._();

  static const background = Color(0xFF070A0F);
  static const surface = Color(0xCC101722);
  static const border = Color(0xFF283546);
  static const primary = Color(0xFF38D996);
  static const secondary = Color(0xFF5DA0FF);
  static const mutedText = Color(0xFF9AA5B3);
  static const subtleText = Color(0xFF647080);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );
  }
}
