import 'package:flutter/material.dart';

/// Responsive breakpoints for the Al-Quran app.
/// Provides consistent sizing utilities without needing flutter_screenutil.
class Responsive {
  Responsive._();

  /// Small phone threshold (width < 360)
  static const double kSmallPhone = 360;

  /// Standard phone threshold (width < 400)
  static const double kStandardPhone = 400;

  /// Large phone / small tablet threshold (width < 600)
  static const double kLargePhone = 600;

  /// Check if the screen is a small phone
  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < kSmallPhone;

  /// Check if the screen is compact (phone-sized)
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < kStandardPhone;

  /// Get horizontal padding that adapts to screen width
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < kSmallPhone) return 12;
    if (width < kStandardPhone) return 16;
    if (width < kLargePhone) return 20;
    return 24;
  }

  /// Get safe bottom sheet height (never exceeds 90% of screen)
  static double safeSheetHeight(BuildContext context, {double fraction = 0.86}) {
    final height = MediaQuery.of(context).size.height;
    return (height * fraction).clamp(300.0, height * 0.95);
  }

  /// Get font scale factor for adaptive text
  static double fontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < kSmallPhone) return 0.88;
    if (width < kStandardPhone) return 0.94;
    return 1.0;
  }

  /// Get icon size that adapts to screen
  static double iconSize(BuildContext context, {double base = 24}) {
    return base * fontScale(context);
  }

  /// Get button size that adapts to screen
  static double buttonSize(BuildContext context, {double base = 30}) {
    final scale = fontScale(context);
    return (base * scale).clamp(24.0, base);
  }
}

/// A responsive wrapper that rebuilds with screen metrics.
/// Use for content that must adapt to orientation/size changes.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}
