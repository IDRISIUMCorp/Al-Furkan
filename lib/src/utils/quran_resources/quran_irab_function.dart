import "package:hive_ce_flutter/hive_flutter.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "dart:convert";
import "package:flutter/services.dart";

import "dart:developer";

class QuranIrabFunction {
  static const String _selectedIrabKey = "selected_irab_book";
  static const String _downloadedIrabKey = "downloaded_irab_books";

  static const String defaultBoxName = "irab_ar_alrab_al_quran_li_da_as";

  static const Map<String, dynamic> defaultIrabMeta = {
    "language": "Arabic",
    "name": "إعراب القرآن (Alrab Al-Quran li-Da'as)",
    "source": "alrab-al-quran-li-da-as",
  };

  static Future<void> init() async {
    if (!Hive.isBoxOpen("user")) {
      await Hive.openBox("user");
    }

    final userBox = Hive.box("user");
    final selected = userBox.get(_selectedIrabKey);
    if (selected == null) return;

    if (selected == defaultBoxName) {
      if (!Hive.isBoxOpen(defaultBoxName)) {
        await Hive.openLazyBox(defaultBoxName);
      }
    }
  }

  static Future<LazyBox> openDefaultBox() async {
    if (!Hive.isBoxOpen(defaultBoxName)) {
      return Hive.openLazyBox(defaultBoxName);
    }
    return Hive.lazyBox(defaultBoxName);
  }

  static String? getSelectedIrabBoxName() {
    final userBox = Hive.box("user");
    return userBox.get(_selectedIrabKey) as String?;
  }

  static Future<void> setDefaultSelected() async {
    final userBox = Hive.box("user");
    await userBox.put(_selectedIrabKey, defaultBoxName);

    final List<dynamic> downloaded =
        List<dynamic>.from(userBox.get(_downloadedIrabKey, defaultValue: []));
    if (!downloaded.contains(defaultBoxName)) {
      downloaded.add(defaultBoxName);
      await userBox.put(_downloadedIrabKey, downloaded);
    }

    await init();
  }

  static Map<String, dynamic>? _irabCache;

  static Future<String?> getIrabText(String ayahKey) async {
    if (_irabCache == null) {
      try {
        final jsonString = await rootBundle.loadString('packages/alrab-al-quran-li-da-as.json');
        _irabCache = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        log("Error loading Irab JSON: $e", name: "QuranIrabFunction");
        return null;
      }
    }

    final normalized = ayahKey.trim();
    String fetchKey = normalized;
    final parts = normalized.split(":");
    if (parts.length == 2) {
      final s = int.tryParse(parts[0]);
      final a = int.tryParse(parts[1]);
      if (s != null && a != null) {
        fetchKey = "$s:$a";
      }
    }

    final data = _irabCache![fetchKey];
    if (data == null) {
      log("[Irab] not found for ayahKey=$ayahKey fetchKey=$fetchKey", name: "QuranIrabFunction");
      return null;
    }

    if (data is String) {
      // If it's a pointer to another ayah text (e.g. "1:2": "1:1")
      if (data.contains(':')) {
        return await getIrabText(data);
      }
      return data;
    }

    if (data is Map) {
      final dynamic text = data["text"] ?? data["tafsir"];
      if (text is String) return text;
      if (text is Map) {
        final inner = text["text"];
        if (inner is String) return inner;
      }
    }

    return null;
  }

  static Future<Map?> getMetaInfoAsync() async {
    if (await Hive.boxExists(defaultBoxName)) {
      final box = await Hive.openLazyBox(defaultBoxName);
      try {
        final data = await box.get("meta_data");
        await box.close();
        return data as Map?;
      } catch (_) {
        await box.close();
        return null;
      }
    }
    return null;
  }

  static Future<List<TafsirBookModel>?> getIrabSelections() async {
    // For now, return a single dummy book model representing the built-in Irab database wrapper
    return [
      TafsirBookModel(
        language: "arabic",
        name: defaultIrabMeta["name"],
        totalAyahs: 6236,
        hasTafsir: 1,
        score: 1.0,
        fullPath: defaultBoxName,
      )
    ];
  }

  static Future<String?> getResolvedIrabTextForBook(
    TafsirBookModel book,
    String ayahKey,
  ) async {
     // Using the existing built-in Irab resolver as the backend
     return await getIrabText(ayahKey);
  }
}
