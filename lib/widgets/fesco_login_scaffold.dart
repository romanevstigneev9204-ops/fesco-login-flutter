import 'package:flutter/material.dart';

import '../theme/fesco_colors.dart';

/// Stub for spec component `FescoLoginScaffold` — pattern/logo/header TBD.
class FescoLoginScaffold extends StatelessWidget {
  const FescoLoginScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.showInfo = true,
    this.figmaNodeId,
  });

  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showInfo;
  final String? figmaNodeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FescoColors.bgAccentActive,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderBar(
              showBack: showBack,
              onBack: onBack,
              showInfo: showInfo,
            ),
            if (figmaNodeId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Figma $figmaNodeId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FescoColors.textColorDisabled,
                    fontSize: 10,
                  ),
                ),
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
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.showBack,
    this.onBack,
    required this.showInfo,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: FescoColors.textInverse),
              )
            else
              const SizedBox(width: 48),
            const Spacer(),
            if (showInfo)
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline, color: FescoColors.textInverse),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
