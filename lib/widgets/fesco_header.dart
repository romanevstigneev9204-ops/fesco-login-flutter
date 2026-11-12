import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'fesco_assets.dart';

/// Status zone + optional back + trailing info (Figma header `1:814` / `1:1150`).
class FescoHeader extends StatelessWidget {
  const FescoHeader({
    super.key,
    this.showBack = false,
    this.onBack,
    this.showInfo = true,
    this.onInfo,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final bool showInfo;
  final VoidCallback? onInfo;

  static const double _toolbarHeight = 56;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _toolbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: showBack
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onBack,
                      icon: SvgPicture.asset(
                        FescoAssets.arrowBack,
                        width: 24,
                        height: 24,
                      ),
                    )
                  : null,
            ),
            const Spacer(),
            if (showInfo)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: onInfo,
                icon: SvgPicture.asset(
                  FescoAssets.infoCircle,
                  width: 24,
                  height: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
