/// Named routes and paths for FESCO login flow (Figma node ids in comments).
abstract final class FescoRoutes {
  static const String loginPhone = 'login-phone';
  static const String loginPhonePath = '/login';

  /// Figma `1:943` — keyboard open, mask empty (same screen, UI state).
  static const String loginPhoneKeyboardEmpty = 'login-phone-keyboard-empty';

  /// Figma `1:574` — keyboard open, number filled.
  static const String loginPhoneKeyboardFilled = 'login-phone-keyboard-filled';

  static const String loginOtp = 'login-otp';
  static const String loginOtpPath = '/login/otp';

  /// Figma `1:1096` — SMS confirmation code.
}

/// Query / extra keys for [go_router] navigation.
abstract final class FescoRouteParams {
  static const String phone = 'phone';
}
