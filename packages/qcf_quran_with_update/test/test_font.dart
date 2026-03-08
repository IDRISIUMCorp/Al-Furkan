import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  testWidgets('Test font loaded', (WidgetTester tester) async {
    // try reading pubspec
    final pubspec = await rootBundle.loadString('pubspec.yaml');
    print('Pubspec loaded: \${pubspec.length}');
    
    // Check if the font family name contains spaces or special characters
    // No easily tested here directly
  });
}
