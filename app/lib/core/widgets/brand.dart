import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// The hospital's mark — the pink pin with mother and child — traced from the
/// logo so it stays sharp at any size (see `tools/build_brand_assets.py`).
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/mark.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: context.tr('مستشفى دار الأمومة', 'Dar El Omouma Hospital'),
    );
  }
}

/// The mark with the hospital's name beneath it, in the logo's teal.
class BrandLockup extends StatelessWidget {
  const BrandLockup({this.markSize = 112, this.onDark = false, super.key});

  final double markSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final nameColour = onDark ? Colors.white : AppColors.accent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(height: 12),
        Text(
          context.tr('مستشفى', 'Hospital'),
          style: TextStyle(
            fontSize: markSize * 0.15,
            color: nameColour.withValues(alpha: 0.85),
            height: 1.1,
          ),
        ),
        Text(
          context.tr('دار الأمومة', 'Dar El Omouma'),
          style: TextStyle(
            fontSize: markSize * 0.26,
            fontWeight: FontWeight.w800,
            color: nameColour,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
