import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../theme/fesco_colors.dart';
import '../../theme/fesco_typography.dart';
import '../../widgets/fesco_login_scaffold.dart';

/// OTP stub — Figma `1:1096` «Код подтверждения».
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

  @override
  void dispose() {
    _codeController.dispose();
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
      figmaNodeId: '1:1096',
      showBack: true,
      onBack: _goBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Код подтверждения',
            textAlign: TextAlign.center,
            style: FescoTypography.titleOnAccent(context),
          ),
          const SizedBox(height: 32),
          _OtpInputStub(
            controller: _codeController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(
            'Отправили код на номер',
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context).copyWith(
              color: FescoColors.textInverse,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayPhone,
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context).copyWith(
              color: FescoColors.textInverse,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Обычно СМС приходит в течение минуты.',
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: const Text('Отправить код еще раз'),
          ),
          const SizedBox(height: 16),
          Text(
            'route: ${FescoRoutes.loginOtp}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FescoColors.textColorDisabled,
              fontSize: 11,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Placeholder for `FescoOtpInput` — four underlined cells.
class _OtpInputStub extends StatelessWidget {
  const _OtpInputStub({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            final char = index < controller.text.length
                ? controller.text[index]
                : '';
            final focused = index == controller.text.length && index < 4;
            return SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(
                    char,
                    style: const TextStyle(
                      color: FescoColors.textInverse,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    color: focused
                        ? FescoColors.otpAccent
                        : FescoColors.textColorDisabled,
                  ),
                ],
              ),
            );
          }),
        ),
        Opacity(
          opacity: 0.01,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
