import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../theme/fesco_typography.dart';
import '../../widgets/fesco_login_scaffold.dart';
import '../../widgets/fesco_logo_vertical.dart';
import '../../widgets/fesco_phone_field.dart';
import '../../widgets/fesco_primary_button.dart';
import '../../widgets/phone_mask_formatter.dart';

enum LoginPhoneUiPhase {
  /// Figma `1:710` — initial, no keyboard focus.
  initial,

  /// Figma `1:943` — keyboard, empty mask.
  keyboardEmpty,

  /// Figma `1:574` — keyboard, full number.
  keyboardFilled,
}

/// Phone entry — Figma `1:710` / `1:943` / `1:574`.
class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _phoneController =
      TextEditingController(text: '+7');

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _phoneController
      ..removeListener(_onPhoneChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _onPhoneChanged() => setState(() {});

  LoginPhoneUiPhase get _phase {
    final digits = _digitsOnly;
    if (!_focusNode.hasFocus && digits.isEmpty) {
      return LoginPhoneUiPhase.initial;
    }
    if (digits.length >= 10) {
      return LoginPhoneUiPhase.keyboardFilled;
    }
    return LoginPhoneUiPhase.keyboardEmpty;
  }

  String get _digitsOnly =>
      PhoneMaskFormatter.extractDigits(_phoneController.text);

  bool get _canConfirm => _digitsOnly.length >= 10;

  void _confirmPhone() {
    if (!_canConfirm) return;
    final phone = '+7$_digitsOnly';
    goToOtpConfirmation(context, phoneE164: phone);
  }

  @override
  Widget build(BuildContext context) {
    final showConfirm = _phase != LoginPhoneUiPhase.initial;

    return FescoLoginScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: _phase == LoginPhoneUiPhase.initial ? 151 : 16),
            const FescoLogoVertical(),
            const SizedBox(height: 32),
            Text(
              'Личный кабинет сотрудника',
              textAlign: TextAlign.center,
              style: FescoTypography.titleOnAccent(context),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: FescoTypography.subtitleOnAccent(context),
                children: const [
                  TextSpan(text: 'Если у вас еще нет аккаунта,\n'),
                  TextSpan(text: 'он будет создан автоматически'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FescoPhoneField(
              controller: _phoneController,
              focusNode: _focusNode,
              onSubmitted: _canConfirm ? _confirmPhone : null,
            ),
            if (showConfirm) ...[
              const SizedBox(height: 24),
              FescoPrimaryButton(
                label: 'Подтвердить номер',
                enabled: _canConfirm,
                onPressed: _confirmPhone,
              ),
            ],
            SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 24),
          ],
        ),
      ),
    );
  }
}
