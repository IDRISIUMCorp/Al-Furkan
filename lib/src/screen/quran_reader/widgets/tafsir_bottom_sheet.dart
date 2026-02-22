import "dart:ui";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// Draggable Bottom Sheet for displaying Tafsir (interpretation)
/// Can be expanded by dragging up, dismissed by dragging down
class TafsirBottomSheet extends StatelessWidget {
  final String ayahKey;
  final String tafsirTitle;
  final String tafsirContent;
  final String? tafsirSource;
  final ScrollController? scrollController;

  const TafsirBottomSheet({
    super.key,
    required this.ayahKey,
    required this.tafsirTitle,
    required this.tafsirContent,
    this.tafsirSource,
    this.scrollController,
  });

  /// Show the Tafsir bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String ayahKey,
    required String tafsirTitle,
    required String tafsirContent,
    String? tafsirSource,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (context, scrollController) => TafsirBottomSheet(
          ayahKey: ayahKey,
          tafsirTitle: tafsirTitle,
          tafsirContent: tafsirContent,
          tafsirSource: tafsirSource,
          scrollController: scrollController,
        ),
      ),
    );
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

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: themeState.primaryShade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatAyahKey(ayahKey),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeState.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tafsirTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: themeState.mutedGray.withValues(alpha: 0.3),
                height: 1,
              ),

              // Tafsir content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    SelectableText(
                      tafsirContent,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 18,
                        height: 2,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                      ),
                    ),
                    if (tafsirSource != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeState.primaryShade100.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: themeState.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.source(tafsirSource!),
                              style: TextStyle(
                                fontSize: 12,
                                color: themeState.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAyahKey(String key) {
    final parts = key.split(":");
    if (parts.length == 2) {
      return "${parts[0]}:${parts[1]}";
    }
    return key;
  }
}
