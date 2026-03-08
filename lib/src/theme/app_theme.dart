import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Theme settings for the whole app
  static ThemeData lightTheme(FlexScheme scheme) {
    final theme = FlexThemeData.light(
      scheme: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 12.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );

    return theme.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: theme.colorScheme.onSurface),
      ),
    );
  }

  static ThemeData darkTheme(FlexScheme scheme) {
    final theme = FlexThemeData.dark(
      scheme: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 12.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
    );

    return theme.copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: theme.colorScheme.onSurface),
      ),
    );
  }
}
