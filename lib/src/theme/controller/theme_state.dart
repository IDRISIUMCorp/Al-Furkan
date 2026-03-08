import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

class ThemeState {
  final ThemeMode themeMode;
  final FlexScheme flexScheme;

  const ThemeState({
    required this.themeMode,
    required this.flexScheme,
  });

  bool get _isDark {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  FlexSchemeColor get _colors => _isDark ? FlexColor.schemes[flexScheme]!.dark : FlexColor.schemes[flexScheme]!.light;

  Color get primary => _colors.primary;
  Color get primaryShade100 => _colors.primaryContainer;
  Color get primaryShade200 => _colors.tertiary;
  Color get primaryShade300 => _colors.tertiaryContainer;
  Color get secondary => _colors.secondary;
  Color get mutedGray => Colors.grey.shade600;

  ThemeState copyWith({
    ThemeMode? themeMode,
    FlexScheme? flexScheme,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      flexScheme: flexScheme ?? this.flexScheme,
    );
  }
}


