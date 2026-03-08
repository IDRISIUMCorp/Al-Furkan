import 'dart:io';
import 'package:archive/archive.dart';

void main() {
  final bytes = File(r'E:\@MyApp\al_quran_v3-main\packages\qcf_quran_with_update\assets\fonts\qcf4.zip').readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  int count = 0;
  for (final file in archive) {
    if (file.isFile && file.name.endsWith('.woff')) {
      count++;
      if (count <= 10) {
        print('${file.name} (${file.size} bytes)');
      }
    }
  }
  print('Total .woff files: $count');
  
  // Also check for any other file types
  for (final file in archive) {
    if (file.isFile && !file.name.endsWith('.woff')) {
      print('Non-woff: ${file.name}');
    }
  }
}
