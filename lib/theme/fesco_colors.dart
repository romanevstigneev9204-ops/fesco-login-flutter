import 'package:flutter/material.dart';

/// Design tokens from FESCO login spec (`fesco-screens.md`).
abstract final class FescoColors {
  static const Color bgAccentActive = Color(0xFF001F64);
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color borderFieldDefault = Color(0xFFE0E4E9);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textColorDisabled = Color(0xFFA4A8AD);
  static const Color textTertiary = Color(0xFF8A8D8F);
  static const Color textPrimary = Color(0xFF000000);

  /// OTP active underline / cursor — placeholder until Figma hex is confirmed.
  static const Color otpAccent = Color(0xFFFF8A00);

  static const Color primaryButtonDisabledFill = Color(0xFF6B7A94);
  static const Color primaryButtonEnabledText = Color(0xFF001F64);
}
