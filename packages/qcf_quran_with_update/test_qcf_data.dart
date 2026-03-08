import 'package:qcf_quran/qcf_quran.dart';

void main() {
  final verse1 = getVerseQCF(1, 1, verseEndSymbol: false);
  print('Verse 1 length: \${verse1.length}');
  print('Verse 1 text: "\$verse1"');
  
  final fullVerse1 = getVerseQCF(1, 1, verseEndSymbol: true);
  print('Full Verse 1 length: \${fullVerse1.length}');
  print('Full Verse 1 text: "\$fullVerse1"');
}
