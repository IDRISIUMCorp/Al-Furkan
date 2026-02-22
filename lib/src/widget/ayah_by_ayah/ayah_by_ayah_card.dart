import "dart:developer";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_sajda.dart"
    show metaDataSajda;
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:al_quran_v3/src/core/audio/cubit/audio_ui_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_position_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_state_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/segmented_quran_reciter_cubit.dart";
import "package:al_quran_v3/src/core/audio/model/audio_player_position_model.dart";
import "package:al_quran_v3/src/core/audio/model/ayahkey_management.dart";
import "package:al_quran_v3/src/core/audio/model/recitation_info_model.dart";
import "package:al_quran_v3/src/core/audio/player/audio_player_manager.dart";
import "package:al_quran_v3/src/resources/quran_resources/language_resources.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/translation_book_model.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_to_highlight.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:al_quran_v3/src/utils/quran_resources/get_translation_with_word_by_word.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/word_by_word_function.dart";
import "package:al_quran_v3/src/utils/quran_word/show_popup_word_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/widget/add_collection_popup/add_note_popup.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_by_ayah_in_scroll_info_cubit.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_cubit.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_state.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/screen/tafsir_view/tafsir_view.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/theme/values/values.dart";
import "package:al_quran_v3/src/widget/history/cubit/quran_history_cubit.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:al_quran_v3/src/widget/quran_script/script_processor.dart";
import "package:dartx/dartx.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:al_quran_v3/src/core/navigation/wahy_page_route.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_html/flutter_html.dart";
import "package:gap/gap.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:just_audio/just_audio.dart" as just_audio;
import "package:qcf_quran/qcf_quran.dart" as qcf;
import "package:visibility_detector/visibility_detector.dart";

import "package:al_quran_v3/src/screen/quran_reader/widgets/ayah_options_sheet.dart";
import "package:al_quran_v3/src/widget/ayah_by_ayah/share_bottom_dialog.dart";

const String _kWahyBookmarks = "wahy_bookmarks";
const String _kWahyNotes = "wahy_notes";

Future<void> _setWahyBookmarkColorForAyahKey({
  required String ayahKey,
  required String colorId,
}) async {
  final box = Hive.box("user");
  final raw = box.get(_kWahyBookmarks, defaultValue: const []) as List?;
  final list = (raw ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final now = DateTime.now().toIso8601String();
  final idx = list.indexWhere((e) => (e["ayahKey"] as String?) == ayahKey);
  final entry = <String, dynamic>{
    "ayahKey": ayahKey,
    "color": colorId,
    "updatedAt": now,
    "createdAt": idx == -1 ? now : (list[idx]["createdAt"] ?? now),
  };
  if (idx == -1) {
    list.insert(0, entry);
  } else {
    list[idx] = entry;
  }
  await box.put(_kWahyBookmarks, list);
}

Future<void> _showWahyBookmarkColorSheet({
  required BuildContext context,
  required ThemeState themeState,
  required String ayahKey,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F1E6);
  final card = isDark ? const Color(0xFF252525) : const Color(0xFFFFF9F2);
  final colors = <String, ({String name, Color color})>{
    "red": (name: "الأحمر", color: const Color(0xFFB3261E)),
    "yellow": (name: "الأصفر", color: const Color(0xFFB68A00)),
    "green": (name: "الأخضر", color: themeState.primary),
    "blue": (name: "الأزرق", color: const Color(0xFF2962FF)),
  };

  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: colors.entries.map((entry) {
                        return ListTile(
                          onTap: () async {
                            Navigator.pop(sheet);
                            await _setWahyBookmarkColorForAyahKey(
                              ayahKey: ayahKey,
                              colorId: entry.key,
                            );
                          },
                          title: Text(
                            entry.value.name,
                            style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : null),
                          ),
                          trailing: Icon(
                            Icons.bookmark_rounded,
                            color: entry.value.color,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showWahyAddNoteSheet({
  required BuildContext context,
  required ThemeState themeState,
  required String ayahKey,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F1E6);
  final controller = TextEditingController();

  final result = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "ملاحظة جديدة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: themeState.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 7,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: "اكتب ملاحظتك هنا…",
                        filled: true,
                        fillColor: isDark ? const Color(0xFF252525) : const Color(0xFFFFF9F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: themeState.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeState.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx, controller.text.trim());
                        },
                        child: const Text(
                          "حفظ الملاحظة",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  final text = (result ?? "").trim();
  if (text.isEmpty) return;
  final box = Hive.box("user");
  final raw = box.get(_kWahyNotes, defaultValue: const []) as List?;
  final list = (raw ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  list.insert(0, {
    "ayahKey": ayahKey,
    "text": text,
    "createdAt": DateTime.now().toIso8601String(),
  });
  await box.put(_kWahyNotes, list);
}

final Map<String, Future<String?>> _defaultTafsirFutureCache = <String, Future<String?>>{};
final Map<String, String?> _defaultTafsirTextCache = <String, String?>{};
final Map<String, String> _defaultTafsirBookNameCache = <String, String>{};

Widget getAyahByAyahTafsirCard({
  dynamic key,
  required String ayahKey,
  required BuildContext context,
  bool showTopOptions = true,
  bool keepMargin = true,
}) {
  final l10n = AppLocalizations.of(context);
  final surahNumber = int.parse(ayahKey.split(":")[0]);
  final ayahNumber = int.parse(ayahKey.split(":")[1]);
  final surahInfoModel = SurahInfoModel.fromMap(metaDataSurah["$surahNumber"]!);
  final bool showSurahBanner = ayahNumber == 1;

  String? sanitizeTafsirTextLocal(String? text) {
    if (text == null) return null;
    var t = text;
    t = t.replaceAll(RegExp(r"```[\s\S]*?```"), "");
    t = t.replaceAll(RegExp(r"<[^>]*>"), " ");
    t = t.replaceAll("&nbsp;", " ");
    t = t.replaceAll("&quot;", '"');
    t = t.replaceAll("&amp;", "&");
    t = t.replaceAll(RegExp(r"\s+"), " ").trim();
    return t;
  }

  Future<String?> cachedLoadDefaultTafsir(String key) {
    final cached = _defaultTafsirTextCache[key];
    if (cached != null && cached.trim().isNotEmpty) {
      return Future.value(cached);
    }

    return _defaultTafsirFutureCache.putIfAbsent(key, () async {
      final selected = await QuranTafsirFunction.getTafsirSelections() ?? [];
      if (selected.isEmpty) return null;

      TafsirBookModel? book;
      for (final b in selected) {
        if (b.name.contains("الميسر")) {
          book = b;
          break;
        }
      }
      book ??= selected.first;

      _defaultTafsirBookNameCache[key] = book.name;
      final t = await QuranTafsirFunction.getResolvedTafsirTextForBook(book, key);
      final sanitized = sanitizeTafsirTextLocal(t);
      _defaultTafsirTextCache[key] = sanitized;
      return sanitized;
    });
  }

  return BlocBuilder<ThemeCubit, ThemeState>(
    builder: (context, themeState) {
      return BlocBuilder<QuranViewCubit, QuranViewState>(
        buildWhen: (previous, current) => current != previous,
        builder: (context, quranViewState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F1E6);
          final card = isDark ? const Color(0xFF252525) : const Color(0xFFEFE3D2);
          final onBg = isDark ? Colors.white : const Color(0xFF1B1B1B);

          final qcfTheme = qcf.QcfThemeData.sepia().copyWith(
            pageBackgroundColor: bg,
            headerBackgroundColor: card,
            headerTextColor: onBg,
            verseTextColor: onBg,
            verseNumberColor: onBg,
          );

          return VisibilityDetector(
            key: Key("tafsir_$ayahKey"),
            onVisibilityChanged: (info) {
              if (!context.mounted) return;
              context.read<QuranHistoryCubit>().addHistory(ayahKey: ayahKey);
              try {
                context.read<AyahByAyahInScrollInfoCubit>().setData(
                  surahInfoModel: surahInfoModel,
                  dropdownAyahKey: ayahKey,
                );
              } catch (_) {}
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              key: key,
              margin:
                  keepMargin
                      ? const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12)
                      : null,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    if (showSurahBanner) ...[
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.92,
                          child: Transform.scale(
                            scale: 1.05,
                            child: qcf.HeaderWidget(
                              suraNumber: surahNumber,
                              theme: qcfTheme,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Center(
                      child: ScriptProcessor(
                        scriptInfo: ScriptInfo(
                          surahNumber: surahNumber,
                          ayahNumber: ayahNumber,
                          quranScriptType: quranViewState.quranScriptType,
                          showWordHighlights: false,
                          skipWordTap: false,
                          textAlign: TextAlign.justify,
                          textStyle: TextStyle(
                            fontSize: (quranViewState.fontSize - 2).clamp(18, 32),
                            height: 2.05,
                            color: onBg,
                          ),
                        ),
                        themeState: themeState,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _defaultTafsirBookNameCache[ayahKey] ?? "التفسير",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: onBg.withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: FutureBuilder<String?>(
                          future: cachedLoadDefaultTafsir(ayahKey),
                          builder: (context, snapshot) {
                            final t = snapshot.data?.trim();
                            if (t == null || t.isEmpty) {
                              return Text(
                                l10n.tafsirNotAvailable(ayahKey),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(height: 1.7),
                              );
                            }
                            return SelectableText(
                              t,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.9,
                                fontWeight: FontWeight.w600,
                                color: onBg,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget getAyahByAyahCard({
  dynamic key,
  required String ayahKey,
  required BuildContext context,
  bool? showFullKey,
  bool showTopOptions = true,
  bool showOnlyAyah = false,
  bool keepMargin = true,
  required List<TranslationOfAyah> translationListWithInfo,
  required List wordByWord,
}) {
  AppLocalizations? l10n = AppLocalizations.of(context);

  int surahNumber = int.parse(ayahKey.toString().split(":")[0]);
  int ayahNumber = int.parse(ayahKey.toString().split(":")[1]);
  List<TranslationBookModel?> translationBookInfoList =
      translationListWithInfo
          .map<TranslationBookModel?>((e) => e.bookInfo)
          .toList();
  List<String> translationList =
      translationListWithInfo
          .map<String>((e) => e.translation?["t"] ?? "Translation Not Found")
          .toList();
  translationList =
      translationList.map((e) => e.replaceAll(">", "> ")).toList();
  List<Map> footNoteList =
      translationListWithInfo
          .map<Map>((e) => e.translation?["f"] ?? {})
          .toList();
  List<Map<int, String>> footNoteAsStringMap = [];
  for (int index = 0; index < footNoteList.length; index++) {
    Map footNote = footNoteList[index];
    String footNoteAsString = "\n";
    if (footNote.isNotEmpty) {
      footNote.forEach((key, value) {
        footNoteAsString += "$key. $value\n";
      });
    }
    if (footNote.isNotEmpty) {
      footNoteAsStringMap.add({index: footNoteAsString});
    } else {
      footNoteAsStringMap.add({});
    }
  }

  bool supportsWordByWord = false;
  final metaDataOfWordByWord = WordByWordFunction.getSelectedWordByWordBook();
  if (metaDataOfWordByWord != null) {
    supportsWordByWord = true;
  }

  SurahInfoModel surahInfoModel = SurahInfoModel.fromMap(
    metaDataSurah["$surahNumber"]!,
  );

  bool isSajdaAyah = false;
  bool isSajdaRequired = false;
  for (Map sajdaAyah in metaDataSajda) {
    if (sajdaAyah["verse_key"] == ayahKey) {
      isSajdaAyah = true;
      isSajdaRequired = sajdaAyah["required"];
      break;
    }
  }

  return BlocBuilder<ThemeCubit, ThemeState>(
    builder: (context, themeState) {
      return BlocBuilder<QuranViewCubit, QuranViewState>(
        buildWhen: (previous, current) {
          return current != previous;
        },
        builder: (context, quranViewState) {
          return VisibilityDetector(
            key: Key(ayahKey),
            onVisibilityChanged: (info) {
              if (!context.mounted) {
                return;
              }
              context.read<QuranHistoryCubit>().addHistory(ayahKey: ayahKey);
              try {
                SurahInfoModel surahInfoModel = SurahInfoModel.fromMap(
                  metaDataSurah[ayahKey.split(":").first]!,
                );

                context.read<AyahByAyahInScrollInfoCubit>().setData(
                  surahInfoModel: surahInfoModel,
                  dropdownAyahKey: ayahKey,
                );
              } catch (e) {
                log(e.toString());
              }
            },
            child: BlocBuilder<AyahToHighlight, String?>(
              buildWhen: (previous, current) {
                return current != previous;
              },
              builder: (context, ayahToHighlightState) {
                final bool isHighlighted = ayahToHighlightState == ayahKey;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onLongPress: () {
                        final words = QuranScriptFunction.getWordListOfAyah(
                          quranViewState.quranScriptType,
                          surahNumber.toString(),
                          ayahNumber.toString(),
                        );
                        final stripped = words.join(" ").replaceAll(RegExp(r"<[^>]+>"), "").replaceAll(RegExp(r"\s+"), " ").trim();
                        final overlayContext = Navigator.of(context).overlay?.context ?? context;
                        AyahOptionsSheet.show(
                          context: overlayContext,
                          ayahKey: ayahKey,
                          ayahText: stripped,
                          // Optional hooks can be added here
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        key: key,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width < 360 ? 14 : 24,
                          vertical: MediaQuery.of(context).size.width < 360 ? 16 : 24,
                ),
                margin: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width < 360 ? 10 : 20,
                  right: MediaQuery.of(context).size.width < 360 ? 10 : 20,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0x1A147b6a) // Subtle Green Highlight (AppColors.ayahHighlightDark)
                      : Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E2121) // AppColors.darkSurface
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20), // Premium rounding
                  boxShadow: [
                    if (!isHighlighted)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],  ),
                  child: Column(
                    children: [
                      if (!(showTopOptions == false) &&
                          !quranViewState.hideToolbar)
                        getToolbarWidget(
                          showFullKey,
                          surahInfoModel,
                          ayahKey,
                          ayahNumber,
                          context,
                          surahNumber,
                          translationList,
                          footNoteAsStringMap,
                          translationBookInfoList,
                          themeState,
                        ),
                      if (!quranViewState.hideQuranAyah) const Gap(10),
                      if (!quranViewState.hideQuranAyah)
                        quranAyahWidget(
                          surahNumber,
                          ayahNumber,
                          quranViewState,
                          themeState,
                        ),
                      if (!showOnlyAyah && !quranViewState.hideTranslation)
                        const Gap(5),
                      if (isSajdaAyah)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(roundedRadius),
                          ),
                          height: 35,

                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image(
                                height: 25,
                                width: 25,
                                image: const AssetImage(
                                  "assets/img/sajadah.png",
                                ),
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.grey.shade900
                                        : Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                              const Gap(10),
                              Text(
                                l10n.sajdaAyah,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Gap(8),
                              const Text("-"),
                              const Gap(8),
                              Text(
                                isSajdaRequired ? l10n.required : l10n.optional,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isSajdaAyah) const Gap(5),

                      if (!showOnlyAyah && !quranViewState.hideTranslation)
                        const Gap(5),
                      if (!showOnlyAyah && !quranViewState.hideTranslation)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.translationTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      if (!showOnlyAyah && !quranViewState.hideTranslation)
                        const Gap(5),
                      if (!showOnlyAyah && !quranViewState.hideTranslation)
                        getTranslationWithFootNoteWidget(
                          context,
                          translationList,
                          footNoteAsStringMap,
                          translationBookInfoList,
                          quranViewState,
                          showOnlyAyah,
                          l10n,
                        ),

                      if (supportsWordByWord &&
                          !quranViewState.alwaysOpenWordByWord &&
                          !quranViewState.hideWordByWord)
                        getWordByWordExpandCloseWidget(context, ayahKey),
                      if (supportsWordByWord && !quranViewState.hideWordByWord)
                        const Gap(5),
                      if (supportsWordByWord && !quranViewState.hideWordByWord)
                        getWordByWordWidget(
                          context,
                          ayahKey,
                          quranViewState,
                          wordByWord,
                          surahNumber,
                          ayahNumber,
                        ),
                    ],
                  ),
                ),
               ),
                  );
              },
            ),
          );
        },
      );
    },
  );
}

class _AyahStatusIndicators extends StatelessWidget {
  final String ayahKey;
  final ThemeState themeState;

  const _AyahStatusIndicators({required this.ayahKey, required this.themeState});

  bool _isAyahBookmarked(List<Map<String, dynamic>> list) {
    return list.any((e) => (e["ayahKey"] as String?) == ayahKey);
  }

  bool _isAyahNoted(List<Map<String, dynamic>> list) {
    return list.any((e) => (e["ayahKey"] as String?) == ayahKey);
  }

  bool _isAyahStarred(List<String> list) {
    return list.contains(ayahKey);
  }

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box("user");

    return ValueListenableBuilder(
      valueListenable: userBox.listenable(),
      builder: (context, _, __) {
        final rawBookmarks =
            userBox.get(_kWahyBookmarks, defaultValue: const []) as List?;
        final rawNotes = userBox.get(_kWahyNotes, defaultValue: const []) as List?;
        final rawStarred = userBox.get("wahy_starred", defaultValue: const []) as List?;

        final bookmarks = (rawBookmarks ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final notes = (rawNotes ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final starred = List<String>.from(rawStarred ?? const []);

        final isBookmarked = _isAyahBookmarked(bookmarks);
        final isNoted = _isAyahNoted(notes);
        final isStarred = _isAyahStarred(starred);

        if (!isBookmarked && !isNoted && !isStarred) {
          return const SizedBox.shrink();
        }

        Widget dot(Color c) {
          return Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStarred) dot(const Color(0xFFF4B400)),
            if (isStarred && isBookmarked) const Gap(6),
            if (isBookmarked) dot(themeState.primary),
            if ((isStarred || isBookmarked) && isNoted) const Gap(6),
            if (isNoted) dot(const Color(0xFF2962FF)),
          ],
        );
      },
    );
  }
}

Align getWordByWordWidget(
  BuildContext context,
  String ayahKey,
  QuranViewState quranViewState,
  List<dynamic> wordByWord,
  int surahNumber,
  int ayahNumber,
) {
  ThemeState themeState = context.read<ThemeCubit>().state;
  return Align(
    alignment: Alignment.centerRight,
    child: BlocBuilder<SegmentedQuranReciterCubit, ReciterInfoModel>(
      builder: (context, segmentsREciterSate) {
        String? highlightingWordIndex;
        List<List>? segments = context
            .read<SegmentedQuranReciterCubit>()
            .getAyahSegments(ayahKey);
        return BlocBuilder<
          AyahByAyahInScrollInfoCubit,
          AyahByAyahInScrollInfoState
        >(
          builder: (context, ayahScrollState) {
            return BlocBuilder<PlayerPositionCubit, AudioPlayerPositionModel>(
              buildWhen: (previous, current) {
                String? currentAyahKey =
                    context.read<AyahKeyCubit>().state.current;
                if (currentAyahKey == ayahKey) {
                  if (segments != null) {
                    for (List word in segments) {
                      word = word.map((e) => e.toInt()).toList();
                      if (Duration(milliseconds: word[1]) <
                              (current.currentDuration ?? Duration.zero) &&
                          Duration(milliseconds: word[2]) >
                              (current.currentDuration ?? Duration.zero)) {
                        if (highlightingWordIndex !=
                            "$currentAyahKey:${word[0]}") {
                          highlightingWordIndex = "$currentAyahKey:${word[0]}";
                          return true;
                        }
                        return false;
                      }
                    }
                  }
                } else {
                  if (highlightingWordIndex != null) {
                    highlightingWordIndex = null;
                    return true;
                  }
                }
                return false;
              },

              builder: (context, playPositionState) {
                return getAyahWordByWord(
                  ayahScrollState,
                  ayahKey,
                  quranViewState,
                  wordByWord,
                  surahNumber,
                  ayahNumber,
                  context,
                  themeState,
                  highlightingWordIndex,
                );
              },
            );
          },
        );
      },
    ),
  );
}

SizedBox getAyahWordByWord(
  AyahByAyahInScrollInfoState ayahScrollState,
  String ayahKey,
  QuranViewState quranViewState,
  List<dynamic> wordByWord,
  int surahNumber,
  int ayahNumber,
  BuildContext context,
  ThemeState themeState,
  String? highlightingWordIndex,
) {
  return SizedBox(
    height:
        (ayahScrollState.expandedForWordByWord?.contains(ayahKey) == true ||
                quranViewState.alwaysOpenWordByWord)
            ? null
            : 0,

    child:
        (ayahScrollState.expandedForWordByWord?.contains(ayahKey) == true ||
                quranViewState.alwaysOpenWordByWord)
            ? Wrap(
              spacing: 5,
              runSpacing: 5,
              textDirection: TextDirection.rtl,
              children: List.generate(wordByWord.length, (index) {
                String currentWordKey = "$surahNumber:$ayahNumber:${index + 1}";

                return InkWell(
                  borderRadius: BorderRadius.circular(roundedRadius),
                  onTap: () async {
                    List<String> wordsKey = List.generate(
                      wordByWord.length,
                      (i) => "$surahNumber:$ayahNumber:${i + 1}",
                    );
                    showPopupWordFunction(
                      context: context,
                      wordKeys: wordsKey,
                      initWordIndex: index,
                      wordByWordList:
                          await WordByWordFunction.getAyahWordByWordData(
                            "${wordsKey.first.split(":")[0]}:${wordsKey.first.split(":")[1]}",
                          ) ??
                          [],
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: themeState.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(roundedRadius),
                      border:
                          highlightingWordIndex == currentWordKey
                              ? Border.all(color: themeState.primary, width: 2)
                              : null,
                    ),
                    child: Column(
                      children: [
                        BlocBuilder<QuranViewCubit, QuranViewState>(
                          builder: (context, quranViewState) {
                            return ScriptProcessor(
                              scriptInfo: ScriptInfo(
                                surahNumber: surahNumber,
                                ayahNumber: ayahNumber,
                                quranScriptType: quranViewState.quranScriptType,
                                wordIndex: index,
                                textStyle: TextStyle(
                                  fontSize: quranViewState.fontSize,
                                  height: quranViewState.lineHeight,
                                ),
                              ),
                              themeState: themeState,
                            );
                          },
                        ),
                        const Gap(5),
                        Text(
                          wordByWord[index],
                          style: TextStyle(
                            fontSize: quranViewState.translationFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            )
            : null,
  );
}

GestureDetector getWordByWordExpandCloseWidget(
  BuildContext context,
  String ayahKey,
) {
  ThemeState themeState = context.read<ThemeCubit>().state;
  AppLocalizations l10n = AppLocalizations.of(context);
  return GestureDetector(
    onTap: () {
      List<String> expandedForWordByWord =
          context
              .read<AyahByAyahInScrollInfoCubit>()
              .state
              .expandedForWordByWord
              ?.toList() ??
          [];

      expandedForWordByWord.contains(ayahKey)
          ? expandedForWordByWord.remove(ayahKey)
          : expandedForWordByWord.add(ayahKey);
      context.read<AyahByAyahInScrollInfoCubit>().setData(
        expandedForWordByWord: expandedForWordByWord,
      );
    },
    behavior: HitTestBehavior.translucent,
    child: Container(
      decoration: BoxDecoration(
        color: themeState.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(roundedRadius),
      ),
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.wordByWordTranslation,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),

          BlocBuilder<AyahByAyahInScrollInfoCubit, AyahByAyahInScrollInfoState>(
            builder:
                (context, quranViewState) => Icon(
                  quranViewState.expandedForWordByWord?.contains(ayahKey) ==
                          true
                      ? Icons.arrow_drop_up
                      : Icons.arrow_right,
                  size: 24,
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    ),
  );
}

Align getFootNoteWidget(
  Map<dynamic, dynamic> footNote,
  BuildContext context,
  QuranViewState quranViewState,
) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Column(
      children: List.generate(footNote.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: context.read<ThemeCubit>().state.primaryShade300,
              child: Text(
                localizedNumber(context, index + 1),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const Gap(5),
            Container(
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.only(bottom: 5),
              width: MediaQuery.of(context).size.width * 0.85,

              child: Html(
                data: footNote.values.elementAt(index).toString().capitalize(),
                style: {
                  "*": Style(
                    fontSize: FontSize(quranViewState.translationFontSize),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              ),
            ),
          ],
        );
      }),
    ),
  );
}

Widget getTranslationWithFootNoteWidget(
  BuildContext context,
  List<String> translationList,
  List<Map<int, String>> footNoteAsStringMap,
  List<TranslationBookModel?> translationBookInfoList,
  QuranViewState quranViewState,
  bool showOnlyAyah,
  AppLocalizations l10n,
) {
  return Column(
    children: List.generate(translationBookInfoList.length, (index) {
      String translation = translationList[index];
      Map<int, String> footNote = footNoteAsStringMap[index];
      TranslationBookModel? bookModel = translationBookInfoList[index];

      return Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Html(
              data: translation.capitalize(),
              style: {
                "*": Style(
                  fontSize: FontSize(quranViewState.translationFontSize),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
              },
            ),
          ),

          if (footNote.keys.isNotEmpty &&
              !showOnlyAyah &&
              !quranViewState.hideFootnote)
            const Gap(8),
          if (footNote.keys.isNotEmpty &&
              !showOnlyAyah &&
              !quranViewState.hideFootnote)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.footNoteTitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          if (footNote.keys.isNotEmpty &&
              !showOnlyAyah &&
              !quranViewState.hideFootnote)
            const Gap(5),

          if (footNote.isNotEmpty &&
              !showOnlyAyah &&
              !quranViewState.hideFootnote)
            getFootNoteWidget(footNote, context, quranViewState),
          const Gap(5),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(height: 1, width: 25, color: Colors.grey),
              const Gap(7),
              Text(
                bookModel?.name ?? bookModel?.fileName.split("/").last ?? "",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (bookModel?.language != null)
                Text(
                  " (${languageNativeNames[bookModel!.language.toLowerCase()] ?? ""})",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
          const Gap(5),
        ],
      );
    }),
  );
}

Align quranAyahWidget(
  int surahNumber,
  int ayahNumber,
  QuranViewState quranViewState,
  ThemeState themeState,
) {
  return Align(
    alignment: Alignment.centerRight,
    child: ScriptProcessor(
      scriptInfo: ScriptInfo(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        quranScriptType: quranViewState.quranScriptType,
        showWordHighlights: quranViewState.enableWordByWordHighlight == true,
        textAlign: TextAlign.justify,
        textStyle: TextStyle(
          fontSize: quranViewState.fontSize,
          height: quranViewState.lineHeight,
        ),
      ),
      themeState: themeState,
    ),
  );
}

Row getToolbarWidget(
  bool? showFullKey,
  SurahInfoModel surahInfoModel,
  String ayahKey,
  int ayahNumber,
  BuildContext context,
  int surahNumber,
  List<String> translation,
  List<Map<int, String>> footNoteAsStringMap,
  List<TranslationBookModel?> translationBookInfoList,
  ThemeState themeState,
) {
  AppLocalizations l10n = AppLocalizations.of(context);
  final double btnSize = MediaQuery.of(context).size.width < 360 ? 26 : 30;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,

    children: [
      Container(
        decoration: BoxDecoration(
          color: themeState.primaryShade300,
          borderRadius: BorderRadius.circular(roundedRadius - 4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          showFullKey == true
              ? "${getSurahName(context, surahInfoModel.id)}\nAyah: ${localizedNumber(context, ayahKey.split(":").first.toInt())}:${localizedNumber(context, ayahNumber)}"
              : localizedNumber(context, ayahNumber),
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      const Gap(6),
      _AyahStatusIndicators(ayahKey: ayahKey, themeState: themeState),
      const Spacer(),
      SizedBox(
        height: 30,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              WahyPageRoute(page: TafsirView(ayahKey: ayahKey)),
            );
          },
          child: Text(l10n.tafsirButton),
        ),
      ),
      const Gap(4),
      SizedBox(
        height: btnSize,
        width: btnSize,
        child: BlocBuilder<QuranViewCubit, QuranViewState>(
          builder: (context, quranViewState) {
            return IconButton(
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: themeState.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: BorderSide(color: themeState.primary),
                ),
              ),
              onPressed: () {
                showShareBottomDialog(
                  context,
                  ayahKey,
                  surahInfoModel,
                  quranViewState.quranScriptType,
                  translation,
                  footNoteAsStringMap.map((e) => e.values.firstOrNull).whereType<String>().map((s) => <String, dynamic>{}).toList(),
                  translationBookInfoList,
                );
              },
              tooltip: l10n.shareButton,
              icon: Icon(FluentIcons.share_24_filled, size: btnSize * 0.6),
            );
          },
        ),
      ),
      const Gap(4),
      SizedBox(
        height: btnSize,
        width: btnSize,
        child: IconButton(
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: themeState.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
              side: BorderSide(color: themeState.primary),
            ),
          ),
          onPressed: () async {
            await showAddNotePopup(context, ayahKey);
          },
          tooltip: l10n.addNoteButton,
          icon: Icon(FluentIcons.note_add_24_filled, size: btnSize * 0.6),
        ),
      ),
      const Gap(4),
      SizedBox(
        height: btnSize,
        width: btnSize,
        child: IconButton(
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: themeState.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
              side: BorderSide(color: themeState.primary),
            ),
          ),
          onPressed: () {
            _showWahyBookmarkColorSheet(
              context: context,
              themeState: themeState,
              ayahKey: ayahKey,
            );
          },
          tooltip: l10n.pinToCollectionButton,
          icon: Icon(FluentIcons.pin_24_filled, size: btnSize * 0.6),
        ),
      ),
      const Gap(4),
      SizedBox(
        height: btnSize,
        width: btnSize,
        child: ValueListenableBuilder(
          valueListenable: Hive.box("user").listenable(keys: ["wahy_starred"]),
          builder: (context, box, _) {
            final starred = List<String>.from(
                box.get("wahy_starred", defaultValue: const []) as List? ?? []);
            final isStarred = starred.contains(ayahKey);

            return IconButton(
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: isStarred ? const Color(0xFFF4B400) : themeState.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                  side: BorderSide(color: isStarred ? const Color(0xFFF4B400) : themeState.primary),
                ),
              ),
              onPressed: () async {
                final list = List<String>.from(starred);
                if (isStarred) {
                  list.remove(ayahKey);
                } else {
                  list.add(ayahKey);
                }
                await box.put("wahy_starred", list);
              },
              tooltip: isStarred ? "إزالة من المفضلة" : "إضافة للمفضلة",
              icon: Icon(
                isStarred ? FluentIcons.star_24_filled : FluentIcons.star_24_regular,
                size: btnSize * 0.6,
              ),
            );
          },
        ),
      ),
      const Gap(4),
      SizedBox(
        height: btnSize,
        width: btnSize,
        child: BlocBuilder<PlayerStateCubit, PlayerState>(
          builder: (context, playerState) {
            return BlocBuilder<AyahKeyCubit, AyahKeyManagement>(
              builder: (context, ayahKeyManagement) {
                bool isPlaying = playerState.isPlaying;
                bool isCurrent =
                    ayahKeyManagement.current == ayahKey &&
                    context.read<AudioUiCubit>().state.isInsideQuranPlayer ==
                        true;

                return getPlayButtonWidget(
                  context,
                  ayahKey,
                  isCurrent,
                  isPlaying,
                  ayahKeyManagement,
                  playerState,
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

IconButton getPlayButtonWidget(
  BuildContext context,
  String ayahKey,
  bool isCurrent,
  bool isPlaying,
  AyahKeyManagement ayahKeyManagement,
  PlayerState playerState,
) {
  ThemeState themeState = context.read<ThemeCubit>().state;
  return IconButton(
    style: IconButton.styleFrom(
      padding: EdgeInsets.zero,
      foregroundColor: themeState.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: BorderSide(color: themeState.primary),
      ),
    ),
    onPressed: () async {
      if (context.read<AudioUiCubit>().state.isInsideQuranPlayer == false) {
        AudioPlayerManager.playSingleAyah(
          ayahKey: ayahKey,
          reciterInfoModel: context.read<SegmentedQuranReciterCubit>().state,
          instantPlay: true,
          isInsideQuran: true,
        );
      } else if (isCurrent && isPlaying) {
        AudioPlayerManager.audioPlayer.pause();
      } else if (isCurrent) {
        AudioPlayerManager.audioPlayer.play();
      } else {
        log("Current Ayah: $ayahKey");
        bool isPlayList = context.read<AudioUiCubit>().state.isPlayList;
        if (isPlayList &&
            ayahKeyManagement.current.split(":").first ==
                ayahKey.split(":").first) {
          await AudioPlayerManager.audioPlayer.seek(
            Duration.zero,
            index: ayahKeyManagement.ayahList.indexOf(ayahKey),
          );
          AudioPlayerManager.audioPlayer.play();
        } else {
          AudioPlayerManager.playSingleAyah(
            ayahKey: ayahKey,
            reciterInfoModel: context.read<SegmentedQuranReciterCubit>().state,
            instantPlay: true,
            isInsideQuran: true,
          );
        }
      }
    },
    icon:
        (isCurrent && playerState.state == just_audio.ProcessingState.loading)
            ? Padding(
              padding: const EdgeInsets.all(3.0),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor:
                    context.read<ThemeCubit>().state.primaryShade100,
              ),
            )
            : Icon(
              isPlaying && isCurrent
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 18,
            ),
  );
}
