import "dart:convert";

import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_irab_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

class DefaultOfflineResources {
  static const String _installFlagKey = "default_offline_resources_installed_v2";
  static const String _enforceFlagKey =
      "default_offline_resources_enforced_v2";

  static const String _muyassarJsonAsset = "packages/ar-tafsir-muyassar.json";

  static final TafsirBookModel defaultTafsirMuyassar = TafsirBookModel(
    language: "Arabic",
    name: "التفسير الميسر",
    totalAyahs: 6236,
    hasTafsir: 5278,
    score: 84,
    fullPath: "bundled/Arabic/Tafsir_Muyassar.json",
  );

  static const String remoteMuyassarFullPath =
      "quranic_universal_library/compressed_tafsir/Arabic/Tafsir_Muyassar.json.txt";

  static Future<void> ensureInstalled() async {
    if (!Hive.isBoxOpen("user")) {
      await Hive.openBox("user");
    }

    final userBox = Hive.box("user");

    // Always keep user selections clean (fast operation, no heavy IO)
    await _cleanupDuplicateMuyassar();

    final tafsirBoxName = QuranTafsirFunction.getTafsirBoxName(
      tafsirBook: defaultTafsirMuyassar,
    );

    await _ensureBoxHasAyahDataOrReinstall(
      boxName: tafsirBoxName,
      reinstall: _installMuyassarTafsir,
    );

    final bool alreadyEnforced =
        userBox.get(_enforceFlagKey, defaultValue: false) == true;
    if (!alreadyEnforced) {
      await userBox.put(_enforceFlagKey, true);
    }

    // Always ensure I'rab data is installed (idempotent - skips if already loaded)
    await _installIrabData();

    final bool alreadyInstalled =
        userBox.get(_installFlagKey, defaultValue: false) == true;
    if (alreadyInstalled) {
      // Do NOT force-enable Muyassar every start.
      // Only auto-select if the user has no tafsir selected at all.
      final currentSelections = await QuranTafsirFunction.getTafsirSelections();
      if (currentSelections == null || currentSelections.isEmpty) {
        await QuranTafsirFunction.setTafsirSelection(defaultTafsirMuyassar);
      }
      return;
    }

    await _installMuyassarTafsir();

    // First install: make sure at least one tafsir is enabled (Muyassar).
    final currentSelections = await QuranTafsirFunction.getTafsirSelections();
    if (currentSelections == null || currentSelections.isEmpty) {
      await QuranTafsirFunction.setTafsirSelection(defaultTafsirMuyassar);
    }

    await userBox.put(_installFlagKey, true);
  }

  static Future<void> _ensureBoxHasAyahDataOrReinstall({
    required String boxName,
    required Future<void> Function() reinstall,
  }) async {
    bool exists = await Hive.boxExists(boxName);
    if (!exists) {
      await reinstall();
      return;
    }

    try {
      final box = await Hive.openLazyBox(boxName);
      final v = await box.get("1:1", defaultValue: null);
      if (v != null) return;
    } catch (_) {
      // Fallthrough to reinstall
    }

    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.lazyBox(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
    } catch (_) {}

    await reinstall();
  }

  static Future<void> _installMuyassarTafsir() async {
    final boxName = QuranTafsirFunction.getTafsirBoxName(
      tafsirBook: defaultTafsirMuyassar,
    );

    final LazyBox box = await Hive.openLazyBox(boxName);

    final String jsonString = await rootBundle.loadString(_muyassarJsonAsset);
    final Map<dynamic, dynamic> data = await compute(_decodeJsonToMap, jsonString);

    for (final entry in data.entries) {
      await box.put(entry.key, entry.value);
    }

    await box.put("meta_data", defaultTafsirMuyassar.toMap());

    await QuranTafsirFunction.setToListAlreadyDownloaded(
      tafsirBook: defaultTafsirMuyassar,
    );

    await QuranTafsirFunction.setTafsirSelection(defaultTafsirMuyassar);
  }

  static Future<void> _cleanupDuplicateMuyassar() async {
    final userBox = Hive.box("user");

    final List<dynamic> downloadedRaw =
        List<dynamic>.from(userBox.get(QuranTafsirFunction.downloadedTafsirBooksKey, defaultValue: []));

    final downloaded = downloadedRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final cleanedDownloaded = downloaded
        .where((m) {
          final name = (m["name"] ?? "").toString();
          final fullPath = (m["full_path"] ?? "").toString();
          final isMuyassarByName = name.trim() == "التفسير الميسر";
          final isMuyassarByPath = fullPath.toLowerCase().contains("muyassar");
          final isBundled = fullPath == defaultTafsirMuyassar.fullPath;
          final isRemote = fullPath == remoteMuyassarFullPath;
          if ((isMuyassarByName || isMuyassarByPath) && !isBundled) {
            return false;
          }
          if (isRemote) {
            return false;
          }
          return true;
        })
        .toList();

    await userBox.put(QuranTafsirFunction.downloadedTafsirBooksKey, cleanedDownloaded);

    final List<dynamic> selectedRaw =
        List<dynamic>.from(userBox.get(QuranTafsirFunction.selectedTafsirListKey, defaultValue: []));
    final selected = selectedRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final cleanedSelected = selected
        .where((m) {
          final name = (m["name"] ?? "").toString();
          final fullPath = (m["full_path"] ?? "").toString();
          final isMuyassarByName = name.trim() == "التفسير الميسر";
          final isMuyassarByPath = fullPath.toLowerCase().contains("muyassar");
          final isBundled = fullPath == defaultTafsirMuyassar.fullPath;
          final isRemote = fullPath == remoteMuyassarFullPath;
          if ((isMuyassarByName || isMuyassarByPath) && !isBundled) {
            return false;
          }
          if (isRemote) {
            return false;
          }
          return true;
        })
        .toList();

    await userBox.put(QuranTafsirFunction.selectedTafsirListKey, cleanedSelected);

    // If remote Muyassar was previously downloaded, delete its Hive box so it stops showing.
    try {
      final remote = defaultTafsirMuyassar.copyWith(fullPath: remoteMuyassarFullPath);
      final remoteBoxName = QuranTafsirFunction.getTafsirBoxName(tafsirBook: remote);
      if (await Hive.boxExists(remoteBoxName)) {
        if (Hive.isBoxOpen(remoteBoxName)) {
          await Hive.lazyBox(remoteBoxName).close();
        }
        await Hive.deleteBoxFromDisk(remoteBoxName);
      }
    } catch (_) {}
  }

  static Map<dynamic, dynamic> _decodeJsonToMap(String source) {
    final decoded = jsonDecode(source);
    if (decoded is Map) return decoded;
    return {};
  }

  /// Install the bundled I'rab (grammatical analysis) database from the local JSON asset.
  static Future<void> _installIrabData() async {
    const irabBoxName = QuranIrabFunction.defaultBoxName;

    // Si already installed and has data, skip
    if (await Hive.boxExists(irabBoxName)) {
      LazyBox box;
      try {
        box = Hive.isBoxOpen(irabBoxName)
            ? Hive.lazyBox(irabBoxName)
            : await Hive.openLazyBox(irabBoxName);
        final v = await box.get("1:1", defaultValue: null);
        if (v != null) {
          // Data already loaded, just ensure selection
          await QuranIrabFunction.setDefaultSelected();
          return;
        }
      } catch (_) {
        // Fallthrough to reinstall
      }
    }

    // Load JSON from bundled asset
    try {
      final String jsonString = await rootBundle.loadString(
        "packages/alrab-al-quran-li-da-as.json",
      );
      final Map<dynamic, dynamic> data = await compute(_decodeJsonToMap, jsonString);

      // Delete old box if corrupt
      try {
        if (Hive.isBoxOpen(irabBoxName)) {
          await Hive.lazyBox(irabBoxName).close();
        }
        await Hive.deleteBoxFromDisk(irabBoxName);
      } catch (_) {}

      final LazyBox box = await Hive.openLazyBox(irabBoxName);

      for (final entry in data.entries) {
        await box.put(entry.key.toString(), entry.value);
      }

      await box.put("meta_data", QuranIrabFunction.defaultIrabMeta);

      // Set as default selection
      await QuranIrabFunction.setDefaultSelected();
    } catch (e) {
      debugPrint("[DefaultOfflineResources] Failed to install I'rab data: $e");
    }
  }
}
