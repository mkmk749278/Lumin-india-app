import 'package:flutter/material.dart';

import 'shared/tokens.dart';

ThemeData buildLuminIndiaTheme() {
  const accent = LuminColors.accent;
  const bg = LuminColors.bgDeep;
  const surface = LuminColors.bgCard;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: surface,
      onPrimary: bg,
      onSecondary: bg,
      onSurface: LuminColors.textPrimary,
      error: LuminColors.loss,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: LuminColors.textPrimary,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5),
      displayMedium: TextStyle(
          color: LuminColors.textPrimary,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.0),
      headlineLarge:
          TextStyle(color: LuminColors.textPrimary, fontWeight: FontWeight.w400),
      headlineMedium:
          TextStyle(color: LuminColors.textPrimary, fontWeight: FontWeight.w500),
      titleLarge:
          TextStyle(color: LuminColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium:
          TextStyle(color: LuminColors.textPrimary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: LuminColors.textPrimary),
      bodyMedium: TextStyle(color: LuminColors.textSecondary),
      labelLarge: TextStyle(
          color: LuminColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: LuminColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: LuminColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5),
    ),
    iconTheme: const IconThemeData(color: LuminColors.textPrimary),
  );
}
