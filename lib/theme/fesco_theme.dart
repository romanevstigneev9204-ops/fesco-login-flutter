import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fesco_colors.dart';

abstract final class FescoTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: FescoColors.bgAccentActive,
      onPrimary: FescoColors.textInverse,
      secondary: FescoColors.bgPrimary,
      onSecondary: FescoColors.primaryButtonEnabledText,
      surface: FescoColors.bgPrimary,
      onSurface: FescoColors.textPrimary,
      error: Colors.red,
      onError: FescoColors.textInverse,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FescoColors.bgAccentActive,
      appBarTheme: const AppBarTheme(
        backgroundColor: FescoColors.bgAccentActive,
        foregroundColor: FescoColors.textInverse,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FescoColors.bgPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: FescoColors.borderFieldDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: FescoColors.borderFieldDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: FescoColors.bgAccentActive, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontSize: 10,
          color: FescoColors.textTertiary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FescoColors.textInverse,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
