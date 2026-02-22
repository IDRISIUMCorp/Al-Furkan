import "package:al_quran_v3/src/widget/history/cubit/quran_history_state.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

class QuranHistoryCubit extends Cubit<QuranHistoryState> {
  QuranHistoryCubit()
    : super(
        QuranHistoryState(
          history: List<HistoryElement>.from(
            Hive.box("user")
                .get("quran_browse_history", defaultValue: [])
                .map(
                  (e) => HistoryElement.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList(),
          ),
        ),
      );

  void addHistory({required String ayahKey, int? pageNumber}) {
    List<HistoryElement> history = state.history;
    HistoryElement? lastHistory =
        state.history.isEmpty ? null : state.history.last;
    int ayahNumber = int.parse(ayahKey.split(":")[1]);
    int surahNumber = int.parse(ayahKey.split(":")[0]);
    if (lastHistory != null &&
        surahNumber == lastHistory.surahNumber &&
        DateTime.fromMillisecondsSinceEpoch(
              lastHistory.timestamp,
            ).difference(DateTime.now()).inMinutes.abs() <
            5) {
      if (history.isNotEmpty) history.removeLast();
      history.add(
        HistoryElement(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          pageNumber: pageNumber,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } else {
      history.add(
        HistoryElement(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          pageNumber: pageNumber,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    Hive.box(
      "user",
    ).put("quran_browse_history", history.map((e) => e.toJson()).toList());
    emit(QuranHistoryState(history: history));
  }

  /// Returns the last read position, or null if no history exists.
  HistoryElement? getLastReadPosition() {
    if (state.history.isEmpty) return null;
    return state.history.last;
  }

  /// Returns the ayah key string (e.g. "2:45") for the last read position.
  /// Falls back to "1:1" (Al-Fatiha) if no history.
  String getLastReadAyahKey() {
    final last = getLastReadPosition();
    if (last == null) return "1:1";
    return "${last.surahNumber}:${last.ayahNumber ?? 1}";
  }
}
