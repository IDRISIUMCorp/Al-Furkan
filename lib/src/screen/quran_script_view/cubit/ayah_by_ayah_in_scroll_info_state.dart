part of "ayah_by_ayah_in_scroll_info_cubit.dart";

class AyahByAyahInScrollInfoState {
  SurahInfoModel? surahInfoModel;
  List<String>? expandedForWordByWord;
  bool isAyahByAyah;
  bool isAyahByAyahHorizontal;
  dynamic dropdownAyahKey;

  AyahByAyahInScrollInfoState({
    this.surahInfoModel,
    this.expandedForWordByWord,
    required this.isAyahByAyah,
    this.isAyahByAyahHorizontal = false,
    this.dropdownAyahKey,
  });

  AyahByAyahInScrollInfoState copyWith({
    SurahInfoModel? surahInfoModel,
    List<String>? expandedForWordByWord,
    bool? isAyahByAyah,
    bool? isAyahByAyahHorizontal,
    dynamic dropdownAyahKey,
    bool? isScrollingToDown,
  }) {
    return AyahByAyahInScrollInfoState(
      surahInfoModel: surahInfoModel ?? this.surahInfoModel,
      expandedForWordByWord:
          expandedForWordByWord ?? this.expandedForWordByWord,
      isAyahByAyah: isAyahByAyah ?? this.isAyahByAyah,
      isAyahByAyahHorizontal:
          isAyahByAyahHorizontal ?? this.isAyahByAyahHorizontal,
      dropdownAyahKey: dropdownAyahKey ?? this.dropdownAyahKey,
    );
  }

  static Map toMap(AyahByAyahInScrollInfoState ayahByAyahInScrollInfoState) {
    return {
      "surahInfoModel": ayahByAyahInScrollInfoState.surahInfoModel?.toMap(),
      "expandedForWordByWord":
          ayahByAyahInScrollInfoState.expandedForWordByWord,
      "isAyahByAyah": ayahByAyahInScrollInfoState.isAyahByAyah,
      "isAyahByAyahHorizontal":
          ayahByAyahInScrollInfoState.isAyahByAyahHorizontal,
      "dropdownAyahKey": ayahByAyahInScrollInfoState.dropdownAyahKey,
    };
  }

  // helper for list equality without imports
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AyahByAyahInScrollInfoState) return false;
    return other.surahInfoModel == surahInfoModel &&
        _listEquals(other.expandedForWordByWord, expandedForWordByWord) &&
        other.isAyahByAyah == isAyahByAyah &&
        other.isAyahByAyahHorizontal == isAyahByAyahHorizontal &&
        other.dropdownAyahKey == dropdownAyahKey;
  }

  @override
  int get hashCode => Object.hash(
    surahInfoModel,
    Object.hashAll(expandedForWordByWord ?? const []),
    isAyahByAyah,
    isAyahByAyahHorizontal,
    dropdownAyahKey,
  );
}
