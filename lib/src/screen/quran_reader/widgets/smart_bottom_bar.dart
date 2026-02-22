import "dart:ui";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/screen/quran_reader/cubit/reader_ui_cubit.dart";
import "package:al_quran_v3/src/screen/quran_reader/cubit/reader_ui_state.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// Smart Bottom Bar that can be shown/hidden with smooth animation
/// Contains: Audio Player, Surah Index, Search, Settings, Prayer Times
class SmartBottomBar extends StatelessWidget {
  final VoidCallback? onSurahIndexTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onPrayerTimeTap;
  final VoidCallback? onAudioTap;

  const SmartBottomBar({
    super.key,
    this.onSurahIndexTap,
    this.onSearchTap,
    this.onSettingsTap,
    this.onPrayerTimeTap,
    this.onAudioTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeState = context.read<ThemeCubit>().state;

    return BlocBuilder<ReaderUICubit, ReaderUIState>(
      buildWhen: (previous, current) =>
          previous.isUIVisible != current.isUIVisible,
      builder: (context, state) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: state.isUIVisible ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: state.isUIVisible ? 1.0 : 0.0,
            child: _buildBottomBar(context, l10n, themeState),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeState themeState,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: themeState.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context: context,
                    icon: FluentIcons.list_24_regular,
                    activeIcon: FluentIcons.list_24_filled,
                    label: l10n.surah, // فهرس السور
                    themeState: themeState,
                    onTap: onSurahIndexTap,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: FluentIcons.search_24_regular,
                    activeIcon: FluentIcons.search_24_filled,
                    label: l10n.search, // البحث
                    themeState: themeState,
                    onTap: onSearchTap,
                  ),
                  _buildCenterButton(context, themeState),
                  _buildNavItem(
                    context: context,
                    icon: FluentIcons.clock_24_regular,
                    activeIcon: FluentIcons.clock_24_filled,
                    label: l10n.prayer, // أوقات الصلاة
                    themeState: themeState,
                    onTap: onPrayerTimeTap,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: FluentIcons.settings_24_regular,
                    activeIcon: FluentIcons.settings_24_filled,
                    label: l10n.settings, // الإعدادات
                    themeState: themeState,
                    onTap: onSettingsTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeState themeState,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive 
                  ? themeState.primary 
                  : Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive 
                    ? themeState.primary 
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Center button for Audio playback
  Widget _buildCenterButton(BuildContext context, ThemeState themeState) {
    return GestureDetector(
      onTap: onAudioTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeState.primary,
              themeState.primary.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: themeState.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          FluentIcons.play_24_filled,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
