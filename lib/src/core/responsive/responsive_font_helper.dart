import 'package:flutter/material.dart';

/// المساعد الأساسي لضبط أحجام خطوط القرآن بناءً على الشاشة (مستوحى من مكتبة الحكمة).
class ResponsiveFontHelper {
  // التصميم الأساسي اللي التطبيق مبني عليه (كما في ScreenUtilInit)
  static const double _designWidth = 360.0;
  static const double _quranLibraryDesignWidth = 392.7;

  /// يحسب نسبة التكبير/التصغير بناءً على عرض الشاشة الفعلي.
  static double _getRatio(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // نستخدم نسبة من عرض التصميم ونضع حدوداً آمنة (Clamp) عشان الخط ميضربش في الشاشات الكبيرة جداً
    return (width / _quranLibraryDesignWidth).clamp(0.6, 1.8);
  }

  /// دالة مخصصة لصفحات القرآن بحسب الـ (Page Index)
  /// لوحات التابلت والويب بيتم تصغير الخط نسبياً عشان يحافظ على التنسيق والشاشة متتمطش.
  static double getQuranFontSize(BuildContext context, int pageIndex) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isLandscape = media.orientation == Orientation.landscape;
    final shortestSide = media.size.shortestSide;

    // تحويل الـ pageIndex لرقم الصفحة الفعلي (يبدأ من 1)
    final page = pageIndex + 1;

    // 1. حساب الحجم المبدئي بناءً على الـ Ratio الخاص بعرض الشاشة
    double ratio = _getRatio(context);
    
    // 2. القيمة الأساسية للخط (Base Value) التي نضربها في الـ Ratio
    double size = 23.1 * ratio;

    // 3. تعديل في وضع Landscape عشان الخط ميطولش برا الشاشة
    if (isLandscape) {
      size *= 0.85; 
    }

    // 4. تعديلات الشاشات الضخمة (التابلت والويب)
    if (shortestSide > 600) {
      // نقلل الحجم في التابلت لأن العرض كبير جداً ومش عايزين الكلمة تبقى عملاقة بشكل مزعج
      size = 18.0 * ratio;
      if (isLandscape) size *= 0.8;
    }

    // 5. تعديلات خاصة للصفحات اللي فيها هوامش كبيرة أو مزخرفة (زي الفاتحة وبداية البقرة)
    if (page == 1 || page == 2) {
      size *= 1.1; // نكبره شوية في البداية لأن السورتين قصيرتين
    }

    // 6. صفحات خاصة تحتاج لضبط دقيق كما في مكتبة quran_library
    final size23Pages = [
      56, 57, 368, 269, 372, 376, 409, 435, 444, 448, 527, 535, 565, 566, 569,
      574, 578, 581, 584, 587, 589, 590, 592, 593, 50, 568, 34
    ];
    if (size23Pages.contains(page)) {
      size = 23.0 * ratio;
    } else if (page == 145 || page == 585) {
      size = 22.7 * ratio;
    } else if ([532, 533, 523, 577].contains(page)) {
      size = 22.5 * ratio;
    } else if (page == 116 || page == 156) {
      size = 23.4 * ratio;
    }

    // 7. Clamp لحدود آمنة جداً
    // أقل خط ممكن 16 وأكبر خط 38
    return size.clamp(16.0, 38.0);
  }

  /// حجم خطوط التفسير والتراجم
  static double getTafsirFontSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    double ratio = (width / _designWidth).clamp(0.8, 1.4);
    double base = 18.0 * ratio;
    
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      base *= 0.9;
    }
    return base.clamp(14.0, 26.0);
  }
}
