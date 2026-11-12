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
    return Container(
      decoration: BoxDecoration(
        color: FescoColors.bgPrimary,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: FescoColors.borderFieldDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Телефон', style: FescoTypography.fieldLabel(context)),
          const SizedBox(height: 2),
          SizedBox(
            height: 22,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              style: FescoTypography.fieldValue(context),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                PhoneMaskFormatter(),
              ],
              onTap: _ensureMaskOnTap,
              onSubmitted: (_) => onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
