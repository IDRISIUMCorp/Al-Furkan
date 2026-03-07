import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dynamic font size helper for Quran pages.
/// Uses ScreenUtil `.sp` for automatic screen adaptation.
/// Values adjusted for our designSize(360) vs reference library designWidth(392.7).
double getFontSize(int pageNumber, BuildContext context) {
  final media = MediaQuery.of(context);
  final isPortrait = media.orientation == Orientation.portrait;
  final shortestSide = media.size.shortestSide;

  // ── 1. Landscape mode ──
  if (!isPortrait) {
    return 31.sp;
  }

  // ── 2. Tablets & large screens (shortestSide > 600) ──
  if (shortestSide > 600) {
    return 13.5.sp;
  }

  // ── 3. Very small screens (width < 360) ──
  final screenWidth = media.size.width;
  if (screenWidth < 360) {
    return 17.5.sp;
  }

  // ── 4. First two pages (Fatihah & start of Baqarah) ──
  if (pageNumber == 1 || pageNumber == 2) {
    return 22.sp;
  }

  // ── 5. Per-page overrides ──
  if (pageNumber == 145 || pageNumber == 585) return 20.2.sp;
  if ([532, 533, 523, 577].contains(pageNumber)) return 20.sp;
  if (pageNumber == 116 || pageNumber == 156) return 20.8.sp;

  const size23Pages = [
    56, 57, 368, 269, 372, 376, 409, 435, 444, 448, 527, 535,
    565, 566, 569, 574, 575, 578, 581, 584, 587, 589, 590, 592, 593, 50, 568, 34,
  ];
  if (size23Pages.contains(pageNumber)) return 20.4.sp;

  if (pageNumber == 70) return 20.8.sp;
  if (pageNumber == 51 || pageNumber == 501) return 21.sp;

  const size228Pages = [576, 567, 371, 446, 447];
  if (size228Pages.contains(pageNumber)) return 20.3.sp;

  // ── 6. Default ──
  return 20.5.sp;
}

enum ScreenType { small, medium, large }

ScreenType getScreenType(BuildContext context) {
  final double screenWidth = MediaQuery.sizeOf(context).width;

  if (screenWidth < 360) {
    return ScreenType.small;
  } else if (screenWidth >= 360 && screenWidth < 600) {
    return ScreenType.medium;
  } else {
    return ScreenType.large;
  }
}

