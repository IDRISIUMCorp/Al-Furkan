import 'dart:async';
import 'dart:ui';

import 'package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart';
import 'package:al_quran_v3/src/theme/controller/theme_cubit.dart';
import 'package:al_quran_v3/src/theme/controller/theme_state.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_to_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:qcf_quran/qcf_quran.dart' as qcf;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  final ValueNotifier<List<Map<String, dynamic>>> _resultsVN =
      ValueNotifier<List<Map<String, dynamic>>>(const []);
  final ValueNotifier<bool> _hasSearchedVN = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isSearchingVN = ValueNotifier<bool>(false);
  List<String> _searchHistory = [];

  static const String _kHistoryKey = 'search_history';
  static const int _maxHistory = 8;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocus.requestFocus();
    });
  }

  Color get _cardBg => _isDark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.025);
  Color get _cardBorder => _isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.black.withValues(alpha: 0.06);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _textMuted => _isDark
      ? Colors.white.withValues(alpha: 0.5)
      : Colors.black.withValues(alpha: 0.45);

  @override
  void dispose() {
    _debounce?.cancel();
    _debounce = null;

    _resultsVN.dispose();
    _hasSearchedVN.dispose();
    _isSearchingVN.dispose();

    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return int.tryParse(v.toString());
  }

  Future<void> _performSearch(String query) async {
    final rawQuery = query.trim();
    final normalizedQuery = qcf.normalise(rawQuery);
    if (rawQuery.isEmpty || normalizedQuery.isEmpty) {
      if (mounted) {
        _resultsVN.value = const [];
        _hasSearchedVN.value = false;
        _isSearchingVN.value = false;
      }
      return;
    }

    _isSearchingVN.value = true;

    dynamic raw = await qcf.searchWordsAsync(normalizedQuery);

    List rawList;
    if (raw is List) {
      rawList = raw;
    } else if (raw is Map) {
      rawList =
          (raw['result'] as List?) ??
          (raw['results'] as List?) ??
          (raw['data'] as List?) ??
          const [];
    } else {
      rawList = const [];
    }

    if (rawList.isEmpty && rawQuery != normalizedQuery) {
      raw = await qcf.searchWordsAsync(rawQuery);
    }

    if (raw is List) {
      rawList = raw;
    } else if (raw is Map) {
      rawList =
          (raw['result'] as List?) ??
          (raw['results'] as List?) ??
          (raw['data'] as List?) ??
          const [];
    } else {
      rawList = const [];
    }

    int? pickSurah(dynamic ayah) {
      if (ayah is! Map) return null;
      return _asInt(
        ayah['suraNumber'] ??
            ayah['surah'] ??
            ayah['sura'] ??
            ayah['surah_number'] ??
            ayah['surah_number'] ??
            ayah['s'],
      );
    }

    int? pickVerse(dynamic ayah) {
      if (ayah is! Map) return null;
      return _asInt(
        ayah['verseNumber'] ??
            ayah['verse'] ??
            ayah['ayah'] ??
            ayah['verse_number'] ??
            ayah['a'],
      );
    }

    String pickText(dynamic ayah) {
      if (ayah is! Map) return '';
      final direct = (ayah['verse_text'] ??
              ayah['content'] ??
              ayah['text'] ??
              '')
          .toString();
      if (direct.trim().isNotEmpty) return direct;

      final surah = pickSurah(ayah);
      final verse = pickVerse(ayah);
      if (surah == null || verse == null) return '';
      try {
        return qcf.getVerse(surah, verse, verseEndSymbol: false);
      } catch (_) {
        return '';
      }
    }

    final results = rawList
        .map((ayah) {
          final surah = pickSurah(ayah);
          final verse = pickVerse(ayah);
          if (surah == null || verse == null) return null;
          return {
            'surah_number': surah,
            'verse_number': verse,
            'content': pickText(ayah),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (!mounted) return;

    _resultsVN.value = results;
    _hasSearchedVN.value = true;
    _isSearchingVN.value = false;

    // Save to history if results found
    if (results.isNotEmpty) {
      _saveToHistory(query.trim());
    }
  }

  void _loadHistory() {
    final box = Hive.box('user');
    final raw = box.get(_kHistoryKey);
    if (raw is List) {
      _searchHistory = raw.cast<String>().toList();
    }
  }

  void _saveToHistory(String query) {
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > _maxHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxHistory);
    }
    Hive.box('user').put(_kHistoryKey, _searchHistory);
    if (mounted) setState(() {});
  }

  void _clearHistory() {
    _searchHistory.clear();
    Hive.box('user').delete(_kHistoryKey);
    if (mounted) setState(() {});
  }

  void _navigateToAyah(BuildContext context, int surah, int ayah) {
    HapticFeedback.lightImpact();
    final key = "$surah:$ayah";
    final page = qcf.getPageNumber(surah, ayah);
    context.read<AyahKeyCubit>().changeLastScrolledPage(page);
    context.read<AyahKeyCubit>().changeCurrentAyahKey(key);
    context.read<AyahToHighlight>().changeAyah(key);

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        final currentKey = context.read<AyahToHighlight>().state;
        if (currentKey == key) {
          context.read<AyahToHighlight>().changeAyah(null);
        }
      }
    });

    Navigator.of(context).pop({"page": page, "key": key});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeState themeState = context.read<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Results list ──
          ValueListenableBuilder<bool>(
            valueListenable: _hasSearchedVN,
            builder: (context, hasSearched, _) {
              return ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _resultsVN,
                builder: (context, results, __) {
                  if (!hasSearched || results.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 90 + 48,
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final int? surahNumber =
                          (result['surah_number'] as num?)?.toInt();
                      final int? ayahNumber =
                          (result['verse_number'] as num?)?.toInt();
                      if (surahNumber == null || ayahNumber == null) {
                        return const SizedBox.shrink();
                      }

                      final surahName = qcf.getSurahNameArabic(surahNumber);
                      final content = (result['content'] as String?) ?? '';

                      return InkWell(
                            onTap: () => _navigateToAyah(
                              context,
                              surahNumber,
                              ayahNumber,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeState.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    surahName,
                                    style: TextStyle(
                                      color: themeState.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "آية $ayahNumber",
                                    style: TextStyle(
                                      color: _textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  FluentIcons.arrow_right_24_regular,
                                  size: 16,
                                  color: _textMuted,
                                ),
                              ],
                            ),
                            const Gap(14),
                            Text(
                              content,
                              style: TextStyle(
                                fontFamily: "QPC_Hafs",
                                fontSize: 22,
                                color: _textPrimary,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: (50 * (index).clamp(0, 8)).ms,
                          )
                          .slideY(begin: 0.05, end: 0);
                    },
                  );
                },
              );
            },
          ),

          // ── Empty results ──
          ValueListenableBuilder<bool>(
            valueListenable: _hasSearchedVN,
            builder: (context, hasSearched, _) {
              return ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _resultsVN,
                builder: (context, results, __) {
                  if (!hasSearched || results.isNotEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeState.primary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                              child: Icon(
                                FluentIcons.search_24_regular,
                                size: 56,
                                color: themeState.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            const Gap(20),
                            Text(
                              "لا توجد نتائج مطابقة",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _textPrimary,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              "جرّب كلمات مختلفة أو بدون تشكيل",
                              style: TextStyle(
                                fontSize: 14,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        curve: Curves.easeOutBack,
                      );
                },
              );
            },
          ),

          // ── Result count badge ──
          ValueListenableBuilder<bool>(
            valueListenable: _hasSearchedVN,
            builder: (context, hasSearched, _) {
              return ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _resultsVN,
                builder: (context, results, __) {
                  if (!hasSearched || results.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    top: MediaQuery.of(context).padding.top + 82,
                    left: 0,
                    right: 0,
                    child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: themeState.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: themeState.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Text(
                              "ذُكرت ${results.length} مرة في القرآن",
                              style: TextStyle(
                                color: themeState.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms)
                        .slideY(begin: -0.3, end: 0),
                  );
                },
              );
            },
          ),

          // ── Search App Bar (Glassmorphism) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.85),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: themeState.primary,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            autofocus: false,
                            autofillHints: const [],
                            enableSuggestions: false,
                            autocorrect: false,
                            textDirection: TextDirection.rtl,
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "بحث في المصحف (مثال: الله، الصبر...)",
                              hintStyle: TextStyle(color: _textMuted),
                              hintTextDirection: TextDirection.rtl,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              suffixIcon: SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 160),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeOutCubic,
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _isSearchingVN,
                                      builder: (context, isSearching, _) {
                                        if (isSearching) {
                                          return SizedBox(
                                            key: const ValueKey('loading'),
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: themeState.primary,
                                            ),
                                          );
                                        }

                                        return ValueListenableBuilder<TextEditingValue>(
                                          key: const ValueKey('action'),
                                          valueListenable: _searchController,
                                          builder: (context, value, _) {
                                            final hasText =
                                                value.text.trim().isNotEmpty;
                                            return IconButton(
                                              icon: Icon(
                                                hasText
                                                    ? FluentIcons
                                                        .dismiss_24_filled
                                                    : FluentIcons
                                                        .search_24_filled,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                if (hasText) {
                                                  _searchController.clear();
                                                  _performSearch('');
                                                  return;
                                                }
                                                _performSearch(
                                                  _searchController.text,
                                                );
                                              },
                                              color: themeState.primary,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            onSubmitted: _performSearch,
                            onChanged: (value) {
                              _debounce?.cancel();
                              _debounce = Timer(
                                const Duration(milliseconds: 220),
                                () => _performSearch(value),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Initial state (no search yet) ──
          ValueListenableBuilder<bool>(
            valueListenable: _hasSearchedVN,
            builder: (context, hasSearched, _) {
              if (hasSearched) return const SizedBox.shrink();

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            themeState.primary.withValues(alpha: 0.1),
                            themeState.primary.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      child: Icon(
                        FluentIcons.search_24_regular,
                        size: 64,
                        color: themeState.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  const Gap(20),
                  Text(
                    "البحث في القرآن الكريم",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _textPrimary,
                    ),
                  ),
                  const Gap(10),
                  Text(
                    "يمكنك البحث في آيات القرآن الكريم\nبدون تشكيل لتجربة أسرع",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textMuted,
                      height: 1.5,
                    ),
                  ),
                  const Gap(24),
                  // Search History or Quick search suggestions
                  if (_searchHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "آخر عمليات البحث",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _textMuted,
                          ),
                        ),
                        const Gap(8),
                        InkWell(
                          onTap: _clearHistory,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              "مسح",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: themeState.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _searchHistory
                          .map((q) => _buildSuggestionChip(q, themeState))
                          .toList(),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildSuggestionChip("الرحمن", themeState),
                        _buildSuggestionChip("الصبر", themeState),
                        _buildSuggestionChip("التوبة", themeState),
                        _buildSuggestionChip("الجنة", themeState),
                      ],
                    ),
                  ],
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ThemeState themeState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _searchController.text = text;
          _performSearch(text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: themeState.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeState.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: themeState.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
