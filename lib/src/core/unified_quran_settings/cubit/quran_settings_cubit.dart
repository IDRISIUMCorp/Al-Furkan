import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'quran_settings_state.dart';

class QuranSettingsCubit extends Cubit<QuranSettingsState> {
  static const String _boxName = 'quran_settings';
  static const String _kFontSize = 'font_size';
  static const String _kTheme = 'quran_theme';
  static const String _kTajweedEnabled = 'tajweed_enabled';
  static const String _kHighlightColorValue = 'highlight_color';
  static const String _kEnableTafsir = 'enable_tafsir';
  static const String _kEnableIrab = 'enable_irab';

  late Box _box;

  QuranSettingsCubit() : super(const QuranSettingsState()) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(_boxName);

    final fontSize = _box.get(_kFontSize, defaultValue: 23.0) as double;
    final themeString =
        _box.get(_kTheme, defaultValue: QuranTheme.oled.name) as String;
    final tajweedEnabled =
        _box.get(_kTajweedEnabled, defaultValue: true) as bool;
    final highlightColorValue =
        _box.get(_kHighlightColorValue, defaultValue: Colors.amber.value)
            as int;
    final enableTafsir = _box.get(_kEnableTafsir, defaultValue: true) as bool;
    final enableIrab = _box.get(_kEnableIrab, defaultValue: false) as bool;

    emit(
      QuranSettingsState(
        fontSize: fontSize,
        theme: QuranTheme.values.firstWhere(
          (e) => e.name == themeString,
          orElse: () => QuranTheme.oled,
        ),
        tajweedEnabled: tajweedEnabled,
        highlightColor: Color(highlightColorValue),
        enableTafsir: enableTafsir,
        enableIrab: enableIrab,
        isInitialized: true,
      ),
    );
  }

  void updateFontSize(double size) {
    if (!state.isInitialized) return;
    _box.put(_kFontSize, size);
    emit(state.copyWith(fontSize: size));
  }

  void updateTheme(QuranTheme theme) {
    if (!state.isInitialized) return;
    _box.put(_kTheme, theme.name);
    emit(state.copyWith(theme: theme));
  }

  void toggleTajweed(bool enabled) {
    if (!state.isInitialized) return;
    _box.put(_kTajweedEnabled, enabled);
    emit(state.copyWith(tajweedEnabled: enabled));
  }

  void updateHighlightColor(Color color) {
    if (!state.isInitialized) return;
    _box.put(_kHighlightColorValue, color.value);
    emit(state.copyWith(highlightColor: color));
  }

  void toggleTafsir(bool enabled) {
    if (!state.isInitialized) return;
    _box.put(_kEnableTafsir, enabled);
    emit(state.copyWith(enableTafsir: enabled));
  }

  void toggleIrab(bool enabled) {
    if (!state.isInitialized) return;
    _box.put(_kEnableIrab, enabled);
    emit(state.copyWith(enableIrab: enabled));
  }
}
