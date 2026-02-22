import "dart:ui";

import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";

enum QuickStartDemoUsageMode {
  simple,
  detailed,
}

class QuickStartDemoPage extends StatefulWidget {
  final ThemeState themeState;
  final QuickStartDemoUsageMode initialMode;
  final ValueChanged<QuickStartDemoUsageMode> onSelect;

  const QuickStartDemoPage({
    super.key,
    required this.themeState,
    required this.initialMode,
    required this.onSelect,
  });

  @override
  State<QuickStartDemoPage> createState() => _QuickStartDemoPageState();
}

class _QuickStartDemoPageState extends State<QuickStartDemoPage> {
  late QuickStartDemoUsageMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF3EDE2),
      appBar: AppBar(
        title: const Text(
          "جرّب قبل ما تختار",
          textDirection: TextDirection.rtl,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ModeSegmented(
                themeState: widget.themeState,
                value: _mode,
                onChanged: (v) => setState(() => _mode = v),
              ),
              const Gap(12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                        border: Border.all(
                          color: widget.themeState.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: _mode == QuickStartDemoUsageMode.detailed
                            ? _DetailedDemo(themeState: widget.themeState)
                            : _SimpleDemo(themeState: widget.themeState),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSelect(_mode);
                    Navigator.pop(context);
                  },
                  icon: const Icon(FluentIcons.checkmark_24_filled, size: 18),
                  label: const Text(
                    "اختار ده",
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeState.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
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
    );
  }
}

class _ModeSegmented extends StatelessWidget {
  final ThemeState themeState;
  final QuickStartDemoUsageMode value;
  final ValueChanged<QuickStartDemoUsageMode> onChanged;

  const _ModeSegmented({
    required this.themeState,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget item({
      required QuickStartDemoUsageMode mode,
      required String label,
      required IconData icon,
    }) {
      final selected = value == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected
                  ? themeState.primary.withValues(alpha: 0.16)
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              border: Border.all(
                color: themeState.primary.withValues(alpha: selected ? 0.40 : 0.14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? themeState.primary : null),
                const Gap(8),
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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
          mode: QuickStartDemoUsageMode.detailed,
          label: "مُفصل",
          icon: FluentIcons.document_one_page_24_regular,
        ),
        const Gap(10),
        item(
          mode: QuickStartDemoUsageMode.simple,
          label: "بسيط",
          icon: FluentIcons.book_open_24_regular,
        ),
      ],
    );
  }
}

class _DetailedDemo extends StatelessWidget {
  final ThemeState themeState;

  const _DetailedDemo({required this.themeState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget line(String text) {
      return Row(
        children: [
          Icon(
            FluentIcons.checkmark_circle_24_filled,
            size: 18,
            color: themeState.primary,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.5,
                fontSize: 12.5,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey("detailed"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "الوضع المُفصل (آية بآية)",
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const Gap(6),
        Text(
          "ده مناسب لو بتحب تدور وتقرأ تفسير وترجمة وتستخدم أدوات الآية كتير.",
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.5,
            fontSize: 12.5,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.62),
          ),
        ),
        const Gap(14),
        _BigPreview(
          themeState: themeState,
          title: "آية 255",
          body: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...",
          footerLeft: const Icon(FluentIcons.search_24_regular, size: 18),
          footerCenter: const Icon(FluentIcons.book_24_regular, size: 18),
          footerRight: const Icon(FluentIcons.share_24_regular, size: 18),
        ),
        const Gap(14),
        line("الافتراضي: آية بآية — تقدر تقلب للمصحف من الهيدر فوق"),
        const Gap(8),
        line("التفسير والترجمة والبحث بيكونوا أقرب وأسهل"),
        const Gap(8),
        line("مناسب للدراسة، الاستدلال، وتجهيز مشاركة آية"),
      ],
    );
  }
}

class _SimpleDemo extends StatelessWidget {
  final ThemeState themeState;

  const _SimpleDemo({required this.themeState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget line(String text) {
      return Row(
        children: [
          Icon(
            FluentIcons.checkmark_circle_24_filled,
            size: 18,
            color: themeState.primary,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.5,
                fontSize: 12.5,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey("simple"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "الوضع البسيط (قراءة)",
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const Gap(6),
        Text(
          "ده مناسب لو هدفك قراءة هادية وورد يومي بدون تشتيت.",
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.5,
            fontSize: 12.5,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.62),
          ),
        ),
        const Gap(14),
        _BigPreview(
          themeState: themeState,
          title: "المصحف",
          body: "...\n...\n...",
          footerLeft: const SizedBox.shrink(),
          footerCenter: const Icon(FluentIcons.book_open_24_regular, size: 18),
          footerRight: const SizedBox.shrink(),
        ),
        const Gap(14),
        line("الافتراضي: المصحف — وتقدر تقلب لآية بآية من الهيدر فوق"),
        const Gap(8),
        line("واجهة أهدى وأقل أدوات أثناء القراءة"),
        const Gap(8),
        line("مناسب للورد اليومي والتركيز"),
      ],
    );
  }
}

class _BigPreview extends StatelessWidget {
  final ThemeState themeState;
  final String title;
  final String body;
  final Widget footerLeft;
  final Widget footerCenter;
  final Widget footerRight;

  const _BigPreview({
    required this.themeState,
    required this.title,
    required this.body,
    required this.footerLeft,
    required this.footerCenter,
    required this.footerRight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.045),
            themeState.primary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: themeState.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.85),
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
            child: Text(
              body,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: 1.9,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.70),
              ),
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [footerLeft, footerCenter, footerRight],
          ),
        ],
      ),
    );
  }
}