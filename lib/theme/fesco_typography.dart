import 'package:flutter/material.dart';

import 'fesco_colors.dart';

/// Typography approximations for scaffold stubs (Arial → system sans).
abstract final class FescoTypography {
  static const String _fontFamily = 'Arial';

  static TextStyle titleOnAccent(BuildContext context) {
    return const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.1,
      color: FescoColors.textInverse,
    );
  }

  static TextStyle subtitleOnAccent(BuildContext context) {
    return const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: FescoColors.textColorDisabled,
    );
  }

  static TextStyle fieldLabel(BuildContext context) {
    return const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1,
      color: FescoColors.textTertiary,
    );
  }

  static TextStyle fieldValue(BuildContext context) {
    return const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: FescoColors.textPrimary,
    );
  }

  static TextStyle primaryButtonEnabled(BuildContext context) {
    return const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: FescoColors.primaryButtonEnabledText,
    );
  }

  static TextStyle primaryButtonDisabled(BuildContext context) {
    return const TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: FescoColors.textInverse,
    );
  }
}
