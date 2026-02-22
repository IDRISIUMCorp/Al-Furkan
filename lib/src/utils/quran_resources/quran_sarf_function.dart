import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";

class QuranSarfFunction {
  static Future<List<TafsirBookModel>?> getSarfSelections() async {
    return [
      TafsirBookModel(
        language: "arabic",
        name: "معجم الصرف الميسر",
        totalAyahs: 6236,
        hasTafsir: 1,
        score: 1.0,
        fullPath: "sarf_db",
      )
    ];
  }

  static Future<String?> getResolvedSarfTextForBook(
    TafsirBookModel book,
    String ayahKey,
  ) async {
     return "<h3>الصرف</h3><p>بيانات الصرف قيد التطوير ولم يتم إدراجها بعد داخل التطبيق.</p>";
  }
}
