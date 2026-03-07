import "dart:ui";

import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:shared_preferences/shared_preferences.dart";

class ThemeFunctions {
  static SharedPreferences? preferences;

  static Future<void> initThemeFunction() async {
    preferences = await SharedPreferences.getInstance();
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    systemChromeSetting(themeMode);
    await preferences!.setString("app_theme_mode", themeMode.toString());
  }

  static ThemeMode loadThemeMode() {
    assert(preferences != null, "Theme Function need to be init first");
    final String? savedThemeName = preferences!.getString("app_theme_mode");
    ThemeMode themeMode =
        savedThemeName == null
            ? ThemeMode.system
            : ThemeMode.values.firstWhere(
              (e) => e.toString() == savedThemeName,
            );
    systemChromeSetting(themeMode);
    return themeMode;
  }

  static void systemChromeSetting(ThemeMode themeMode) {
    if (themeMode == ThemeMode.dark) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    } else if (themeMode == ThemeMode.light) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    } else {
      if (PlatformDispatcher.instance.platformBrightness == Brightness.dark) {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      } else {
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      }
    }
  }

  static FlexScheme getFlexSchemeFromDB() {
    assert(preferences != null, "Theme Function need to be init first");
    int? schemeIndex = preferences!.getInt("flex_scheme_index");
    if (schemeIndex == null || schemeIndex >= FlexScheme.values.length) {
      return FlexScheme.tealM3; // Default Apple-level Teal color
    }
    return FlexScheme.values[schemeIndex];
  }

  static Future<void> setFlexSchemeToDB(FlexScheme scheme) async {
    assert(preferences != null, "Theme Function need to be init first");
    preferences!.setInt("flex_scheme_index", scheme.index);
  }

  // Deprecated fallback for backward compatibility
  static Color? getColorFromDB() {
    return FlexColor.schemes[getFlexSchemeFromDB()]!.light.primary;
  }
  static Future<void> setColorToDB(Color color) async {
    // No-op for now as we transition to setFlexSchemeToDB
  }

  static ThemeState getThemeState(FlexScheme scheme, ThemeMode mode) {
    // Derive primary dynamically from scheme
    final primary = FlexColor.schemes[scheme]!.light.primary;
    
    return ThemeState(
      themeMode: mode,
      flexScheme: scheme,
      primary: primary,
      primaryShade100: primary.withValues(alpha: 0.1),
      primaryShade200: primary.withValues(alpha: 0.2),
      primaryShade300: primary.withValues(alpha: 0.3),
      secondary: Colors.orange,
      mutedGray: Colors.grey.withValues(alpha: 0.2),
    );
  }
}

