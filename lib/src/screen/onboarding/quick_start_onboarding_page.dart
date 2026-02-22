import "dart:ui";

import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_by_ayah_in_scroll_info_cubit.dart";
import "package:al_quran_v3/src/screen/onboarding/quick_start_demo_page.dart";
import "package:al_quran_v3/src/screen/setup/setup_page.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

enum QuickStartUsageMode {
  simple,
  detailed,
}

class QuickStartOnboardingPage extends StatefulWidget {
  const QuickStartOnboardingPage({super.key});

  @override
  State<QuickStartOnboardingPage> createState() => _QuickStartOnboardingPageState();
}

class _QuickStartOnboardingPageState extends State<QuickStartOnboardingPage> {
  final PageController _pageController = PageController();

  QuickStartUsageMode _mode = QuickStartUsageMode.detailed;
  ThemeMode _themeMode = ThemeMode.system;

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

  Future<void> _continue() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final userBox = Hive.box("user");

    final isAyahByAyahDefault = _mode == QuickStartUsageMode.detailed;
    await userBox.put("quick_setup_done", true);
    await userBox.put("quick_usage_mode", _mode.name);

    await userBox.put("isAyahByAyah", isAyahByAyahDefault);
    if (!isAyahByAyahDefault) {
      await userBox.put("isAyahByAyahHorizontal", false);
    }

    if (mounted) {
      context
          .read<AyahByAyahInScrollInfoCubit>()
          .setData(isAyahByAyah: isAyahByAyahDefault);

      context.read<ThemeCubit>().setTheme(_themeMode);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppSetupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor:
              isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF3EDE2),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  _TopHeader(themeState: themeState),
                  const Gap(12),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStepUsage(themeState),
                        _buildStepTheme(themeState),
                      ],
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

  Widget _buildStepUsage(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "ابدأ بسرعة",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const Gap(6),
                Text(
                  "اختار النظام اللي يناسبك… وتقدر تغيّره بعدين من الهيدر فوق بسهولة.",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(14),
                _UsageCard(
                  themeState: themeState,
                  isSelected: _mode == QuickStartUsageMode.detailed,
                  title: "الوضع المُفصل (آية بآية)",
                  subtitle: "تدبر، بحث، تفسير، واستدلال — كل الأدوات جاهزة.",
                  exampleTitle: "مثال لمستخدم:",
                  exampleBody:
                      "أنا بدوّر على آية في موضوع معيّن، وبقرأ التفسير والترجمة وبشاركها — فعايز كل الأدوات تكون قدامي.",
                  badges: const [
                    _ModeBadge(label: "بحث سريع"),
                    _ModeBadge(label: "تفسير"),
                    _ModeBadge(label: "ترجمة"),
                  ],
                  preview: const _ModePreviewDetailed(),
                  onTap: () => setState(() => _mode = QuickStartUsageMode.detailed),
                ),
                const Gap(12),
                _UsageCard(
                  themeState: themeState,
                  isSelected: _mode == QuickStartUsageMode.simple,
                  title: "الوضع البسيط (قراءة) ",
                  subtitle: "قراءة هادية بدون تشتيت — المصحف أول ما تفتح.",
                  exampleTitle: "مثال لمستخدم:",
                  exampleBody:
                      "أنا بفتح اقرأ وردي اليومي بس، ومش عايز قوائم كتير ولا تفاصيل أثناء القراءة.",
                  badges: const [
                    _ModeBadge(label: "قراءة"),
                    _ModeBadge(label: "بدون تشتيت"),
                  ],
                  preview: const _ModePreviewSimple(),
                  onTap: () => setState(() => _mode = QuickStartUsageMode.simple),
                ),
                const Gap(12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await Navigator.push<QuickStartDemoUsageMode>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuickStartDemoPage(
                            themeState: themeState,
                            initialMode: _mode == QuickStartUsageMode.detailed
                                ? QuickStartDemoUsageMode.detailed
                                : QuickStartDemoUsageMode.simple,
                            onSelect: (m) {
                              Navigator.pop(context, m);
                            },
                          ),
                        ),
                      );

                      if (selected == null) return;
                      setState(() {
                        _mode = selected == QuickStartDemoUsageMode.detailed
                            ? QuickStartUsageMode.detailed
                            : QuickStartUsageMode.simple;
                      });
                    },
                    icon: const Icon(FluentIcons.play_24_filled, size: 18),
                    label: const Text(
                      "جرّب قبل ما تختار",
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeState.primary,
                      side: BorderSide(color: themeState.primary.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _PrimaryButton(
          themeState: themeState,
          label: "متابعة",
          icon: FluentIcons.arrow_right_24_filled,
          onPressed: _continue,
        ),
      ],
    );
  }

  Widget _buildStepTheme(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "اللمسة الأخيرة",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const Gap(6),
                Text(
                  "اختار الثيم اللي يريح عينك. تقدر تغيّره في أي وقت من الإعدادات.",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(14),
                _ThemeModePicker(
                  themeState: themeState,
                  value: _themeMode,
                  onChanged: (v) => setState(() => _themeMode = v),
                ),
                const Gap(14),
                _SummaryCard(themeState: themeState, mode: _mode),
              ],
            ),
          ),
        ),
        _PrimaryButton(
          themeState: themeState,
          label: "ابدأ الآن",
          icon: FluentIcons.checkmark_24_filled,
          onPressed: _finish,
        ),
      ],
    );
  }
}

class _TopHeader extends StatelessWidget {
  final ThemeState themeState;

  const _TopHeader({required this.themeState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
            border: Border.all(
              color: themeState.primary.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeState.primary.withValues(alpha: 0.22),
                      themeState.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: themeState.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  FluentIcons.sparkle_24_filled,
                  color: themeState.primary,
                  size: 20,
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
              Text(
                "إعداد سريع",
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: themeState.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final ThemeState themeState;
  final bool isSelected;
  final String title;
  final String subtitle;
  final String exampleTitle;
  final String exampleBody;
  final List<_ModeBadge> badges;
  final Widget preview;
  final VoidCallback onTap;

  const _UsageCard({
    required this.themeState,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.exampleTitle,
    required this.exampleBody,
    required this.badges,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isDark ? Colors.white : Colors.black).withValues(alpha: isSelected ? 0.06 : 0.04),
              themeState.primary.withValues(alpha: isSelected ? 0.10 : 0.06),
            ],
          ),
          border: Border.all(
            color: themeState.primary.withValues(alpha: isSelected ? 0.38 : 0.18),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.18 : 0.08),
              blurRadius: isSelected ? 26 : 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? themeState.primary.withValues(alpha: 1)
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 13, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    subtitle,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: badges,
                  ),
                  const Gap(12),
                  Text(
                    exampleTitle,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.85),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    exampleBody,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            preview,
          ],
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;

  const _ModeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _ModePreviewDetailed extends StatelessWidget {
  const _ModePreviewDetailed();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 92,
      height: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.045),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
            child: const Align(
              alignment: Alignment.center,
              child: Text(
                "آية",
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              ),
              child: const Center(
                child: Icon(FluentIcons.document_one_page_24_regular, size: 22),
              ),
            ),
          ),
          const Gap(8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(FluentIcons.search_24_regular, size: 16),
              Icon(FluentIcons.book_24_regular, size: 16),
              Icon(FluentIcons.share_24_regular, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModePreviewSimple extends StatelessWidget {
  const _ModePreviewSimple();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 92,
      height: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.045),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            ),
            child: const Align(
              alignment: Alignment.center,
              child: Text(
                "مصحف",
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
              ),
              child: const Center(
                child: Icon(FluentIcons.book_open_24_regular, size: 22),
              ),
            ),
          ),
          const Gap(8),
          Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  final ThemeState themeState;
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModePicker({
    required this.themeState,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget item({
      required ThemeMode mode,
      required String label,
      required IconData icon,
    }) {
      final selected = value == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? themeState.primary.withValues(alpha: 0.14)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              border: Border.all(
                color: themeState.primary.withValues(alpha: selected ? 0.40 : 0.14),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? themeState.primary : null),
                const Gap(8),
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? themeState.primary
                        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(
          mode: ThemeMode.system,
          label: "تلقائي",
          icon: FluentIcons.desktop_24_regular,
        ),
        const Gap(10),
        item(
          mode: ThemeMode.dark,
          label: "داكن",
          icon: FluentIcons.weather_moon_24_regular,
        ),
        const Gap(10),
        item(
          mode: ThemeMode.light,
          label: "فاتح",
          icon: FluentIcons.weather_sunny_24_regular,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ThemeState themeState;
  final QuickStartUsageMode mode;

  const _SummaryCard({required this.themeState, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = mode == QuickStartUsageMode.detailed
        ? "الوضع الحالي: مُفصل (آية بآية)"
        : "الوضع الحالي: بسيط (قراءة)";

    final desc = mode == QuickStartUsageMode.detailed
        ? "افتراضيًا هتبدأ على آية بآية، وتقدر تقلب للمصحف من زر الهيدر فوق."
        : "افتراضيًا هتبدأ على المصحف، وتقدر تقلب لآية بآية من زر الهيدر فوق.";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        border: Border.all(
          color: themeState.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const Gap(6),
          Text(
            desc,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final ThemeState themeState;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.themeState,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w900),
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
    );
  }
}
