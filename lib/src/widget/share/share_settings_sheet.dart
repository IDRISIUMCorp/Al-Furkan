import "dart:io";
import "dart:ui";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/model/ayah_image_settings.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "package:al_quran_v3/src/resources/quran_resources/tafsir_info_with_score.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_translation_function.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/widget/share/ayah_image_preview.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:html/parser.dart" as html_parser;
import "package:path_provider/path_provider.dart";
import "package:screenshot/screenshot.dart";
import "package:share_plus/share_plus.dart";

/// Bottom Sheet متقدم لتخصيص ومشاركة صورة الآية
class ShareSettingsSheet extends StatefulWidget {
  final String ayahKey;
  final String ayahText;
  final String? translationText;
  final String? tafsirText;

  const ShareSettingsSheet({
    super.key,
    required this.ayahKey,
    required this.ayahText,
    this.translationText,
    this.tafsirText,
  });

  /// Show the share settings sheet
  static Future<void> show({
    required BuildContext context,
    required String ayahKey,
    required String ayahText,
    String? translationText,
    String? tafsirText,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ShareSettingsSheet(
          ayahKey: ayahKey,
          ayahText: ayahText,
          translationText: translationText,
          tafsirText: tafsirText,
        ),
      ),
    );
  }

  @override
  State<ShareSettingsSheet> createState() => _ShareSettingsSheetState();
}

class _ShareSettingsSheetState extends State<ShareSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AyahImageSettings _settings;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;
  bool _filtersExpanded = false;
  double _filtersPanelHeight = 72;

  final TransformationController _previewTransformController =
      TransformationController();

  String? _resolvedTranslation;
  String? _resolvedTafsir;
  String? _resolvedFootnotes;
  bool _isLoadingContent = false;

  late Set<String> _selectedAllowedTafsirNames;
  final Set<String> _downloadingAllowedTafsirNames = {};

  static const String _arabicLanguageKey = "arabic";

  List<TafsirBookModel> _getAllArabicTafsirBooksSorted() {
    final arabic = tafsirInformationWithScore[_arabicLanguageKey] ?? [];
    final out = <TafsirBookModel>[];
    for (final raw in arabic) {
      try {
        out.add(TafsirBookModel.fromMap(Map<String, dynamic>.from(raw)));
      } catch (_) {}
    }
    out.sort((a, b) => (b.score).compareTo(a.score));
    return out;
  }

  Set<String> _getAllArabicTafsirNames() {
    return _getAllArabicTafsirBooksSorted().map((e) => e.name).toSet();
  }

  void _applyTemplate(AyahImageSettings template) {
    _updateSettings(template);
  }

  void _toggleFilters() {
    setState(() {
      _filtersExpanded = !_filtersExpanded;
      if (_filtersExpanded) {
        _filtersPanelHeight = _filtersPanelHeight < 220 ? 340 : _filtersPanelHeight;
      } else {
        _filtersPanelHeight = 72;
      }
    });
  }

  void _setFiltersPanelHeight(double newHeight) {
    final minH = 72.0;
    final maxH = 520.0;
    final clamped = newHeight.clamp(minH, maxH);

    if (clamped <= 90) {
      if (_filtersExpanded) {
        setState(() {
          _filtersExpanded = false;
          _filtersPanelHeight = 72;
        });
      } else if (_filtersPanelHeight != 72) {
        setState(() {
          _filtersPanelHeight = 72;
        });
      }
      return;
    }

    if (!_filtersExpanded) {
      setState(() {
        _filtersExpanded = true;
        _filtersPanelHeight = clamped;
      });
      return;
    }

    if (_filtersPanelHeight != clamped) {
      setState(() {
        _filtersPanelHeight = clamped;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _settings = const AyahImageSettings();

    _selectedAllowedTafsirNames = <String>{};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _previewTransformController.dispose();
    super.dispose();
  }

  void _updateSettings(AyahImageSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });

    _refreshContentIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshContentIfNeeded();
  }

  Future<void> _refreshContentIfNeeded() async {
    if (!mounted) return;
    if (_isLoadingContent) return;

    final bool shouldHaveTranslation =
        _settings.showTranslation && (widget.translationText?.isNotEmpty != true);
    final bool shouldHaveTafsir =
        _settings.showTafsir && (widget.tafsirText?.isNotEmpty != true);
    final bool shouldHaveFootnotes = _settings.showFootnotes;

    if (!shouldHaveTranslation && !shouldHaveTafsir && !shouldHaveFootnotes) {
      setState(() {
        _resolvedTranslation = null;
        _resolvedTafsir = null;
        _resolvedFootnotes = null;
      });
      return;
    }

    setState(() {
      _isLoadingContent = true;
    });

    try {
      if (shouldHaveTranslation) {
        final translations = await QuranTranslationFunction.getTranslation(
          widget.ayahKey,
        );
        final String merged = translations
            .map((t) => (t.translation?["t"] as String?)?.trim() ?? "")
            .where((t) => t.isNotEmpty)
            .join("\n\n");
        _resolvedTranslation = merged.isEmpty ? null : merged;

        if (shouldHaveFootnotes) {
          final footnotes = _formatFootnotesFromTranslations(translations);
          _resolvedFootnotes = footnotes.isEmpty ? null : footnotes;
        } else {
          _resolvedFootnotes = null;
        }
      } else {
        _resolvedTranslation = null;
        _resolvedFootnotes = null;
      }

      // Footnotes rendering is not supported in this sheet yet.

      if (shouldHaveTafsir) {
        _resolvedTafsir = await _loadAllowedTafsirOrNull(
          context,
          selectedNames: _selectedAllowedTafsirNames,
        );
      } else {
        _resolvedTafsir = null;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  String _formatFootnotesFromTranslations(List<dynamic> translations) {
    final List<String> blocks = [];

    for (final t in translations) {
      final Map? map = (t.translation as Map?);
      final Map? footnotes = map?["f"] as Map?;
      if (footnotes == null || footnotes.isEmpty) continue;

      final List<String> lines = [];
      for (final entry in footnotes.entries) {
        final key = entry.key;
        final value = entry.value;
        final valueText = value?.toString().trim() ?? "";
        if (valueText.isEmpty) continue;
        lines.add("$key. $valueText");
      }

      if (lines.isEmpty) continue;
      blocks.add(lines.join("\n"));
    }

    return blocks.join("\n\n");
  }

  Widget _buildAdditionalArabicTafsirSection(dynamic themeState, bool isDark) {
    final books = _getAllArabicTafsirBooksSorted();
    if (books.isEmpty) return const SizedBox.shrink();

    final downloaded = QuranTafsirFunction.getDownloadedTafsirBooks();
    final downloadedPaths = downloaded.map((e) => e.fullPath).toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedIconColor: themeState.primary,
        iconColor: themeState.primary,
        title: Text(
          "تفاسير عربية إضافية (اختياري)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          "ممكن تكبّر حجم الصورة",
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: books.map((book) {
                final name = book.name;
                final isDownloaded = downloadedPaths.contains(book.fullPath);
                final selected = _selectedAllowedTafsirNames.contains(name);
                final isDownloading =
                    _downloadingAllowedTafsirNames.contains(name);

                return FilterChip(
                  selected: selected,
                  onSelected: (v) {
                    if (isDownloading) return;
                    if (!isDownloaded) {
                      _downloadAllowedTafsirIfNeeded(name);
                      return;
                    }
                    setState(() {
                      if (v) {
                        _selectedAllowedTafsirNames.add(name);
                      } else {
                        _selectedAllowedTafsirNames.remove(name);
                      }
                    });
                    _refreshContentIfNeeded();
                  },
                  label: Text(name),
                  selectedColor: themeState.primary.withValues(alpha: 0.14),
                  checkmarkColor: themeState.primary,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _loadAllowedTafsirOrNull(
    BuildContext context, {
    required Set<String> selectedNames,
  }) async {
    final allArabic = _getAllArabicTafsirNames();
    final selectedAllowed = selectedNames.where(allArabic.contains).toList();
    if (selectedAllowed.isEmpty) return null;

    final downloaded = QuranTafsirFunction.getDownloadedTafsirBooks();
    final allowedDownloaded = downloaded
        .where((b) => allArabic.contains(b.name))
        .toList();

    // Map by name for fast lookup.
    final Map<String, TafsirBookModel> byName = {
      for (final b in allowedDownloaded) b.name: b,
    };

    final List<String> parts = [];
    for (final name in selectedAllowed) {
      final book = byName[name];
      if (book == null) continue;

      final raw = await QuranTafsirFunction.getResolvedTafsirTextForBook(
        book,
        widget.ayahKey,
      );
      if (raw == null || raw.trim().isEmpty) continue;

      // Strip HTML tags if present.
      final fragment = html_parser.parseFragment(raw);
      final plain = (fragment.text ?? "").trim();
      if (plain.isEmpty) continue;

      // Simple heading so the user understands which tafsir is shown.
      parts.add("$name\n$plain");
    }

    if (parts.isEmpty) return null;
    return parts.join("\n\n────────────────\n\n");
  }

  TafsirBookModel? _getAllowedArabicTafsirBookByName(String name) {
    final arabic = tafsirInformationWithScore[_arabicLanguageKey] ?? [];
    try {
      final map = arabic.firstWhere(
        (e) => (e["name"] as String?) == name,
      );
      return TafsirBookModel.fromMap(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadAllowedTafsirIfNeeded(String name) async {
    if (_downloadingAllowedTafsirNames.contains(name)) return;
    final book = _getAllowedArabicTafsirBookByName(name);
    if (book == null) return;

    setState(() {
      _downloadingAllowedTafsirNames.add(name);
    });

    try {
      final ok = await QuranTafsirFunction.downloadResources(
        context: context,
        tafsirBook: book,
        isSetupProcess: false,
      );
      if (!mounted) return;

      if (ok) {
        setState(() {
          _selectedAllowedTafsirNames.add(name);
        });
        await _refreshContentIfNeeded();
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAllowedTafsirNames.remove(name);
        });
      }
    }
  }

  Widget _buildTafsirSelectionRow(dynamic themeState, bool isDark) {
    final downloaded = QuranTafsirFunction.getDownloadedTafsirBooks();
    final allArabic = _getAllArabicTafsirNames();
    final allowedDownloaded = downloaded
        .where((b) => allArabic.contains(b.name))
        .map((b) => b.name)
        .toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeState.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "اختار التفسير اللي يظهر في الصورة (2 فقط)",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getAllArabicTafsirBooksSorted().map((b) {
                final name = b.name;
                final bool isDownloaded = allowedDownloaded.contains(name);
                final bool selected = _selectedAllowedTafsirNames.contains(name);
                final bool isDownloading =
                    _downloadingAllowedTafsirNames.contains(name);

                return FilterChip(
                  selected: selected,
                  onSelected: (v) {
                    if (isDownloading) return;
                    if (!isDownloaded) {
                      _downloadAllowedTafsirIfNeeded(name);
                      return;
                    }
                    setState(() {
                      if (v) {
                        _selectedAllowedTafsirNames.add(name);
                      } else {
                        _selectedAllowedTafsirNames.remove(name);
                      }
                    });
                    _refreshContentIfNeeded();
                  },
                  label: Text(name),
                  avatar: Icon(
                    isDownloading
                        ? FluentIcons.arrow_clockwise_24_regular
                        : (isDownloaded
                            ? FluentIcons.book_open_24_regular
                            : FluentIcons.arrow_download_24_regular),
                    size: 16,
                    color: isDownloaded || isDownloading
                        ? themeState.primary
                        : Colors.grey,
                  ),
                  selectedColor: themeState.primary.withValues(alpha: 0.14),
                  checkmarkColor: themeState.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isDownloaded || isDownloading
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surahInfo = SurahInfoModel.fromMap(
      metaDataSurah[widget.ayahKey.split(":").first]!,
    );

    Widget toolButton({
      required IconData icon,
      required VoidCallback onTap,
      bool isActive = false,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? themeState.primary.withValues(alpha: isDark ? 0.22 : 0.14)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? themeState.primary.withValues(alpha: 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.10)),
            ),
          ),
          child: Icon(
            icon,
            color: isActive
                ? themeState.primary
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0B0C) : colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Top toolbar (Wahy-like)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  toolButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final i = _tabController.index;
                      return Row(
                        children: [
                          toolButton(
                            icon: Icons.music_note_rounded,
                            isActive: _settings.watermark.enabled,
                            onTap: () {
                              _updateSettings(
                                _settings.copyWith(
                                  watermark: _settings.watermark.copyWith(
                                    enabled: !_settings.watermark.enabled,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          toolButton(
                            icon: FluentIcons.crop_24_regular,
                            isActive: _settings.aspectRatio !=
                                AyahImageAspectRatio.auto,
                            onTap: () {
                              _tabController.animateTo(0);
                              if (!_filtersExpanded) _toggleFilters();
                            },
                          ),
                          const SizedBox(width: 10),
                          toolButton(
                            icon: FluentIcons.color_24_regular,
                            isActive: i == 0,
                            onTap: () {
                              _tabController.animateTo(0);
                              if (!_filtersExpanded) _toggleFilters();
                            },
                          ),
                          const SizedBox(width: 10),
                          toolButton(
                            icon: FluentIcons.text_font_24_regular,
                            isActive: i == 1,
                            onTap: () {
                              _tabController.animateTo(1);
                              if (!_filtersExpanded) _toggleFilters();
                            },
                          ),
                          const SizedBox(width: 10),
                          toolButton(
                            icon: FluentIcons.draw_shape_24_regular,
                            isActive: i == 2,
                            onTap: () {
                              _tabController.animateTo(2);
                              if (!_filtersExpanded) _toggleFilters();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Preview (center)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Builder(
                      builder: (context) {
                        final cardRadius = BorderRadius.circular(22);

                        return ClipRRect(
                          borderRadius: cardRadius,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 18,
                              sigmaY: 18,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: cardRadius,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.surface.withValues(
                                      alpha: isDark ? 0.40 : 0.80,
                                    ),
                                    themeState.primary.withValues(
                                      alpha: isDark ? 0.18 : 0.10,
                                    ),
                                  ],
                                ),
                                border: Border.all(
                                  color: themeState.primary.withValues(
                                    alpha: isDark ? 0.28 : 0.18,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.45 : 0.10,
                                    ),
                                    blurRadius: 30,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: InteractiveViewer(
                                    transformationController:
                                        _previewTransformController,
                                    minScale: 1,
                                    maxScale: 3.5,
                                    panEnabled: true,
                                    scaleEnabled: true,
                                    boundaryMargin: const EdgeInsets.all(80),
                                    child: AyahImagePreview(
                                      ayahKey: widget.ayahKey,
                                      ayahText: _getCleanAyahText(),
                                      surahInfo: surahInfo,
                                      settings: _settings,
                                      themeState: themeState,
                                      translationText: widget.translationText ??
                                          _resolvedTranslation,
                                      tafsirText:
                                          widget.tafsirText ?? _resolvedTafsir,
                                      footnotesText: _resolvedFootnotes,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Options panel (keeps existing advanced options)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0B0B0C)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: SizedBox(
                height: _filtersPanelHeight,
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleFilters,
                      onVerticalDragUpdate: (details) {
                        _setFiltersPanelHeight(
                          _filtersPanelHeight - details.delta.dy,
                        );
                      },
                      onVerticalDragEnd: (_) {
                        if (!_filtersExpanded) return;
                        if (_filtersPanelHeight < 180) {
                          _toggleFilters();
                          return;
                        }
                        if (_filtersPanelHeight > 520) {
                          _setFiltersPanelHeight(520);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _filtersExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Filters",
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_filtersExpanded)
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBackgroundTab(themeState, true),
                            _buildFontTab(themeState, true),
                            _buildContentTab(themeState, true, l10n),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Share button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeState.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(FluentIcons.share_24_regular),
                  label: Text(
                    _isSharing ? "جاري التحضير..." : l10n.shareButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundTab(dynamic themeState, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "المقاس",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AyahImageAspectRatio.values.map((r) {
            final isSelected = _settings.aspectRatio == r;
            return ChoiceChip(
              label: Text(r.getDisplayName()),
              selected: isSelected,
              onSelected: (_) =>
                  _updateSettings(_settings.copyWith(aspectRatio: r)),
              selectedColor: themeState.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),

        if (_settings.headerStyle == AyahImageHeaderStyle.banner) ...[
          const SizedBox(height: 16),
          Text(
            "Banner خيارات متقدمة",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          Text(
            "الارتفاع: ${_settings.headerBannerHeight.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.headerBannerHeight.clamp(44, 90),
            min: 44,
            max: 90,
            divisions: 23,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(headerBannerHeight: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "الشفافية: ${_settings.headerBannerOpacity.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.headerBannerOpacity.clamp(0.04, 0.35),
            min: 0.04,
            max: 0.35,
            divisions: 31,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(headerBannerOpacity: v),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "محاذاة العنوان",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AyahImageHeaderAlign.values.map((a) {
              final selected = _settings.headerBannerAlign == a;
              return ChoiceChip(
                selected: selected,
                label: Text(a.getDisplayName()),
                onSelected: (_) => _updateSettings(
                  _settings.copyWith(headerBannerAlign: a),
                ),
                selectedColor: themeState.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: "إظهار معنى السورة",
            value: _settings.showSurahMeaning,
            onChanged: (v) =>
                _updateSettings(_settings.copyWith(showSurahMeaning: v)),
            themeState: themeState,
            isDark: isDark,
          ),
        ],

        const SizedBox(height: 24),

        Text(
          "جودة التصدير",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AyahImageExportQuality.values.map((q) {
            final isSelected = _settings.exportQuality == q;
            return ChoiceChip(
              label: Text(q.getDisplayName()),
              selected: isSelected,
              onSelected: (_) =>
                  _updateSettings(_settings.copyWith(exportQuality: q)),
              selectedColor: themeState.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text(
          "قوالب جاهزة",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "كلاسيك",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.auto,
                    background: AyahImageBackground.light,
                    frameStyle: AyahImageFrameStyle.simple,
                    showSurahName: true,
                    showAyahNumber: false,
                    showTranslation: true,
                    showTafsir: false,
                    showFootnotes: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "Minimal",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.square,
                    background: AyahImageBackground.transparent,
                    frameStyle: AyahImageFrameStyle.none,
                    showSurahName: false,
                    showAyahNumber: false,
                    showTranslation: false,
                    showTafsir: false,
                    showFootnotes: false,
                    watermark: _settings.watermark.copyWith(enabled: false),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "تفسير",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.post,
                    background: AyahImageBackground.light,
                    frameStyle: AyahImageFrameStyle.simple,
                    showSurahName: true,
                    showAyahNumber: true,
                    showTranslation: false,
                    showTafsir: true,
                    showFootnotes: false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "ستوري",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.story,
                    background: AyahImageBackground.dark,
                    frameStyle: AyahImageFrameStyle.islamic,
                    showSurahName: true,
                    showAyahNumber: true,
                    showTranslation: true,
                    showTafsir: false,
                    showFootnotes: false,
                    watermark: _settings.watermark.copyWith(enabled: true),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "Gold",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.post,
                    background: AyahImageBackground.gradientGold,
                    frameStyle: AyahImageFrameStyle.decorated,
                    headerStyle: AyahImageHeaderStyle.banner,
                    ayahTextAlign: AyahImageTextAlign.center,
                    ayahLineHeight: 2.2,
                    ayahLetterSpacing: 0,
                    showAyahNumber: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "Emerald",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.auto,
                    background: AyahImageBackground.gradientGreen,
                    frameStyle: AyahImageFrameStyle.simple,
                    headerStyle: AyahImageHeaderStyle.banner,
                    showAyahNumber: true,
                    showSurahName: true,
                    ayahTextAlign: AyahImageTextAlign.center,
                    ayahLineHeight: 2.15,
                    ayahLetterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "Night",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.square,
                    background: AyahImageBackground.dark,
                    frameStyle: AyahImageFrameStyle.none,
                    headerStyle: AyahImageHeaderStyle.simple,
                    showAyahNumber: false,
                    ayahTextAlign: AyahImageTextAlign.center,
                    ayahLineHeight: 2.0,
                    ayahLetterSpacing: 0,
                    watermark: _settings.watermark.copyWith(
                      enabled: true,
                      opacity: 0.14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _templateChip(
                themeState: themeState,
                isDark: isDark,
                title: "Glass",
                onTap: () => _applyTemplate(
                  _settings.copyWith(
                    aspectRatio: AyahImageAspectRatio.post,
                    background: AyahImageBackground.transparent,
                    frameStyle: AyahImageFrameStyle.decorated,
                    headerStyle: AyahImageHeaderStyle.banner,
                    contentPadding: 10,
                    ayahTextAlign: AyahImageTextAlign.center,
                    ayahLineHeight: 2.1,
                    ayahLetterSpacing: 0,
                    showAyahNumber: true,
                    watermark: _settings.watermark.copyWith(
                      enabled: true,
                      opacity: 0.10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          "عنوان السورة",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AyahImageHeaderStyle.values.map((h) {
            final isSelected = _settings.headerStyle == h;
            return ChoiceChip(
              label: Text(h.getDisplayName()),
              selected: isSelected,
              onSelected: (_) =>
                  _updateSettings(_settings.copyWith(headerStyle: h)),
              selectedColor: themeState.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text(
          "المسافات",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeState.primary.withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Padding: ${_settings.contentPadding.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Slider(
                value: _settings.contentPadding.clamp(0, 32),
                min: 0,
                max: 32,
                divisions: 32,
                activeColor: themeState.primary,
                onChanged: (v) =>
                    _updateSettings(_settings.copyWith(contentPadding: v)),
              ),
            ],
          ),
        ),

        Text(
          "نوع الخلفية",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AyahImageBackground.values.map((bg) {
            final isSelected = _settings.background == bg;
            return GestureDetector(
              onTap: () => _updateSettings(_settings.copyWith(background: bg)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: bg.getGradient() == null ? bg.getBackgroundColor() : null,
                  gradient: bg.getGradient(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? themeState.primary : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded, color: bg.getTextColor())
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text(
          "نمط الإطار",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: AyahImageFrameStyle.values.map((style) {
            final isSelected = _settings.frameStyle == style;
            return ChoiceChip(
              label: Text(_getFrameStyleName(style)),
              selected: isSelected,
              onSelected: (_) => _updateSettings(
                _settings.copyWith(frameStyle: style),
              ),
              selectedColor: themeState.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _templateChip({
    required dynamic themeState,
    required bool isDark,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: themeState.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildFontTab(dynamic themeState, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "نوع الخط",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: AyahImageFontType.values.map((fontType) {
            final isSelected = _settings.fontType == fontType;
            return ChoiceChip(
              label: Text(fontType.getDisplayName()),
              selected: isSelected,
              onSelected: (_) => _updateSettings(
                _settings.copyWith(fontType: fontType),
              ),
              selectedColor: themeState.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontFamily: fontType.getFontFamily(),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text(
          "حجم الخط",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: AyahImageFontSize.values.map((size) {
            final isSelected = _settings.fontSize == size;
            return ChoiceChip(
              label: Text(_getFontSizeName(size)),
              selected: isSelected,
              onSelected: (_) => _updateSettings(
                _settings.copyWith(fontSize: size),
              ),
              selectedColor: themeState.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContentTab(dynamic themeState, bool isDark, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isLoadingContent)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(themeState.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "جاري تجهيز المحتوى...",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        _buildSwitchTile(
          title: "إظهار اسم السورة",
          value: _settings.showSurahName,
          onChanged: (v) => _updateSettings(_settings.copyWith(showSurahName: v)),
          themeState: themeState,
          isDark: isDark,
        ),
        _buildSwitchTile(
          title: "إظهار رقم الآية",
          value: _settings.showAyahNumber,
          onChanged: (v) => _updateSettings(_settings.copyWith(showAyahNumber: v)),
          themeState: themeState,
          isDark: isDark,
        ),
        _buildSwitchTile(
          title: "إظهار الترجمة",
          value: _settings.showTranslation,
          onChanged: (v) => _updateSettings(_settings.copyWith(showTranslation: v)),
          themeState: themeState,
          isDark: isDark,
        ),
        if (_settings.showTranslation) ...[
          const SizedBox(height: 10),
          Text(
            "إعدادات الترجمة",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            "حجم الخط: ${_settings.translationFontSize.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.translationFontSize.clamp(10, 24),
            min: 10,
            max: 24,
            divisions: 14,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(translationFontSize: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Line Height: ${_settings.translationLineHeight.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.translationLineHeight.clamp(1.2, 2.4),
            min: 1.2,
            max: 2.4,
            divisions: 12,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(translationLineHeight: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Max Lines: ${_settings.translationMaxLines}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.translationMaxLines.toDouble().clamp(1, 12),
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: themeState.primary,
            label: _settings.translationMaxLines.toString(),
            onChanged: (v) => _updateSettings(
              _settings.copyWith(translationMaxLines: v.round()),
            ),
          ),
          const Divider(height: 24),
        ],
        _buildSwitchTile(
          title: "إظهار التفسير",
          value: _settings.showTafsir,
          onChanged: (v) => _updateSettings(_settings.copyWith(showTafsir: v)),
          themeState: themeState,
          isDark: isDark,
        ),
        if (_settings.showTafsir) ...[
          const SizedBox(height: 10),
          Text(
            "إعدادات التفسير",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            "حجم الخط: ${_settings.tafsirFontSize.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.tafsirFontSize.clamp(10, 22),
            min: 10,
            max: 22,
            divisions: 12,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(tafsirFontSize: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Line Height: ${_settings.tafsirLineHeight.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.tafsirLineHeight.clamp(1.2, 2.6),
            min: 1.2,
            max: 2.6,
            divisions: 14,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(tafsirLineHeight: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Max Lines: ${_settings.tafsirMaxLines}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.tafsirMaxLines.toDouble().clamp(1, 10),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: themeState.primary,
            label: _settings.tafsirMaxLines.toString(),
            onChanged: (v) => _updateSettings(
              _settings.copyWith(tafsirMaxLines: v.round()),
            ),
          ),
        ],
        if (_settings.showTafsir) ...[
          _buildTafsirSelectionRow(themeState, isDark),
          _buildAdditionalArabicTafsirSection(themeState, isDark),
          _buildTafsirAvailabilityHint(themeState, isDark, l10n),
        ],
        _buildSwitchTile(
          title: "إظهار الحواشي",
          value: _settings.showFootnotes,
          onChanged: (v) => _updateSettings(_settings.copyWith(showFootnotes: v)),
          themeState: themeState,
          isDark: isDark,
        ),
        if (_settings.showFootnotes) ...[
          const SizedBox(height: 10),
          Text(
            "إعدادات الحواشي",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: "عرض داخل Box",
            value: _settings.footnotesBoxed,
            onChanged: (v) =>
                _updateSettings(_settings.copyWith(footnotesBoxed: v)),
            themeState: themeState,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          Text(
            "حجم الخط: ${_settings.footnotesFontSize.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.footnotesFontSize.clamp(10, 20),
            min: 10,
            max: 20,
            divisions: 10,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(footnotesFontSize: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Line Height: ${_settings.footnotesLineHeight.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.footnotesLineHeight.clamp(1.2, 2.4),
            min: 1.2,
            max: 2.4,
            divisions: 12,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(footnotesLineHeight: v),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Max Lines: ${_settings.footnotesMaxLines}",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.footnotesMaxLines.toDouble().clamp(1, 8),
            min: 1,
            max: 8,
            divisions: 7,
            activeColor: themeState.primary,
            label: _settings.footnotesMaxLines.toString(),
            onChanged: (v) => _updateSettings(
              _settings.copyWith(footnotesMaxLines: v.round()),
            ),
          ),
        ],

        const Divider(height: 32),

        _buildSwitchTile(
          title: "العلامة المائية",
          value: _settings.watermark.enabled,
          onChanged: (v) => _updateSettings(
            _settings.copyWith(
              watermark: _settings.watermark.copyWith(enabled: v),
            ),
          ),
          themeState: themeState,
          isDark: isDark,
        ),

        if (_settings.watermark.enabled) ...[
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: "نص العلامة المائية",
              hintText: "القرآن الكريم",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _updateSettings(
              _settings.copyWith(
                watermark: _settings.watermark.copyWith(
                  customText: value.isEmpty ? null : value,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            "شفافية العلامة المائية",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          Slider(
            value: _settings.watermark.opacity.clamp(0.05, 1),
            min: 0.05,
            max: 1,
            divisions: 19,
            activeColor: themeState.primary,
            onChanged: (v) => _updateSettings(
              _settings.copyWith(
                watermark: _settings.watermark.copyWith(opacity: v),
              ),
            ),
          ),

          const SizedBox(height: 4),
          Text(
            "المكان",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WatermarkPosition.values.map((p) {
              final selected = _settings.watermark.position == p;
              final label = switch (p) {
                WatermarkPosition.topLeft => "أعلى يسار",
                WatermarkPosition.topRight => "أعلى يمين",
                WatermarkPosition.bottomLeft => "أسفل يسار",
                WatermarkPosition.bottomRight => "أسفل يمين",
                WatermarkPosition.center => "الوسط",
              };
              return ChoiceChip(
                selected: selected,
                label: Text(label),
                onSelected: (_) => _updateSettings(
                  _settings.copyWith(
                    watermark: _settings.watermark.copyWith(position: p),
                  ),
                ),
                selectedColor: themeState.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required dynamic themeState,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.3)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: themeState.primary,
      ),
    );
  }

  String _getFrameStyleName(AyahImageFrameStyle style) {
    switch (style) {
      case AyahImageFrameStyle.none:
        return "بدون";
      case AyahImageFrameStyle.simple:
        return "بسيط";
      case AyahImageFrameStyle.decorated:
        return "مزخرف";
      case AyahImageFrameStyle.islamic:
        return "إسلامي";
    }
  }

  String _getFontSizeName(AyahImageFontSize size) {
    switch (size) {
      case AyahImageFontSize.small:
        return "صغير";
      case AyahImageFontSize.medium:
        return "متوسط";
      case AyahImageFontSize.large:
        return "كبير";
      case AyahImageFontSize.xlarge:
        return "كبير جداً";
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);

    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: _settings.exportQuality.getPixelRatio(),
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes != null) {
        final surahName = getSurahName(context, 
          int.parse(widget.ayahKey.split(":").first));

        final dir = await getTemporaryDirectory();
        final safeKey = widget.ayahKey.replaceAll(":", "_");
        final fileName = "$surahName - ${widget.ayahKey}.png";
        final file = File("${dir.path}/share_$safeKey.png");
        await file.writeAsBytes(imageBytes, flush: true);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            fileNameOverrides: [fileName],
            downloadFallbackEnabled: false,
            mailToFallbackEnabled: false,
          ),
        );

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("Error sharing image: $e");
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  String _getCleanAyahText() {
    // Always fetch clean Uthmani for sharing image to avoid tajweed markup.
    final split = widget.ayahKey.split(":");
    final surah = split.first;
    final ayah = split.last;
    final words = QuranScriptFunction.getWordListOfAyah(
      QuranScriptType.uthmani,
      surah,
      ayah,
    );
    String text = words.join(" ").trim();
    final parts = text.split(RegExp(r"\s+"));
    if (parts.isNotEmpty && RegExp(r"^[0-9٠-٩]+$").hasMatch(parts.last)) {
      text = parts.sublist(0, parts.length - 1).join(" ").trim();
    }
    return text.isEmpty ? widget.ayahText : text;
  }

  Widget _buildTafsirAvailabilityHint(
    dynamic themeState,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final downloaded = QuranTafsirFunction.getDownloadedTafsirBooks();
    final allArabic = _getAllArabicTafsirNames();
    final allowedDownloaded = downloaded.where((b) => allArabic.contains(b.name)).toList();

    if (allowedDownloaded.isNotEmpty) {
      final selectedAvailable = allowedDownloaded
          .where((b) => _selectedAllowedTafsirNames.contains(b.name))
          .map((e) => e.name)
          .toList();

      return Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 6),
        child: Text(
          selectedAvailable.isEmpty
              ? "التفاسير المحملة: ${allowedDownloaded.map((e) => e.name).join(" / ")} (اختار واحد منهم فوق)"
              : "هيظهر في الصورة: ${selectedAvailable.join(" / ")}",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    // Not downloaded: show CTA to open resources view (tafsir tab)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeState.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              FluentIcons.book_open_24_regular,
              size: 18,
              color: themeState.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "مفيش تفسير محمّل حالياً. حمّل تفسير من (موارد القرآن) عشان يظهر في الصورة.",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
