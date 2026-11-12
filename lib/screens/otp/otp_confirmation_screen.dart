import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../theme/fesco_colors.dart';
import '../../theme/fesco_typography.dart';
import '../../widgets/fesco_login_scaffold.dart';
import '../../widgets/fesco_otp_input.dart';

/// OTP screen — Figma `1:1096` «Код подтверждения».
class OtpConfirmationScreen extends StatefulWidget {
  const OtpConfirmationScreen({
    super.key,
    required this.phoneE164,
  });

  final String phoneE164;

  @override
  State<OtpConfirmationScreen> createState() => _OtpConfirmationScreenState();
}

class _OtpConfirmationScreenState extends State<OtpConfirmationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String get _displayPhone {
    final raw = widget.phoneE164.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 11) return widget.phoneE164;
    final n = raw.length >= 11 ? raw.substring(raw.length - 10) : raw;
    return '+7 ${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6, 8)} ${n.substring(8)}.';
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(FescoRoutes.loginPhonePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FescoLoginScaffold(
      showBack: true,
      onBack: _goBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Код подтверждения',
            textAlign: TextAlign.center,
            style: FescoTypography.titleOnAccent(context),
          ),
          const SizedBox(height: 32),
          FescoOtpInput(
            controller: _codeController,
            focusNode: _otpFocus,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          Text(
            'Отправили код на номер',
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context).copyWith(
              color: FescoColors.textFormMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayPhone,
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context).copyWith(
              color: FescoColors.textFormMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Обычно СМС приходит в течение минуты.',
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context).copyWith(
              color: FescoColors.textFormMuted,
            ),
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Отправить код еще раз'),
            ),
          ),
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 16),
        ],
      ),
    );
  }
}
