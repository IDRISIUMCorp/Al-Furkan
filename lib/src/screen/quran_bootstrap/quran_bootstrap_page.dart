import "dart:developer";

import "package:al_quran_v3/src/screen/mushaf/mushaf_screen.dart";
import "package:al_quran_v3/src/utils/quran_resources/default_offline_resources.dart";
import "package:flutter/material.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

class QuranBootstrapPage extends StatefulWidget {
  const QuranBootstrapPage({super.key});

  @override
  State<QuranBootstrapPage> createState() => _QuranBootstrapPageState();
}

class _QuranBootstrapPageState extends State<QuranBootstrapPage> {
  bool _didRun = false;
  String _status = "Preparing...";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRun) return;
    _didRun = true;
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    try {
      if (!Hive.isBoxOpen("user")) {
        await Hive.openBox("user");
      }
      final userBox = Hive.box("user");

      await userBox.put("quick_setup_done", true);
      await userBox.put("is_setup_complete", true);

      await userBox.put("isAyahByAyah", false);
      await userBox.put("isAyahByAyahHorizontal", false);

      setState(() => _status = "Preparing offline resources...");
      await DefaultOfflineResources.ensureInstalled();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MushafScreen(),
        ),
      );
    } catch (e, s) {
      log("Bootstrap failed: $e\n$s", name: "QuranBootstrap");
      if (!mounted) return;
      setState(() => _status = "Failed to prepare. Please restart.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 14),
              Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
