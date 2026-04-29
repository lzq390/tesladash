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
  static const primaryTint = Color(0x1A38D996);
  static const primaryBorder = Color(0x6638D996);
  static const progressTrack = Color(0xFF26313F);
  static const speedBorder = Color(0x335DA0FF);
  static const speedGlow = Color(0x2238D996);
  static const speedGradientStart = Color(0xFF0A0E14);
  static const speedGradientEnd = Color(0xFF111A24);

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

class TDashSpacing {
  const TDashSpacing._();

  static const screen = 16.0;
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 10.0;
  static const xl = 12.0;
  static const panel = 14.0;
  static const section = 18.0;
  static const hero = 24.0;
  static const speedInner = 28.0;
}

class TDashRadius {
  const TDashRadius._();

  static const panel = 8.0;
  static const control = 8.0;
  static const pill = 999.0;
}

class TDashSizes {
  const TDashSizes._();

  static const speedDiameterMax = 330.0;
  static const speedFont = 112.0;
  static const unitFont = 18.0;
  static const bodyStrongFont = 18.0;
  static const labelFont = 12.0;
  static const progressHeight = 12.0;
}
