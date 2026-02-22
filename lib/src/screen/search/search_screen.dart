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
import 'package:qcf_quran/qcf_quran.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran/src/data/quran_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;
  bool _isSearching = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Normalize Arabic text for comparison: strip tashkeel & unify letters
  String _normalizeForSearch(String input) {
    var s = input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('\u0640', '')
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '')
        .replaceAll('\u0670', '')
        .trim();
    return s;
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final normalizedQuery = _normalizeForSearch(query).toLowerCase();

    List<Map<String, dynamic>> results = [];

    for (var ayah in quranText) {
      final String rawNormal =
          (ayah['text_normal'] ?? ayah['content'] ?? '').toString();
      final String strippedContent =
          _normalizeForSearch(rawNormal).toLowerCase();

      if (strippedContent.contains(normalizedQuery)) {
        results.add({
          'surah_number': ayah['surah_number'],
          'verse_number': ayah['verse_number'],
          'content': (ayah['content'] ?? rawNormal).toString(),
        });
      }
    }

    setState(() {
      _searchResults = results;
      _hasSearched = true;
      _isSearching = false;
    });
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
          if (_hasSearched && _searchResults.isNotEmpty)
            ListView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 90 + 48,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                final surahName =
                    qcf.getSurahNameArabic(result['surah_number']);
                final ayahNumber = result['verse_number'];
                final content = result['content'] as String;

                return InkWell(
                  onTap: () => _navigateToAyah(
                      context, result['surah_number'], result['verse_number']),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: themeState.primary
                                    .withValues(alpha: 0.1),
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
                                  horizontal: 8, vertical: 4),
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
                        delay: (50 * (index).clamp(0, 8)).ms)
                    .slideY(begin: 0.05, end: 0);
              },
            ),

          // ── Empty results ──
          if (_hasSearched && _searchResults.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeState.primary.withValues(alpha: 0.06),
                    ),
                    child: Icon(
                      FluentIcons.search_24_regular,
                      size: 56,
                      color: themeState.primary.withValues(alpha: 0.3),
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
                    style: TextStyle(fontSize: 14, color: _textMuted),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                    begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

          // ── Result count badge ──
          if (_hasSearched && _searchResults.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 82,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: themeState.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeState.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    "ذُكرت ${_searchResults.length} مرة في القرآن",
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
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.85),
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
                            autofocus: true,
                            textDirection: TextDirection.rtl,
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
                                  horizontal: 16, vertical: 14),
                              suffixIcon: _isSearching
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: themeState.primary,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        _searchController.text.isNotEmpty
                                            ? FluentIcons.dismiss_24_filled
                                            : FluentIcons.search_24_filled,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        if (_searchController
                                            .text.isNotEmpty) {
                                          _searchController.clear();
                                          _performSearch('');
                                        } else {
                                          _performSearch(
                                              _searchController.text);
                                        }
                                      },
                                      color: themeState.primary,
                                    ),
                            ),
                            onSubmitted: _performSearch,
                            onChanged: _performSearch,
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
          if (!_hasSearched)
            Center(
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
                  // Quick search suggestions
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
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.1, end: 0),
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
