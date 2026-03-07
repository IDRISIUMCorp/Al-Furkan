import "package:flutter/material.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";

class ThemeState {
  final ThemeMode themeMode;
  final FlexScheme flexScheme;
  // Kept for backward compatibility in some components
  final Color primary;
  final Color primaryShade100;
  final Color primaryShade200;
  final Color primaryShade300;
  final Color secondary;
  final Color mutedGray;

  ThemeState({
    required this.themeMode,
    required this.flexScheme,
    required this.primary,
    required this.primaryShade100,
    required this.primaryShade200,
    required this.primaryShade300,
    required this.secondary,
    required this.mutedGray,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
    Color? primary,
    Color? primaryShade100,
    Color? primaryShade200,
    Color? primaryShade300,
    Color? secondary,
    Color? mutedGray,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
      primary: primary ?? this.primary,
      primaryShade100: primaryShade100 ?? this.primaryShade100,
      primaryShade200: primaryShade200 ?? this.primaryShade200,
      primaryShade300: primaryShade300 ?? this.primaryShade300,
      secondary: secondary ?? this.secondary,
      mutedGray: mutedGray ?? this.mutedGray,
    );
  }
}

