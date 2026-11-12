import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'fesco_assets.dart';

/// `Fesco_new_logo_vert` — 186×80 per spec.
class FescoLogoVertical extends StatelessWidget {
  const FescoLogoVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        FescoAssets.logoVertical,
        width: 186,
        height: 80,
        fit: BoxFit.contain,
      ),
    );
  }
}
