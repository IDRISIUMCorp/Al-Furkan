import "dart:ui";

import "package:al_quran_v3/src/core/unified_quran_settings/cubit/quran_settings_cubit.dart";
import "package:al_quran_v3/src/screen/settings/theme_settings.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

class PremiumOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PremiumOnboardingScreen({super.key, required this.onComplete});

  @override
  State<PremiumOnboardingScreen> createState() =>
      _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 6;

  // Page 2: Theme Mode
  ThemeMode _themeMode = ThemeMode.system;

  // Page 4: Tajweed & Highlight
  bool _tajweedEnabled = true;
  Color _highlightColor = Colors.amber;

  // Page 6: Notifications
  bool _notifKhatma = true;
  bool _notifDailyVerse = true;
  bool _notifMorningAzkar = true;
  bool _notifEveningAzkar = false;

  @override
  void initState() {
    super.initState();
    _themeMode = context.read<ThemeCubit>().state.themeMode;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final userBox = Hive.box("user");
    await userBox.put("onboarding_v2_done", true);

    if (mounted) {
      // Apply theme choice
      context.read<ThemeCubit>().setTheme(_themeMode);

      // Apply quran settings
      final qsCubit = context.read<QuranSettingsCubit>();
      qsCubit.toggleTajweed(_tajweedEnabled);
      qsCubit.updateHighlightColor(_highlightColor);
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFF8F5EE),
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(themeState, isDark),
                const Gap(8),

                // Page indicator
                _buildPageIndicator(themeState),
                const Gap(16),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildWelcomePage(themeState, isDark),
                      _buildThemeModePage(themeState, isDark),
                      _buildQuranThemePage(themeState, isDark),
                      _buildTajweedHighlightPage(themeState, isDark),
                      _buildContentPage(themeState, isDark),
                      _buildNotificationsPage(themeState, isDark),
                    ],
                  ),
                ),

                // Bottom buttons
                _buildBottomButtons(themeState, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TOP BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildTopBar(ThemeState themeState, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.04,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeState.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        themeState.primary.withValues(alpha: 0.25),
                        themeState.primary.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Icon(
                    FluentIcons.sparkle_24_filled,
                    color: themeState.primary,
                    size: 18,
                  ),
                ),
                const Gap(10),
                const Expanded(
                  child: Text(
                    "الفُرقان",
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                if (_currentPage < _totalPages - 1)
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      "تخطي",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: themeState.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE INDICATOR
  // ════════════════════════════════════════════════════════════════
  Widget _buildPageIndicator(ThemeState themeState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: List.generate(_totalPages, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? themeState.primary
                    : themeState.primary.withValues(alpha: 0.15),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BOTTOM BUTTONS
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomButtons(ThemeState themeState, bool isDark) {
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLast ? _finish : _next,
          icon: Icon(
            isLast
                ? FluentIcons.checkmark_24_filled
                : FluentIcons.arrow_left_24_filled,
            size: 18,
          ),
          label: Text(
            isLast ? "ابدأ الآن" : "التالي",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeState.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE 1: WELCOME
  // ════════════════════════════════════════════════════════════════
  Widget _buildWelcomePage(ThemeState themeState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Gap(40),
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: themeState.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    "assets/img/Quran_Logo_v3.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 800.ms)
              .scaleXY(begin: 0.8, end: 1, curve: Curves.easeOut),
          const Gap(30),
          const Text(
                "مرحبًا بك في الفُرقان",
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.15, end: 0),
          const Gap(12),
          Text(
            "مصحف رقمي متكامل — صُمم بعناية ليكون رفيقك في تلاوة كتاب الله.",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const Gap(40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _featurePill(
                "تجويد ملوّن",
                FluentIcons.color_24_filled,
                themeState.primary,
                isDark,
              ),
              _featurePill(
                "+43 قارئ",
                FluentIcons.headphones_24_filled,
                themeState.primary,
                isDark,
              ),
              _featurePill(
                "بحث ذكي",
                FluentIcons.search_24_filled,
                themeState.primary,
                isDark,
              ),
              _featurePill(
                "تفسير متعدد",
                FluentIcons.book_24_filled,
                themeState.primary,
                isDark,
              ),
              _featurePill(
                "إعراب",
                FluentIcons.text_grammar_wand_24_filled,
                themeState.primary,
                isDark,
              ),
              _featurePill(
                "ختمة يومية",
                FluentIcons.target_24_filled,
                themeState.primary,
                isDark,
              ),
            ],
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _featurePill(String label, IconData icon, Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: primary.withValues(alpha: 0.08),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE 2: THEME MODE + FLEX SCHEME
  // ════════════════════════════════════════════════════════════════
  Widget _buildThemeModePage(ThemeState themeState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageTitle("المظهر العام", "اختار الوضع واللون اللي يريحك."),
          const Gap(20),

          // Dark / Light / System
          Row(
            children: [
              _themeModeCard(
                themeState,
                isDark,
                mode: ThemeMode.system,
                label: "تلقائي",
                icon: FluentIcons.desktop_24_regular,
              ),
              const Gap(10),
              _themeModeCard(
                themeState,
                isDark,
                mode: ThemeMode.dark,
                label: "داكن",
                icon: FluentIcons.weather_moon_24_regular,
              ),
              const Gap(10),
              _themeModeCard(
                themeState,
                isDark,
                mode: ThemeMode.light,
                label: "فاتح",
                icon: FluentIcons.weather_sunny_24_regular,
              ),
            ],
          ),
          const Gap(24),

          // Flex Scheme Color Picker
          _sectionLabel("لون التطبيق"),
          const Gap(10),
          const ThemeSettings(),
        ],
      ),
    );
  }

  Widget _themeModeCard(
    ThemeState themeState,
    bool isDark, {
    required ThemeMode mode,
    required String label,
    required IconData icon,
  }) {
    final selected = _themeMode == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() => _themeMode = mode);
          context.read<ThemeCubit>().setTheme(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? themeState.primary.withValues(alpha: 0.14)
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
            border: Border.all(
              color: themeState.primary.withValues(
                alpha: selected ? 0.40 : 0.12,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? themeState.primary : null, size: 22),
              const Gap(8),
              Text(
                label,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? themeState.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE 3: QURAN THEME (OLED, SEPIA, CREAM, NIGHT BLUE)
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuranThemePage(ThemeState themeState, bool isDark) {
    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, qsState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageTitle(
                "ثيم المصحف",
                "اختار خلفية المصحف اللي تريح عينك أثناء القراءة.",
              ),
              const Gap(20),
              _quranThemeGrid(themeState, isDark, qsState),
              const Gap(24),
              // Live Preview
              _sectionLabel("معاينة"),
              const Gap(12),
              _quranThemePreview(qsState),
            ],
          ),
        );
      },
    );
  }

  Widget _quranThemeGrid(
    ThemeState themeState,
    bool isDark,
    QuranSettingsState qsState,
  ) {
    final themes = [
      (QuranTheme.oled, "OLED", Colors.black, Colors.white),
      (QuranTheme.sepia, "سيبيا", const Color(0xFFF4ECD8), Colors.black87),
      (QuranTheme.cream, "كريمي", const Color(0xFFFFFDD0), Colors.black87),
      (
        QuranTheme.nightBlue,
        "أزرق ليلي",
        const Color(0xFF0F172A),
        Colors.white,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: themes.map((t) {
        final isSelected = qsState.theme == t.$1;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.read<QuranSettingsCubit>().updateTheme(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: (MediaQuery.of(context).size.width - 58) / 2,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.$3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? themeState.primary
                    : (isDark ? Colors.white24 : Colors.black12),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: themeState.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: themeState.primary,
                        size: 18,
                      ),
                    Text(
                      t.$2,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: t.$4,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                // Mini verse preview
                Text(
                  "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: "KFGQPC-Uthmanic-HAFS-Regular",
                    color: t.$4.withValues(alpha: 0.85),
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _quranThemePreview(QuranSettingsState qsState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: qsState.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Text(
        "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ ۝ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ ۝ مَـٰلِكِ يَوْمِ ٱلدِّينِ",
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontFamily: "KFGQPC-Uthmanic-HAFS-Regular",
          color: qsState.textColor,
          height: 2.2,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE 4: TAJWEED & HIGHLIGHT
  // ════════════════════════════════════════════════════════════════
  Widget _buildTajweedHighlightPage(ThemeState themeState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageTitle(
            "التجويد والتظليل",
            "فعّل التجويد الملون واختار لون التظليل اللي يناسبك.",
          ),
          const Gap(20),

          // Tajweed Toggle
          _buildGlassCard(
            isDark,
            themeState,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "تلوين التجويد",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        "تلوين الكلمات حسب أحكام التجويد (16 حكم)",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                Switch.adaptive(
                  value: _tajweedEnabled,
                  activeColor: themeState.primary,
                  onChanged: (v) => setState(() => _tajweedEnabled = v),
                ),
              ],
            ),
          ),
          const Gap(16),

          // Highlight Color
          _sectionLabel("لون التظليل"),
          const Gap(10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Colors.amber,
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.pink,
              Colors.cyan,
              Colors.teal,
            ].map((c) => _colorCircle(c, themeState)).toList(),
          ),
          const Gap(24),

          // Preview
          _sectionLabel("معاينة التظليل"),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.04,
              ),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: RichText(
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "KFGQPC-Uthmanic-HAFS-Regular",
                  color: isDark ? Colors.white : Colors.black87,
                  height: 2.0,
                ),
                children: [
                  const TextSpan(text: "إِنَّا أَعْطَيْنَاكَ "),
                  TextSpan(
                    text: "ٱلْكَوْثَرَ",
                    style: TextStyle(
                      backgroundColor: _highlightColor.withValues(alpha: 0.35),
                    ),
                  ),
                  const TextSpan(text: " ۝"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCircle(Color color, ThemeState themeState) {
    final isSelected = _highlightColor.value == color.value;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _highlightColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? themeState.primary : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
              : [],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE 5: CONTENT (TAFSIR)
  // ════════════════════════════════════════════════════════════════
  Widget _buildContentPage(ThemeState themeState, bool isDark) {
    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      builder: (context, qsState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageTitle(
                "المحتوى والأدوات",
                "اختار الأدوات اللي تحتاجها أثناء القراءة.",
              ),
              const Gap(20),

              // Tafsir
              _buildGlassCard(
                isDark,
                themeState,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "التفسير الميسّر",
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            "تفسير مبسّط محمّل مع التطبيق — لا يحتاج إنترنت",
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Switch.adaptive(
                      value: qsState.enableTafsir,
                      activeColor: themeState.primary,
                      onChanged: (v) =>
                          context.read<QuranSettingsCubit>().toggleTafsir(v),
                    ),
                  ],
                ),
              ),
              const Gap(14),

              // I'rab
              _buildGlassCard(
                isDark,
                themeState,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "الإعراب",
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            "إعراب الآيات — تقدر تفعله أو تلغيه في أي وقت",
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(12),
                    Switch.adaptive(
                      value: qsState.enableIrab,
                      activeColor: themeState.primary,
                      onChanged: (v) =>
                          context.read<QuranSettingsCubit>().toggleIrab(v),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: themeState.primary.withValues(alpha: 0.06),
                  border: Border.all(
                    color: themeState.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "تقدر تغيّر كل الإعدادات دي بعدين من الإعدادات.",
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: themeState.primary,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Icon(
                      FluentIcons.info_24_regular,
                      color: themeState.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PAGE 6: NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════
  Widget _buildNotificationsPage(ThemeState themeState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageTitle("الإشعارات", "فعّل التنبيهات اللي تفكّرك بالقرآن والذكر."),
          const Gap(20),
          _notifToggle(
            themeState,
            isDark,
            title: "تذكير الختمة",
            subtitle: "تذكير يومي بورد القراءة",
            icon: FluentIcons.book_24_filled,
            value: _notifKhatma,
            onChanged: (v) => setState(() => _notifKhatma = v),
          ),
          const Gap(10),
          _notifToggle(
            themeState,
            isDark,
            title: "آية اليوم",
            subtitle: "آية عشوائية يومية مع تفسيرها",
            icon: FluentIcons.star_24_filled,
            value: _notifDailyVerse,
            onChanged: (v) => setState(() => _notifDailyVerse = v),
          ),
          const Gap(10),
          _notifToggle(
            themeState,
            isDark,
            title: "أذكار الصباح",
            subtitle: "تذكير بأذكار الصباح",
            icon: FluentIcons.weather_sunny_24_filled,
            value: _notifMorningAzkar,
            onChanged: (v) => setState(() => _notifMorningAzkar = v),
          ),
          const Gap(10),
          _notifToggle(
            themeState,
            isDark,
            title: "أذكار المساء",
            subtitle: "تذكير بأذكار المساء",
            icon: FluentIcons.weather_moon_24_filled,
            value: _notifEveningAzkar,
            onChanged: (v) => setState(() => _notifEveningAzkar = v),
          ),
          const Gap(24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: themeState.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: themeState.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "تقدر تعدّل مواعيد وإعدادات الإشعارات بالتفصيل من شاشة الإعدادات.",
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: themeState.primary,
                    ),
                  ),
                ),
                const Gap(8),
                Icon(
                  FluentIcons.info_24_regular,
                  color: themeState.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifToggle(
    ThemeState themeState,
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildGlassCard(
      isDark,
      themeState,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: themeState.primary.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, color: themeState.primary, size: 18),
                ),
              ],
            ),
          ),
          const Gap(10),
          Switch.adaptive(
            value: value,
            activeColor: themeState.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ════════════════════════════════════════════════════════════════
  Widget _pageTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const Gap(6),
        Text(
          subtitle,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildGlassCard(
    bool isDark,
    ThemeState themeState, {
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.04,
            ),
            border: Border.all(
              color: themeState.primary.withValues(alpha: 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
