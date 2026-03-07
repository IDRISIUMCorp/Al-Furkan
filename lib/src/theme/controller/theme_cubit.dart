import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/theme/functions/theme_functions.dart";
import "package:flutter/material.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
    : super(
        ThemeFunctions.getThemeState(
          ThemeFunctions.getFlexSchemeFromDB(),
          ThemeFunctions.loadThemeMode(),
        ),
      );

  void setTheme(ThemeMode themeMode) async {
    ThemeFunctions.setThemeMode(themeMode);
    emit(state.copyWith(themeMode: themeMode));
  }

  void changeFlexScheme(FlexScheme flexScheme) async {
    await ThemeFunctions.setFlexSchemeToDB(flexScheme);
    emit(ThemeFunctions.getThemeState(flexScheme, state.themeMode));
  }

  // Deprecated but kept to prevent breaking other files temporarily
  void changePrimaryColor(Color color) async {
     // Currently mapped to teal, but realistically should be replaced across UI
     changeFlexScheme(FlexScheme.tealM3);
  }

  void refresh() {
    emit(state.copyWith());
  }
}


