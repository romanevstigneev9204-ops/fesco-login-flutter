import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../theme/fesco_colors.dart';
import '../../theme/fesco_typography.dart';
import '../../widgets/fesco_login_scaffold.dart';
import '../../widgets/fesco_primary_button.dart';

enum LoginPhoneUiPhase {
  /// Figma `1:710` — initial, no keyboard focus.
  initial,

  /// Figma `1:943` — keyboard, empty mask.
  keyboardEmpty,

  /// Figma `1:574` — keyboard, full number.
  keyboardFilled,
}

/// Phone entry stub covering Figma `1:710` / `1:943` / `1:574` UI phases.
class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _digitsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _digitsController.addListener(_onDigitsChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _digitsController
      ..removeListener(_onDigitsChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  void _onDigitsChanged() => setState(() {});

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
      _digitsController.text.replaceAll(RegExp(r'\D'), '');

  bool get _canConfirm => _digitsOnly.length >= 10;

  String get _routeNameForPhase => switch (_phase) {
        LoginPhoneUiPhase.initial => FescoRoutes.loginPhone,
        LoginPhoneUiPhase.keyboardEmpty =>
          FescoRoutes.loginPhoneKeyboardEmpty,
        LoginPhoneUiPhase.keyboardFilled =>
          FescoRoutes.loginPhoneKeyboardFilled,
      };

  String get _figmaNodeForPhase => switch (_phase) {
        LoginPhoneUiPhase.initial => '1:710',
        LoginPhoneUiPhase.keyboardEmpty => '1:943',
        LoginPhoneUiPhase.keyboardFilled => '1:574',
      };

  void _confirmPhone() {
    if (!_canConfirm) return;
    final phone = '+7$_digitsOnly';
    goToOtpConfirmation(context, phoneE164: phone);
  }

  @override
  Widget build(BuildContext context) {
    return FescoLoginScaffold(
      figmaNodeId: _figmaNodeForPhase,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _LogoPlaceholder(),
          const SizedBox(height: 32),
          Text(
            'Личный кабинет сотрудника',
            textAlign: TextAlign.center,
            style: FescoTypography.titleOnAccent(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Если у вас еще нет аккаунта,\nон будет создан автоматически',
            textAlign: TextAlign.center,
            style: FescoTypography.subtitleOnAccent(context),
          ),
          const SizedBox(height: 32),
          TextField(
            focusNode: _focusNode,
            controller: _digitsController,
            keyboardType: TextInputType.phone,
            style: FescoTypography.fieldValue(context),
            decoration: InputDecoration(
              labelText: 'Телефон',
              prefixText: '+7 ',
              hintText: _phase == LoginPhoneUiPhase.initial
                  ? null
                  : '(___) ___-__-__',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onTap: () {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
          ),
          const SizedBox(height: 24),
          FescoPrimaryButton(
            label: 'Подтвердить номер',
            enabled: _canConfirm,
            onPressed: _confirmPhone,
          ),
          const SizedBox(height: 16),
          Text(
            'route: $_routeNameForPhase',
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

class _LogoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: FescoColors.textColorDisabled.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'FescoLogoVertical (stub)',
        style: TextStyle(color: FescoColors.textInverse, fontSize: 12),
      ),
    );
  }
}
