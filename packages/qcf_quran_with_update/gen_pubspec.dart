import 'dart:io';

void main() {
  final sb = StringBuffer();
  
  // Header
  sb.writeln('''name: qcf_quran
description: "High-fidelity Quran Mushaf (QCF) rendering with per-page bundled fonts. Includes widgets for a single ayah (QcfVerse) and a full RTL PageView mushaf (PageviewQuran), plus search and helpers."
version: 0.0.5
homepage: https://github.com/m4hmoud-atef/qcf_quran
repository: https://github.com/m4hmoud-atef/qcf_quran
issue_tracker: https://github.com/m4hmoud-atef/qcf_quran/issues
topics:
  - flutter
  - quran
  - arabic
  - fonts
  - qcf
screenshots:
  - description: Quran page view
    path: assets/Screenshot_1756290211.png
  - description: Search and verse
    path: assets/Screenshot_1756290218.png

environment:
  sdk: ">=3.7.0 <4.0.0"
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_animate: ^4.5.2
  flutter_screenutil: ^5.9.3
  html: ^0.15.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  assets:
    - assets/
  fonts:

    - family: "arsura"
      fonts:
        - asset: assets/fonts/arsura.ttf

    - family: "surahname"
      fonts:
        - asset: assets/fonts/surah-name-v2.woff

    - family: "versenumber"
      fonts:
        - asset: assets/fonts/versenumbers-Regular.otf
    - family: QCF_BSML 
      fonts:
        - asset: assets/fonts/QCF2BSMLfonts/QCF4_QBSML-Regular.woff''');

  // Generate 604 font families
  for (int i = 1; i <= 604; i++) {
    final padded = i.toString().padLeft(3, '0');
    sb.writeln('''    - family: QCF_P$padded
      fonts:
        - asset: assets/fonts/qcf4/QCF4${padded}_X-Regular.ttf
''');
  }

  File(r'E:\@MyApp\al_quran_v3-main\packages\qcf_quran_with_update\pubspec.yaml')
      .writeAsStringSync(sb.toString());
  
  print('Generated pubspec.yaml with 604 font families');
}
