import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/login/login_phone_screen.dart';
import '../screens/otp/otp_confirmation_screen.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: FescoRoutes.loginPhonePath,
    routes: [
      GoRoute(
        path: FescoRoutes.loginPhonePath,
        name: FescoRoutes.loginPhone,
        builder: (context, state) => const LoginPhoneScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            name: FescoRoutes.loginOtp,
            builder: (context, state) {
              final phone =
                  state.uri.queryParameters[FescoRouteParams.phone] ?? '';
              return OtpConfirmationScreen(phoneE164: phone);
            },
          ),
        ],
      ),
    ],
  );
}

/// Navigates from phone step to OTP (`1:1096`) with the confirmed number.
void goToOtpConfirmation(BuildContext context, {required String phoneE164}) {
  final uri = Uri(
    path: FescoRoutes.loginOtpPath,
    queryParameters: {FescoRouteParams.phone: phoneE164},
  );
  context.go(uri.toString());
}
