import 'package:flutter/services.dart';

/// Formats Russian mobile digits as `+7 (XXX) XXX-XX-XX` (10 national digits).
class PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
  final limited =
      digits.length > 10 ? digits.substring(0, 10) : digits;
    final formatted = formatRussianPhone(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String formatRussianPhone(String digits) {
    if (digits.isEmpty) return '+7';

    final buffer = StringBuffer('+7 (');
    for (var i = 0; i < 3; i++) {
      buffer.write(i < digits.length ? digits[i] : '_');
    }
    buffer.write(') ');
    for (var i = 3; i < 6; i++) {
      buffer.write(i < digits.length ? digits[i] : '_');
    }
    buffer.write('-');
    for (var i = 6; i < 8; i++) {
      buffer.write(i < digits.length ? digits[i] : '_');
    }
    buffer.write('-');
    for (var i = 8; i < 10; i++) {
      buffer.write(i < digits.length ? digits[i] : '_');
    }
    return buffer.toString();
  }

  static String maskPlaceholder() => '+7 (___) ___-__-__';

  static int digitsFromFormatted(String text) {
    final raw = text.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('7') && raw.length > 1) {
      return raw.substring(1).length;
    }
    return raw.length;
  }

  static String extractDigits(String text) {
    var raw = text.replaceAll(RegExp(r'\D'), '');
    if (raw.startsWith('7')) {
      raw = raw.substring(1);
    }
    return raw.length > 10 ? raw.substring(0, 10) : raw;
  }
}
