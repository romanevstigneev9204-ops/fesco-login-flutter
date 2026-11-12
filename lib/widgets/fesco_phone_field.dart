import 'package:flutter/material.dart';

import '../theme/fesco_colors.dart';
import '../theme/fesco_typography.dart';
import 'phone_mask_formatter.dart';

/// Floating-style phone field with `+7` mask per Figma input master.
class FescoPhoneField extends StatelessWidget {
  const FescoPhoneField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onSubmitted;

  void _ensureMaskOnTap() {
    final digits = PhoneMaskFormatter.extractDigits(controller.text);
    if (digits.isEmpty && controller.text.trim() == '+7') {
      controller.text = PhoneMaskFormatter.maskPlaceholder();
      controller.selection = TextSelection.collapsed(offset: '+7 '.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FescoColors.bgPrimary,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: FescoColors.borderFieldDefault),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Телефон', style: FescoTypography.fieldLabel(context)),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                style: FescoTypography.fieldValue(context),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
                inputFormatters: [
                  PhoneMaskFormatter(),
                ],
                onTap: _ensureMaskOnTap,
                onSubmitted: (_) => onSubmitted?.call(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
