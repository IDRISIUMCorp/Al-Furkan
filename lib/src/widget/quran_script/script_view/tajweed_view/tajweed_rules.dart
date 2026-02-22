import "package:flutter/material.dart";

import "color/tajweed_dark.dart";
import "color/tajweed_light.dart";

/// A utility class to access all Tajweed rule definitions.
class TajweedRules {
  /// A list of all Tajweed rule definition classes.
  /// You can iterate over this list to get all rule details.
  static const List<Type> all = [
    GhunnahRule,
    IdghamShafawiRule,
    IqlabRule,
    IkhafaShafawiRule,
    QalqalahRule,
    IdghamGhunnahRule,
    IdghamWoGhunnahRule,
    IkhafaRule,
    MaddTabiiRule,
    MaddLazimRule,
    MaddLeenRule,
    MaddWajibMuttasilRule,
    MaddJaizMunfasilRule,
    HamWaslRule,
    LaamShamsiyahRule,
    SlntRule,
    IdghamMutajanisaynRule,
    IdghamMutaqaribaynRule,
    CustomAlefMaksoraRule,
  ];
}

// 1. Ghunnah
class GhunnahRule {
  static const Color lightColor = lightGhunnah;
  static const Color darkColor = darkGhunnah;
  static const String key = "ghunnah";
  static const String description = """
  <b>الغُنَّة</b>
  <p>صوتٌ أنفي يخرج من الخيشوم ويُمدّ غالبًا بمقدار <b>حركتين</b>. وتكون في <b>النون (ن)</b> و<b>الميم (م)</b> إذا جاء عليهما <b>شدّة</b> (مثل: <b>نّ</b>، <b>مّ</b>).</p>
  <p><b>طريقة النطق:</b> ثبّت الصوت على الحرف مع إبقاء الغُنّة واضحة لمدة حركتين تقريبًا.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>إِنَّ</span>، <span style='font-family:QPC_Hafs'>ثُمَّ</span></p>
  """;
}

// 2. Idgham Shafawi
class IdghamShafawiRule {
  static const Color lightColor = lightIdghamShafawi;
  static const Color darkColor = darkIdghamShafawi;
  static const String key = "idgham_shafawi";
  static const String description = """
  <b>الإدغام الشفوي</b>
  <p>يكون إذا جاءت <b>ميم ساكنة (مْ)</b> وبعدها <b>ميم متحركة (م)</b>، فتُدغم الميم الساكنة في الميم التي بعدها مع <b>غُنّة</b>.</p>
  <p><b>طريقة النطق:</b> تُضم الشفتان للميم الثانية ويُحافظ على الغُنّة بمقدار حركتين.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>لَكُم مَّا</span></p>
  """;
}

// 3. Iqlab
class IqlabRule {
  static const Color lightColor = lightIqlab;
  static const Color darkColor = darkIqlab;
  static const String key = "iqlab";
  static const String description = """
  <b>الإقلاب</b>
  <p>يكون إذا جاءت <b>نون ساكنة (نْ)</b> أو <b>تنوين</b> وبعدهما حرف <b>الباء (ب)</b>. فيتحوّل صوت النون إلى <b>ميم مخفاة</b> مع <b>غُنّة</b>.</p>
  <p><b>طريقة النطق:</b> تُحوَّل النون إلى ميمٍ خفيّة مع غُنّة بمقدار حركتين قبل الباء.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>مِن بَعْدِ</span></p>
  """;
}

// 4. Ikhafa Shafawi
class IkhafaShafawiRule {
  static const Color lightColor = lightIkhafaShafawi;
  static const Color darkColor = darkIkhafaShafawi;
  static const String key = "ikhafa_shafawi";
  static const String description = """
  <b>الإخفاء الشفوي</b>
  <p>يكون إذا جاءت <b>ميم ساكنة (مْ)</b> وبعدها حرف <b>الباء (ب)</b>. تُخفى الميم إخفاءً شفويًا مع <b>غُنّة</b>.</p>
  <p><b>طريقة النطق:</b> تُنطق الميم بخفّة مع غُنّة، وتكون الشفتان في تماس خفيف (أو انفراج بسيط جدًا) استعدادًا للباء.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>تَرْمِيهِم بِحِجَارَةٍ</span></p>
  """;
}

// 5. Qalqalah
class QalqalahRule {
  static const Color lightColor = lightQalaqah;
  static const Color darkColor = darkQalaqah;
  static const String key = "qalaqah";
  static const String description = """
  <b>القلقلة</b>
  <p>هي اضطراب الصوت عند النطق بأحد حروف <b>قطب جد (ق ط ب ج د)</b> إذا كانت <b>ساكنة</b>.</p>
  <p><b>طريقة النطق:</b> يُسمع للحرف نبرة/ارتداد خفيف عند السكون بدون إضافة حركة زائدة.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>يَدْعُونَ</span>، <span style='font-family:QPC_Hafs'>خَلَقْنَا</span></p>
  """;
}

// 6. Idgham with Ghunnah
class IdghamGhunnahRule {
  static const Color lightColor = lightIdghamGhunnah;
  static const Color darkColor = darkIdghamGhunnah;
  static const String key = "idgham_ghunnah";
  static const String description = """
  <b>إدغام بغُنَّة</b>
  <p>يكون إذا جاءت <b>نون ساكنة</b> أو <b>تنوين</b> وبعدهما أحد حروف <b>ينمو (ي ن م و)</b>، فتُدغم النون في الحرف الذي بعدها مع <b>غُنّة</b> بمقدار حركتين.</p>
  <p><b>طريقة النطق:</b> تُسقط النون لفظًا وتُدخلها في الحرف التالي مع غُنّة واضحة.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>مَن يَقُولُ</span></p>
  """;
}

// 7. Idgham without Ghunnah
class IdghamWoGhunnahRule {
  static const Color lightColor = lightIdghamWoGhunnah;
  static const Color darkColor = darkIdghamWoGhunnah;
  static const String key = "idgham_wo_ghunnah";
  static const String description = """
  <b>إدغام بلا غُنَّة</b>
  <p>يكون إذا جاءت <b>نون ساكنة</b> أو <b>تنوين</b> وبعدهما <b>لام (ل)</b> أو <b>راء (ر)</b>، فتُدغم النون إدغامًا كاملًا <b>بدون غُنّة</b>.</p>
  <p><b>طريقة النطق:</b> تُسقط النون نهائيًا وتُشدّد الحرف الذي بعدها دون غُنّة.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>مِن لَدُنْهُ</span></p>
  """;
}

// 8. Ikhafa
class IkhafaRule {
  static const Color lightColor = lightIkhafa;
  static const Color darkColor = darkIkhafa;
  static const String key = "ikhafa";
  static const String description = """
  <b>الإخفاء</b>
  <p>يكون إذا جاءت <b>نون ساكنة</b> أو <b>تنوين</b> وبعدهما أحد حروف الإخفاء (خمسة عشر حرفًا). تُخفى النون مع <b>غُنّة</b>.</p>
  <p><b>طريقة النطق:</b> صوتٌ بين الإظهار والإدغام مع غُنّة بمقدار حركتين، مع تهيئة الفم للحرف التالي.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>الإِنسَانُ</span></p>
  """;
}

// 9. Madd Tabi'i (Normal)
class MaddTabiiRule {
  static const Color lightColor = lightMaddaNormal;
  static const Color darkColor = darkMaddaNormal;
  static const String key = "madda_normal";
  static const String description = """
  <b>المد الطبيعي</b>
  <p>هو مدّ حرف المد بمقدار <b>حركتين</b> دون سبب من همز أو سكون. ويكون في الألف بعد الفتحة، والياء بعد الكسرة، والواو بعد الضمة.</p>
  <p><b>طريقة النطق:</b> يُمدّ الصوت مدًّا طبيعيًا لا إفراط فيه ولا تقصير.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>قَالَ</span></p>
  """;
}

// 10. Madd Lazim (Necessary)
class MaddLazimRule {
  static const Color lightColor = lightMaddaNecessary;
  static const Color darkColor = darkMaddaNecessary;
  static const String key = "madda_necessary";
  static const String description = """
  <b>المد اللازم</b>
  <p>يكون إذا جاء <b>حرف المد</b> وبعده <b>سكون لازم</b> (أصلي) أو <b>شدّة</b>، ويُمدّ بمقدار <b>ست حركات</b>.</p>
  <p><b>طريقة النطق:</b> يُمدّ الصوت مدًّا طويلًا ثابتًا.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>الضَّالِّينَ</span></p>
  """;
}

// 11. Madd Leen (Permissible)
class MaddLeenRule {
  static const Color lightColor = lightMaddaPermissible;
  static const Color darkColor = darkMaddaPermissible;
  static const String key = "madda_permissible";
  static const String description = """
  <b>مدّ اللين</b>
  <p>يكون إذا جاءت <b>واو ساكنة</b> أو <b>ياء ساكنة</b> وقبلها <b>فتحة</b>، ثم وقف القارئ على الحرف الذي بعدها. ويُمدّ عند الوقف بمقدار <b>2 أو 4 أو 6</b> حركات.</p>
  <p><b>طريقة النطق:</b> يُمدّ صوت اللين بسلاسة عند الوقف.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>خَوْفٌ</span>، <span style='font-family:QPC_Hafs'>الْبَيْتِ</span></p>
  """;
}

// 12. Madd Wajib Muttasil (Obligatory Connected)
class MaddWajibMuttasilRule {
  static const Color lightColor = lightMaddaObligatoryMottasel;
  static const Color darkColor = darkMaddaObligatoryMottasel;
  static const String key = "madda_obligatory_mottasel";
  static const String description = """
  <b>المد الواجب المتصل</b>
  <p>يكون إذا جاء <b>حرف مد</b> وبعده <b>همزة (ء)</b> في <b>كلمة واحدة</b>. ويُمدّ غالبًا بمقدار <b>4 أو 5</b> حركات (بحسب الرواية/الأداء).</p>
  <p><b>طريقة النطق:</b> مدّ متوسط إلى طويل مع المحافظة على الهمزة بعده.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>السَّمَاءِ</span></p>
  """;
}

// 13. Madd Ja'iz Munfasil (Permissible Separate)
class MaddJaizMunfasilRule {
  static const Color lightColor = lightMaddaObligatoryMonfasel;
  static const Color darkColor = darkMaddaObligatoryMonfasel;
  static const String key = "madda_obligatory_monfasel";
  static const String description = """
  <b>المد الجائز المنفصل</b>
  <p>يكون إذا جاء <b>حرف مد</b> في آخر كلمة، ثم جاءت <b>همزة</b> في أول الكلمة التي بعدها. ويُمدّ غالبًا <b>4 أو 5</b> حركات (بحسب الرواية/الأداء).</p>
  <p><b>طريقة النطق:</b> مدّ متوسط إلى طويل مع بدء الهمزة بوضوح في الكلمة التالية.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>يَا أَيُّهَا</span></p>
  """;
}

// 14. Hamzat al-Wasl
class HamWaslRule {
  static const Color lightColor = lightHamWasl;
  static const Color darkColor = darkHamWasl;
  static const String key = "ham_wasl";
  static const String description = """
  <b>همزة الوصل</b>
  <p>تُنطق عند <b>الابتداء</b> بالكلمة وتسقط لفظًا عند <b>الوصل</b> بما قبلها.</p>
  <p><b>طريقة النطق:</b> عند الابتداء تُنطق بهمزة مناسبة للحركة، وعند الوصل تُترك ولا تُنطق.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>ٱهْدِنَا</span></p>
  """;
}

// 15. Lam Shamsiyyah
class LaamShamsiyahRule {
  static const Color lightColor = lightLaamShamsiyah;
  static const Color darkColor = darkLaamShamsiyah;
  static const String key = "laam_shamsiyah";
  static const String description = """
  <b>اللام الشمسية</b>
  <p>إذا جاءت (الـ) التعريف وبعدها <b>حرف شمسي</b>، فإن <b>اللام لا تُنطق</b> ويُشدّد الحرف الذي بعدها.</p>
  <p><b>طريقة النطق:</b> تُسقط اللام ويُشدّد الحرف الشمسي مباشرة.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>الشَّمْسُ</span></p>
  """;
}

// 16. Silent Letter
class SlntRule {
  static const Color lightColor = lightSlnt;
  static const Color darkColor = darkSlnt;
  static const String key = "slnt";
  static const String description = """
  <b>حرف صامت (لا يُنطق)</b>
  <p>حرف يُكتب في الرسم/الخط لكنه <b>لا يُنطق</b> عند القراءة.</p>
  <p><b>طريقة النطق:</b> يُترك الحرف تمامًا دون تلفّظ به.</p>
  <p><b>مثال:</b> الألف في آخر <span style='font-family:QPC_Hafs'>قَالُوا۟</span></p>
  """;
}

// 17. Idgham Mutajanisayn
class IdghamMutajanisaynRule {
  static const Color lightColor = lightIdghamMutajanisayn;
  static const Color darkColor = darkIdghamMutajanisayn;
  static const String key = "idgham_mutajanisayn";
  static const String description = """
  <b>إدغام المتماثلين/المتجانسين</b>
  <p>إدغام حرفين متقاربين/متجانسين في المخرج، بحيث يُدغم الأول في الثاني ويُشدّد الثاني.</p>
  <p><b>طريقة النطق:</b> يُترك الأول لفظًا وتُشدد الثاني.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>قَد تَبَيَّنَ</span></p>
  """;
}

// 18. Idgham Mutaqaribayn
class IdghamMutaqaribaynRule {
  static const Color lightColor = lightIdghamMutaqaribayn;
  static const Color darkColor = darkIdghamMutaqaribayn;
  static const String key = "idgham_mutaqaribayn";
  static const String description = """
  <b>إدغام المتقاربين</b>
  <p>إدغام حرفين <b>متقاربين</b> في المخرج بحيث يُدغم الأول في الثاني ويُشدّد الثاني.</p>
  <p><b>طريقة النطق:</b> يُترك الأول لفظًا ويُشدّد الثاني مباشرة.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>أَلَمْ نَخْلُقكُّم</span></p>
  """;
}

// 19. Custom Alef Maksora
class CustomAlefMaksoraRule {
  static const Color lightColor = lightCustomAlefMaksora;
  static const Color darkColor = darkCustomAlefMaksora;
  static const String key = "custom-alef-maksora";
  static const String description = """
  <b>الألف المقصورة</b>
  <p>تكتب على صورة (ى) وتُنطق <b>ألفًا</b> عند القراءة (مدّ طبيعي غالبًا).</p>
  <p><b>طريقة النطق:</b> تُنطق صوت "آ/ا" الطبيعي بمقدار حركتين عند وجود المد.</p>
  <p><b>مثال:</b> <span style='font-family:QPC_Hafs'>مُوسَىٰ</span></p>
  """;
}
