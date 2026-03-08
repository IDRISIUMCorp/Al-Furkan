import "dart:ui";

import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
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
    String? schemeName = preferences!.getString("flex_scheme");
    if (schemeName == null) return FlexScheme.flutterDash;
    return FlexScheme.values.firstWhere(
      (e) => e.toString() == schemeName,
      orElse: () => FlexScheme.flutterDash,
    );
  }

  static Future<void> setFlexSchemeToDB(FlexScheme scheme) async {
    assert(preferences != null, "Theme Function need to be init first");
    await preferences!.setString("flex_scheme", scheme.toString());
  }

  static ThemeState getThemeState(FlexScheme scheme, ThemeMode mode) {
    return ThemeState(
      themeMode: mode,
      flexScheme: scheme,
    );
  }
}
