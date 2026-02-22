import "package:flutter/material.dart";

/// إعدادات تخصيص صورة الآية للمشاركة
class AyahImageSettings {
  /// نوع الخلفية
  final AyahImageBackground background;

  /// نسبة أبعاد الصورة
  final AyahImageAspectRatio aspectRatio;
  
  /// حجم الخط
  final AyahImageFontSize fontSize;
  
  /// نوع الخط
  final AyahImageFontType fontType;

  /// مسافات داخلية إضافية (للتخصيص الاحترافي)
  final double contentPadding;

  /// جودة التصدير (للصورة المصدّرة)
  final AyahImageExportQuality exportQuality;
  
  /// إعدادات العلامة المائية
  final WatermarkSettings watermark;
  
  /// إظهار التفسير
  final bool showTafsir;
  
  /// إظهار الترجمة
  final bool showTranslation;
  
  /// إظهار الحواشي
  final bool showFootnotes;
  
  /// إظهار رقم الآية
  final bool showAyahNumber;
  
  /// إظهار اسم السورة
  final bool showSurahName;
  
  /// نمط الإطار
  final AyahImageFrameStyle frameStyle;

  /// نمط الهيدر (عنوان السورة)
  final AyahImageHeaderStyle headerStyle;

  /// محاذاة نص الآية
  final AyahImageTextAlign ayahTextAlign;

  /// تباعد السطور لنص الآية
  final double ayahLineHeight;

  /// تباعد الحروف لنص الآية
  final double ayahLetterSpacing;

  /// حجم خط الترجمة
  final double translationFontSize;

  /// تباعد السطور للترجمة
  final double translationLineHeight;

  /// أقصى عدد سطور للترجمة
  final int translationMaxLines;

  /// حجم خط التفسير
  final double tafsirFontSize;

  /// تباعد السطور للتفسير
  final double tafsirLineHeight;

  /// أقصى عدد سطور للتفسير
  final int tafsirMaxLines;

  /// حجم خط الحواشي
  final double footnotesFontSize;

  /// تباعد السطور للحواشي
  final double footnotesLineHeight;

  /// أقصى عدد سطور للحواشي
  final int footnotesMaxLines;

  /// عرض الحواشي داخل Box
  final bool footnotesBoxed;

  /// ارتفاع بانر الهيدر
  final double headerBannerHeight;

  /// شفافية خلفية بانر الهيدر
  final double headerBannerOpacity;

  /// محاذاة عنوان السورة داخل بانر الهيدر
  final AyahImageHeaderAlign headerBannerAlign;

  /// إظهار معنى السورة داخل بانر الهيدر
  final bool showSurahMeaning;

  const AyahImageSettings({
    this.background = AyahImageBackground.light,
    this.aspectRatio = AyahImageAspectRatio.auto,
    this.fontSize = AyahImageFontSize.medium,
    this.fontType = AyahImageFontType.uthmanic,
    this.contentPadding = 0,
    this.exportQuality = AyahImageExportQuality.hd,
    this.watermark = const WatermarkSettings(),
    this.showTafsir = false,
    this.showTranslation = true,
    this.showFootnotes = false,
    this.showAyahNumber = false,
    this.showSurahName = true,
    this.frameStyle = AyahImageFrameStyle.simple,
    this.headerStyle = AyahImageHeaderStyle.simple,
    this.ayahTextAlign = AyahImageTextAlign.center,
    this.ayahLineHeight = 2,
    this.ayahLetterSpacing = 0,
    this.translationFontSize = 14,
    this.translationLineHeight = 1.6,
    this.translationMaxLines = 4,
    this.tafsirFontSize = 13,
    this.tafsirLineHeight = 1.8,
    this.tafsirMaxLines = 3,
    this.footnotesFontSize = 12,
    this.footnotesLineHeight = 1.6,
    this.footnotesMaxLines = 3,
    this.footnotesBoxed = true,
    this.headerBannerHeight = 56,
    this.headerBannerOpacity = 0.12,
    this.headerBannerAlign = AyahImageHeaderAlign.center,
    this.showSurahMeaning = false,
  });

  AyahImageSettings copyWith({
    AyahImageBackground? background,
    AyahImageAspectRatio? aspectRatio,
    AyahImageFontSize? fontSize,
    AyahImageFontType? fontType,
    double? contentPadding,
    AyahImageExportQuality? exportQuality,
    WatermarkSettings? watermark,
    bool? showTafsir,
    bool? showTranslation,
    bool? showFootnotes,
    bool? showAyahNumber,
    bool? showSurahName,
    AyahImageFrameStyle? frameStyle,
    AyahImageHeaderStyle? headerStyle,
    AyahImageTextAlign? ayahTextAlign,
    double? ayahLineHeight,
    double? ayahLetterSpacing,
    double? translationFontSize,
    double? translationLineHeight,
    int? translationMaxLines,
    double? tafsirFontSize,
    double? tafsirLineHeight,
    int? tafsirMaxLines,
    double? footnotesFontSize,
    double? footnotesLineHeight,
    int? footnotesMaxLines,
    bool? footnotesBoxed,
    double? headerBannerHeight,
    double? headerBannerOpacity,
    AyahImageHeaderAlign? headerBannerAlign,
    bool? showSurahMeaning,
  }) {
    return AyahImageSettings(
      background: background ?? this.background,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      fontSize: fontSize ?? this.fontSize,
      fontType: fontType ?? this.fontType,
      contentPadding: contentPadding ?? this.contentPadding,
      exportQuality: exportQuality ?? this.exportQuality,
      watermark: watermark ?? this.watermark,
      showTafsir: showTafsir ?? this.showTafsir,
      showTranslation: showTranslation ?? this.showTranslation,
      showFootnotes: showFootnotes ?? this.showFootnotes,
      showAyahNumber: showAyahNumber ?? this.showAyahNumber,
      showSurahName: showSurahName ?? this.showSurahName,
      frameStyle: frameStyle ?? this.frameStyle,
      headerStyle: headerStyle ?? this.headerStyle,
      ayahTextAlign: ayahTextAlign ?? this.ayahTextAlign,
      ayahLineHeight: ayahLineHeight ?? this.ayahLineHeight,
      ayahLetterSpacing: ayahLetterSpacing ?? this.ayahLetterSpacing,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      translationLineHeight:
          translationLineHeight ?? this.translationLineHeight,
      translationMaxLines: translationMaxLines ?? this.translationMaxLines,
      tafsirFontSize: tafsirFontSize ?? this.tafsirFontSize,
      tafsirLineHeight: tafsirLineHeight ?? this.tafsirLineHeight,
      tafsirMaxLines: tafsirMaxLines ?? this.tafsirMaxLines,
      footnotesFontSize: footnotesFontSize ?? this.footnotesFontSize,
      footnotesLineHeight: footnotesLineHeight ?? this.footnotesLineHeight,
      footnotesMaxLines: footnotesMaxLines ?? this.footnotesMaxLines,
      footnotesBoxed: footnotesBoxed ?? this.footnotesBoxed,
      headerBannerHeight: headerBannerHeight ?? this.headerBannerHeight,
      headerBannerOpacity: headerBannerOpacity ?? this.headerBannerOpacity,
      headerBannerAlign: headerBannerAlign ?? this.headerBannerAlign,
      showSurahMeaning: showSurahMeaning ?? this.showSurahMeaning,
    );
  }

}

enum AyahImageHeaderAlign {
  center,
  right,
  left,
}

extension AyahImageHeaderAlignExt on AyahImageHeaderAlign {
  String getDisplayName() {
    switch (this) {
      case AyahImageHeaderAlign.center:
        return "وسط";
      case AyahImageHeaderAlign.right:
        return "يمين";
      case AyahImageHeaderAlign.left:
        return "يسار";
    }
  }

  TextAlign toTextAlign() {
    switch (this) {
      case AyahImageHeaderAlign.center:
        return TextAlign.center;
      case AyahImageHeaderAlign.right:
        return TextAlign.right;
      case AyahImageHeaderAlign.left:
        return TextAlign.left;
    }
  }
}

enum AyahImageTextAlign {
  center,
  right,
  justify,
}

extension AyahImageTextAlignExt on AyahImageTextAlign {
  String getDisplayName() {
    switch (this) {
      case AyahImageTextAlign.center:
        return "وسط";
      case AyahImageTextAlign.right:
        return "يمين";
      case AyahImageTextAlign.justify:
        return "ضبط";
    }
  }

  TextAlign toTextAlign() {
    switch (this) {
      case AyahImageTextAlign.center:
        return TextAlign.center;
      case AyahImageTextAlign.right:
        return TextAlign.right;
      case AyahImageTextAlign.justify:
        return TextAlign.justify;
    }
  }
}
/// جودة تصدير الصورة (تؤثر على pixelRatio أثناء الالتقاط)
enum AyahImageExportQuality {
  standard,
  hd,
  ultra,
}

extension AyahImageExportQualityExt on AyahImageExportQuality {
  String getDisplayName() {
    switch (this) {
      case AyahImageExportQuality.standard:
        return "Standard";
      case AyahImageExportQuality.hd:
        return "HD";
      case AyahImageExportQuality.ultra:
        return "Ultra";
    }
  }

  double getPixelRatio() {
    switch (this) {
      case AyahImageExportQuality.standard:
        return 2.0;
      case AyahImageExportQuality.hd:
        return 3.0;
      case AyahImageExportQuality.ultra:
        return 4.0;
    }
  }
}

/// خيارات الخلفية
enum AyahImageBackground {
  light,           // أبيض/كريمي
  dark,            // داكن
  gradientGold,    // تدرج ذهبي
  gradientGreen,   // تدرج أخضر
  gradientBlue,    // تدرج أزرق
  transparent,     // شفاف
}

/// مقاسات جاهزة لنسبة أبعاد الصورة
enum AyahImageAspectRatio {
  auto, // يعتمد على المحتوى
  square, // 1:1
  post, // 4:5
  story, // 9:16
}

extension AyahImageAspectRatioExt on AyahImageAspectRatio {
  double? getValue() {
    switch (this) {
      case AyahImageAspectRatio.auto:
        return null;
      case AyahImageAspectRatio.square:
        return 1;
      case AyahImageAspectRatio.post:
        return 4 / 5;
      case AyahImageAspectRatio.story:
        return 9 / 16;
    }
  }

  String getDisplayName() {
    switch (this) {
      case AyahImageAspectRatio.auto:
        return "تلقائي";
      case AyahImageAspectRatio.square:
        return "1:1";
      case AyahImageAspectRatio.post:
        return "4:5";
      case AyahImageAspectRatio.story:
        return "9:16";
    }
  }
}

/// أحجام الخط
enum AyahImageFontSize {
  small,   // 18
  medium,  // 24
  large,   // 32
  xlarge,  // 40
}

/// أنواع الخطوط
enum AyahImageFontType {
  uthmanic,  // خط عثماني
  amiri,     // أميري
  noto,      // Noto Naskh
  scheherazade, // شهرزاد
}

/// أنماط الإطار
enum AyahImageFrameStyle {
  none,       // بدون إطار
  simple,     // إطار بسيط
  decorated,  // إطار مزخرف
  islamic,    // إطار إسلامي
}

/// أنماط الهيدر (عنوان السورة) في صورة المشاركة
enum AyahImageHeaderStyle {
  none,
  simple,
  banner,
}

extension AyahImageHeaderStyleExt on AyahImageHeaderStyle {
  String getDisplayName() {
    switch (this) {
      case AyahImageHeaderStyle.none:
        return "إخفاء";
      case AyahImageHeaderStyle.simple:
        return "بسيط";
      case AyahImageHeaderStyle.banner:
        return "بانر";
    }
  }
}

/// إعدادات العلامة المائية
class WatermarkSettings {
  /// إظهار العلامة المائية
  final bool enabled;
  
  /// نص العلامة المائية (فارغ = اسم التطبيق الافتراضي)
  final String? customText;
  
  /// موضع العلامة المائية
  final WatermarkPosition position;
  
  /// شفافية العلامة المائية
  final double opacity;

  const WatermarkSettings({
    this.enabled = true,
    this.customText,
    this.position = WatermarkPosition.bottomRight,
    this.opacity = 0.3,
  });

  WatermarkSettings copyWith({
    bool? enabled,
    String? customText,
    WatermarkPosition? position,
    double? opacity,
  }) {
    return WatermarkSettings(
      enabled: enabled ?? this.enabled,
      customText: customText ?? this.customText,
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// موضع العلامة المائية
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

/// Extension methods للحصول على قيم فعلية
extension AyahImageBackgroundExt on AyahImageBackground {
  /// الحصول على لون الخلفية
  Color getBackgroundColor() {
    switch (this) {
      case AyahImageBackground.light:
        return const Color(0xFFF5F5DC); // كريمي
      case AyahImageBackground.dark:
        return const Color(0xFF1C1C1E);
      case AyahImageBackground.transparent:
        return Colors.transparent;
      default:
        return const Color(0xFFF5F5DC);
    }
  }

  /// الحصول على تدرج الخلفية
  Gradient? getGradient() {
    switch (this) {
      case AyahImageBackground.gradientGold:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8DC), Color(0xFFD4AF37), Color(0xFFB8860B)],
        );
      case AyahImageBackground.gradientGreen:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D5A27), Color(0xFF1A3520), Color(0xFF0D1A10)],
        );
      case AyahImageBackground.gradientBlue:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        );
      default:
        return null;
    }
  }

  /// لون النص المناسب للخلفية
  Color getTextColor() {
    switch (this) {
      case AyahImageBackground.light:
        return Colors.black87;
      case AyahImageBackground.dark:
      case AyahImageBackground.gradientGold:
      case AyahImageBackground.gradientGreen:
      case AyahImageBackground.gradientBlue:
        return Colors.white;
      case AyahImageBackground.transparent:
        return Colors.black87;
    }
  }
}

extension AyahImageFontSizeExt on AyahImageFontSize {
  double getValue() {
    switch (this) {
      case AyahImageFontSize.small:
        return 18.0;
      case AyahImageFontSize.medium:
        return 24.0;
      case AyahImageFontSize.large:
        return 32.0;
      case AyahImageFontSize.xlarge:
        return 40.0;
    }
  }
}

extension AyahImageFontTypeExt on AyahImageFontType {
  String getFontFamily() {
    switch (this) {
      case AyahImageFontType.uthmanic:
        return "KFGQPC-Uthmanic-HAFS-Regular";
      case AyahImageFontType.amiri:
        return "AlQuranNeov5x1";
      case AyahImageFontType.noto:
        return "QPC_Hafs";
      case AyahImageFontType.scheherazade:
        return "IndopakNastaleeq";
    }
  }

  String getDisplayName() {
    switch (this) {
      case AyahImageFontType.uthmanic:
        return "خط عثماني";
      case AyahImageFontType.amiri:
        return "أميري";
      case AyahImageFontType.noto:
        return "نوتو نسخ";
      case AyahImageFontType.scheherazade:
        return "شهرزاد";
    }
  }
}
