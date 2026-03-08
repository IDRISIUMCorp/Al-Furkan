import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  String contents = file.readAsStringSync();
  
  // Find the start of the qcf fonts
  final startIdx = contents.indexOf('    - family: QCF_P001');
  if (startIdx == -1) {
    print('Could not find start index');
    return;
  }
  
  // Keep everything before the fonts
  final beforeFonts = contents.substring(0, startIdx);
  
  final sb = StringBuffer();
  sb.write(beforeFonts);
  
  // Generate the new block
  for (var i = 1; i <= 604; i++) {
    final pageNumStr = i.toString().padLeft(3, '0'); // 001, 100, etc.
    final fileNumStr = i.toString().padLeft(3, '0'); // For file name, it is QCF4 + 001
    
    final family = 'QCF_P$pageNumStr';
    final fileName = 'QCF4${fileNumStr}_X-Regular.woff';
    
    sb.writeln('    - family: $family');
    sb.writeln('      fonts:');
    sb.writeln('        - asset: assets/fonts/qcf4/$fileName');
  }
  
  file.writeAsStringSync(sb.toString());
  print('Updated pubspec.yaml');
}
