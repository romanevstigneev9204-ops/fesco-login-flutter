import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'fesco_assets.dart';

/// Decorative `pattern-03` layer from the login screens (right edge).
class FescoPatternBackground extends StatelessWidget {
  const FescoPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -120,
              top: -40,
              bottom: 0,
              width: MediaQuery.sizeOf(context).width + 200,
              child: Opacity(
                opacity: 0.55,
                child: SvgPicture.asset(
                  FescoAssets.pattern03,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            Positioned(
              left: -200,
              top: 80,
              child: Opacity(
                opacity: 0.35,
                child: SvgPicture.asset(
                  FescoAssets.patternBg,
                  width: 360,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
