import 'dart:ui';
import 'package:al_quran_v3/l10n/app_localizations.dart';
import 'package:al_quran_v3/src/theme/controller/theme_cubit.dart';
import 'package:al_quran_v3/src/theme/controller/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:al_quran_v3/src/core/constants/app_strings.dart';
import 'package:al_quran_v3/src/core/constants/app_assets.dart';
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
            letterSpacing: 0.5,
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
            // ── Minimalist Hero (Animated) ──
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
                          color: cs.primary.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        AppAssets.quranLogo,
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
                    AppStrings.appSlogan,
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
            ),
            const Gap(40),

            // ── Clean Mission Section (Glassmorphic) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.05),
                    blurRadius: 20,
                  )
                ]
              ),
              child: const Text(
                AppStrings.devMissionMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.1, curve: Curves.easeOut),
            
            const Gap(40),

            // ── Developer Section (IDRISIUM SIGNATURE) ──
            _buildDeveloperSection(themeState, isDark, cs.primary).animate().fade(delay: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
            
            const Gap(32),

            // ── Categorized Detailed Features (Animated List) ──
            Column(
              children: [
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
                  "الوضع الداكن والفاتح — ثيمات متعددة بمرونة تامة",
                  "ألوان مخصصة — اختر لون التطبيق وتصميم المصحف",
                  "حجم الخط — حاسبة ذكية تناسب الشاشات الكبيرة والصغيرة",
                ], cs.primary, cardColor, borderColor),
              ],
            ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
            
            const Gap(40),
            
            // ── Footer ──
            _buildFooter(textMuted).animate().fade(delay: 800.ms),
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

  // ════════════════════════════════════════════════════════════════
  //  DEVELOPER SECTION (IDRISIUM SIGNATURE MODAL)
  // ════════════════════════════════════════════════════════════════
  Widget _buildDeveloperSection(ThemeState themeState, bool isDark, Color primary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.05),
                blurRadius: 30,
              )
            ]
          ),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary.withValues(alpha: 0.3), width: 3),
                  boxShadow: [
                    BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
                  ]
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.devImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Center(
                      child: Text("I", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primary)),
                    ),
                  ),
                ),
              ),
              const Gap(16),
              const Text(
                AppStrings.developerNameAr,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                textDirection: TextDirection.rtl,
              ),
              const Gap(4),
              Text(
                AppStrings.developerNameEn,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black45, letterSpacing: 1.2),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.2))
                ),
                child: Text(
                  AppStrings.devTitle,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primary, letterSpacing: 1.2),
                ),
              ),
              const Gap(24),
              
              // App Github Repo Link
              InkWell(
                onTap: () => launchUrl(Uri.parse(AppStrings.githubPath), mode: LaunchMode.externalApplication),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(SimpleIcons.github, size: 18),
                      Gap(10),
                      Text("مسار التطبيق على Github (مفتوح المصدر)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              const Gap(16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _socialChip(primary, isDark, icon: SimpleIcons.tiktok, label: AppStrings.tiktokHandle, url: AppStrings.tiktokUrl),
                  _socialChip(primary, isDark, icon: SimpleIcons.instagram, label: AppStrings.instagramHandle, url: AppStrings.instagramUrl),
                  _socialChip(primary, isDark, icon: SimpleIcons.telegram, label: AppStrings.telegramHandle, url: AppStrings.telegramUrl),
                  _socialChip(primary, isDark, icon: SimpleIcons.github, label: "IDRISIUM", url: "https://github.com/IDRISIUM"),
                  _socialChip(primary, isDark, icon: Icons.language_rounded, label: "Website", url: AppStrings.website),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialChip(Color primary, bool isDark, {required IconData icon, required String label, required String url}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: primary),
              const Gap(8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

