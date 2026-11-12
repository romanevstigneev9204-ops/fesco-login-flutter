import 'package:flutter/material.dart';

import '../theme/fesco_colors.dart';
import 'fesco_header.dart';
import 'fesco_pattern_background.dart';

/// Blue login shell: pattern, header, padded body (Figma `FescoLoginScaffold`).
class FescoLoginScaffold extends StatelessWidget {
  const FescoLoginScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.showInfo = true,
    this.onInfo,
    this.bottomOverlay,
  });

  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showInfo;
  final VoidCallback? onInfo;
  final Widget? bottomOverlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FescoColors.bgAccentActive,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const FescoPatternBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FescoHeader(
                  showBack: showBack,
                  onBack: onBack,
                  showInfo: showInfo,
                  onInfo: onInfo,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
          if (bottomOverlay != null) bottomOverlay!,
        ],
      ),
    );
  }
}
