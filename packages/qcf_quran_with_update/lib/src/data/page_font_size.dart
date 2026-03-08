import 'package:flutter/material.dart';

/// Calculates the optimal font size for QCF fonts based on the available width.
/// The [maxWidth] should come from a LayoutBuilder or similar constrained context.
double getFontSize(int pageNumber, double maxWidth) {
  // Base scale factor assuming 400 logical pixels width as a baseline for the default sizes
  double scaleFactor = maxWidth / 400.0;

  double pageBaseSize = 23.1; // default

  if (pageNumber == 1 || pageNumber == 2) {
    pageBaseSize = 25;
  } else if (pageNumber == 145 || pageNumber == 585) {
    pageBaseSize = 22.7;
  } else if (pageNumber == 532 ||
      pageNumber == 533 ||
      pageNumber == 523 ||
      pageNumber == 577) {
    pageBaseSize = 22.5;
  } else if (pageNumber == 116 || pageNumber == 156) {
    pageBaseSize = 23.4;
  } else if ([
    56,
    57,
    368,
    269,
    372,
    376,
    409,
    435,
    444,
    448,
    527,
    535,
    565,
    566,
    569,
    574,
    578,
    581,
    584,
    587,
    589,
    590,
    592,
    593,
    50,
    568,
  ].contains(pageNumber)) {
    pageBaseSize = 23;
  } else if (pageNumber == 34) {
    pageBaseSize = 23;
  } else if (pageNumber == 70) {
    pageBaseSize = 23.5;
  } else if (pageNumber == 51 || pageNumber == 501) {
    pageBaseSize = 23.7;
  } else if ([576, 567, 577, 371, 446, 447, 581, 575].contains(pageNumber)) {
    pageBaseSize = 22.8;
  }

  // Calculate scaled size and clamp it to reasonable bounds (10 to 150)
  return (pageBaseSize * scaleFactor).clamp(10.0, 150.0);
}

// Deprecated: Kept for backwards compatibility but not used in core qcf widgets anymore.
enum ScreenType { small, medium, large }

ScreenType getScreenType(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 360) {
    return ScreenType.small;
  } else if (screenWidth >= 360 && screenWidth < 600) {
    return ScreenType.medium;
  } else {
    return ScreenType.large;
  }
}
