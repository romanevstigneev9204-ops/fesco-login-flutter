import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'fesco_assets.dart';

/// Decorative `pattern-03` layer from the login screens (right edge).
class FescoPatternBackground extends StatelessWidget {
  const FescoPatternBackground({super.key, this.showOtpBottomStrip = false});

  final bool showOtpBottomStrip;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -120,
              top: -40,
              bottom: 0,
              width: screenW + 200,
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
              left: -335,
              top: -91,
              child: Opacity(
                opacity: 0.9,
                child: SvgPicture.asset(
                  FescoAssets.patternBg,
                  width: 695,
                  height: 435,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            if (showOtpBottomStrip)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 213,
                child: Image.asset(
                  FescoAssets.otpBottomShip,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
