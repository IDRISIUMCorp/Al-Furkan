import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// التصميم المرجعي اللي حسبنا عليه الأبعاد (من تطبيق quran_library)
const double _quranLibraryDesignWidth = 392.7;

double getFontSize(int pageIndex, BuildContext context) {
  final media = MediaQuery.of(context);
  final width = media.size.width;
  final isLandscape = media.orientation == Orientation.landscape;
  final shortestSide = media.size.shortestSide;

  // تحويل الـ pageIndex لرقم الصفحة الفعلي (يبدأ من 1)
  final page = pageIndex;

  // 1. حساب نسبة التكبير/التصغير بناءً على عرض الشاشة الفعلي مقارنة بالمقاس الافتراضي
  double ratio = (width / _quranLibraryDesignWidth).clamp(0.6, 1.8);
  
  // 2. القيمة الأساسية للخط التي نضربها في الـ Ratio
  double size = 23.1 * ratio;

  // 3. تعديل في وضع Landscape عشان الخط ميطولش برا الشاشة والأبعاد متضربش
  if (isLandscape) {
    size *= 0.85; 
  }

  // 4. تعديلات الشاشات الضخمة (التابلت والويب)
  if (shortestSide > 600) {
    // تقليل الحجم في التابلت لأن التمدد بنسبة العرض بيخلي الكلمة عملاقة 
    size = 18.0 * ratio;
    if (isLandscape) size *= 0.8;
  }

  // 5. تعديلات خاصة للصفحات اللي فيها هوامش كبيرة أو مزخرفة (زي الفاتحة وبداية البقرة)
  if (page == 1 || page == 2) {
    size *= 1.1; // نكبره شوية في البداية لأن السورتين قصيرتين
  }

  // 6. صفحات خاصة تحتاج لضبط دقيق كما في المكتبة المرجعية quran_library
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
  } else if (page == 70) {
    size = 23.5 * ratio;
  } else if (page == 51 || page == 501) {
    size = 23.7 * ratio;
  }

  // 7. Clamp لحدود آمنة جداً
  // أقل خط 16 وأكبر خط 45 عشان الشاشات متكسرش
  return size.clamp(16.0, 45.0);
}

enum ScreenType { small, medium, large }

ScreenType getScreenType(BuildContext context) {
  final double screenWidth = MediaQuery.sizeOf(context).width;

  if (screenWidth < 360) {
    return ScreenType.small;
  } else if (screenWidth >= 360 && screenWidth < 600) {
    return ScreenType.medium;
  } else {
    return ScreenType.large;
  }
}
