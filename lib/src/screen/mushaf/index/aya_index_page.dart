import "package:al_quran_v3/src/screen/collections/collection_page.dart";
import "dart:ui" as ui;
import "package:flutter/material.dart";
import "package:al_quran_v3/src/screen/smart_khatma/smart_khatma_page.dart";
import "package:al_quran_v3/src/screen/surah_list_view/surah_list_view.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/get_page_number.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:qcf_quran/qcf_quran.dart" hide getPageNumber;

class AyaIndexPage extends StatefulWidget {
  final int initialTabIndex;
  final bool isEmbedded;
  final void Function(int page, String ayahKey)? onOpenLocation;

  const AyaIndexPage({
    super.key, 
    this.initialTabIndex = 4,
    this.isEmbedded = false,
    this.onOpenLocation,
  });

  @override
  State<AyaIndexPage> createState() => _AyaIndexPageState();
}

class _AyaIndexPageState extends State<AyaIndexPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: widget.isEmbedded ? null : AppBar(
        title: Text(
          "الفهرس",
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: widget.isEmbedded,
        child: Column(
          children: [
          // Body content will dynamically load based on selected tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildStarredTab(),
                _buildSeparatorsTab(cs, isDark),
                _buildKhatmaTab(),
                _buildSurahsTab(),
              ],
            ),
          ),
        ],
      )),
      extendBody: true,
      bottomNavigationBar: _buildBottomTabBar(cs, isDark),
    );
  }

  Widget _buildBottomTabBar(ColorScheme cs, bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
      child: TabBar(
        controller: _tabController,
        labelColor: cs.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: cs.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        tabs: const [
          Tab(text: "ملاحظات", icon: Icon(Icons.sticky_note_2_rounded)),
          Tab(text: "مميزة", icon: Icon(Icons.star_rounded)),
          Tab(text: "الفواصل", icon: Icon(Icons.bookmark_rounded)),
          Tab(text: "الختمة", icon: Icon(Icons.check_circle_rounded)),
          Tab(text: "السور", icon: Icon(Icons.format_list_bulleted_rounded)),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    return CollectionPage(
      collectionType: CollectionType.notes,
      isEmbedded: true,
      onOpenLocation: widget.onOpenLocation,
    );
  }

  Widget _buildStarredTab() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box("user").listenable(keys: ["wahy_bookmarks"]),
      builder: (context, box, _) {
        final rawBookmarks = box.get("wahy_bookmarks", defaultValue: const []) as List?;
        final starred = (rawBookmarks ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((e) {
              // Only show star-bookmarked (any color) items
              final color = (e["color"] as String?)?.trim();
              return color != null && color.isNotEmpty;
            })
            .toList()
            .reversed
            .toList();

        if (starred.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_outline_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Text(
                  "لا توجد آيات مميزة بنجمة",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "اضغط مطولاً على آية واختر ★ لتمييزها",
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: starred.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            indent: 20,
            endIndent: 20,
          ),
          itemBuilder: (context, index) {
            final bm = starred[index];
            final ayahKey = bm["ayahKey"] as String? ?? "";
            final parts = ayahKey.split(":");
            if (parts.length != 2) return const SizedBox.shrink();

            final surahNum = int.tryParse(parts[0]) ?? 1;
            final verseNum = int.tryParse(parts[1]) ?? 1;
            final surahName = getSurahNameArabic(surahNum);
            final verseText = localizedNumber(context, verseNum);
            final page = getPageNumber(ayahKey) ?? 1;

            final ayahPreview = _getAyahPreview(ayahKey);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 28),
              title: Text(
                "$surahName: الآية $verseText",
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: ayahPreview.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        ayahPreview,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Uthmanic",
                          fontSize: 14,
                          height: 1.6,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                if (widget.onOpenLocation != null) {
                  widget.onOpenLocation!(page, ayahKey);
                } else {
                  Navigator.pop(context);
                }
              },
            );
          },
        );
      },
    );
  }

  /// Get a clean ayah text preview from ayahKey (surah:verse)
  String _getAyahPreview(String ayahKey) {
    final parts = ayahKey.split(":");
    if (parts.length != 2) return "";
    try {
      final words = QuranScriptFunction.getWordListOfAyah(
        QuranScriptType.tajweed,
        parts[0],
        parts[1],
      );
      final clean = words
          .map((w) => w
              .replaceAll(RegExp(r"<[^>]+>"), "")
              .replaceAll("\uFD3E", "")
              .replaceAll("\uFD3F", "")
              .replaceAll(RegExp(r"[0-9\u0660-\u0669]+"), "")
              .trim())
          .where((w) => w.isNotEmpty)
          .toList();
      if (clean.isEmpty) return "";
      final joined = clean.join(" ");
      return joined;
    } catch (_) {
      return "";
    }
  }

  Widget _buildSeparatorsTab(ColorScheme cs, bool isDark) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box("user").listenable(keys: ["wahy_bookmarks"]),
      builder: (context, box, _) {
        final rawBookmarks = box.get("wahy_bookmarks", defaultValue: const []) as List?;
        final bookmarks = (rawBookmarks ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
            .reversed
            .toList();

        if (bookmarks.isEmpty) {
          return Center(
            child: Text(
              "لا توجد فواصل محفظة",
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: bookmarks.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            indent: 20,
            endIndent: 20,
          ),
          itemBuilder: (context, index) {
            final bm = bookmarks[index];
            final ayahKey = bm["ayahKey"] as String? ?? "";
            final colorName = bm["color"] as String? ?? "green";
            
            final parts = ayahKey.split(":");
            if (parts.length != 2) return const SizedBox.shrink();
            
            final surahNum = int.tryParse(parts[0]) ?? 1;
            final surahName = getSurahNameArabic(surahNum);
            final verseNumber = localizedNumber(context, int.tryParse(parts[1]) ?? 1);
            final ayahPreview = _getAyahPreview(ayahKey);

            Color iconColor = cs.primary;
            if (colorName == "red") iconColor = Colors.red;
            if (colorName == "yellow") iconColor = Colors.amber;
            if (colorName == "blue") iconColor = Colors.blue;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Icon(Icons.bookmark_rounded, color: iconColor, size: 28),
              title: Text(
                "$surahName: الآية $verseNumber",
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: ayahPreview.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        ayahPreview,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Uthmanic",
                          fontSize: 14,
                          height: 1.6,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () {
                   final newBookmarks = List<Map<String, dynamic>>.from(bookmarks.reversed);
                   newBookmarks.removeWhere((element) => element["ayahKey"] == ayahKey);
                   box.put("wahy_bookmarks", newBookmarks);
                },
              ),
              onTap: () {
                 if (widget.onOpenLocation != null) {
                   final p = getPageNumber(ayahKey) ?? 1;
                   widget.onOpenLocation!(p, ayahKey);
                 } else {
                   Navigator.pop(context, {"page": 1, "ayahKey": ayahKey});
                 }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKhatmaTab() {
    return const SmartKhatmaPage();
  }

  Widget _buildSurahsTab() {
    return SurahListView(
      onOpenLocation: widget.onOpenLocation,
      surahInfoList: metaDataSurah.values
          .map((v) => SurahInfoModel.fromMap(v))
          .toList(),
    );
  }
}
