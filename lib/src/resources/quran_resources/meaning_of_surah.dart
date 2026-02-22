import "dart:convert";

import "package:al_quran_v3/main.dart";
import "package:al_quran_v3/src/resources/translation/language_cubit.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";

Map<String, dynamic> surahNameLocalization = {};
Map<String, dynamic> surahMeaningLocalization = {};

Future<void> loadMetaSurah() async {
  if (surahNameLocalization.isEmpty) {
    surahNameLocalization = jsonDecode(
      await rootBundle.loadString(
        "assets/meta_data/surah_name_localization.json",
      ),
    );
  }

  if (surahMeaningLocalization.isEmpty) {
    surahMeaningLocalization = jsonDecode(
      await rootBundle.loadString(
        "assets/meta_data/surah_meaning_localization.json",
      ),
    );
  }
}

String getSurahName(BuildContext? context, int index) {
  context ??= navigatorKey.currentContext!;
  if (surahNameLocalization.isEmpty) return "سورة $index";
  Locale locale = context.read<LanguageCubit>().state.locale;
  final data = surahNameLocalization[locale.languageCode] ??
      surahNameLocalization["en"] ??
      surahNameLocalization["ar"];
  if (data == null) return "سورة $index";
  final list = List<String>.from(data);
  if (index < 1 || index > list.length) return "سورة $index";
  return list[index - 1];
}

String getSurahNameArabic(int index) {
  if (surahNameLocalization.isEmpty || surahNameLocalization["ar"] == null) {
    return "سورة $index";
  }
  final list = List<String>.from(surahNameLocalization["ar"]);
  if (index < 1 || index > list.length) return "سورة $index";
  return list[index - 1];
}

String getSurahMeaning(BuildContext? context, int index) {
  context ??= navigatorKey.currentContext!;
  if (surahMeaningLocalization.isEmpty) return "";
  Locale locale = context.read<LanguageCubit>().state.locale;
  final data = surahMeaningLocalization[locale.languageCode] ??
      surahNameLocalization["en"];
  if (data == null) return "";
  final list = List<String>.from(data);
  if (index < 1 || index > list.length) return "";
  return list[index - 1];
}
