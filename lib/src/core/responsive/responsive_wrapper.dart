import 'package:flutter/material.dart';

/// Wrapper لضبط الواجهات بحسب حجم الشاشة
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWrapper({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 &&
      MediaQuery.sizeOf(context).width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    
    if (size.width >= 1024 && desktop != null) {
      return desktop!;
    } else if (size.width >= 600 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
