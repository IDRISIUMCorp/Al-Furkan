import "dart:ui" as ui;

import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../theme/controller/theme_cubit.dart";

/// A premium bottom-sheet that allows the user to browse all FlexScheme
/// options with a live preview card for each scheme.  Designed to feel
/// like an Apple-level settings panel in dark mode.
class ThemePreviewSheet extends StatefulWidget {
  const ThemePreviewSheet({super.key});

  /// Shows the sheet via [showModalBottomSheet].
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemePreviewSheet(),
    );
  }

  @override
  State<ThemePreviewSheet> createState() => _ThemePreviewSheetState();
}

class _ThemePreviewSheetState extends State<ThemePreviewSheet> {
  /// All available schemes the user can pick from.
  static const List<FlexScheme> _schemes = FlexScheme.values;

  late FlexScheme _previewScheme;

  @override
  void initState() {
    super.initState();
    _previewScheme = context.read<ThemeCubit>().state.flexScheme;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _schemeName(FlexScheme scheme) {
    // FlexColor.schemes contains a human-readable description for each scheme.
    return FlexColor.schemes[scheme]?.name ?? scheme.name;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E0E12) : const Color(0xFFF7F1E6);
    final cardBg = isDark ? const Color(0xFF1A1A1F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B1B);
    final subtitleColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    // Colors for the currently previewed scheme
    final previewColors = FlexColor.schemes[_previewScheme]!;
    final lightPalette = previewColors.light;
    final darkPalette = previewColors.dark;
    final activePalette = isDark ? darkPalette : lightPalette;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: bg.withValues(alpha: isDark ? 0.92 : 0.97),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // ─── Handle bar ───
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Title ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.palette_rounded,
                            color: activePalette.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "اختيار السمة",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ),
                        // Apply button
                        _ApplyButton(
                          active: _previewScheme !=
                              context.read<ThemeCubit>().state.flexScheme,
                          color: activePalette.primary,
                          onTap: () {
                            context
                                .read<ThemeCubit>()
                                .changeFlexScheme(_previewScheme);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ─── Live Preview Card ───
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: _LivePreviewCard(
                      primary: activePalette.primary,
                      secondary: activePalette.secondary,
                      tertiary: activePalette.tertiary,
                      schemeName: _schemeName(_previewScheme),
                      isDark: isDark,
                      cardBg: cardBg,
                    ),
                  )
                      .animate(key: ValueKey(_previewScheme))
                      .fadeIn(duration: 300.ms)
                      .scaleXY(
                          begin: 0.97,
                          end: 1.0,
                          duration: 300.ms,
                          curve: Curves.easeOut),

                  const SizedBox(height: 6),

                  // ─── Scheme Grid ───
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: _schemes.length,
                        itemBuilder: (context, index) {
                          final scheme = _schemes[index];
                          // Skip the "custom" placeholder if present
                          if (scheme == FlexScheme.custom) {
                            return const SizedBox.shrink();
                          }

                          final colors = FlexColor.schemes[scheme];
                          if (colors == null) return const SizedBox.shrink();

                          final palette = isDark ? colors.dark : colors.light;
                          final isSelected = scheme == _previewScheme;

                          return _SchemeChip(
                            label: colors.name,
                            primary: palette.primary,
                            secondary: palette.secondary,
                            tertiary: palette.tertiary,
                            isSelected: isSelected,
                            isDark: isDark,
                            subtitleColor: subtitleColor,
                            onTap: () =>
                                setState(() => _previewScheme = scheme),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

/// The mini live-preview card that shows how the selected scheme looks.
class _LivePreviewCard extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final String schemeName;
  final bool isDark;
  final Color cardBg;

  const _LivePreviewCard({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.schemeName,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scheme name
          Text(
            schemeName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 14),

          // Color swatches row
          Row(
            children: [
              _ColorSwatch(label: "Primary", color: primary),
              const SizedBox(width: 10),
              _ColorSwatch(label: "Secondary", color: secondary),
              const SizedBox(width: 10),
              _ColorSwatch(label: "Tertiary", color: tertiary),
            ],
          ),
          const SizedBox(height: 16),

          // Fake UI preview
          Row(
            children: [
              // Fake FAB
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              // Fake text lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: secondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
              // Fake chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tertiary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Chip",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One swatch circle with a label below.
class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorSwatch({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// A selectable chip representing a single FlexScheme in the grid.
class _SchemeChip extends StatelessWidget {
  final String label;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final bool isSelected;
  final bool isDark;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _SchemeChip({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.isSelected,
    required this.isDark,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.18 : 0.10)
              : (isDark
                  ? const Color(0xFF1A1A1F)
                  : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Three color dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _dot(primary),
                const SizedBox(width: 4),
                _dot(secondary),
                const SizedBox(width: 4),
                _dot(tertiary),
              ],
            ),
            const SizedBox(height: 8),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? primary : subtitleColor,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle_rounded, color: primary, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
}

/// The apply/save button shown in the header.
class _ApplyButton extends StatelessWidget {
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ApplyButton({
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: active ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: const Text(
            "تطبيق",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
