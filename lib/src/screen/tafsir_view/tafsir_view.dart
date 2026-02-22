import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "package:al_quran_v3/src/screen/quran_resources/quran_resources_view.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_cubit.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_state.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "dart:ui" as ui;
import "package:flutter_html/flutter_html.dart";
import "package:gap/gap.dart";
import "package:share_plus/share_plus.dart";
import "package:al_quran_v3/src/resources/quran_resources/quran_ayah_count.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_irab_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_sarf_function.dart";

class TafsirView extends StatefulWidget {
  final String ayahKey;
  const TafsirView({super.key, required this.ayahKey});

  @override
  State<TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends State<TafsirView> {
  late SurahInfoModel surahInfoModel;
  late AppLocalizations appLocalizations;

  late List<TafsirBookModel> tafsirBookList;

  Future<_TafsirSectionsData>? _sectionsFuture;
  _TafsirSectionsData? _cachedSectionsData;
  int _selectedTab = 0;

  @override
  void initState() {
    surahInfoModel = SurahInfoModel.fromMap(
      metaDataSurah[widget.ayahKey.split(":").first]!,
    );
    tafsirBookList = [];
    super.initState();

    _initBooks();
  }

  bool _isLoadingBooks = true;

  Future<void> _initBooks() async {
    List<TafsirBookModel>? selected;
    if (_selectedTab == 0) {
      selected = await QuranTafsirFunction.getTafsirSelections();
    } else if (_selectedTab == 1) {
      selected = await QuranIrabFunction.getIrabSelections();
    } else if (_selectedTab == 2) {
      selected = await QuranSarfFunction.getSarfSelections();
    }
    
    final books = selected ?? [];

    if (!mounted) return;
    setState(() {
      tafsirBookList = books;
      _isLoadingBooks = false;
      _sectionsFuture = _loadSections(
        surahIntroAyahKey: "${widget.ayahKey.split(":").first}:1",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    appLocalizations = AppLocalizations.of(context);

    if (_isLoadingBooks) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(
            appLocalizations.tafsirAppBarTitle(
              getSurahName(context, surahInfoModel.id),
              getSurahNameArabic(surahInfoModel.id),
              widget.ayahKey,
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            backgroundColor: context.read<ThemeCubit>().state.primaryShade100,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF6F0E7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _modalHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: context.read<ThemeCubit>().state.primary,
                  ),
                  segments: const [
                    ButtonSegment(value: 0, label: Text("التفسير", style: TextStyle(fontWeight: FontWeight.bold))),
                    ButtonSegment(value: 1, label: Text("الإعراب", style: TextStyle(fontWeight: FontWeight.bold))),
                    ButtonSegment(value: 2, label: Text("الصرف", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (set) {
                    final v = set.first;
                    if (v != _selectedTab) {
                       setState(() {
                          _selectedTab = v;
                          _isLoadingBooks = true;
                       });
                       _initBooks();
                    }
                  },
                ),
              ),
            ),
            Expanded(child: _sectionsBody()),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: (isDark ? cs.surface : const Color(0xFFF6F0E7)).withValues(alpha: 0.85),
            child: SafeArea(
              top: false,
              child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _getPreviousAyahKey(widget.ayahKey) == null
                      ? null
                      : () {
                          final prev = _getPreviousAyahKey(widget.ayahKey);
                          if (prev == null) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TafsirView(ayahKey: prev),
                            ),
                          );
                        },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text("السابق"),
                ),
              ),
              const Gap(10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.read<ThemeCubit>().state.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _getNextAyahKey(widget.ayahKey) == null
                      ? null
                      : () {
                          final next = _getNextAyahKey(widget.ayahKey);
                          if (next == null) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TafsirView(ayahKey: next),
                            ),
                          );
                        },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text("التالي"),
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

  Widget _modalHeader() {
    final themeState = context.read<ThemeCubit>().state;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 8),
      child: Row(
        children: [
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuranResourcesView(initTab: 1),
                ),
              );
              if (!mounted) return;
              setState(() {
                _isLoadingBooks = true;
              });
              await _initBooks();
            },
            child: Text(
              "تحرير",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: themeState.primary,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            "المكتبة",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _sectionsBody() {
    return FutureBuilder<_TafsirSectionsData>(
      future: _sectionsFuture,
      builder: (context, snapshot) {
        if (_sectionsFuture == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : _cachedSectionsData;

        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          _cachedSectionsData = snapshot.data;
        }

        if (data == null) {
          return Center(child: Text(appLocalizations.tafsirNotAvailable(widget.ayahKey)));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          children: [
            if (data.surahNamingHtml != null && data.surahNamingHtml!.trim().isNotEmpty)
              _sectionCard(
                title: "التفسير الميسر (العربية)",
                html: data.surahNamingHtml!,
                shareTitle: "تسمية السورة",
              ),

            if (data.surahObjectivesHtml != null &&
                data.surahObjectivesHtml!.trim().isNotEmpty) ...[
              const Gap(12),
              _sectionCard(
                title: "التفسير الميسر (العربية)",
                html: data.surahObjectivesHtml!,
                shareTitle: "مقاصد السورة",
              ),
            ],

            const Gap(12),
            _sectionCard(
              title: _selectedTab == 1
                  ? "إعراب القرآن (الدعاس)"
                  : _selectedTab == 2
                      ? "الميزان الصرفي"
                      : "التفسير الميسر (العربية)",
              html: _selectedTab == 0 ? _removeBasmala(data.ayahTafsirHtml ?? "") : (data.ayahTafsirHtml ?? ""),
              shareTitle: _selectedTab == 1
                  ? "الإعراب"
                  : _selectedTab == 2
                      ? "الصرف"
                      : "التفسير",
            ),

            const Gap(12),
          ],
        );
      },
    );
  }

  Future<_TafsirSectionsData> _loadSections({required String surahIntroAyahKey}) async {
    final TafsirBookModel? tafsirBook = tafsirBookList.isEmpty ? null : tafsirBookList.first;

    final String? surahIntroTafsirHtml = tafsirBook == null || _selectedTab != 0
        ? null
        : await QuranTafsirFunction.getResolvedTafsirTextForBook(
            tafsirBook,
            surahIntroAyahKey,
          );

    String? ayahTafsirHtml;
    if (_selectedTab == 0) {
      if (tafsirBook != null) {
        ayahTafsirHtml = await QuranTafsirFunction.getResolvedTafsirTextForBook(
          tafsirBook,
          widget.ayahKey,
        );
      }
    } else if (_selectedTab == 1) {
      ayahTafsirHtml = await QuranIrabFunction.getIrabText(widget.ayahKey);
    } else if (_selectedTab == 2) {
      ayahTafsirHtml = "<h3>الصرف</h3><p>بيانات الصرف قيد التطوير ولم يتم إدراجها بعد داخل التطبيق.</p>";
    }

    return _TafsirSectionsData(
      surahNamingHtml: _extractSectionHtml(surahIntroTafsirHtml, "تسمية السورة"),
      surahObjectivesHtml: _extractSectionHtml(surahIntroTafsirHtml, "من مقاصد السورة"),
      ayahTafsirHtml: ayahTafsirHtml,
    );
  }

  String? _extractSectionHtml(String? html, String title) {
    if (html == null || html.trim().isEmpty) return null;

    // Prefer QUL-style <h3>Title</h3> sections.
    final pattern = RegExp(
      r"<h3>\s*${RegExp.escape(title)}\s*<\/h3>([\s\S]*?)(?=<h3>|$)",
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match == null) return null;

    final content = match.group(1);
    if (content == null) return null;
    return content.trim();
  }

  Widget _sectionCard({
    required String title,
    required String html,
    required String shareTitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeState = context.read<ThemeCubit>().state;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: themeState.primaryShade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    final buffer = StringBuffer()
                      ..writeln(shareTitle)
                      ..writeln()
                      ..writeln(_stripHtml(html));
                    await SharePlus.instance.share(
                      ShareParams(text: buffer.toString(), subject: shareTitle),
                    );
                  },
                  icon: Icon(Icons.share_rounded, color: themeState.primary),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: themeState.primary.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 16),
            child: BlocBuilder<QuranViewCubit, QuranViewState>(
              builder: (context, state) {
                return Html(
                  data: html.isEmpty
                      ? "<div class=ar lang=ar><p>${appLocalizations.tafsirNotAvailable(widget.ayahKey)}</p></div>"
                      : html,
                  style: {
                    "*": Style(
                      padding: HtmlPaddings.zero,
                      margin: Margins.zero,
                      fontSize: FontSize(state.translationFontSize),
                      lineHeight: const LineHeight(1.6),
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _removeBasmala(String input) {
    return input
        .replaceAll("بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ", "")
        .replaceAll("بسم الله الرحمن الرحيم", "")
        .trim();
  }

  String? _getPreviousAyahKey(String ayahKey) {
    final parts = ayahKey.split(":");
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts.first);
    final ayah = int.tryParse(parts.last);
    if (surah == null || ayah == null) return null;

    if (ayah > 1) return "$surah:${ayah - 1}";
    if (surah <= 1) return null;
    final prevSurah = surah - 1;
    final lastAyah = quranAyahCount[prevSurah - 1];
    return "$prevSurah:$lastAyah";
  }

  String? _getNextAyahKey(String ayahKey) {
    final parts = ayahKey.split(":");
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts.first);
    final ayah = int.tryParse(parts.last);
    if (surah == null || ayah == null) return null;

    final maxAyah = quranAyahCount[surah - 1];
    if (ayah < maxAyah) return "$surah:${ayah + 1}";
    if (surah >= 114) return null;
    return "${surah + 1}:1";
  }

  String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r"<[^>]*>"), "")
        .replaceAll("&nbsp;", " ")
        .replaceAll("&amp;", "&")
        .replaceAll("&quot;", "\"")
        .replaceAll("&#39;", "'")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
  }
}

class _TafsirSectionsData {
  final String? surahNamingHtml;
  final String? surahObjectivesHtml;
  final String? ayahTafsirHtml;

  const _TafsirSectionsData({
    required this.surahNamingHtml,
    required this.surahObjectivesHtml,
    required this.ayahTafsirHtml,
  });
}
