import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:qcf_quran/src/helpers/woff_to_ttf.dart';

/// Top-level function to run Zip decoding in a background isolate
void _extractZipIsolate(Map<String, dynamic> args) {
  final Uint8List bytes = args['bytes'];
  final String dirPath = args['dirPath'];

  final archive = ZipDecoder().decodeBytes(bytes);
  int extractedCount = 0;
  for (final file in archive) {
    if (file.isFile && file.name.endsWith('.woff')) {
      final filename = file.name.split('/').last;
      // Convert WOFF → TTF on extraction so Flutter can render them
      final woffBytes = Uint8List.fromList(file.content as List<int>);
      final ttfBytes = woffToTtf(woffBytes);
      final ttfName = filename.replaceAll('.woff', '.ttf');
      final outFile = File('$dirPath/$ttfName');
      outFile.writeAsBytesSync(ttfBytes);
      extractedCount++;
    }
  }
  debugPrint('[QCF_FONT] Extracted & converted $extractedCount fonts (WOFF→TTF) to $dirPath');
}

class DynamicFontLoader {
  static final Set<String> _loadedFonts = {};
  static final Map<String, Future<void>> _loadingTasks = {};

  static Future<void>? _zipExtractTask;

  /// Set to true in widget tests to bypass actual font loading
  static bool isTestMode = false;

  static Future<void> loadFont(int pageNumber) async {
    if (isTestMode) return;

    final fontName = 'QCF_P${pageNumber.toString().padLeft(3, '0')}';

    if (_loadedFonts.contains(fontName)) return;

    if (_loadingTasks.containsKey(fontName)) {
      return _loadingTasks[fontName];
    }

    final task = _extractAndLoadFont(fontName);
    _loadingTasks[fontName] = task;

    try {
      await task;
      _loadedFonts.add(fontName);
      debugPrint('[QCF_FONT] ✅ Loaded font: $fontName');
    } catch (e, stack) {
      debugPrint('[QCF_FONT] ❌ FAILED to load font $fontName: $e');
      debugPrint('[QCF_FONT] Stack: $stack');
      rethrow;
    } finally {
      _loadingTasks.remove(fontName);
    }
  }

  static Future<void> _extractZipIfNeeded(Directory dir) async {
    if (_zipExtractTask != null) {
      return _zipExtractTask;
    }

    _zipExtractTask = _doExtractZip(dir);
    try {
      await _zipExtractTask;
    } catch (e) {
      _zipExtractTask = null;
      rethrow;
    }
  }

  static Future<void> _doExtractZip(Directory dir) async {
    debugPrint('[QCF_FONT] Loading zip from assets...');
    final byteData = await rootBundle.load(
      'packages/qcf_quran/assets/fonts/qcf4.zip',
    );
    final bytes = byteData.buffer.asUint8List();
    debugPrint('[QCF_FONT] Zip loaded (${bytes.length} bytes). Extracting & converting WOFF→TTF...');

    await compute(_extractZipIsolate, {'bytes': bytes, 'dirPath': dir.path});
    debugPrint('[QCF_FONT] Extraction complete.');
  }

  static Future<void> _extractAndLoadFont(String fontName) async {
    final dir = await getApplicationDocumentsDirectory();
    final pageStr = fontName.substring(5); // "001" from "QCF_P001"

    // Look for TTF file first (converted from WOFF), then fallback to WOFF
    final ttfFileName = 'QCF4${pageStr}_X-Regular.ttf';
    final woffFileName = 'QCF4${pageStr}_X-Regular.woff';
    File fontFile = File('${dir.path}/$ttfFileName');

    if (!await fontFile.exists()) {
      // Maybe old extraction left .woff files, check
      final woffFile = File('${dir.path}/$woffFileName');
      if (await woffFile.exists()) {
        // Delete old woff files and re-extract
        await woffFile.delete();
      }
      await _extractZipIfNeeded(dir);
    }

    if (!await fontFile.exists()) {
      throw Exception('Font file $ttfFileName not found after extraction');
    }

    final fontLoader = FontLoader(fontName);
    fontLoader.addFont(_readFontFile(fontFile));
    await fontLoader.load();
  }

  static Future<ByteData> _readFontFile(File file) async {
    final bytes = await file.readAsBytes();
    return ByteData.view(bytes.buffer);
  }
}
