import "dart:ui";

import "package:al_quran_v3/src/core/unified_quran_settings/cubit/quran_settings_cubit.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";

class QuranSettingsBottomSheet extends StatelessWidget {
  const QuranSettingsBottomSheet({super.key});

  /// Call this helper to show the sheet from anywhere.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<QuranSettingsCubit>(),
        child: const QuranSettingsBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, state) {
        final bool isThemeCompatibleWithMode =
            isDark
                ? (state.theme == QuranTheme.oled ||
                    state.theme == QuranTheme.nightBlue ||
                    state.theme == QuranTheme.custom ||
                    state.theme == QuranTheme.graphite ||
                    state.theme == QuranTheme.midnightPurple)
                : (state.theme == QuranTheme.sepia ||
                    state.theme == QuranTheme.cream ||
                    state.theme == QuranTheme.paperWhite ||
                    state.theme == QuranTheme.sand);

        if (state.isInitialized && !isThemeCompatibleWithMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<QuranSettingsCubit>().updateTheme(
              isDark ? QuranTheme.nightBlue : QuranTheme.cream,
            );
          });
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(color: primary.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Gap(16),

                      // Title
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "إعدادات المصحف",
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: primary.withValues(alpha: 0.10),
                            ),
                            child: Icon(
                              FluentIcons.settings_24_filled,
                              color: primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),

                      // ── Font Size Slider ──
                      _SectionLabel(label: "حجم الخط", isDark: isDark),
                      const Gap(8),
                      Row(
                        children: [
                          Icon(
                            FluentIcons.text_font_size_24_regular,
                            size: 18,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Slider(
                              value: state.fontSize,
                              min: 16,
                              max: 36,
                              divisions: 20,
                              activeColor: primary,
                              label: state.fontSize.toStringAsFixed(0),
                              onChanged: (v) => context
                                  .read<QuranSettingsCubit>()
                                  .updateFontSize(v),
                            ),
                          ),
                          Text(
                            state.fontSize.toStringAsFixed(0),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // ── Quran Theme ──
                      _SectionLabel(label: "ثيم المصحف", isDark: isDark),
                      const Gap(10),
                      _QuranThemeSelector(
                        state: state,
                        primary: primary,
                        isDark: isDark,
                      ),
                      const Gap(16),

                      // ── Live Preview ──
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: state.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: RichText(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: state.fontSize,
                              fontFamily: "KFGQPC-Uthmanic-HAFS-Regular",
                              color: state.textColor,
                              height: 2.0,
                            ),
                            children: [
                              const TextSpan(text: "بِسْمِ "),
                              TextSpan(
                                text: "ٱللَّهِ",
                                style: TextStyle(
                                  backgroundColor: state.highlightColor.withValues(alpha: 0.3),
                                ),
                              ),
                              const TextSpan(text: " ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"),
                            ],
                          ),
                        ),
                      ),
                      const Gap(20),

                      // ── Tajweed Toggle ──
                      _ToggleTile(
                        isDark: isDark,
                        primary: primary,
                        icon: FluentIcons.color_24_filled,
                        title: "تلوين التجويد",
                        subtitle: "تلوين حسب أحكام التجويد (16 حكم)",
                        value: state.tajweedEnabled,
                        onChanged: (v) =>
                            context.read<QuranSettingsCubit>().toggleTajweed(v),
                      ),
                      const Gap(12),

                      // ── Highlight Color ──
                      _SectionLabel(label: "لون التظليل", isDark: isDark),
                      const Gap(10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            [
                              Colors.amber,
                              Colors.green,
                              Colors.blue,
                              Colors.purple,
                              Colors.orange,
                              Colors.pink,
                              Colors.cyan,
                              Colors.teal,
                            ].map((c) {
                              final isSelected =
                                  state.highlightColor.value == c.value;
                              return InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => context
                                    .read<QuranSettingsCubit>()
                                    .updateHighlightColor(c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c,
                                    border: Border.all(
                                      color: isSelected
                                          ? primary
                                          : Colors.transparent,
                                      width: isSelected ? 3 : 0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: c.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                      ),
                      const Gap(30),
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
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _QuranThemeSelector extends StatelessWidget {
  final QuranSettingsState state;
  final Color primary;
  final bool isDark;

  const _QuranThemeSelector({
    required this.state,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      (QuranTheme.oled, "OLED", Colors.black, Colors.white),
      (
        QuranTheme.nightBlue,
        "أزرق ليلي",
        const Color(0xFF0F172A),
        Colors.white,
      ),
      (QuranTheme.custom, "Dark", const Color(0xFF0B0B0F), Colors.white),
      (QuranTheme.graphite, "جرافيت", const Color(0xFF121417), Colors.white),
      (QuranTheme.midnightPurple, "بنفسجي", const Color(0xFF140B2D), Colors.white),
      (QuranTheme.sepia, "سيبيا", const Color(0xFFF4ECD8), Colors.black87),
      (QuranTheme.cream, "كريمي", const Color(0xFFFFFDD0), Colors.black87),
      (QuranTheme.paperWhite, "أبيض", Colors.white, Colors.black87),
      (QuranTheme.sand, "رملي", const Color(0xFFF3E7D3), Colors.black87),
    ].where((t) {
      final theme = t.$1;
      if (isDark) {
        return theme == QuranTheme.oled ||
            theme == QuranTheme.nightBlue ||
            theme == QuranTheme.custom ||
            theme == QuranTheme.graphite ||
            theme == QuranTheme.midnightPurple;
      }
      return theme == QuranTheme.sepia ||
          theme == QuranTheme.cream ||
          theme == QuranTheme.paperWhite ||
          theme == QuranTheme.sand;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: themes.map((t) {
          final isSelected = state.theme == t.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.read<QuranSettingsCubit>().updateTheme(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 90,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: t.$3,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    if (isSelected)
                      Icon(Icons.check_circle, color: primary, size: 16)
                    else
                      const SizedBox(height: 16),
                    const Gap(4),
                    Text(
                      t.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: t.$4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.isDark,
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        subtitle,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, color: primary, size: 18),
                ),
              ],
            ),
          ),
          const Gap(10),
          Switch.adaptive(
            value: value,
            activeColor: primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
