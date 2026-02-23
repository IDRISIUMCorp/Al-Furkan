import "dart:async";
import "dart:convert";
import "dart:developer";
import "dart:io";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:qcf_quran/qcf_quran.dart" hide getPageNumber;
import "package:http/http.dart" as http;
import "package:share_plus/share_plus.dart";
import "package:path_provider/path_provider.dart";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/main.dart";
import "package:al_quran_v3/src/core/audio/cubit/audio_ui_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_state_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/segmented_quran_reciter_cubit.dart";
import "package:al_quran_v3/src/core/audio/model/ayahkey_management.dart";
import "package:al_quran_v3/src/core/audio/player/audio_player_manager.dart";
import "package:al_quran_v3/src/core/notifications/khatma_notification_service.dart";
import "package:al_quran_v3/src/screen/quran_reader/widgets/ayah_options_sheet.dart";
import "package:al_quran_v3/src/screen/quran_resources/quran_resources_view.dart";
import "package:al_quran_v3/src/widget/audio/audio_controller_ui.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_to_highlight.dart";
import "package:al_quran_v3/src/screen/quran_script_view/quran_script_view.dart";
import "package:al_quran_v3/src/screen/search/search_screen.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_cubit.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_irab_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/default_offline_resources.dart";
import "package:al_quran_v3/src/utils/quran_resources/word_by_word_function.dart";
import "package:al_quran_v3/src/utils/quran_word/show_popup_word_function.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:al_quran_v3/src/widget/quran_script_words/cubit/word_playing_state_cubit.dart";
import "package:al_quran_v3/src/screen/settings/app_language_settings.dart";
import "package:al_quran_v3/src/screen/settings/settings_page.dart";
import "package:al_quran_v3/src/screen/prayer_time/prayer_time_page.dart";
import "package:al_quran_v3/src/screen/qibla/qibla_direction.dart";
import "package:al_quran_v3/src/screen/mushaf/index/aya_index_page.dart";
import "package:al_quran_v3/src/screen/audio/audio_page.dart";
import "package:al_quran_v3/src/widget/add_collection_popup/add_note_popup.dart";
import "package:al_quran_v3/src/screen/about/about_the_app.dart";
import "package:al_quran_v3/src/screen/smart_khatma/smart_khatma_page.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:qcf_quran/qcf_quran.dart" as qcf;
import "package:al_quran_v3/src/resources/quran_resources/tafsir_info_with_score.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/get_page_number.dart";
import "package:al_quran_v3/src/resources/quran_resources/quran_pages_info.dart";
import "package:al_quran_v3/src/utils/basic_functions.dart";
import "package:al_quran_v3/src/theme/app_colors.dart";
import "package:al_quran_v3/src/screen/collections/common_function.dart";
 

class MushafScreen extends StatelessWidget {
  const MushafScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MushafRoot();
  }

}

class _HeaderIconPill extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color primary;
  final VoidCallback onTap;

  const _HeaderIconPill({
    required this.tooltip,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        splashColor: primary.withValues(alpha: 0.1),
        highlightColor: primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          // Aya uses primary green icons on the transparent bar without background pills
          child: Icon(icon, color: primary, size: 26), 
        ),
      ),
    );
  }
}

class _AyahSearchResult {
  final int surah;
  final int verse;
  final String ayahKey;
  final String snippet;

  const _AyahSearchResult({
    required this.surah,
    required this.verse,
    required this.ayahKey,
    required this.snippet,
  });
}

class _MushafRoot extends StatefulWidget {
  const _MushafRoot();

  @override
  State<_MushafRoot> createState() => _MushafRootState();
}

class _MushafRootState extends State<_MushafRoot> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // ignore: prefer_final_fields
  bool _isMushafMode = true;
  bool _showHeader = true;

  final PageController _mushafPageController = PageController(
    initialPage: (() {
      final box = Hive.box("user");
      final savedPage = box.get("wahy_last_page", defaultValue: 1) as int;
      return (savedPage - 1).clamp(0, 603);
    })(),
  );

  bool _quranScriptReady = false;
  Future<void>? _quranScriptInitFuture;

  Map<String, String>? _uthmaniAssetText;
  Future<void>? _uthmaniAssetLoadFuture;

  static const String _kWahyBookmarks = "wahy_bookmarks";
  static const String _kWahyStarred = "wahy_starred";
  static const String _kWahyNotes = "wahy_notes";

  static Color _bg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark ? Color(0xFF141414) : Color(0xFFF7F1E6);
  static Color _onBg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Color(0xFF1B1B1B);
  static const _headerHeight = 56.0;
  static const _miniPlayerBottomPadding = 0.0;

  static const int _kSearchMaxResults = 120;
  final Map<String, List<_AyahSearchResult>> _ayahSearchCache =
      <String, List<_AyahSearchResult>>{};

  Future<void> _flashAyahHighlight(String ayahKey) async {
    if (!mounted) return;
    final highlighter = context.read<AyahToHighlight>();
    highlighter.changeAyah(ayahKey);
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    if (highlighter.state == ayahKey) {
      highlighter.changeAyah(null);
    }
  }

  String _ayahPreviewForKey(String ayahKey) {
    final parts = ayahKey.split(":");
    final surah = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final verse = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (surah == null || verse == null) return ayahKey;

    final QuranScriptType scriptType =
        context.read<QuranViewCubit>().state.quranScriptType;
    final words = QuranScriptFunction.getWordListOfAyah(
      scriptType,
      surah.toString(),
      verse.toString(),
    );
    if (words.isEmpty) return ayahKey;
    final raw = words.join(" ");
    final stripped = raw.replaceAll(RegExp(r"<[^>]+>"), "");
    return stripped.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  ({int surah, int verse})? _parseKey(String ayahKey) {
    final parts = ayahKey.split(":");
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]);
    final v = int.tryParse(parts[1]);
    if (s == null || v == null) return null;
    return (surah: s, verse: v);
  }

  Future<void> _removeBookmark(String ayahKey) async {
    final box = Hive.box("user");
    final list = _getWahyBookmarks();
    list.removeWhere((e) => (e["ayahKey"] as String?) == ayahKey);
    await box.put(_kWahyBookmarks, list);
  }

  Future<void> _pickBookmarkColorForAyahKey(String ayahKey) async {
    final themeState = context.read<ThemeCubit>().state;
    const card = Color(0xFFFFF9F2);
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
color: _bg(sheet),
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
                    Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: colors.entries.map((entry) {
                          return _bookmarkColorRow(
                            sheet,
                            title: entry.value.name,
                            color: entry.value.color,
                            onTap: () async {
                              Navigator.pop(sheet);
                              await _setBookmarkColorForAyahKey(ayahKey, entry.key);
                            },
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

  Future<void> _removeNoteAt(int index) async {
    final box = Hive.box("user");
    final list = _getWahyNotes();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await box.put(_kWahyNotes, list);
  }

  Future<void> _addNoteForCurrentAyah() async {
    final key = context.read<AyahKeyCubit>().state.current;
    if (key.isEmpty) return;
    await _addNoteForAyahKey(key);
  }

  Future<void> _addNoteForAyahKey(String ayahKey) async {
    final controller = TextEditingController();
    final themeState = context.read<ThemeCubit>().state;

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
color: _bg(ctx),
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
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "اكتب ملاحظتك هنا…",
                          hintStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx, controller.text.trim());
                          },
                          child: const Text("حفظ"),
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
    final list = _getWahyNotes();
    list.insert(0, {
      "ayahKey": ayahKey,
      "text": text,
      "createdAt": DateTime.now().toIso8601String(),
    });
    await box.put(_kWahyNotes, list);
    await syncWahyNoteToCollection(ayahKey, text);
  }

  String _removeTashkeel(String text) {
    return text
        .replaceAll(RegExp(r"[\u064B-\u0652\u0670\u06D6-\u06ED]"), "")
        .replaceAll("\u0640", "");
  }

  Future<void> _ensureQuranScriptReady() async {
    if (_quranScriptReady) return;
    _quranScriptInitFuture ??= () async {
      await QuranScriptFunction.initQuranScript(QuranScriptType.uthmani);
      _quranScriptReady = true;
    }();
    await _quranScriptInitFuture;
  }

  Future<void> _ensureUthmaniAssetLoaded() async {
    if (_uthmaniAssetText != null) return;
    _uthmaniAssetLoadFuture ??= () async {
      final raw = await rootBundle.loadString("assets/quran_script/Uthmani.json");
      final decoded = jsonDecode(raw) as Map;
      final out = <String, String>{};
      for (final entry in decoded.entries) {
        final surahKey = entry.key.toString();
        final surahMap = Map<String, dynamic>.from(entry.value as Map);
        for (final ayahEntry in surahMap.entries) {
          final words = List<String>.from(ayahEntry.value as List);
          final joined = words.join(" ");
          final stripped = joined.replaceAll(RegExp(r"<[^>]+>"), "");
          out["$surahKey:${ayahEntry.key}"] =
              stripped.replaceAll(RegExp(r"\s+"), " ").trim();
        }
      }
      _uthmaniAssetText = out;
    }();
    await _uthmaniAssetLoadFuture;
  }

  Future<String> _getAyahTextForSearch(int surah, int verse) async {
    final QuranScriptType scriptType =
        context.read<QuranViewCubit>().state.quranScriptType;

    List<String> words = QuranScriptFunction.getWordListOfAyah(
      scriptType,
      surah.toString(),
      verse.toString(),
    );
    if (words.isEmpty) {
      words = QuranScriptFunction.getWordListOfAyah(
        QuranScriptType.uthmani,
        surah.toString(),
        verse.toString(),
      );
    }

    if (words.isEmpty) {
      await _ensureUthmaniAssetLoaded();
      final cached = _uthmaniAssetText?["$surah:$verse"] ?? "";
      return cached;
    }

    if (words.isEmpty) return "";
    final raw = words.join(" ");
    final stripped = raw.replaceAll(RegExp(r"<[^>]+>"), "");
    return stripped.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  Future<List<_AyahSearchResult>> _searchAllAyahs({
    required String rawQuery,
  }) async {
    final normalizedQuery = _removeTashkeel(rawQuery).trim();
    if (normalizedQuery.length < 2) return const <_AyahSearchResult>[];

    // Ensure we can always search even if Hive scripts are not prepared yet.
    await _ensureUthmaniAssetLoaded();

    final cached = _ayahSearchCache[normalizedQuery];
    if (cached != null) return cached;

    final out = <_AyahSearchResult>[];
    for (int s = 1; s <= 114; s++) {
      final total = getVerseCount(s);
      for (int v = 1; v <= total; v++) {
        final t = await _getAyahTextForSearch(s, v);
        if (t.isEmpty) continue;
        final normalized = _removeTashkeel(t);
        if (!normalized.contains(normalizedQuery)) continue;

        final snippet = t.length <= 140 ? t : "${t.substring(0, 140)}…";
        out.add(
          _AyahSearchResult(
            surah: s,
            verse: v,
            ayahKey: "$s:$v",
            snippet: snippet,
          ),
        );
        if (out.length >= _kSearchMaxResults) {
          _ayahSearchCache[normalizedQuery] = out;
          return out;
        }
      }
    }

    _ayahSearchCache[normalizedQuery] = out;
    return out;
  }

  Future<void> _openKhatmaSheet() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _bg(ctx),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "الختمة",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _onBg(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: SmartKhatmaPage()),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getWahyBookmarks() {
    final box = Hive.box("user");
    final raw = box.get(_kWahyBookmarks, defaultValue: const []) as List?;
    return (raw ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<String> _getWahyStarred() {
    final box = Hive.box("user");
    final raw = box.get(_kWahyStarred, defaultValue: const []) as List?;
    return List<String>.from(raw ?? const []);
  }

  List<Map<String, dynamic>> _getWahyNotes() {
    final box = Hive.box("user");
    final raw = box.get(_kWahyNotes, defaultValue: const []) as List?;
    return (raw ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _setBookmarkColorForCurrentAyah(String colorId) async {
    final key = context.read<AyahKeyCubit>().state.current;
    if (key.isEmpty) return;
    await _setBookmarkColorForAyahKey(key, colorId);
  }

  Future<void> _setBookmarkColorForAyahKey(String ayahKey, String colorId) async {
    final box = Hive.box("user");

    final list = _getWahyBookmarks();
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

  Future<void> _toggleStarForCurrentAyah() async {
    final box = Hive.box("user");
    final key = context.read<AyahKeyCubit>().state.current;
    if (key.isEmpty) return;
    final list = _getWahyStarred();
    if (list.contains(key)) {
      list.remove(key);
    } else {
      list.insert(0, key);
    }
    await box.put(_kWahyStarred, list);
  }

  Future<void> _openBookmarksSheet() async {
    final themeState = context.read<ThemeCubit>().state;
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        const card = Color(0xFFFFF9F2);
        final colors = <String, ({String name, Color color})>{
          "red": (name: "الأحمر", color: const Color(0xFFB3261E)),
          "yellow": (name: "الأصفر", color: const Color(0xFFB68A00)),
          "green": (name: "الأخضر", color: themeState.primary),
          "blue": (name: "الأزرق", color: const Color(0xFF2962FF)),
        };

        List<Map<String, dynamic>> load() => _getWahyBookmarks();

        String formatTime(String iso) {
          final dt = DateTime.tryParse(iso)?.toLocal();
          if (dt == null) return "";
          final hourOfPeriod = dt.hour % 12;
          final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
          final mm = dt.minute.toString().padLeft(2, "0");
          final suffix = dt.hour < 12 ? "ص" : "م";
          return "${localizedNumber(ctx, h)}:$mm $suffix";
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: _bg(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    bool editMode = false;
                    final all = load();
                    final grouped = <String, List<Map<String, dynamic>>>{
                      for (final k in colors.keys) k: <Map<String, dynamic>>[],
                    };
                    for (final e in all) {
                      final c = (e["color"] as String?) ?? "green";
                      if (grouped.containsKey(c)) grouped[c]!.add(e);
                    }

                    Future<void> onTapColor(String colorId) async {
                      final list = grouped[colorId] ?? const <Map<String, dynamic>>[];
                      if (list.isEmpty) {
                        await _setBookmarkColorForCurrentAyah(colorId);
                        setState(() {});
                        return;
                      }

                      final key = (list.first["ayahKey"] as String?) ?? "";
                      if (key.isEmpty) return;
                      final page = getPageNumber(key) ?? 1;
                      context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                      context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
                      Navigator.pop(ctx);
                    }

                    Widget wahyColorRow(String colorId) {
                      final meta = colors[colorId]!;
                      final list = grouped[colorId] ?? const <Map<String, dynamic>>[];

                      String? subtitle;
                      if (list.isNotEmpty) {
                        final e = list.first;
                        final key = (e["ayahKey"] as String?) ?? "";
                        final page = getPageNumber(key) ?? 1;
                        final parsed = _parseKey(key);
                        final time = formatTime((e["createdAt"] as String?) ?? "");
                        if (parsed != null && time.isNotEmpty) {
                          subtitle = "$time ${getSurahNameArabic(parsed.surah)}: ${localizedNumber(ctx, parsed.verse)} - الصفحة ${localizedNumber(ctx, page)}";
                        } else if (parsed != null) {
                          subtitle = "${getSurahNameArabic(parsed.surah)}: ${localizedNumber(ctx, parsed.verse)} - الصفحة ${localizedNumber(ctx, page)}";
                        } else {
                          subtitle = "الصفحة ${localizedNumber(ctx, page)}";
                        }
                      }

                      return ListTile(
                        dense: true,
                        title: Text(
                          meta.name,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: subtitle == null
                            ? null
                            : Text(
                                subtitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8F8F8F),
                                ),
                              ),
                        trailing: Icon(Icons.bookmark_rounded, color: meta.color),
                        onTap: () async => onTapColor(colorId),
                      );
                    }

                    Widget section(String colorId) {
                      final meta = colors[colorId]!;
                      final list = grouped[colorId] ?? const <Map<String, dynamic>>[];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                meta.name,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              trailing: Icon(Icons.bookmark_rounded, color: meta.color),
                            ),
                            if (list.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 14),
                                child: Text(
                                  "لا توجد فواصل",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF9C9C9C),
                                  ),
                                ),
                              )
                            else
                              ...list.map((e) {
                                final key = (e["ayahKey"] as String?) ?? "";
                                final parsed = _parseKey(key);
                                final page = getPageNumber(key) ?? 1;
                                final title = parsed == null
                                    ? key
                                    : "${getSurahNameArabic(parsed.surah)}: ${localizedNumber(ctx, parsed.verse)}";
                                final preview = _ayahPreviewForKey(key);

                                return ListTile(
                                  title: Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  subtitle: Text(
                                    "${preview.isEmpty ? key : preview}\nالصفحة ${localizedNumber(ctx, page)}",
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    onPressed: () async {
                                      await _removeBookmark(key);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded),
                                  ),
                                  onTap: key.isEmpty
                                      ? null
                                      : () {
                                          context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                                          context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
                                          Navigator.pop(ctx);
                                        },
                                );
                              }),
                          ],
                        ),
                      );
                    }

                    return Column(
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "الفواصل",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: _onBg(context),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  editMode = !editMode;
                                });
                              },
                              child: Text(
                                "تحرير",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: themeState.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!editMode)
                          Container(
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              children: [
                                wahyColorRow("red"),
                                wahyColorRow("yellow"),
                                wahyColorRow("green"),
                                wahyColorRow("blue"),
                              ],
                            ),
                          )
                        else
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: [
                                section("red"),
                                section("yellow"),
                                section("green"),
                                section("blue"),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.black.withValues(alpha: 0.06),
    );
  }

  Widget _bookmarkColorRow(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      trailing: Icon(Icons.bookmark_rounded, color: color),
    );
  }

  Future<void> _openStarredSheet() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
color: _bg(ctx),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.86,
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    final starred = _getWahyStarred();

                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "مميزة بنجمة",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _onBg(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: starred.isEmpty
                              ? const Center(
                                  child: Text(
                                    "لا توجد آيات مميزة بنجمة",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF9C9C9C),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                  itemCount: starred.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 14,
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                  itemBuilder: (context, index) {
                                    final key = starred[index];
                                    final parsed = _parseKey(key);
                                    final page = getPageNumber(key) ?? 1;
                                    final title = parsed == null
                                        ? key
                                        : "${getSurahNameArabic(parsed.surah)}: ${localizedNumber(ctx, parsed.verse)}";
                                    final preview = _ayahPreviewForKey(key);

                                    return ListTile(
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${preview.isEmpty ? key : preview}\nالصفحة ${localizedNumber(ctx, page)}",
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: IconButton(
                                        onPressed: () async {
                                          final box = Hive.box("user");
                                          final list = _getWahyStarred();
                                          list.remove(key);
                                          await box.put(_kWahyStarred, list);
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.star_outline_rounded),
                                      ),
                                      onTap: () {
                                        context
                                            .read<AyahKeyCubit>()
                                            .changeLastScrolledPage(page);
                                        context
                                            .read<AyahKeyCubit>()
                                            .changeCurrentAyahKey(key);
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNotesSheet() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
color: _bg(ctx),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.86,
                child: StatefulBuilder(
                  builder: (ctx, setState) {
                    final themeState = context.read<ThemeCubit>().state;
                    final notes = _getWahyNotes();

                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "الملاحظات",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: _onBg(context),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final currentAyahKey = context.read<AyahKeyCubit>().state.current;
                                  if (currentAyahKey.isNotEmpty) {
                                    Navigator.pop(ctx);
                                    await showAddNotePopup(context, currentAyahKey);
                                  }
                                },
                                child: Text(
                                  "إضافة",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: themeState.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: notes.isEmpty
                              ? const Center(
                                  child: Text(
                                    "لا توجد ملاحظات",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF9C9C9C),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                  itemCount: notes.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 14,
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                  itemBuilder: (context, index) {
                                    final n = notes[index];
                                    final key = (n["ayahKey"] as String?) ?? "";
                                    final text = (n["text"] as String?) ?? "";
                                    final parsed = _parseKey(key);
                                    final page = getPageNumber(key) ?? 1;
                                    final title = parsed == null
                                        ? key
                                        : "${getSurahNameArabic(parsed.surah)}: ${localizedNumber(ctx, parsed.verse)}";
                                    final preview = _ayahPreviewForKey(key);

                                    return ListTile(
                                      title: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${text.isEmpty ? preview : text}\nالصفحة ${localizedNumber(ctx, page)}",
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: IconButton(
                                        onPressed: () async {
                                          await _removeNoteAt(index);
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded),
                                      ),
                                      onTap: key.isEmpty
                                          ? null
                                          : () {
                                              context
                                                  .read<AyahKeyCubit>()
                                                  .changeLastScrolledPage(page);
                                              context
                                                  .read<AyahKeyCubit>()
                                                  .changeCurrentAyahKey(key);
                                              context.read<AyahToHighlight>().changeAyah(key);
                                              Navigator.pop(ctx);

                                              if (_isMushafMode && _mushafPageController.hasClients) {
                                                _mushafPageController.animateToPage(
                                                  page - 1,
                                                  duration: const Duration(milliseconds: 520),
                                                  curve: Curves.easeOutCubic,
                                                );
                                              }
                                            },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openIndexSheet() async {
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
color: _bg(ctx),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.86,
                child: _WahyIndexSheet(
                  onOpenPage: (page) async {
                    if (_isMushafMode) {
                      Navigator.pop(ctx);
                      await Future<void>.delayed(const Duration(milliseconds: 80));
                      if (!_mushafPageController.hasClients) {
                        context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                        return;
                      }
                      _mushafPageController.animateToPage(
                        page - 1,
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                      );
                      context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                      return;
                    }

                    context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                    Navigator.pop(ctx);
                  },
                  onOpenAyah: (key) async {
                    Navigator.pop(ctx);
                    await Future<void>.delayed(const Duration(milliseconds: 80));

                    final page = getPageNumber(key) ?? 1;
                    context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                    context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
                    context.read<AyahToHighlight>().changeAyah(key);

                    if (_isMushafMode && _mushafPageController.hasClients) {
                      _mushafPageController.animateToPage(
                        page - 1,
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getAyahText(BuildContext context, int surah, int verse) {
    final QuranScriptType scriptType =
        context.read<QuranViewCubit>().state.quranScriptType;
    final words = QuranScriptFunction.getWordListOfAyah(
      scriptType,
      surah.toString(),
      verse.toString(),
    );

    List<String> resolved = List<String>.from(words);
    if (resolved.isEmpty) {
      final fallback = QuranScriptFunction.getWordListOfAyah(
        QuranScriptType.uthmani,
        surah.toString(),
        verse.toString(),
      );
      resolved = List<String>.from(fallback);
    }
    if (resolved.isEmpty) return "";

    final raw = resolved.join(" ");
    final stripped = raw.replaceAll(RegExp(r"<[^>]+>"), "");
    return stripped.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  @override
  void initState() {
    super.initState();
    _ensureQuranScriptReady();

    // Restore last-read ayah key
    final box = Hive.box("user");
    final lastAyahKey = box.get("wahy_last_ayah_key") as String?;
    if (lastAyahKey != null && lastAyahKey.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AyahKeyCubit>().changeCurrentAyahKey(lastAyahKey);
      });
    }

    // Save page on scroll
    _mushafPageController.addListener(_onPageChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audioUi = context.read<AudioUiCubit>();
      audioUi.changeIsInsideQuran(true);
      audioUi.showUI(true);
      audioUi.expand(false);
    });
  }

  void _onPageChanged() {
    if (!_mushafPageController.hasClients) return;
    final page = _mushafPageController.page?.round();
    if (page != null) {
      Hive.box("user").put("wahy_last_page", page + 1);
      KhatmaNotificationService.instance.updateReminderTextIfNeeded();
    }
  }

  @override
  void dispose() {
    // Save last ayah key before leaving
    try {
      final lastKey = context.read<AyahKeyCubit>().state.current;
      if (lastKey.isNotEmpty) {
        Hive.box("user").put("wahy_last_ayah_key", lastKey);
      }
    } catch (_) {}
    _mushafPageController.removeListener(_onPageChanged);
    _mushafPageController.dispose();
    super.dispose();
  }

  void _navigateToMushafPage(int targetPage) {
    if (!_isMushafMode || !_mushafPageController.hasClients) return;
    final int currentPage = _mushafPageController.page?.round() ?? 0;
    if ((targetPage - currentPage).abs() > 2) {
      _mushafPageController.jumpToPage(targetPage);
    } else {
      _mushafPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0B0F) : AppColors.ayaBackground;
    final topBarColor = isDark ? const Color(0xFF1B1B1F).withValues(alpha: 0.85) : AppColors.ayaSurface.withValues(alpha: 0.85);
    final topBarBorderColor = isDark ? Colors.white10 : AppColors.ayaBorder.withValues(alpha: 0.5);


    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final safeH = (screenH - _headerHeight).clamp(1.0, screenH);
    final availableRatio = safeH / screenH;
    final mushafScale = (availableRatio + 0.12).clamp(0.84, 0.92);

    Future<void> openKeywordSearch() async {
      final controller = TextEditingController();

      await showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return _SearchSheet(
            controller: controller,
            primary: themeState.primary,
            search: (q) => _searchAllAyahs(rawQuery: q),
            onResultTap: (key) {
              final page = getPageNumber(key) ?? 1;
              context.read<AyahKeyCubit>().changeLastScrolledPage(page);
              context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
              _flashAyahHighlight(key);
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);

              if (_isMushafMode && _mushafPageController.hasClients) {
                _mushafPageController.animateToPage(
                  page - 1,
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          );
        },
      );
    }

    Future<void> openOverflowMenu() async {
      await showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final bg = _bg(sheetContext);
          const card = Color(0xFFFFF9F2);
          final fontBase = _onBg(sheetContext);

          Widget item({
            required IconData icon,
            required String title,
            required String subtitle,
            required VoidCallback onTap,
          }) {
            return ListTile(
              onTap: () {
                Navigator.pop(sheetContext);
                onTap();
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeState.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: themeState.primary),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: fontBase,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8F8F8F),
                ),
              ),
              trailing: Icon(
                Icons.chevron_left_rounded,
                color: themeState.primary.withValues(alpha: 0.85),
              ),
            );
          }

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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
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
                              const SizedBox(height: 10),
                              Text(
                                "خيارات",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: fontBase,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    item(
                                      icon: Icons.settings_rounded,
                                      title: "الإعدادات",
                                      subtitle: "تخصيص التطبيق",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SettingsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    const _WahyDrawerDivider(),
                                    item(
                                      icon: Icons.library_books_rounded,
                                      title: "الموارد",
                                      subtitle: "التفاسير والترجمات",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const QuranResourcesView(),
                                          ),
                                        );
                                      },
                                    ),
                                    const _WahyDrawerDivider(),
                                    item(
                                      icon: Icons.language_rounded,
                                      title: "اللغة",
                                      subtitle: "تغيير لغة التطبيق",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AppLanguageSettings(),
                                          ),
                                        );
                                      },
                                    ),
                                    const _WahyDrawerDivider(),
                                    item(
                                      icon: Icons.info_outline_rounded,
                                      title: "عن التطبيق",
                                      subtitle: "معلومات وإصدار",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AboutAppPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    const _WahyDrawerDivider(),
                                    item(
                                      icon: Icons.bug_report_rounded,
                                      title: "بلاغ / اقتراح",
                                      subtitle: "ابعت مشكلة أو فكرة تطوير",
                                      onTap: () async {
                                        await showDialog(
                                          context: context,
                                          builder: (ctx) => _WahyFeedbackDialog(
                                            primary: themeState.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true, 
      body: MultiBlocListener(
        listeners: [
          BlocListener<PlayerStateCubit, PlayerState>(
            listenWhen: (p, c) => p.isPlaying != c.isPlaying,
            listener: (context, state) {
              final highlighter = context.read<AyahToHighlight>();
              if (!state.isPlaying) {
                highlighter.changeAyah(null);
                return;
              }
              highlighter.changeAyah(context.read<AyahKeyCubit>().state.current);
            },
          ),
          BlocListener<AyahKeyCubit, AyahKeyManagement>(
            listenWhen: (p, c) => p.current != c.current,
            listener: (context, ayahState) {
              if (!context.read<PlayerStateCubit>().state.isPlaying) return;
              context.read<AyahToHighlight>().changeAyah(ayahState.current);
            },
          ),
        ],
        child: Stack(
          children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _showHeader = !_showHeader),
              child: Container(
                color: isDark ? const Color(0xFF0B0B0F) : _bg(context),
                child: Padding(
                    padding: const EdgeInsets.only(
                      top: 44, // Adjusted further from 47 to 44 to raise headers more
                      bottom: _miniPlayerBottomPadding,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _isMushafMode
                          ? MushafView(
                              key: const ValueKey("mushaf"),
                              useDefaultAppBar: false,
                              initialPageNumber:
                                  context.watch<AyahKeyCubit>().state.lastScrolledPageNumber,
                              controller: _mushafPageController,
                              spOverride: mushafScale,
                              hOverride: mushafScale,
                              onToggleHeader: () => setState(() => _showHeader = !_showHeader),
                            )
                          : QuranScriptView(
                              key: const ValueKey("ayah_by_ayah"),
                              startKey: "1:1",
                              endKey: "114:6",
                              toScrollKey: context.read<AyahKeyCubit>().state.current,
                              embedded: true,
                              topPaddingOverride: 0,
                              showAudioController: false,
                            ),
                    ),
                  ),
                ),
            ),
          ),

          // Top header (Beige)
          AnimatedSlide(
            duration:
                Duration(milliseconds: _showHeader ? 320 : 520),
            curve: Curves.easeInOutCubic,
            offset: _showHeader ? Offset.zero : const Offset(0, -1.15),
            child: AnimatedOpacity(
              duration:
                  Duration(milliseconds: _showHeader ? 240 : 420),
              opacity: _showHeader ? 1 : 0,
              child: AnimatedScale(
                duration:
                    Duration(milliseconds: _showHeader ? 320 : 520),
                curve: Curves.easeInOutCubic,
                scale: _showHeader ? 1.0 : 0.985,
                child: Container(
                  // Dynamic height to account for status bar
                  height: _headerHeight + MediaQuery.of(context).padding.top,
                  decoration: BoxDecoration(
                    color: Colors.transparent, 
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
                      child: Container(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: topBarColor, 
                          border: Border(
                            bottom: BorderSide(
                              color: topBarBorderColor, 
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _HeaderIconPill(
                                tooltip: "الفهرس",
                                icon: Icons.notes_rounded, // Hamburger-like icon
                                primary: AppColors.ayaPrimary,
                                onTap: () {
                                  showGeneralDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: "إغلاق الفهرس",
                                    barrierColor: Colors.black.withValues(alpha: 0.4),
                                    transitionDuration: const Duration(milliseconds: 380),
                                    pageBuilder: (ctx, anim1, anim2) => Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 340,
                                        child: Material(
                                          color: bgColor,
                                          child: AyaIndexPage(
                                            isEmbedded: true,
                                            onOpenLocation: (page, ayahKey) {
                                              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                                              context.read<AyahKeyCubit>().changeLastScrolledPage(page);
                                              context.read<AyahKeyCubit>().changeCurrentAyahKey(ayahKey);
                                              context.read<AyahToHighlight>().changeAyah(ayahKey);
                                              _navigateToMushafPage(page - 1);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    transitionBuilder: (ctx, anim1, anim2, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                                            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
                                        child: child,
                                      );
                                    },
                                  );
                                },
                              ),
                              _HeaderIconPill(
                                tooltip: "البحث",
                                icon: Icons.search_rounded,
                                primary: AppColors.ayaPrimary,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                                  );
                                  if (result != null && result is Map) {
                                    if (_isMushafMode && _mushafPageController.hasClients) {
                                      final page = result["page"] as int?;
                                      if (page != null) {
                                        _navigateToMushafPage(page - 1);
                                      }
                                    }
                                  }
                                },
                              ),
                              _HeaderIconPill(
                                tooltip: "طريقة العرض",
                                icon: _isMushafMode ? Icons.chrome_reader_mode_outlined : Icons.menu_book_rounded,
                                primary: AppColors.ayaPrimary,
                                onTap: () {
                                  setState(() => _isMushafMode = !_isMushafMode);
                                },
                              ),
                              _HeaderIconPill(
                                tooltip: "الختمة",
                                icon: Icons.bookmark_border_rounded,
                                primary: AppColors.ayaPrimary,
                                onTap: () async => _openKhatmaSheet(),
                              ),
                              _buildMoreMenu(themeState.primary, isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom mini audio controller (overlay)
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: const SizedBox.shrink(),
            ),
          ),

          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: const SizedBox.shrink(),
            ),
          ),

          // Audio Controller UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 25,
            child: AnimatedSlide(
              duration: Duration(milliseconds: _showHeader ? 320 : 520),
              curve: Curves.easeInOutCubic,
              offset: _showHeader ? Offset.zero : const Offset(0, 1.15),
              child: AnimatedOpacity(
                duration: Duration(milliseconds: _showHeader ? 240 : 420),
                opacity: _showHeader ? 1 : 0,
                child: const AudioControllerUi(),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu(Color primaryColor, bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF141414) : AppColors.ayaSurface;
    final textColor = isDark ? Colors.white : AppColors.ayaTextMain;

    return PopupMenuButton<int>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surfaceColor,
      elevation: 8,
      offset: const Offset(0, 50),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ayaPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.more_vert_rounded, color: AppColors.ayaPrimary),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.settings_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("الإعدادات", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 4,
          child: Row(
            children: [
              const Icon(Icons.headphones_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("الصوتيات", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 5,
          child: Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("مواقيت الصلاة", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 6,
          child: Row(
            children: [
              const Icon(Icons.explore_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("القبلة", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("التفاسير والترجمات", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("عن التطبيق", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: AppColors.ayaPrimary, size: 22),
              const SizedBox(width: 12),
              Text("إرسال ملاحظة", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
        } else if (val == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranResourcesView()));
        } else if (val == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()));
        } else if (val == 3) {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: "إغلاق الملاحظة",
            transitionDuration: const Duration(milliseconds: 320),
            pageBuilder: (ctx, anim1, anim2) => _WahyFeedbackDialog(primary: primaryColor),
            transitionBuilder: (ctx, anim1, anim2, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                    .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim1, child: child),
              );
            }
          );
        } else if (val == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioPage()));
        } else if (val == 5) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimePage()));
        } else if (val == 6) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaDirection()));
        }
      },
    );
  }
}

class _WahySideDrawer extends StatefulWidget {
  final Color primary;
  final Future<void> Function() onOpenIndex;
  final Future<void> Function() onOpenKhatma;
  final Future<void> Function() onOpenBookmarks;
  final Future<void> Function() onOpenStarred;
  final Future<void> Function() onOpenNotes;
  final Future<void> Function() onJumpToAyah;

  const _WahySideDrawer({
    required this.primary,
    required this.onOpenIndex,
    required this.onOpenKhatma,
    required this.onOpenBookmarks,
    required this.onOpenStarred,
    required this.onOpenNotes,
    required this.onJumpToAyah,
  });

  @override
  State<_WahySideDrawer> createState() => _WahySideDrawerState();
}

class _WahySideDrawerState extends State<_WahySideDrawer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 600)
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, c) {
        final double delay = index * 0.08;
        final double curveValue = Curves.easeOutCubic.transform(
          ((_controller.value - delay) / (1 - delay)).clamp(0.0, 1.0)
        );
        return Transform.translate(
           offset: Offset(-30 * (1 - curveValue), 0),
           child: Opacity(
             opacity: curveValue,
             child: c,
           ),
        );
      },
      child: child,
    );
  }

  Future<void> _closeThen(BuildContext context, Future<void> Function() action) async {
    Navigator.pop(context);
    await action();
  }

  Future<void> _closeThenPush(BuildContext context, Widget page) async {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    // Apple Dark Aesthetics
    const bg = Color(0xFF0A0A0A);
    const card = Color(0xFF161616);
    const onBg = Colors.white;

    int i = 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        width: 320,
        backgroundColor: bg,
        // Glassmorphism effect for drawer
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: bg.withValues(alpha: 0.8),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context); // Close drawer
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppPage()));
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "مركز الخدمات",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: onBg,
                                      ),
                                    ),
                                    Text(
                                      "IDRISIUM STANDARD",
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w700,
                                        color: widget.primary,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            color: widget.primary,
                            style: IconButton.styleFrom(
                              backgroundColor: widget.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildAnimItem(i++, Text(
                            "الرئيسية",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                          )),
                          const SizedBox(height: 8),
                          _buildAnimItem(i++, _WahyDrawerItem(
                            title: "المصحف المعلم",
                            subtitle: "تلاوة وتفسير",
                            icon: Icons.menu_book_rounded,
                            primary: widget.primary,
                            onTap: () => Navigator.pop(context), 
                            cardColor: card,
                          )),
                          const SizedBox(height: 10),
                          _buildAnimItem(i++, Text(
                            "الخدمات الإسلامية",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                          )),
                          const SizedBox(height: 8),
                          _buildAnimItem(i++, Container(
                            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                _WahyDrawerItem(
                                  title: "مواقيت الصلاة",
                                  subtitle: "مواعيد وتنبيهات",
                                  icon: Icons.access_time_filled_rounded,
                                  primary: widget.primary,
                                  onTap: () => _closeThenPush(context, const PrayerTimePage()),
                                ),
                                _WahyDrawerDivider(),
                                _WahyDrawerItem(
                                  title: "اتجاه القبلة",
                                  subtitle: "البوصلة الذكية",
                                  icon: Icons.explore_rounded,
                                  primary: widget.primary,
                                  onTap: () => _closeThenPush(context, const QiblaDirection()),
                                ),
                                _WahyDrawerDivider(),
                                _WahyDrawerItem(
                                  title: "الصوتيات",
                                  subtitle: "مكتبة القراء",
                                  icon: Icons.headphones_rounded,
                                  primary: widget.primary,
                                  onTap: () => _closeThenPush(context, const AudioPage()),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 20),
                          _buildAnimItem(i++, Text(
                            "الإدارة السريعة",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                          )),
                          const SizedBox(height: 8),
                          _buildAnimItem(i++, Container(
                            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                _WahyDrawerItem(
                                  title: "الفهرس والانتقال",
                                  subtitle: "سورة / آية / صفحة",
                                  icon: Icons.format_list_bulleted_rounded,
                                  primary: widget.primary,
                                  onTap: () => _closeThen(context, widget.onOpenIndex),
                                ),
                                _WahyDrawerDivider(),
                                _WahyDrawerItem(
                                  title: "مساحة الختمة",
                                  subtitle: "متابعة الحفظ",
                                  icon: Icons.auto_awesome_rounded,
                                  primary: widget.primary,
                                  onTap: () => _closeThenPush(context, const SmartKhatmaPage()),
                                ),
                                _WahyDrawerDivider(),
                                _WahyDrawerItem(
                                  title: "الإعدادات",
                                  subtitle: "تخصيص التطبيق",
                                  icon: Icons.settings_rounded,
                                  primary: widget.primary,
                                  onTap: () => _closeThenPush(context, const SettingsPage()),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WahyDrawerItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primary;
  final VoidCallback onTap;
  final Color? cardColor;

  const _WahyDrawerItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primary,
    required this.onTap,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8F8F8F),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WahyDrawerDivider extends StatelessWidget {
  const _WahyDrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}

class _WahyFeedbackDialog extends StatefulWidget {
  final Color primary;
  const _WahyFeedbackDialog({required this.primary});

  @override
  State<_WahyFeedbackDialog> createState() => _WahyFeedbackDialogState();
}

class _WahyFeedbackDialogState extends State<_WahyFeedbackDialog> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _message = TextEditingController();
  bool _isSending = false;

  static const String _telegramBotToken = String.fromEnvironment(
    "TELEGRAM_BOT_TOKEN",
    defaultValue: "",
  );
  static const String _telegramChatId = String.fromEnvironment(
    "TELEGRAM_CHAT_ID",
    defaultValue: "",
  );

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<bool> _sendToTelegram(String text) async {
    try {
      final url = Uri.parse("https://api.telegram.org/bot$_telegramBotToken/sendMessage");
      final res = await http.post(
        url,
        body: {
          "chat_id": _telegramChatId,
          "text": text,
          "disable_web_page_preview": "true",
        },
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1B1F) : AppColors.ayaSurface;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.ayaBorder;
    final inputBg = isDark ? const Color(0xFF252529) : Colors.white.withValues(alpha: 0.5);

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, curve: Curves.easeOut),
        ScaleEffect(begin: const Offset(0.98, 0.98), duration: 300.ms, curve: Curves.easeOutBack),
      ],
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minimalist Header
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_rounded, color: widget.primary, size: 28),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "إرسال ملاحظة",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "شارك في تطوير التطبيق تؤجر بإذن الله",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Fields
                    _buildField(
                      controller: _name,
                      label: "الاسم",
                      hint: "اسمك الكريم",
                      icon: Icons.person_outline_rounded,
                      bg: inputBg,
                      border: borderColor,
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      controller: _contact,
                      label: "التواصل",
                      hint: "رقم أو إيميل (اختياري)",
                      icon: Icons.alternate_email_rounded,
                      bg: inputBg,
                      border: borderColor,
                    ),
                    const SizedBox(height: 18),
                    _buildField(
                      controller: _message,
                      label: "الرسالة",
                      hint: "اكتب ملاحظتك أو اقتراحك هنا...",
                      icon: Icons.edit_note_rounded,
                      minLines: 4,
                      maxLines: 6,
                      bg: inputBg,
                      border: borderColor,
                    ),
                    const SizedBox(height: 36),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isSending ? null : () => Navigator.pop(context),
                            child: Text(
                              "إلغاء",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white38 : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSending ? null : _handleSubmit,
                            child: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "إرسال",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
    required Color bg,
    required Color border,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: widget.primary, size: 20),
            filled: true,
            fillColor: bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: widget.primary.withValues(alpha: 0.3))),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    final msg = _message.text.trim();
    if (msg.isEmpty) return;

    final name = _name.text.trim();
    final contact = _contact.text.trim();

    final payload = StringBuffer()
      ..writeln("💎 [IDRISIUM App Feedback]")
      ..writeln("━━━━━━━━━━━━━━━")
      ..writeln("📱 Platform: ${defaultTargetPlatform.name}")
      ..writeln("👤 Name: ${name.isEmpty ? '-' : name}")
      ..writeln("🔗 Contact: ${contact.isEmpty ? '-' : contact}")
      ..writeln("━━━━━━━━━━━━━━━")
      ..writeln("📝 Message:")
      ..writeln(msg);

    setState(() => _isSending = true);
    try {
      final canSend = _telegramBotToken.isNotEmpty && _telegramChatId.isNotEmpty;
      if (!canSend) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("إرسال تيليجرام غير مُفعّل حالياً")),
          );
        }
        return;
      }

      final ok = await _sendToTelegram(payload.toString());
      if (ok && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("تم إرسال رسالتك بنجاح، شكراً لك! 💎")),
        );
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("فشل إرسال الرسالة، يرجى المحاولة لاحقاً")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _WahyBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _WahyBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1B1B1F).withValues(alpha: 0.85) : AppColors.ayaSurface.withValues(alpha: 0.85);
    final borderColor = isDark ? Colors.white10 : AppColors.ayaBorder.withValues(alpha: 0.5);
    final textColor = isDark ? Colors.white : AppColors.ayaTextMain;
    final inactiveColor = isDark ? Colors.white24 : AppColors.ayaBorder;

    // Aya Bottom Slider mimics the top bar glass but sits at the bottom.
    // Left: Juz Name, Right: Surah Name, Center: Slider
    final ayahKeyCubit = context.watch<AyahKeyCubit>();
    final currentPage = ayahKeyCubit.state.lastScrolledPageNumber ?? 1;
    final totalPages = 604;
    final double sliderValue = (currentPage.toDouble()).clamp(1.0, totalPages.toDouble());

    String surahName = "";
    String juzName = "";

    try {
      final key = ayahKeyCubit.state.current;
      final parts = key.split(":");
      if (parts.length == 2) {
        final surah = int.tryParse(parts[0]);
        if (surah != null) {
          surahName = getSurahNameArabic(surah);
          final ayah = int.tryParse(parts[1]);
          if (ayah != null) {
             final j = qcf.getJuzNumber(surah, ayah);
             juzName = "الجزء ${localizedNumber(context, j)}";
          }
        }
      }
    } catch (_) {}

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.transparent, // Let parent clip handle glass
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                   Expanded(
                     flex: 2,
                     child: Text(
                       surahName,
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       textAlign: TextAlign.start,
                       style: TextStyle(
                         color: textColor,
                         fontSize: 14,
                         fontWeight: FontWeight.w700,
                       ),
                     ),
                   ),
                   Expanded(
                     flex: 6,
                     child: SliderTheme(
                       data: SliderTheme.of(context).copyWith(
                         activeTrackColor: themeState.primary,
                         inactiveTrackColor: inactiveColor,
                         thumbColor: themeState.primary,
                         overlayColor: themeState.primary.withValues(alpha: 0.1),
                         trackHeight: 3,
                         thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                       ),
                       child: Slider(
                         value: sliderValue,
                         min: 1,
                         max: totalPages.toDouble(),
                         onChanged: (val) {
                           final target = val.toInt();
                           context.read<AyahKeyCubit>().changeLastScrolledPage(target);
                           // Rough estimate for ayah key to update top text
                           final pageSurahs = qcf.getPageData(target);
                           if (pageSurahs.isNotEmpty) {
                             final firstSurah = pageSurahs[0];
                             context.read<AyahKeyCubit>().changeCurrentAyahKey("${firstSurah['surah']}:${firstSurah['start']}");
                           }
                         },
                       ),
                     ),
                   ),
                   Expanded(
                     flex: 2,
                     child: Text(
                       juzName,
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                       textAlign: TextAlign.end,
                       style: TextStyle(
                         color: textColor,
                         fontSize: 14,
                         fontWeight: FontWeight.w700,
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
  }
}

// Removed _WahyNavItem as it is no longer needed since the bottom bar is now a slider
class _WahyIndexSheet extends StatefulWidget {
  final ValueChanged<int> onOpenPage;
  final ValueChanged<String>? onOpenAyah;
  const _WahyIndexSheet({required this.onOpenPage, this.onOpenAyah});

  @override
  State<_WahyIndexSheet> createState() => _WahyIndexSheetState();
}

class _WahyIndexSheetState extends State<_WahyIndexSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _sheetSearchField(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: themeState.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: "ابحث عن سورة…",
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_searchController.text.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF8F8F8F),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  Widget _wahySurahList(BuildContext context, List<SurahInfoModel> surahs) {
    final q = _searchController.text.trim();
    final filtered = q.isEmpty
        ? surahs
        : surahs
            .where((s) {
              final id = s.id;
              final arabic = getSurahNameArabic(id);
              final key =
                  "$id $arabic ${s.pagesRange} ${s.versesCount} ${s.revelationPlace}".toLowerCase();
              return key.contains(q.toLowerCase());
            })
            .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          "مفيش نتائج",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF9C9C9C),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: 10,
        color: Colors.black.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final s = filtered[index];
        final id = s.id;
        final title = getSurahNameArabic(id);
        final ayahKey = "$id:1";
        final page = getPageNumber(ayahKey) ?? 1;

        return InkWell(
          onTap: () {
            final cb = widget.onOpenAyah;
            if (cb != null) {
              cb(ayahKey);
              return;
            }
            widget.onOpenPage(page);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _MushafRootState._bg(context),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: Text(
                    localizedNumber(context, id),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _MushafRootState._onBg(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _MushafRootState._onBg(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "الصفحة ${localizedNumber(context, page)} · ${localizedNumber(context, s.versesCount)} آية",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8F8F8F),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF8F8F8F),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    final surahInfoList = metaDataSurah.values
        .map((value) => SurahInfoModel.fromMap(value))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "الفهرس",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _MushafRootState._onBg(context),
                  ),
                ),
              ),
              Text(
                "السور والأربع",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _MushafRootState._onBg(context).withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _sheetSearchField(context),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F2),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: themeState.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: themeState.primary.withValues(alpha: 0.35)),
              ),
              padding: const EdgeInsets.all(4),
              labelColor: themeState.primary,
              unselectedLabelColor:
                  _MushafRootState._onBg(context).withValues(alpha: 0.55),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(fontWeight: FontWeight.w900),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
              tabs: const [
                Tab(text: "السور"),
                Tab(text: "الأربع"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _wahySurahList(context, surahInfoList),
              _RubListView(
                onOpenPage: widget.onOpenPage,
                query: _searchController.text.trim(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RubListView extends StatelessWidget {
  final ValueChanged<int> onOpenPage;
  final String query;
  const _RubListView({required this.onOpenPage, required this.query});

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    return FutureBuilder<String>(
      future: rootBundle.loadString("assets/meta_data/Rub.json"),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
          return const SizedBox.shrink();
        }

        final Map data = jsonDecode(snap.data!);
        final items = data.values.toList();

        bool matchesQuery({
          required int rubNumber,
          required int surah,
          required int verse,
          required int page,
        }) {
          if (q.isEmpty) return true;
          final surahName = getSurahNameArabic(surah);
          final key = "$rubNumber $surahName $surah:$verse $page".toLowerCase();
          return key.contains(q);
        }

        final filtered = <Map<String, dynamic>>[];
        for (var i = 0; i < items.length; i++) {
          final m = Map<String, dynamic>.from(items[i]);
          final String firstKey = (m["fvk"] as String?) ?? "1:1";
          final int rubNumber = (m["rn"] as int?) ?? (i + 1);
          final surah = int.tryParse(firstKey.split(":").first) ?? 1;
          final verse = int.tryParse(firstKey.split(":").last) ?? 1;
          final page = getPageNumber(firstKey) ?? 1;
          if (matchesQuery(rubNumber: rubNumber, surah: surah, verse: verse, page: page)) {
            filtered.add({
              ...m,
              "_firstKey": firstKey,
              "_rubNumber": rubNumber,
              "_surah": surah,
              "_verse": verse,
              "_page": page,
            });
          }
        }

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              "مفيش نتائج",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF9C9C9C),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => Divider(
            height: 10,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          itemBuilder: (context, index) {
            final m = filtered[index];
            final int rubNumber = (m["_rubNumber"] as int?) ?? (index + 1);
            final surah = (m["_surah"] as int?) ?? 1;
            final verse = (m["_verse"] as int?) ?? 1;
            final page = (m["_page"] as int?) ?? 1;

            return InkWell(
              onTap: () => onOpenPage(page),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _MushafRootState._bg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        localizedNumber(context, rubNumber),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _MushafRootState._onBg(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ربع ${localizedNumber(context, rubNumber)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _MushafRootState._onBg(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${getSurahNameArabic(surah)}: ${localizedNumber(context, verse)} · الصفحة ${localizedNumber(context, page)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8F8F8F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF8F8F8F),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchSheet extends StatefulWidget {
  final TextEditingController controller;
  final Color primary;
  final Future<List<_AyahSearchResult>> Function(String query) search;
  final void Function(String ayahKey) onResultTap;

  const _SearchSheet({
    required this.controller,
    required this.primary,
    required this.search,
    required this.onResultTap,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _lastQuery = "";
  Future<List<_AyahSearchResult>>? _future;

  void _updateSearch() {
    final q = widget.controller.text;
    if (q == _lastQuery) return;
    _lastQuery = q;
    setState(() {
      _future = widget.search(q);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSearch);
    _future = widget.search(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSearch);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.controller.text.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _MushafRootState._bg(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Text(
                          "بحث في الآيات",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: widget.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              hintText: "اكتب كلمة من الآية…",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (q.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              widget.controller.clear();
                            },
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF8F8F8F),
                            splashRadius: 18,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (q.length < 2)
                    const Padding(
                      padding: EdgeInsets.only(top: 26),
                      child: Text(
                        "اكتب حرفين أو أكثر",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9C9C9C),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: FutureBuilder<List<_AyahSearchResult>>(
                        future: _future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final results = snapshot.data ?? const <_AyahSearchResult>[];
                          if (results.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 26),
                              child: Center(
                                child: Text(
                                  "مفيش نتائج",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF9C9C9C),
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 10),
                            itemCount: results.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 10,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            itemBuilder: (context, index) {
                              final r = results[index];
                              return ListTile(
                                onTap: () => widget.onResultTap(r.ayahKey),
                                title: Text(
                                  "${getSurahNameArabic(r.surah)}: ${localizedNumber(context, r.verse)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1B1B1B),
                                  ),
                                ),
                                subtitle: Text(
                                  r.snippet,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    height: 1.55,
                                    color: Color(0xFF8F8F8F),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_left_rounded,
                                  color: widget.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MushafView extends StatefulWidget {
  final bool useDefaultAppBar;
  final int? initialPageNumber;
  final PageController? controller;
  final double? spOverride;
  final double? hOverride;
  final VoidCallback? onToggleHeader;
  const MushafView({
    super.key,
    this.useDefaultAppBar = true,
    this.initialPageNumber,
    this.controller,
    this.spOverride,
    this.hOverride,
    this.onToggleHeader,
  });

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  static Color _bg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark ? Color(0xFF141414) : Color(0xFFF7F1E6);
  static const _pageHeaderSidePadding = 22.0;
  static const _pageFooterBottomPadding = 10.0;

  static const String _kWahyBookmarks = "wahy_bookmarks";
  static const String _kWahyNotes = "wahy_notes";

  Timer? _menuTimer;
  bool _isSheetOpen = false;

  bool _hasAnyWahyMarker({
    required String ayahKey,
    required Set<String> starred,
    required Set<String> notes,
    required Set<String> bookmarks,
  }) {
    return starred.contains(ayahKey) || notes.contains(ayahKey) || bookmarks.contains(ayahKey);
  }

  Future<void> _addNoteForAyahKey(String ayahKey) async {
    final controller = TextEditingController();
    final themeState = context.read<ThemeCubit>().state;

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
color: _bg(ctx),
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
                          fillColor: const Color(0xFFFFF9F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx, controller.text.trim());
                          },
                          child: const Text("حفظ"),
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
    await syncWahyNoteToCollection(ayahKey, text);
  }

  Future<void> _setBookmarkColorForAyahKey(String ayahKey, String colorId) async {
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

  Future<void> _pickBookmarkColorForAyahKey(String ayahKey) async {
    final themeState = context.read<ThemeCubit>().state;
    const card = Color(0xFFFFF9F2);
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
color: _bg(sheet),
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
                    Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: colors.entries.map((entry) {
                          return ListTile(
                            onTap: () async {
                              Navigator.pop(sheet);
                              await _setBookmarkColorForAyahKey(ayahKey, entry.key);
                            },
                            title: Text(
                              entry.value.name,
                              style: const TextStyle(fontWeight: FontWeight.w900),
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

  String _arabicOrdinalLocal(BuildContext context, int n) {
    const ord = [
      "الأول",
      "الثاني",
      "الثالث",
      "الرابع",
      "الخامس",
      "السادس",
      "السابع",
      "الثامن",
      "التاسع",
      "العاشر",
      "الحادي عشر",
      "الثاني عشر",
      "الثالث عشر",
      "الرابع عشر",
      "الخامس عشر",
      "السادس عشر",
      "السابع عشر",
      "الثامن عشر",
      "التاسع عشر",
      "العشرون",
      "الحادي والعشرون",
      "الثاني والعشرون",
      "الثالث والعشرون",
      "الرابع والعشرون",
      "الخامس والعشرون",
      "السادس والعشرون",
      "السابع والعشرون",
      "الثامن والعشرون",
      "التاسع والعشرون",
      "الثلاثون",
    ];
    if (n >= 1 && n <= ord.length) return ord[n - 1];
    return localizedNumber(context, n);
  }

  int _quarterNumberFor(int surahNumber, int startVerse) {
    var last = 1;
    for (var i = 0; i < quarters.length; i++) {
      final q = quarters[i];
      final s = (q["surah"] as int?) ?? 1;
      final a = (q["ayah"] as int?) ?? 1;

      if (s < surahNumber || (s == surahNumber && a <= startVerse)) {
        last = i + 1;
      } else {
        break;
      }
    }
    return last.clamp(1, quarters.length);
  }

  int _hizbNumberFor(int surahNumber, int startVerse) {
    final quarter = _quarterNumberFor(surahNumber, startVerse);
    return ((quarter - 1) ~/ 4) + 1;
  }

  String _stripHtml(String input) {
    // Preserve readable line breaks before stripping tags
    final normalized = input
        .replaceAll(RegExp(r"<\s*br\s*\/?>", caseSensitive: false), "\n")
        .replaceAll(RegExp(r"<\s*\/p\s*>", caseSensitive: false), "\n")
        .replaceAll(RegExp(r"<\s*p[^>]*>", caseSensitive: false), "");

    return normalized
        .replaceAll(RegExp(r"<[^>]*>"), "")
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&")
        .replaceAll("&quot;", "\"")
        .replaceAll("&#39;", "'")
        .replaceAll("\r", "")
        .trim();
  }

  bool _isHizbStart(int surahNumber, int startVerse) {
    final q = _quarterNumberFor(surahNumber, startVerse);
    final hizb = ((q - 1) ~/ 4) + 1;
    final hizbStartQuarterIndex = ((hizb - 1) * 4).clamp(0, quarters.length - 1);
    final entry = quarters[hizbStartQuarterIndex];
    final s = (entry["surah"] as int?) ?? -1;
    final a = (entry["ayah"] as int?) ?? -1;
    return s == surahNumber && a == startVerse;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final page = (widget.initialPageNumber ?? 1).clamp(1, 604);
        final info = quranPagesInfo[
            (page - 1).clamp(0, quranPagesInfo.length - 1)];
        final ayahId = info["s"] ?? 1;
        final key = convertAyahNumberToKey(ayahId);
        if (key != null) {
          context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
        }
      } catch (_) {}
    });
  }

  String _getAyahText(BuildContext context, int surah, int verse) {
    const QuranScriptType scriptType = QuranScriptType.tajweed;
    final words = QuranScriptFunction.getWordListOfAyah(
      scriptType,
      surah.toString(),
      verse.toString(),
    );
    if (words.isEmpty) return "$surah:$verse";

    final raw = words.join(" ");
    final stripped = raw.replaceAll(RegExp(r"<[^>]+>"), "");
    return stripped.replaceAll(RegExp(r"\s+"), " ").trim();
  }

  String _formatAyahTextForSharing({
    required String ayahKey,
    required String ayahText,
  }) {
    final parts = ayahKey.split(":");
    final verse = parts.length == 2 ? parts[1].trim() : "";
    final verseInBrackets = verse.isEmpty ? "" : "﴿${_toArabicDigits(verse)}﴾";

    var t = ayahText.trimRight();
    t = t.replaceAll(RegExp(r"[\s\u06DD۝]+$"), "");
    t = t.replaceAll(RegExp(r"[\s0-9٠-٩۰-۹]+$"), "");
    t = t.trimRight();

    return "$t $verseInBrackets".trim();
  }

  String _formatAyahTextForImage({
    required String ayahText,
  }) {
    var t = ayahText.trimRight();
    t = t.replaceAll(RegExp(r"[\s\u06DD۝]+$"), "");
    t = t.replaceAll(RegExp(r"[\s0-9٠-٩۰-۹]+$"), "");
    t = t.trimRight();
    return t;
  }

  String _removeTashkeel(String text) {
    return text
        .replaceAll(RegExp(r"[\u064B-\u0652\u0670\u06D6-\u06ED]"), "")
        .replaceAll("\u0640", "");
  }

  String _formatAyahTextWithBrackets({
    required int verseNumber,
    required String ayahText,
  }) {
    final cleaned = _formatAyahTextForImage(ayahText: ayahText);
    return "$cleaned ﴿${_toArabicDigits(verseNumber.toString())}﴾".trim();
  }

  Future<void> _showShareDialog({
    required BuildContext context,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final l10n = AppLocalizations.of(context);
    final themeState = context.read<ThemeCubit>().state;
    final total = getVerseCount(surahNumber);

    int from = verseNumber;
    int to = verseNumber;
    int shareType = 0; // 0 image, 1 text, 2 plain

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            const bg = Color(0xFFF7F1E6);
            const card = Color(0xFFFFF9F2);
            final green = themeState.primary;

            Widget section({required Widget child}) {
              return Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              );
            }

            Future<void> doShare() async {
              final overlayContext =
                  navigatorKey.currentState?.overlay?.context;
              final shareContext = overlayContext ?? sheetContext;

              if (shareType == 0) {
                if (from != to) {
                  setSheetState(() {
                    shareType = 1;
                  });
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "مشاركة الصورة متاحة لآية واحدة فقط — تم التحويل لمشاركة نص.",
                        textDirection: TextDirection.rtl,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final ayahText = _getAyahText(shareContext, surahNumber, from);
                await _shareAsImage(
                  shareContext,
                  "$surahNumber:$from",
                  ayahText,
                );
                return;
              }

              final buffer = StringBuffer();
              buffer.writeln("${getSurahNameArabic(surahNumber)}");
              buffer.writeln();

              for (int v = from; v <= to; v++) {
                final t = _getAyahText(shareContext, surahNumber, v);
                final line = _formatAyahTextWithBrackets(verseNumber: v, ayahText: t);
                buffer.writeln(line);
                buffer.writeln();
              }

              var finalText = buffer.toString().trim();
              if (shareType == 2) {
                finalText = _removeTashkeel(finalText);
              }

              await SharePlus.instance.share(
                ShareParams(text: finalText),
              );
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
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
                                  const SizedBox(height: 10),
                                  const Text(
                                    "مشاركة",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1B1B1B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  section(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "من",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1B1B1B),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                DropdownButtonFormField<int>(
                                                  value: from,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    filled: true,
                                                    fillColor: Color(0xFFF7F1E6),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide.none,
                                                      borderRadius: BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                  items: List.generate(
                                                    total,
                                                    (i) => DropdownMenuItem(
                                                      value: i + 1,
                                                      child: Text(
                                                        "${getSurahNameArabic(surahNumber)}: ${_toArabicDigits((i + 1).toString())}",
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  onChanged: (v) {
                                                    if (v == null) return;
                                                    setSheetState(() {
                                                      from = v;
                                                      if (to < from) to = from;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  "إلى",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1B1B1B),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                DropdownButtonFormField<int>(
                                                  value: to,
                                                  decoration: const InputDecoration(
                                                    isDense: true,
                                                    filled: true,
                                                    fillColor: Color(0xFFF7F1E6),
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide.none,
                                                      borderRadius: BorderRadius.all(
                                                        Radius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                  items: List.generate(
                                                    total,
                                                    (i) => DropdownMenuItem(
                                                      value: i + 1,
                                                      child: Text(
                                                        "${getSurahNameArabic(surahNumber)}: ${_toArabicDigits((i + 1).toString())}",
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  onChanged: (v) {
                                                    if (v == null) return;
                                                    setSheetState(() {
                                                      to = v;
                                                      if (to < from) from = to;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  section(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Column(
                                        children: [
                                          RadioListTile<int>(
                                            value: 0,
                                            groupValue: shareType,
                                            activeColor: green,
                                            title: const Text("مشاركة صورة"),
                                            onChanged: from == to
                                                ? (v) => setSheetState(() => shareType = v ?? 0)
                                                : null,
                                          ),
                                          RadioListTile<int>(
                                            value: 1,
                                            groupValue: shareType,
                                            activeColor: green,
                                            title: const Text("مشاركة نص"),
                                            onChanged: (v) => setSheetState(() => shareType = v ?? 1),
                                          ),
                                          RadioListTile<int>(
                                            value: 2,
                                            groupValue: shareType,
                                            activeColor: green,
                                            title: const Text("نص بدون تشكيل"),
                                            onChanged: (v) => setSheetState(() => shareType = v ?? 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: card,
                                foregroundColor: const Color(0xFF1B1B1B),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.black.withValues(alpha: 0.10),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                await doShare();
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                              },
                              child: Text(
                                l10n.shareButton,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
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
      },
    );
  }

  String _toArabicDigits(String number) {
    const arabics = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final buffer = StringBuffer();
    for (final ch in number.split('')) {
      final digit = int.tryParse(ch);
      if (digit == null) {
        buffer.write(ch);
      } else {
        buffer.write(arabics[digit]);
      }
    }
    return buffer.toString();
  }

  String _stripTrailingVerseNumber(String text) {
    var t = text.trimRight();
    t = t.replaceAll(RegExp(r"[\s\u06DD۝]+$"), "");
    t = t.replaceAll(RegExp(r"[\s0-9٠-٩۰-۹]+$"), "");
    return t.trimRight();
  }

  String? _sanitizeTafsirText(String? raw) {
    if (raw == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;

    if (t.startsWith("Instance of ")) return null;

    // Some sources may return JSON/Map string; try to extract a `text` field.
    if ((t.startsWith("{") && t.endsWith("}")) || (t.startsWith("[") && t.endsWith("]"))) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is Map && decoded["text"] is String) {
          t = (decoded["text"] as String).trim();
        }
      } catch (_) {}
    }

    // Extract `text:` if it looks like a dart map toString.
    if (t.contains("text:") && t.contains("{")) {
      final m = RegExp(r"text:\s*([^,}]+)").firstMatch(t);
      if (m != null) {
        t = m.group(1)?.trim() ?? t;
      }
    }

    // Strip html tags if present.
    t = t.replaceAll(RegExp(r"<[^>]+>"), " ");
    t = t.replaceAll("\\n", "\n");
    t = t.replaceAll(RegExp(r"\n{3,}"), "\n\n");
    t = t.replaceAll(RegExp(r"\s{2,}"), " ");
    t = t.trim();
    return t.isEmpty ? null : t;
  }

  bool _allowTafsirImageShare(String tafsirTitle) {
    final t = tafsirTitle.trim();
    return t.contains("الميسر") || t.contains("المختصر");
  }

  TafsirBookModel? _findTafsirBookByNameContains(String needle) {
    final n = needle.trim();
    if (n.isEmpty) return null;
    for (final langKey in tafsirInformationWithScore.keys) {
      final rawList = tafsirInformationWithScore[langKey];
      if (rawList == null) continue;
      for (final raw in rawList) {
        try {
          final m = Map<String, dynamic>.from(raw);
          final b = TafsirBookModel.fromMap(m);
          if (b.name.contains(n)) return b;
        } catch (_) {}
      }
    }
    return null;
  }

  bool _isDownloadedByFullPath(String fullPath, List<TafsirBookModel> downloaded) {
    return downloaded.any((b) => b.fullPath == fullPath);
  }

  Future<void> _downloadAndSelectTafsir(
    BuildContext context,
    TafsirBookModel book,
  ) async {
    await QuranTafsirFunction.downloadResources(
      context: context,
      isSetupProcess: false,
      tafsirBook: book,
    );
    if (await QuranTafsirFunction.isAlreadyDownloaded(book)) {
      await QuranTafsirFunction.setTafsirSelection(book);
    }
  }

  Future<void> _shareLibraryAsText({
    required BuildContext context,
    required int surahNumber,
    required int verseNumber,
    required String ayahText,
    required Future<List<MapEntry<String, String?>>> Function() loadTafsirs,
  }) async {
    final tafsirs = await loadTafsirs();
    final buffer = StringBuffer();

    final surahName = "سورة ${getSurahNameArabic(surahNumber)}";
    final verseMark = "﴿$verseNumber﴾";

    buffer.writeln(surahName);
    buffer.writeln();
    buffer.writeln(
      "${_stripTrailingVerseNumber(ayahText)} ﴿$verseNumber﴾",
    );

    final cleaned = tafsirs
        .map(
          (e) => MapEntry(e.key, _sanitizeTafsirText(e.value)),
        )
        .where((e) => e.value != null && e.value!.trim().isNotEmpty)
        .toList();

    if (cleaned.isNotEmpty) {
      for (final e in cleaned) {
        buffer.writeln();
        buffer.writeln("──────────────");
        buffer.writeln(e.key.trim());
        buffer.writeln();
        buffer.writeln(e.value!.trim());
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).copiedWithTafsir),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openTafsirStyleShareOptions({
    required BuildContext context,
    required int surahNumber,
    required int verseNumber,
    required String ayahText,
  }) async {
    final themeState = context.read<ThemeCubit>().state;
    final downloadedBooks = QuranTafsirFunction.getDownloadedTafsirBooks();
    final selectedBooksFuture = QuranTafsirFunction.getTafsirSelections();
    final String ayahKey = "$surahNumber:$verseNumber";

    Future<List<MapEntry<String, String?>>> loadAllSelectedTafsirs() async {
      final selectedBooks = await selectedBooksFuture;
      final books = (selectedBooks ?? []).toList();
      if (books.isEmpty) return [];
      final List<MapEntry<String, String?>> out = [];
      for (final b in books) {
        final t = await QuranTafsirFunction.getResolvedTafsirTextForBook(b, ayahKey);
        out.add(MapEntry(b.name, t));
      }
      return out;
    }

    Future<String?> loadTafsir() async {
      final selectedBooks = await selectedBooksFuture;
      final selectedList = (selectedBooks ?? []).toList();
      TafsirBookModel? selectedBook;
      for (final b in selectedList) {
        if (b.name.contains("الميسر")) {
          selectedBook = b;
          break;
        }
      }
      selectedBook ??= (selectedList.isNotEmpty ? selectedList.first : null);
      if (selectedBook == null) return null;
      return QuranTafsirFunction.getResolvedTafsirTextForBook(selectedBook, ayahKey);
    }

    final selectedBooks = await selectedBooksFuture;
    final selected = (selectedBooks ?? []).toList();
    final String tafsirTitle = selected.isNotEmpty ? selected.first.name : "التفسير";

    TafsirBookModel? muyassar = _findTafsirBookByNameContains("الميسر");
    final TafsirBookModel? mukhtasar = _findTafsirBookByNameContains("المختصر");

    // Ensure we treat the offline bundled Muyassar as the authoritative one.
    if (muyassar != null && muyassar.name.contains("الميسر")) {
      muyassar = DefaultOfflineResources.defaultTafsirMuyassar;
    }

    bool muyassarDownloaded =
        muyassar != null && _isDownloadedByFullPath(muyassar.fullPath, downloadedBooks);
    final bool mukhtasarDownloaded =
        mukhtasar != null && _isDownloadedByFullPath(mukhtasar.fullPath, downloadedBooks);

    // Extra safety: bundled offline Muyassar might not exist in downloadedBooks list.
    if (muyassar != null &&
        muyassar.fullPath == DefaultOfflineResources.defaultTafsirMuyassar.fullPath) {
      final boxName = QuranTafsirFunction.getTafsirBoxName(tafsirBook: muyassar);
      final exists = await Hive.boxExists(boxName);
      muyassarDownloaded = muyassarDownloaded || exists;
    }

    final bool selectedMuyassar = selected.any((b) => b.name.contains("الميسر"));
    final bool selectedMukhtasar = selected.any((b) => b.name.contains("المختصر"));
    final bool showPickBetweenImageBooks = selectedMuyassar && selectedMukhtasar;

    final bool isAyahDayn = ayahKey == "2:282";
    final bool isVeryLongAyah =
        isAyahDayn || ayahText.replaceAll(RegExp(r"\s+"), "").length > 280;
    final bool allowImageShareWithTafsir =
        !isVeryLongAyah && (selectedMuyassar || selectedMukhtasar) && (muyassarDownloaded || mukhtasarDownloaded);

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F2),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: themeState.primary),
                  title: const Text("كنص"),
                  subtitle: const Text("ينسخ الآية + كل التفاسير المختارة بشكل مرتب"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _shareLibraryAsText(
                      context: context,
                      surahNumber: surahNumber,
                      verseNumber: verseNumber,
                      ayahText: ayahText,
                      loadTafsirs: loadAllSelectedTafsirs,
                    );
                  },
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                ListTile(
                  leading: Icon(Icons.image_outlined, color: themeState.primary),
                  title: const Text("كصورة (بدون تفسير)"),
                  subtitle: const Text("مشاركة الآية فقط كصورة — مناسب للآيات الطويلة"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _shareAsImage(context, ayahKey, ayahText);
                  },
                ),
                if (allowImageShareWithTafsir && showPickBetweenImageBooks) ...[
                  ListTile(
                    leading: Icon(Icons.image_outlined, color: themeState.primary),
                    title: const Text("كصورة - التفسير الميسر"),
                    subtitle: const Text("مشاركة صورة بالتفسير الميسر"),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (selected.isEmpty) {
                        await _shareAsImage(context, ayahKey, ayahText);
                        return;
                      }
                      final b = selected.firstWhere(
                        (x) => x.name.contains("الميسر"),
                        orElse: () => selected.first,
                      );
                      await _shareLibraryAsImage(
                        context: context,
                        surahNumber: surahNumber,
                        verseNumber: verseNumber,
                        ayahKey: ayahKey,
                        tafsirTitle: "التفسير الميسر",
                        loadTafsir: () => QuranTafsirFunction.getResolvedTafsirTextForBook(
                          b,
                          ayahKey,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.image_outlined, color: themeState.primary),
                    title: const Text("كصورة - التفسير المختصر"),
                    subtitle: const Text("مشاركة صورة بالتفسير المختصر"),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (selected.isEmpty) {
                        await _shareAsImage(context, ayahKey, ayahText);
                        return;
                      }
                      final b = selected.firstWhere(
                        (x) => x.name.contains("المختصر"),
                        orElse: () => selected.first,
                      );
                      await _shareLibraryAsImage(
                        context: context,
                        surahNumber: surahNumber,
                        verseNumber: verseNumber,
                        ayahKey: ayahKey,
                        tafsirTitle: "التفسير المختصر",
                        loadTafsir: () => QuranTafsirFunction.getResolvedTafsirTextForBook(
                          b,
                          ayahKey,
                        ),
                      );
                    },
                  ),
                ] else if (allowImageShareWithTafsir)
                  ListTile(
                    leading: Icon(Icons.image_outlined, color: themeState.primary),
                    title: const Text("كصورة"),
                    subtitle: Text("يصنع صورة بنفس تنسيق المكتبة ($tafsirTitle)"),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _shareLibraryAsImage(
                        context: context,
                        surahNumber: surahNumber,
                        verseNumber: verseNumber,
                        ayahKey: ayahKey,
                        tafsirTitle: tafsirTitle,
                        loadTafsir: loadTafsir,
                      );
                    },
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareLibraryAsImage({
    required BuildContext context,
    required int surahNumber,
    required int verseNumber,
    required String ayahKey,
    required String tafsirTitle,
    required Future<String?> Function() loadTafsir,
  }) async {
    final MediaQueryData mq = MediaQuery.of(context);
    const double canvasWidth = 1400; // زودت العرض
    const double minCaptureHeight = 980;

    const double paddingH = 40;
    final double headerWidth = canvasWidth - (paddingH * 2);
    final double bannerWidth = headerWidth * 0.82; // صغرنا البانر شوية

    final int pageNumber = getPageNumber(ayahKey) ?? 1;
    final String pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";

    // اسم السورة في البانر - أكبر (ثابت في الدارك مود واللايت مود)
    final qcfTheme = QcfThemeData.sepia().copyWith(
      pageBackgroundColor: const Color(0xFFF7F1E6), // خلفية بيج ثابتة
      headerBackgroundColor: const Color(0xFFEFE3D2), // لون البانر ثابت
      headerWidthLarge: bannerWidth * 1.25, // صغرنا شوية
      headerWidthSmall: bannerWidth * 1.25,
      headerFontSizeLarge: 105, // صغرنا شوية
      headerFontSizeSmall: 105,
      headerTextColor: const Color(0xFF1B1B1B), // اسم السورة أسود ثابت
      verseTextColor: const Color(0xFF1B1B1B), // الآية سوداء ثابتة
      verseNumberColor: const Color(0xFF1B1B1B), // رقم الآية أسود ثابت
    );

    final String? tafsirText = _sanitizeTafsirText(await loadTafsir());

    final double titleFontSize = (44 - (tafsirTitle.length * 0.35)).clamp(36, 44);
    final TextStyle titleStyle = TextStyle(
      fontSize: titleFontSize,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1B1B1B).withValues(alpha: 0.55),
    );

    const tafsirStyle = TextStyle(
      fontSize: 48,
      height: 2.2,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1B1B1B),
    );

    final String tafsirBody = (tafsirText == null || tafsirText.trim().isEmpty)
        ? "لا يوجد تفسير لهذه الآية في المصدر المحدد."
        : tafsirText.trim();

    final TextPainter tafsirPainter = TextPainter(
      text: const TextSpan(text: "", style: tafsirStyle),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    )
      ..text = TextSpan(text: tafsirBody, style: tafsirStyle)
      ..layout(maxWidth: headerWidth - 36);

    final TextPainter titlePainter = TextPainter(
      text: TextSpan(text: tafsirTitle, style: titleStyle),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      maxLines: 2,
    )..layout(maxWidth: headerWidth);

    // ارتفاع الصورة = المحتوى + هامش بسيط فقط (يتغير حسب طول التفسير)
    final double estimatedHeight =
        30 +
        180 + // بانر كبير + تباعد
        540 + // كتلة الآية
        14 +
        titlePainter.height +
        14 +  // فاصل
        (tafsirPainter.height + 20) + // صندوق التفسير
        30 + // مسافة سفلية
        120; // هامش إضافي

    // تصميم مثل الصورة المرجعية: بانر → آية → فاصل رفيع → عنوان التفسير (نص فقط على البيج) → صندوق التفسير
    final GlobalKey cardKey = GlobalKey();
    
    final Widget card = Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        key: cardKey,
        child: Container(
          width: canvasWidth,
          padding: const EdgeInsets.symmetric(horizontal: paddingH, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1E6),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 30),
                // البانر الكبير من qcf_quran
                Center(
                  child: SizedBox(
                    width: bannerWidth,
                    child: Transform.scale(
                      scale: 1.22, // صغرنا شوية بسيطة
                      child: HeaderWidget(
                        suraNumber: surahNumber,
                        theme: qcfTheme,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // الآية الكريمة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: getVerseQCF(
                            surahNumber,
                            verseNumber,
                            verseEndSymbol: false,
                          ),
                        ),
                        const TextSpan(text: "\u200A"),
                        TextSpan(
                          text: getVerseNumberQCF(surahNumber, verseNumber),
                          style: TextStyle(
                            fontFamily: pageFont,
                            package: "qcf_quran",
                            color: qcfTheme.verseNumberColor,
                            height: qcfTheme.verseNumberHeight,
                          ),
                        ),
                      ],
                    ),
                    locale: const Locale("ar"),
                    textScaler: const TextScaler.linear(1),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: pageFont,
                      package: "qcf_quran",
                      fontSize: 75,
                      height: 2.1,
                      color: qcfTheme.verseTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              // فاصل رفيع بين الآية ومنطقة التفسير
              Container(
                width: double.infinity,
                height: 1.2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFF1B1B1B).withValues(alpha: 0.12),
              ),
              const SizedBox(height: 14),
              // اسم كتاب التفسير كنص فقط على خلفية البيج (بدون بار ملون)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    tafsirTitle,
                    style: titleStyle,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE3D2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    tafsirBody,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: tafsirStyle,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      )
      ),
    );

    // render the card to an image using RepaintBoundary
    // نعرض الكارد بشكل مؤقت عشان يتصور (في مكان بعيد عشان ميبانش)
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: -10000, // مكان بعيد جداً عشان ميبانش
        left: -10000,
        child: card,
      ),
    );
    overlay.insert(overlayEntry);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    final boundary = cardKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    overlayEntry.remove();
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: "image/png")],
        fileNameOverrides: ["$ayahKey-tafsir.png"],
        downloadFallbackEnabled: false,
        mailToFallbackEnabled: false,
      ),
    );
  }

  Future<void> _shareAsText(BuildContext context, String ayahKey, String ayahText) async {
    final parts = ayahKey.split(":");
    final surahNum = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final verseNum = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (surahNum == null || verseNum == null) {
      final formatted = _formatAyahTextForSharing(ayahKey: ayahKey, ayahText: ayahText);
      await SharePlus.instance.share(ShareParams(text: "$ayahKey\n\n$formatted"));
      return;
    }
    final formatted = _formatAyahTextForSharing(ayahKey: ayahKey, ayahText: ayahText);
    await SharePlus.instance.share(
      ShareParams(text: "${getSurahNameArabic(surahNum)} - $ayahKey\n\n$formatted"),
    );
  }

  Future<void> _shareAsImage(
    BuildContext context,
    String ayahKey,
    String ayahText,
  ) async {
    final parts = ayahKey.split(":");
    final surahNumber = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final verseNumber = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (surahNumber == null || verseNumber == null) {
      await SharePlus.instance.share(ShareParams(text: "$ayahKey\n\n${_formatAyahTextForSharing(ayahKey: ayahKey, ayahText: ayahText)}"));
      return;
    }

    final int pageNumber = getPageNumber(ayahKey) ?? 1;
    final String pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    final MediaQueryData mq = MediaQuery.of(context);
    const double canvasWidth = 1400; // زودت العرض
    const double canvasHeight = 1400; // ارتفاع كافي

    const double paddingH = 40;
    final double headerWidth = canvasWidth - (paddingH * 2);
    final double bannerWidth = headerWidth * 0.82; // صغرنا البانر شوية

    // اسم السورة في البانر - أكبر (ثابت في الدارك مود واللايت مود)
    final qcfTheme = QcfThemeData.sepia().copyWith(
      pageBackgroundColor: const Color(0xFFF7F1E6), // خلفية بيج ثابتة
      headerBackgroundColor: const Color(0xFFEFE3D2), // لون البانر ثابت
      headerWidthLarge: bannerWidth * 1.25, // صغرنا شوية
      headerWidthSmall: bannerWidth * 1.25,
      headerFontSizeLarge: 105, // صغرنا شوية
      headerFontSizeSmall: 105,
      headerTextColor: const Color(0xFF1B1B1B), // اسم السورة أسود ثابت
      verseTextColor: const Color(0xFF1B1B1B), // الآية سوداء ثابتة
      verseNumberColor: const Color(0xFF1B1B1B), // رقم الآية أسود ثابت
    );

    // حساب ارتفاع الآية
    final TextPainter ayahPainter = TextPainter(
      text: TextSpan(
        text: getVerseQCF(surahNumber, verseNumber, verseEndSymbol: false),
        style: TextStyle(
          fontFamily: pageFont,
          package: "qcf_quran",
          fontSize: 75, // كبرنا حجم الآية
          height: 2.1,  // طول سطر أطول
          color: qcfTheme.verseTextColor,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: headerWidth);

    // حساب الارتفاع حسب المحتوى (بانر + آية + مسافة)
    // الارتفاع هيتزاد لو الآية طويلة
    final double estimatedHeight = 26 + 160 + ayahPainter.height + 12 + 150;

    final GlobalKey cardKey = GlobalKey();

    final Widget card = Material(
      color: Colors.transparent,
      child: RepaintBoundary(
        key: cardKey,
        child: Container(
          width: canvasWidth,
          padding: const EdgeInsets.symmetric(horizontal: paddingH, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1E6),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 26),
                // البانر الكبير من qcf_quran
                Center(
                  child: SizedBox(
                    width: bannerWidth,
                    child: Transform.scale(
                      scale: 1.22, // صغرنا شوية بسيطة
                      child: HeaderWidget(
                        suraNumber: surahNumber,
                        theme: qcfTheme,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // الآية الكريمة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: getVerseQCF(
                            surahNumber,
                            verseNumber,
                            verseEndSymbol: false,
                          ),
                        ),
                        const TextSpan(text: "\u200A"),
                        TextSpan(
                          text: getVerseNumberQCF(surahNumber, verseNumber),
                          style: TextStyle(
                            fontFamily: pageFont,
                            package: "qcf_quran",
                            color: qcfTheme.verseNumberColor,
                            height: qcfTheme.verseNumberHeight,
                          ),
                        ),
                      ],
                    ),
                    locale: const Locale("ar"),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: pageFont,
                      package: "qcf_quran",
                      fontSize: 75,
                      height: 2.1,
                      color: qcfTheme.verseTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );

    // render the card to an image using RepaintBoundary
    // نعرض الكارد بشكل مؤقت عشان يتصور (في مكان بعيد عشان ميبانش)
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      await SharePlus.instance.share(
        ShareParams(
          text: "$ayahKey\n\n${_formatAyahTextForSharing(ayahKey: ayahKey, ayahText: ayahText)}",
        ),
      );
      return;
    }
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: -10000, // مكان بعيد جداً عشان ميبانش
        left: -10000,
        child: card,
      ),
    );
    overlay.insert(overlayEntry);

    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 120));

    final ctx = cardKey.currentContext;
    if (ctx == null) {
      overlayEntry.remove();
      await SharePlus.instance.share(
        ShareParams(
          text: "$ayahKey\n\n${_formatAyahTextForSharing(ayahKey: ayahKey, ayahText: ayahText)}",
        ),
      );
      return;
    }

    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      overlayEntry.remove();
      await SharePlus.instance.share(
        ShareParams(
          text: "$ayahKey\n\n${_formatAyahTextForSharing(ayahKey: ayahKey, ayahText: ayahText)}",
        ),
      );
      return;
    }
    final bytes = byteData.buffer.asUint8List();

    overlayEntry.remove();

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$ayahKey.png");
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        fileNameOverrides: ["$ayahKey.png"],
        downloadFallbackEnabled: false,
        mailToFallbackEnabled: false,
      ),
    );
  }

  Future<void> _showLibrarySheet({
    required BuildContext context,
    required int surahNumber,
    required int verseNumber,
  }) async {
    final themeState = context.read<ThemeCubit>().state;
    final total = getVerseCount(surahNumber);

    int currentVerse = verseNumber;
    final Map<String, Future<String?>> tafsirFutureByPath = <String, Future<String?>>{};

    List<TafsirBookModel>? cachedSelectedBooks;

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F1E6);
            final card = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF9F2);

            final downloadedBooks = QuranTafsirFunction.getDownloadedTafsirBooks();
            final selectedBooksFuture = QuranTafsirFunction.getTafsirSelections();

            final String ayahKey = "$surahNumber:$currentVerse";
            final String ayahTextRaw = _getAyahText(sheetContext, surahNumber, currentVerse);
            final int ayahPageNumber = getPageNumber(ayahKey) ?? 1;
            final String ayahPageFont = "QCF_P${ayahPageNumber.toString().padLeft(3, '0')}";
            final String qcfAyah = getVerseQCF(
              surahNumber,
              currentVerse,
              verseEndSymbol: false,
            );

            Future<String?> loadTafsir() async {
              final selectedBooks = await selectedBooksFuture;
              final selectedList = (selectedBooks ?? []).toList();
              TafsirBookModel? selectedBook;
              for (final b in selectedList) {
                if (b.name.contains("الميسر")) {
                  selectedBook = b;
                  break;
                }
              }
              selectedBook ??=
                  (selectedList.isNotEmpty ? selectedList.first : null);
              if (selectedBook == null) return null;
              return QuranTafsirFunction.getResolvedTafsirTextForBook(selectedBook, ayahKey);
            }

            String? extractSectionHtml(String? html, String title) {
              if (html == null || html.trim().isEmpty) return null;
              final pattern = RegExp(
                r"<h3>\s*${RegExp.escape(title)}\s*<\/h3>([\s\S]*?)(?=<h3>|$)",
                caseSensitive: false,
              );
              final match = pattern.firstMatch(html);
              final content = match?.group(1);
              return content?.trim();
            }

            Future<List<MapEntry<String, String?>>> loadAllSelectedTafsirs() async {
              final selectedBooks = await selectedBooksFuture;
              final books = (selectedBooks ?? []).toList();
              if (books.isEmpty) return [];
              final List<MapEntry<String, String?>> out = [];
              for (final b in books) {
                final t = await QuranTafsirFunction.getResolvedTafsirTextForBook(b, ayahKey);
                out.add(MapEntry(b.name, t));
              }
              return out;
            }

            Future<void> openShareOptions() async {
              final selectedBooks = await selectedBooksFuture;
              final selected = (selectedBooks ?? []).toList();
              final String tafsirTitle = selected.isNotEmpty ? selected.first.name : "التفسير";

              TafsirBookModel? muyassar = _findTafsirBookByNameContains("الميسر");
              final TafsirBookModel? mukhtasar = _findTafsirBookByNameContains("المختصر");

              // Ensure we treat the offline bundled Muyassar as the authoritative one.
              if (muyassar != null && muyassar.name.contains("الميسر")) {
                muyassar = DefaultOfflineResources.defaultTafsirMuyassar;
              }

              bool muyassarDownloaded =
                  muyassar != null && _isDownloadedByFullPath(muyassar.fullPath, downloadedBooks);
              final bool mukhtasarDownloaded =
                  mukhtasar != null && _isDownloadedByFullPath(mukhtasar.fullPath, downloadedBooks);

              // Extra safety: bundled offline Muyassar might not exist in downloadedBooks list.
              if (muyassar != null &&
                  muyassar.fullPath == DefaultOfflineResources.defaultTafsirMuyassar.fullPath) {
                final boxName = QuranTafsirFunction.getTafsirBoxName(tafsirBook: muyassar);
                final exists = await Hive.boxExists(boxName);
                muyassarDownloaded = muyassarDownloaded || exists;
              }

              final bool showDownloadMuyassar =
                  muyassar != null && !muyassarDownloaded && muyassar.fullPath != DefaultOfflineResources.defaultTafsirMuyassar.fullPath;
              // Intentionally no "download mukhtasar" from share sheet (download happens from Resources only).
              const bool showDownloadMukhtasar = false;

              final bool selectedMuyassar = selected.any((b) => b.name.contains("الميسر"));
              final bool selectedMukhtasar = selected.any((b) => b.name.contains("المختصر"));
              final bool showPickBetweenImageBooks = selectedMuyassar && selectedMukhtasar;

              final bool isAyahDayn = ayahKey == "2:282";
              final bool isVeryLongAyah = isAyahDayn || ayahTextRaw.replaceAll(RegExp(r"\s+"), "").length > 280;
              final bool allowImageShareWithTafsir =
                  !isVeryLongAyah && (selectedMuyassar || selectedMukhtasar) && (muyassarDownloaded || mukhtasarDownloaded);

              await showModalBottomSheet(
                context: sheetContext,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) {
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: Container(
                      decoration: BoxDecoration(
                                 color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.copy_rounded, color: themeState.primary),
                            title: const Text("كنص"),
                            subtitle: const Text("ينسخ الآية + كل التفاسير المختارة بشكل مرتب"),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await _shareLibraryAsText(
                                context: sheetContext,
                                surahNumber: surahNumber,
                                verseNumber: currentVerse,
                                ayahText: ayahTextRaw,
                                loadTafsirs: loadAllSelectedTafsirs,
                              );
                            },
                          ),
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.black.withValues(alpha: 0.06),
                          ),

                          if (showDownloadMuyassar || showDownloadMukhtasar)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                              child: Column(
                                children: [
                                  if (showDownloadMuyassar)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final TafsirBookModel? book = muyassar;
                                          if (book == null) return;
                                          await _downloadAndSelectTafsir(sheetContext, book);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          setSheetState(() {});
                                        },
                                        icon: const Icon(Icons.download_rounded),
                                        label: const Text("تحميل التفسير الميسر"),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          ListTile(
                            leading: Icon(Icons.image_outlined, color: themeState.primary),
                            title: const Text("كصورة (بدون تفسير)"),
                            subtitle: const Text("مشاركة الآية فقط كصورة — مناسب للآيات الطويلة"),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await _shareAsImage(sheetContext, ayahKey, ayahTextRaw);
                            },
                          ),

                          if (allowImageShareWithTafsir && showPickBetweenImageBooks) ...[
                            ListTile(
                              leading: Icon(Icons.image_outlined, color: themeState.primary),
                              title: const Text("كصورة - التفسير الميسر"),
                              subtitle: const Text("مشاركة صورة بالتفسير الميسر"),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final b = selected.firstWhere(
                                  (x) => x.name.contains("الميسر"),
                                  orElse: () => selected.first,
                                );
                                await _shareLibraryAsImage(
                                  context: sheetContext,
                                  surahNumber: surahNumber,
                                  verseNumber: currentVerse,
                                  ayahKey: ayahKey,
                                  tafsirTitle: "التفسير الميسر",
                                  loadTafsir: () => QuranTafsirFunction.getResolvedTafsirTextForBook(
                                    b,
                                    ayahKey,
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.image_outlined, color: themeState.primary),
                              title: const Text("كصورة - التفسير المختصر"),
                              subtitle: const Text("مشاركة صورة بالتفسير المختصر"),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final b = selected.firstWhere(
                                  (x) => x.name.contains("المختصر"),
                                  orElse: () => selected.first,
                                );
                                await _shareLibraryAsImage(
                                  context: sheetContext,
                                  surahNumber: surahNumber,
                                  verseNumber: currentVerse,
                                  ayahKey: ayahKey,
                                  tafsirTitle: "التفسير المختصر",
                                  loadTafsir: () => QuranTafsirFunction.getResolvedTafsirTextForBook(
                                    b,
                                    ayahKey,
                                  ),
                                );
                              },
                            ),
                          ] else if (allowImageShareWithTafsir)
                            ListTile(
                              leading: Icon(Icons.image_outlined, color: themeState.primary),
                              title: const Text("كصورة"),
                              subtitle: Text("يصنع صورة بنفس تنسيق المكتبة ($tafsirTitle)"),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await _shareLibraryAsImage(
                                  context: sheetContext,
                                  surahNumber: surahNumber,
                                  verseNumber: currentVerse,
                                  ayahKey: ayahKey,
                                  tafsirTitle: tafsirTitle,
                                  loadTafsir: loadTafsir,
                                );
                              },
                            ),

                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              height: MediaQuery.of(sheetContext).size.height * 0.92,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () async {
                              await Navigator.of(sheetContext, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => const QuranResourcesView(initTab: 1),
                                ),
                              );
                              setSheetState(() {});
                            },
                            child: Text(
                              "تحرير",
                              style: TextStyle(
                                color: themeState.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "المكتبة",
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B1B1B),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                            color: themeState.primary,
                          ),
                        ],
                      ),
                    ),
                    Container(height: 1, color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(sheetContext).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF1E9DD),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: qcfAyah),
                                        const TextSpan(text: "\u200A"),
                                        TextSpan(
                                          text: getVerseNumberQCF(surahNumber, currentVerse),
                                          style: TextStyle(
                                            fontFamily: ayahPageFont,
                                            package: "qcf_quran",
                                            height: 1,
                                            color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF1B1B1B).withValues(alpha: 0.70),
                                          ),
                                        ),
                                      ],
                                    ),
                                    locale: const Locale("ar"),
                                    textScaler: const TextScaler.linear(1),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    strutStyle: StrutStyle(
                                      fontFamily: ayahPageFont,
                                      package: "qcf_quran",
                                      fontSize: 18,
                                      height: 1.40,
                                      forceStrutHeight: true,
                                    ),
                                    style: TextStyle(
                                      fontFamily: ayahPageFont,
                                      package: "qcf_quran",
                                      fontSize: 18,
                                      height: 1.40,
                                      color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B1B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: openShareOptions,
                                  icon: const Icon(Icons.share_rounded),
                                  color: themeState.primary,
                                ),
                                const Spacer(),
                                FutureBuilder<List<TafsirBookModel>?>(
                                  future: selectedBooksFuture,
                                  builder: (context, snap) {
                                    final books =
                                        snap.connectionState == ConnectionState.done
                                            ? (snap.data ?? const <TafsirBookModel>[])
                                            : (cachedSelectedBooks ?? const <TafsirBookModel>[]);

                                    if (snap.connectionState == ConnectionState.done &&
                                        snap.data != null) {
                                      cachedSelectedBooks = snap.data;
                                    }

                                    final String label;
                                    if (books.isEmpty) {
                                      label = "التفسير";
                                    } else if (books.length == 1) {
                                      label = books.first.name;
                                    } else {
                                      label =
                                          "${_toArabicDigits(books.length.toString())} تفاسير";
                                    }

                                    log(
                                      "[Library] header ayahKey=$ayahKey selectedCount=${books.length}",
                                      name: "LibrarySheet",
                                    );

                                    return Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(sheetContext).brightness == Brightness.dark
                                            ? Colors.white.withValues(alpha: 0.60)
                                            : const Color(0xFF1B1B1B).withValues(alpha: 0.60),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<TafsirBookModel>?>(
                              future: selectedBooksFuture,
                              builder: (context, booksSnap) {
                                final books = booksSnap.connectionState == ConnectionState.done
                                    ? (booksSnap.data ?? const <TafsirBookModel>[])
                                    : (cachedSelectedBooks ?? const <TafsirBookModel>[]);

                                if (booksSnap.connectionState == ConnectionState.done &&
                                    booksSnap.data != null) {
                                  cachedSelectedBooks = booksSnap.data;
                                }

                                log(
                                  "[Library] ayahKey=$ayahKey selectedTafsirs=${books.map((e) => e.fullPath).toList()}",
                                  name: "LibrarySheet",
                                );

                                if (books.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "مفيش تفسير مختار حالياً. اضغط تحرير واختار التفاسير اللي عايزها.",
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B1B1B),
                                      ),
                                    ),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: books.map<Widget>((book) {
                                    final Future<String?> ayahTafsirFuture =
                                        tafsirFutureByPath.putIfAbsent(
                                      "${book.fullPath}|$ayahKey",
                                      () => QuranTafsirFunction.getResolvedTafsirTextForBook(
                                        book,
                                        ayahKey,
                                      ),
                                    );

                                    final bool isMuyassarBook = book.name.contains("الميسر");
                                    final Future<List<String?>> mergedFuture;
                                    if (isMuyassarBook) {
                                      final Future<String?> introFuture =
                                          tafsirFutureByPath.putIfAbsent(
                                        "${book.fullPath}|$surahNumber:1",
                                        () => QuranTafsirFunction.getResolvedTafsirTextForBook(
                                          book,
                                          "$surahNumber:1",
                                        ),
                                      );
                                      mergedFuture = Future.wait([introFuture, ayahTafsirFuture]);
                                    } else {
                                      mergedFuture = Future.wait([
                                        Future<String?>.value(null),
                                        ayahTafsirFuture,
                                      ]);
                                    }

                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: card,
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 14,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "${book.name} (العربية)",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Theme.of(sheetContext).brightness == Brightness.dark
                                                      ? Colors.white.withValues(alpha: 0.70)
                                                      : const Color(0xFF1B1B1B).withValues(alpha: 0.70),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          FutureBuilder<List<String?>>(
                                            future: mergedFuture,
                                            builder: (context, mergedSnap) {
                                              if (mergedSnap.connectionState != ConnectionState.done) {
                                                return const SizedBox.shrink();
                                              }
                                              final introRaw = mergedSnap.data?.first?.trim() ?? "";
                                              final ayahRaw = mergedSnap.data?.last?.trim() ?? "";

                                              final String shown;
                                              if (isMuyassarBook) {
                                                final naming = extractSectionHtml(introRaw, "تسمية السورة") ?? "";
                                                final objectives =
                                                    extractSectionHtml(introRaw, "من مقاصد السورة") ?? "";

                                                final buffer = StringBuffer();
                                                if (naming.trim().isNotEmpty) {
                                                  buffer.writeln(
                                                    "تسمية السورة:\n${_stripHtml(naming)}\n",
                                                  );
                                                }
                                                if (objectives.trim().isNotEmpty) {
                                                  buffer.writeln(
                                                    "من مقاصد السورة:\n${_stripHtml(objectives)}\n",
                                                  );
                                                }
                                                if (ayahRaw.trim().isNotEmpty) {
                                                  buffer.writeln(_stripHtml(ayahRaw));
                                                }
                                                shown = buffer.toString().trim();
                                              } else {
                                                shown = _stripHtml(ayahRaw).trim();
                                              }

                                              if (shown.isEmpty) {
                                                return const Text(
                                                  "لا يوجد تفسير لهذه الآية.",
                                                  textAlign: TextAlign.center,
                                                  textDirection: TextDirection.rtl,
                                                );
                                              }

                                              return Text(
                                                shown,
                                                textDirection: TextDirection.rtl,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  height: 1.7,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B1B1B),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()..add(
                                    FutureBuilder<String?>(
                                      future: QuranIrabFunction.getIrabText(ayahKey),
                                      builder: (context, irabSnap) {
                                        if (irabSnap.connectionState != ConnectionState.done ||
                                            irabSnap.data == null ||
                                            irabSnap.data!.trim().isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: card,
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 14,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    "إعراب القرآن الكريم",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w800,
                                                      color: Theme.of(sheetContext).brightness == Brightness.dark
                                                          ? Colors.white.withValues(alpha: 0.70)
                                                          : const Color(0xFF1B1B1B).withValues(alpha: 0.70),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                _stripHtml(irabSnap.data!),
                                                textDirection: TextDirection.rtl,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  height: 1.7,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(sheetContext).brightness == Brightness.dark ? Colors.white : const Color(0xFF1B1B1B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: currentVerse > 1
                                ? () => setSheetState(() => currentVerse -= 1)
                                : null,
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: themeState.primary,
                          ),
                          Expanded(
                            child: Text(
                              "${getSurahNameArabic(surahNumber)}: ${_toArabicDigits(currentVerse.toString())}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B1B1B),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: currentVerse < total
                                ? () => setSheetState(() => currentVerse += 1)
                                : null,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            color: themeState.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ));
          },
        );
      },
    );
  }

  void _cancelMenuTimer() {
    _menuTimer?.cancel();
    _menuTimer = null;
  }

  void _showOptionsSheetForAyah({
    required BuildContext context,
    required int surah,
    required int verse,
  }) {
    if (_isSheetOpen) return;

    final String ayahKey = "$surah:$verse";

    final String ayahText = _getAyahText(context, surah, verse);

    final overlayContext = navigatorKey.currentState?.overlay?.context;
    final sheetContext = overlayContext ?? context;

    setState(() {
      _isSheetOpen = true;
    });

    AyahOptionsSheet.show(
      context: sheetContext,
      ayahKey: ayahKey,
      ayahText: ayahText,
      onShareAsImage: () async {
        await _openTafsirStyleShareOptions(
          context: context,
          surahNumber: surah,
          verseNumber: verse,
          ayahText: ayahText,
        );
      },
      onWordsPronunciation: () {
        _showWordsPronunciationSheet(
          context: context,
          surah: surah,
          verse: verse,
        );
      },
      onNotes: () async {
        await showAddNotePopup(sheetContext, ayahKey);
      },
      onViewTafsir: () {
        _showLibrarySheet(
          context: context,
          surahNumber: surah,
          verseNumber: verse,
        );
      },
      onBookmark: () {
        _pickBookmarkColorForAyahKey(ayahKey);
      },
      onSetBookmarkColor: (colorId) async {
        await _setBookmarkColorForAyahKey(ayahKey, colorId);
      },
      onRemoveBookmark: () async {
        final box = Hive.box("user");
        final raw = box.get(_kWahyBookmarks, defaultValue: const []) as List?;
        final list = (raw ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        list.removeWhere((e) => (e["ayahKey"] as String?) == ayahKey);
        await box.put(_kWahyBookmarks, list);
      },
      onShareAsText: () {
        _openTafsirStyleShareOptions(
          context: context,
          surahNumber: surah,
          verseNumber: verse,
          ayahText: ayahText,
        );
      },
      onListen: () {
        final reciter = context.read<SegmentedQuranReciterCubit>().state;
        AudioPlayerManager.playSingleAyah(
          ayahKey: ayahKey,
          reciterInfoModel: reciter,
          isInsideQuran: true,
        );
      },
      onListenRange: () async {
        final themeState = context.read<ThemeCubit>().state;
        final int total = getVerseCount(surah);
        int from = verse;
        int to = verse;

        await showModalBottomSheet(
          context: sheetContext,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setState) {
                final isDark = Theme.of(ctx).brightness == Brightness.dark;
                final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F1E6);
                final card = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF9F2);

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
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                              const SizedBox(height: 10),
                              Text(
                                "تشغيل",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                                ),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "من",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<int>(
                                            value: from,
                                            dropdownColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F1E6),
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true,
                                              fillColor: isDark ? const Color(0xFF333333) : const Color(0xFFF7F1E6),
                                              border: const OutlineInputBorder(
                                                borderSide: BorderSide.none,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                            items: List.generate(
                                              total,
                                              (i) => DropdownMenuItem(
                                                value: i + 1,
                                                child: Text(
                                                  "${getSurahNameArabic(surah)}: ${_toArabicDigits((i + 1).toString())}",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              if (v == null) return;
                                              setState(() {
                                                from = v;
                                                if (to < from) to = from;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "إلى",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<int>(
                                            value: to,
                                            dropdownColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F1E6),
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                                              fontSize: 14,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true,
                                              fillColor: isDark ? const Color(0xFF333333) : const Color(0xFFF7F1E6),
                                              border: const OutlineInputBorder(
                                                borderSide: BorderSide.none,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                            items: List.generate(
                                              total,
                                              (i) => DropdownMenuItem(
                                                value: i + 1,
                                                child: Text(
                                                  "${getSurahNameArabic(surah)}: ${_toArabicDigits((i + 1).toString())}",
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            onChanged: (v) {
                                              if (v == null) return;
                                              setState(() {
                                                to = v;
                                                if (to < from) from = to;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeState.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final reciter = sheetContext.read<SegmentedQuranReciterCubit>().state;
                                    await AudioPlayerManager.playMultipleAyahAsPlaylist(
                                      startAyahKey: "$surah:$from",
                                      endAyahKey: "$surah:$to",
                                      isInsideQuran: true,
                                      reciterInfoModel: reciter,
                                      initialIndex: 0,
                                      instantPlay: true,
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text(
                                    "تشغيل",
                                    style: TextStyle(fontWeight: FontWeight.w900),
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
          },
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isSheetOpen = false;
      });
    });
  }

  Future<void> _showWordsPronunciationSheet({
    required BuildContext context,
    required int surah,
    required int verse,
  }) async {
    final themeState = context.read<ThemeCubit>().state;
    final currentScriptType = context.read<QuranViewCubit>().state.quranScriptType;

    String sanitizeToken(String token) {
      return token
          .replaceAll(RegExp(r"<[^>]+>"), "")
          .replaceAll("﴿", "")
          .replaceAll("﴾", "")
          .replaceAll(RegExp(r"[0-9٠-٩]+"), "")
          .trim();
    }

    List<String> words = QuranScriptFunction.getWordListOfAyah(
      QuranScriptType.tajweed,
      surah.toString(),
      verse.toString(),
    )
        .map(sanitizeToken)
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      final userBox = Hive.box("user");
      final bool isProcessed =
          userBox.get("writeQuranScript", defaultValue: false) == true;
      final String? version = userBox.get("writeQuranScriptVersion");
      final bool scriptBoxExists =
          await Hive.boxExists("script_${QuranScriptType.tajweed.name}");

      final bool needsWrite =
          !isProcessed || version != QuranScriptFunction.quranScriptVersion || !scriptBoxExists;

      if (needsWrite) {
        if (!context.mounted) return;
        // Show non-blocking loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: themeState.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "جاري تجهيز سكربت القرآن...",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        try {
          await QuranScriptFunction.writeQuranScript();
          await QuranScriptFunction.initQuranScript(currentScriptType);
        } finally {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        words = QuranScriptFunction.getWordListOfAyah(
          QuranScriptType.tajweed,
          surah.toString(),
          verse.toString(),
        )
            .map(sanitizeToken)
            .where((w) => w.isNotEmpty)
            .toList();
      }
    }

    if (words.isEmpty && currentScriptType != QuranScriptType.tajweed) {
      words = QuranScriptFunction.getWordListOfAyah(
        currentScriptType,
        surah.toString(),
        verse.toString(),
      )
          .map(sanitizeToken)
          .where((w) => w.isNotEmpty)
          .toList();
    }

    final wordKeys = List.generate(words.length, (i) => "$surah:$verse:${i + 1}");

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.38,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              Timer? ayahHighlightTimer;
              int highlightedIndex = -1;
              bool ayahModeActive = false;
              final bool isDark = Theme.of(ctx).brightness == Brightness.dark;

              void stopAyahHighlight() {
                ayahHighlightTimer?.cancel();
                ayahHighlightTimer = null;
              }

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: StatefulBuilder(
                    builder: (ctx, setSheetState) {
                      Future<void> playAyahWordByWord() async {
                        if (!mounted) return;

                        stopAyahHighlight();
                        setSheetState(() {
                          ayahModeActive = true;
                          highlightedIndex = 0;
                        });

                        await AudioPlayerManager.playWordsSequence(
                          wordKeys,
                          onWordStart: (i, _) {
                            if (!mounted) return;
                            setSheetState(() {
                              highlightedIndex = i;
                            });
                          },
                        );

                        if (!mounted) return;
                        setSheetState(() {
                          ayahModeActive = false;
                          highlightedIndex = -1;
                        });
                      }

                      return SingleChildScrollView(
                        controller: scrollController,
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
                            const SizedBox(height: 10),
                            Text(
                              "نطق الكلمات",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 1,
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeState.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: playAyahWordByWord,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text(
                                  "تشغيل الآية كلمة كلمة",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: List.generate(words.length, (i) {
                                final k = i < wordKeys.length ? wordKeys[i] : null;
                                return BlocBuilder<WordPlayingStateCubit, String?>(
                                  builder: (context, playingKey) {
                                    final isPlayingWord =
                                        k != null && playingKey == k;
                                    final isHighlighted =
                                        ayahModeActive && i == highlightedIndex;
                                    final isActive = isPlayingWord || isHighlighted;

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? themeState.primary.withValues(alpha: 0.08)
                                            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF7F1E6)),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isActive
                                              ? themeState.primary.withValues(alpha: 0.38)
                                              : themeState.primary.withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            words[i],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF1B1B1B),
                                              height: 1.25,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: themeState.primary,
                                              backgroundColor: isPlayingWord
                                                  ? themeState.primary
                                                      .withValues(alpha: 0.06)
                                                  : null,
                                              side: BorderSide(
                                                color: themeState.primary
                                                    .withValues(alpha: 0.25),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: k == null
                                                ? null
                                                : () {
                                                    setSheetState(() {
                                                      ayahModeActive = false;
                                                      highlightedIndex = -1;
                                                    });
                                                    stopAyahHighlight();
                                                    AudioPlayerManager.playWord(k);
                                                  },
                                            icon: AnimatedSwitcher(
                                              duration:
                                                  const Duration(milliseconds: 160),
                                              child: Icon(
                                                isPlayingWord
                                                    ? Icons.graphic_eq_rounded
                                                    : Icons.volume_up_rounded,
                                                key: ValueKey(isPlayingWord),
                                                size: 18,
                                              ),
                                            ),
                                            label: Text(
                                              isPlayingWord ? "شغال" : "تشغيل",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cancelMenuTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[Mushaf] build");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ThemeState themeState = context.read<ThemeCubit>().state;

    const starredHiveKey = "wahy_starred";

    final userBox = Hive.box("user");
    final rawBookmarks = userBox.get(_kWahyBookmarks, defaultValue: const []) as List?;
    final bookmarksList = (rawBookmarks ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final bookmarkKeys = bookmarksList
        .map((e) => (e["ayahKey"] as String?) ?? "")
        .where((k) => k.isNotEmpty)
        .toSet();

    final rawNotes = userBox.get(_kWahyNotes, defaultValue: const []) as List?;
    final notesKeys = (rawNotes ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((e) => (e["ayahKey"] as String?) ?? "")
        .where((k) => k.isNotEmpty)
        .toSet();

    final rawStarred = userBox.get(starredHiveKey, defaultValue: const []) as List?;
    final starredKeys = List<String>.from(rawStarred ?? const []).toSet();

    final body = BlocBuilder<AyahToHighlight, String?>(
      buildWhen: (p, c) => p != c,
      builder: (context, highlightedAyahKey) {
        final verseNumberColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1B1B1B);
        final verseNumberHeight = QcfThemeData.sepia().verseNumberHeight;
        final qcfTheme = QcfThemeData.sepia().copyWith(
          pageBackgroundColor: isDark ? Color(0xFF0B0B0F) : _bg(context),
          headerBackgroundColor: const Color(0xFFEFE3D2),
          headerTextColor: const Color(0xFF1B1B1B),
          verseTextColor:
              isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1B1B1B),
          verseNumberColor:
              isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1B1B1B),
          verseNumberBuilder: (surah, verse, verseNumber) {
            final key = "$surah:$verse";
            final hasMarker = _hasAnyWahyMarker(
              ayahKey: key,
              starred: starredKeys,
              notes: notesKeys,
              bookmarks: bookmarkKeys,
            );

            final pageNumber = qcf.getPageNumber(surah, verse);
            final pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";

            final base = TextSpan(
              text: verseNumber,
              style: TextStyle(
                fontFamily: pageFont,
                package: "qcf_quran",
                color: verseNumberColor,
                height: verseNumberHeight / (widget.hOverride ?? 0.86),
              ),
            );

            if (!hasMarker) return base;

            Color dotColor;
            if (starredKeys.contains(key)) {
              dotColor = const Color(0xFFF4B400);
            } else if (bookmarkKeys.contains(key)) {
              dotColor = themeState.primary;
            } else {
              dotColor = const Color(0xFF2962FF);
            }

            return TextSpan(
              children: [
                base,
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1),
          ),
          child: Container(
            color: isDark ? Color(0xFF0B0B0F) : _bg(context),
            child: PageviewQuran(
              controller: widget.controller,
              initialPageNumber: (widget.initialPageNumber ?? 1).clamp(1, 604),
              sp: widget.spOverride ?? 0.86,
              h: widget.hOverride ?? 0.86,
              physics: const ClampingScrollPhysics(),
              theme: qcfTheme.copyWith(
                headerScale: 0.985,
                firstPagesTopSpacerFactor: 0.10,
                pageTopOverlayBuilder: (pageNumber, surahNumber, startVerse) {
                  final juzNumber = getJuzNumber(surahNumber, startVerse);
                  return Transform.translate(
                    offset: const Offset(0, -2),
                    child: IgnorePointer(
                      ignoring: true,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _pageHeaderSidePadding,
                          8, // Significantly reduced from 25 to 8 to raise it to the top
                          _pageHeaderSidePadding,
                          0,
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Inter",
                            color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1B1B1B)
                                .withValues(alpha: 0.6),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      getSurahNameArabic(surahNumber),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      "الجزء ${_arabicOrdinalLocal(context, juzNumber)}",
                                      textDirection: TextDirection.rtl,
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
                pageBottomOverlayBuilder: (pageNumber, surahNumber, startVerse) {
                  final pageLabel = localizedNumber(context, pageNumber);
                  final hizbNumber = _hizbNumberFor(surahNumber, startVerse);
                  final hizbLabel =
                      "الحزب ${localizedNumber(context, hizbNumber)}";
                  final showHizb = _isHizbStart(surahNumber, startVerse);

                  return SafeArea(
                    top: false,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: _pageFooterBottomPadding,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showHizb) ...[
                                  Text(
                                    hizbLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white54 : const Color(0xFF1B1B1B)
                                          .withValues(alpha: 0.54),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  pageLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white70 : const Color(0xFF1B1B1B)
                                        .withValues(alpha: 0.7),
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
              ),
              verseBackgroundColor: (surah, verse) {
                final key = "$surah:$verse";
                if (highlightedAyahKey != key) return null;
                final isDk = Theme.of(context).brightness == Brightness.dark;
                // Warm amber glow in dark mode, beige in light
                return isDk
                    ? const Color(0xFF3A2E1A).withValues(alpha: 0.85)
                    : const Color(0xFFEFE3D2).withValues(alpha: 0.78);
              },
              onTapDown: (surah, verse, details) {
                final key = "$surah:$verse";
                context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
                context.read<AyahToHighlight>().changeAyah(key);
              },
              onTap: (surah, verse) {
                context.read<AyahToHighlight>().changeAyah(null);
                widget.onToggleHeader?.call();
              },
              onLongPressDown: (surah, verse, details) {
                _cancelMenuTimer();
                final ayahKey = "$surah:$verse";
                context.read<AyahKeyCubit>().changeCurrentAyahKey(ayahKey);
                context.read<AyahToHighlight>().changeAyah(ayahKey);
              },
              onLongPress: (surah, verse) {
                _cancelMenuTimer();
                HapticFeedback.selectionClick();
                _showOptionsSheetForAyah(
                  context: context,
                  surah: surah,
                  verse: verse,
                );
              },
              onLongPressUp: (surah, verse) {
                _cancelMenuTimer();
                context.read<AyahToHighlight>().changeAyah(null);
              },
              onLongPressCancel: (surah, verse) {
                _cancelMenuTimer();
                context.read<AyahToHighlight>().changeAyah(null);
              },
              onDoubleTap: (surah, verse) async {
                final ayahKey = "$surah:$verse";
                context.read<AyahKeyCubit>().changeCurrentAyahKey(ayahKey);

                final wordsKey = List.generate(
                  QuranScriptFunction.getWordListOfAyah(
                    context.read<QuranViewCubit>().state.quranScriptType,
                    surah.toString(),
                    verse.toString(),
                  ).length,
                  (i) => "$surah:$verse:${i + 1}",
                );

                if (wordsKey.isEmpty) return;

                showPopupWordFunction(
                  context: context,
                  wordKeys: wordsKey,
                  initWordIndex: 0,
                  wordByWordList:
                      await WordByWordFunction.getAyahWordByWordData(ayahKey) ??
                      [],
                );
              },
              onPageChanged: (page) {
                _cancelMenuTimer();
                context.read<AyahKeyCubit>().changeLastScrolledPage(page);

                final info = quranPagesInfo[
                    (page - 1).clamp(0, quranPagesInfo.length - 1)];
                final ayahId = info["s"] ?? 1;
                final key = convertAyahNumberToKey(ayahId);
                if (key != null) {
                  context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
                }
              },
            ),
          ),
        );
      },
    );

    if (!widget.useDefaultAppBar) return body;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B0F) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0B0F) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeState.primary),
        title: Text(
          "المصحف",
          style: TextStyle(
            color: themeState.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: body,
    );
  }

}
