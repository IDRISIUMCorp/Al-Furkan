part of 'quran_settings_cubit.dart';

enum QuranTheme {
  oled,
  nightBlue,
  custom,
  graphite,
  midnightPurple,
  sepia,
  cream,
  paperWhite,
  sand,
}

class QuranSettingsState {
  final double fontSize;
  final QuranTheme theme;
  final bool tajweedEnabled;
  final Color highlightColor;
  final bool enableTafsir;
  final bool enableIrab;
  final bool isInitialized;

  const QuranSettingsState({
    this.fontSize = 23.0,
    this.theme = QuranTheme.oled,
    this.tajweedEnabled = true,
    this.highlightColor = Colors.amber,
    this.enableTafsir = true,
    this.enableIrab = false,
    this.isInitialized = false,
  });

  QuranSettingsState copyWith({
    double? fontSize,
    QuranTheme? theme,
    bool? tajweedEnabled,
    Color? highlightColor,
    bool? enableTafsir,
    bool? enableIrab,
    bool? isInitialized,
  }) {
    return QuranSettingsState(
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      tajweedEnabled: tajweedEnabled ?? this.tajweedEnabled,
      highlightColor: highlightColor ?? this.highlightColor,
      enableTafsir: enableTafsir ?? this.enableTafsir,
      enableIrab: enableIrab ?? this.enableIrab,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // --- Helpers for UI Theme mapping ---

  Color get backgroundColor {
    switch (theme) {
      case QuranTheme.oled:
        return Colors.black;
      case QuranTheme.nightBlue:
        return const Color(0xFF0F172A); // Slate 900
      case QuranTheme.custom:
        return Colors.black; // Fallback, could be expanded
      case QuranTheme.graphite:
        return const Color(0xFF121417);
      case QuranTheme.midnightPurple:
        return const Color(0xFF140B2D);
      case QuranTheme.sepia:
        return const Color(0xFFF4ECD8);
      case QuranTheme.cream:
        return const Color(0xFFFFFDD0);
      case QuranTheme.paperWhite:
        return Colors.white;
      case QuranTheme.sand:
        return const Color(0xFFF3E7D3);
    }
  }

  Color get textColor {
    switch (theme) {
      case QuranTheme.oled:
      case QuranTheme.nightBlue:
      case QuranTheme.graphite:
      case QuranTheme.midnightPurple:
        return Colors.white;
      case QuranTheme.sepia:
      case QuranTheme.cream:
      case QuranTheme.paperWhite:
      case QuranTheme.sand:
        return Colors.black87;
      case QuranTheme.custom:
        return Colors.white;
    }
  }
}
