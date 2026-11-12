import 'package:flutter/material.dart';

import '../theme/fesco_colors.dart';
import '../theme/fesco_typography.dart';

/// Stub for spec component `FescoPrimaryButton` (320×44, 2px radius).
class FescoPrimaryButton extends StatelessWidget {
  const FescoPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background = enabled ? FescoColors.bgPrimary : FescoColors.primaryButtonDisabledFill;
    final textStyle = enabled
        ? FescoTypography.primaryButtonEnabled(context)
        : FescoTypography.primaryButtonDisabled(context);

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(2),
          child: Center(
            child: Text(label, style: textStyle),
          ),
        ),
      ),
    );
  }
}
