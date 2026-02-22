import "dart:ui";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// Surah Index Sheet with tabs: Surahs, Juz, Hizb
class SurahIndexSheet extends StatefulWidget {
  final Function(int surahNumber) onSurahSelected;
  final Function(int juzNumber)? onJuzSelected;
  final int? currentSurahNumber;

  const SurahIndexSheet({
    super.key,
    required this.onSurahSelected,
    this.onJuzSelected,
    this.currentSurahNumber,
  });

  /// Show the Surah Index sheet
  static Future<void> show({
    required BuildContext context,
    required Function(int surahNumber) onSurahSelected,
    Function(int juzNumber)? onJuzSelected,
    int? currentSurahNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SurahIndexSheet(
          onSurahSelected: onSurahSelected,
          onJuzSelected: onJuzSelected,
          currentSurahNumber: currentSurahNumber,
        ),
      ),
    );
  }

  @override
  State<SurahIndexSheet> createState() => _SurahIndexSheetState();
}

class _SurahIndexSheetState extends State<SurahIndexSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.98)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: l10n.searchForASurah,
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: Icon(
                      FluentIcons.search_24_regular,
                      color: themeState.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey.shade800.withValues(alpha: 0.5)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800.withValues(alpha: 0.3)
                      : Colors.grey.shade200.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: themeState.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: l10n.surah),
                    Tab(text: l10n.juz),
                    Tab(text: l10n.hizb),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSurahList(themeState, isDark),
                    _buildJuzList(themeState, isDark),
                    _buildHizbList(themeState, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList(ThemeState themeState, bool isDark) {
    List<SurahInfoModel> surahs = List.generate(114, (index) {
      return SurahInfoModel.fromMap(metaDataSurah["${index + 1}"]!);
    });

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      surahs = surahs.where((surah) {
        final name = getSurahName(context, surah.id).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            surah.id.toString().contains(query);
      }).toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        final isCurrent = widget.currentSurahNumber == surah.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isCurrent
                ? themeState.primaryShade100
                : isDark
                    ? Colors.grey.shade800.withValues(alpha: 0.3)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: isCurrent
                ? Border.all(color: themeState.primary, width: 2)
                : null,
          ),
          child: ListTile(
            onTap: () {
              Navigator.pop(context);
              widget.onSurahSelected(surah.id);
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: themeState.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  localizedNumber(context, surah.id),
                  style: TextStyle(
                    color: themeState.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              getSurahName(context, surah.id),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              "${surah.revelationPlace == "makkah" ? "مكية" : "مدنية"} • ${localizedNumber(context, surah.versesCount)} آية",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            trailing: isCurrent
                ? Icon(
                    Icons.check_circle_rounded,
                    color: themeState.primary,
                  )
                : Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildJuzList(ThemeState themeState, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.3)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () {
              Navigator.pop(context);
              widget.onJuzSelected?.call(juzNumber);
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: themeState.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  localizedNumber(context, juzNumber),
                  style: TextStyle(
                    color: themeState.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              "الجزء ${localizedNumber(context, juzNumber)}",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHizbList(ThemeState themeState, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 60,
      itemBuilder: (context, index) {
        final hizbNumber = index + 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.3)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () {
              Navigator.pop(context);
              // Navigate to Hizb (Future Implementation)
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: themeState.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  localizedNumber(context, hizbNumber),
                  style: TextStyle(
                    color: themeState.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              "الحزب ${localizedNumber(context, hizbNumber)}",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        );
      },
    );
  }
}
