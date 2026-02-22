import 'package:al_quran_v3/l10n/app_localizations.dart';
import 'package:al_quran_v3/src/theme/controller/theme_cubit.dart';
import 'package:al_quran_v3/src/theme/controller/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String _appVersion = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = "Build ${info.version} (${info.buildNumber})");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeState = context.watch<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cs = Theme.of(context).colorScheme;
    final bgColor = cs.surface;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final textMuted = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "عن التطبيق",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.primary, size: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // ── Minimalist Hero ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        "assets/img/Quran_Logo_v3.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const Gap(24),
                  Text(
                    l10n.appFullName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    "مصحف رقمي متكامل بأحدث التقنيات",
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(40),

            // ── Categorized Detailed Features (Minimalist) ──
            _buildFeatureCategory("📕 القراءة", [
              "وضع المصحف — عرض الصفحات بشكل يشبه المصحف الحقيقي",
              "وضع آية بآية — عرض كل آية بشكل منفصل مع خيارات التفاعل",
              "خطوط قرآنية متعددة — حفص، ورش، التجويد الملون",
              "البحث في الآيات — بحث فوري في جميع آيات القرآن",
              "الإعراب — إعراب الآيات",
              "التفسير — تفاسير متعددة (الميسر، ابن كثير، وغيرها)",
              "الترجمة — ترجمات متعددة اللغات",
            ], cs.primary, cardColor, borderColor),
            
            _buildFeatureCategory("🎧 التلاوة", [
              "+43 قارئ — مكتبة كبيرة من القراء المشهورين",
              "تلاوة كلمة بكلمة — لتعلّم النطق الصحيح",
              "التحكم في السرعة — من 0.5x إلى 2x",
              "البث المباشر أو التنزيل — اختر الوضع المناسب لك",
              "استمع إلى أي آية — تشغيل فوري لأي آية",
            ], cs.primary, cardColor, borderColor),

            _buildFeatureCategory("🕌 مواقيت الصلاة", [
              "مواقيت دقيقة — حسب موقعك الجغرافي",
              "إشعارات — تنبيه بوقت الصلاة",
              "اتجاه القبلة — بوصلة دقيقة مع خاصية الـ AR",
            ], cs.primary, cardColor, borderColor),

            _buildFeatureCategory("📚 ختمة القرآن", [
              "ختمة ذكية — حدد مدة الختمة (7، 15، 30 يوم)",
              "وِرد يومي — تتبع تقدمك اليومي",
            ], cs.primary, cardColor, borderColor),

            _buildFeatureCategory("🔖 التنظيم", [
              "المجموعات — نظّم آياتك المفضلة بالألوان",
              "الملاحظات — أضف ملاحظات على أي آية",
              "المفضلة — احفظ آياتك المفضلة بنقرة واحدة",
              "التعليقات — علّق على الآيات",
            ], cs.primary, cardColor, borderColor),

            _buildFeatureCategory("🎨 التخصيص", [
              "الوضع الداكن والفاتح — ثيمات متعددة",
              "ألوان مخصصة — اختر لون التطبيق المفضل",
              "حجم الخط — تحكم في حجم النص",
            ], cs.primary, cardColor, borderColor),
            
            const Gap(32),

            // ── Clean Mission Section ──
            _buildSectionHeader("رسالة التطبيق", cs.primary),
            const Gap(12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
              ),
              child: const Text(
                "هذا العمل صدقة جارية خالصة لوجه الله تعالى. التطبيق مجاني بالكامل، لا يحتوي على إعلانات، ومتاح للجميع للنفع والانتفاع بكتاب الله.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // ── Cross Platform Promotion ──
            _buildAvailableOnSection(themeState, isDark, cs),
            const Gap(40),

            // ── Developer Section (STRICTLY PRESERVED) ──
            _buildDeveloperSection(themeState, isDark),
            
            const Gap(40),
            
            // ── Footer ──
            _buildFooter(textMuted),
            const Gap(60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const Gap(8),
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCategory(String categoryTitle, List<String> items, Color primary, Color bg, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader(categoryTitle, primary),
        const Gap(12),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: items.map((item) => _buildFeatureItem(item, primary)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color muted) {
    return Column(
      children: [
        Text(
          "CRAFTED WITH PRECISION BY IDRISIUM CORP",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: muted,
            letterSpacing: 1.5,
          ),
        ),
        const Gap(6),
        Text(
          _appVersion,
          style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── CROSS-PLATFORM LINKS (IDRISIUM) ──
  Widget _buildAvailableOnSection(ThemeState themeState, bool isDark, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: 40,
              color: cs.primary.withValues(alpha: 0.2),
            ),
            const Gap(12),
            Text(
              "متوفر أيضاً على",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const Gap(12),
            Container(
              height: 1,
              width: 40,
              color: cs.primary.withValues(alpha: 0.2),
            ),
          ],
        ),
        const Gap(24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _platformButton(
              themeState: themeState,
              isDark: isDark,
              icon: SimpleIcons.apple,
              label: "App Store",
              url: "https://idrisium.linkpc.net/alfurkan/ios",
            ),
            _platformButton(
              themeState: themeState,
              isDark: isDark,
              icon: SimpleIcons.googleplay,
              label: "Google Play",
              url: "https://idrisium.linkpc.net/alfurkan/android",
            ),
            _platformButton(
              themeState: themeState,
              isDark: isDark,
              icon: Icons.language_rounded,
              label: "Web App",
              url: "https://alfurqan.vercel.app/",
            ),
          ],
        ),
      ],
    );
  }

  Widget _platformButton({
    required ThemeState themeState,
    required bool isDark,
    required IconData icon,
    required String label,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeState.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: themeState.primary),
              const Gap(10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  DEVELOPER SECTION (IDRISIUM) - NO CHANGES TO CONTENT/LOGIC
  // ════════════════════════════════════════════════════════════════
  Widget _buildDeveloperSection(ThemeState themeState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeState.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: themeState.primary.withValues(alpha: 0.2), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/dev/dev image.jpg",
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Center(
                  child: Text("I", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: themeState.primary)),
                ),
              ),
            ),
          ),
          const Gap(14),
          const Text(
            "إدريس غامد",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            textDirection: TextDirection.rtl,
          ),
          const Gap(4),
          Text(
            "IDRIS GHAMID",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black45, letterSpacing: 1.2),
          ),
          const Gap(6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: themeState.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "IDRISIUM Corp",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: themeState.primary, letterSpacing: 1.2),
            ),
          ),
          const Gap(24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _socialChip(themeState, isDark, icon: SimpleIcons.tiktok, label: "@idris.ghamid", url: "https://www.tiktok.com/@idris.ghamid"),
              _socialChip(themeState, isDark, icon: SimpleIcons.instagram, label: "@idris.ghamid", url: "https://www.instagram.com/idris.ghamid"),
              _socialChip(themeState, isDark, icon: SimpleIcons.telegram, label: "@IDRV72", url: "https://t.me/IDRV72"),
              _socialChip(themeState, isDark, icon: SimpleIcons.github, label: "IDRISIUM", url: "https://github.com/IDRISIUM"),
              _socialChip(themeState, isDark, icon: Icons.email_outlined, label: "idris.ghamid@gmail.com", url: "mailto:idris.ghamid@gmail.com"),
              _socialChip(themeState, isDark, icon: Icons.language_rounded, label: "idrisium.linkpc.net", url: "http://idrisium.linkpc.net/"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialChip(ThemeState themeState, bool isDark, {required IconData icon, required String label, required String url}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: themeState.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: themeState.primary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}
