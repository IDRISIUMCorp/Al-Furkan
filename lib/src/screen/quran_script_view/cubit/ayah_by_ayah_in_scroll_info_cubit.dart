import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:bloc/bloc.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

part "ayah_by_ayah_in_scroll_info_state.dart";

class AyahByAyahInScrollInfoCubit extends Cubit<AyahByAyahInScrollInfoState> {
  AyahByAyahInScrollInfoCubit()
    : super(
        AyahByAyahInScrollInfoState(
          isAyahByAyah: true,
          isAyahByAyahHorizontal: Hive.box(
            "user",
          ).get("isAyahByAyahHorizontal", defaultValue: false),
        ),
      );

  void setData({
    SurahInfoModel? surahInfoModel,
    List<String>? expandedForWordByWord,
    bool? isAyahByAyah,
    bool? isAyahByAyahHorizontal,
    dynamic dropdownAyahKey,
    bool clearDropdownAyahKey = false,
  }) {
    final newState = state.copyWith(
      surahInfoModel: surahInfoModel,
      expandedForWordByWord: expandedForWordByWord,
      isAyahByAyah: true,
      isAyahByAyahHorizontal: isAyahByAyahHorizontal,
      dropdownAyahKey: dropdownAyahKey,
    );
    if (clearDropdownAyahKey) {
      newState.dropdownAyahKey = null;
    }
    if (AyahByAyahInScrollInfoState.toMap(newState).toString() !=
        AyahByAyahInScrollInfoState.toMap(state).toString()) {
      emit(newState);
    }
    // isAyahByAyah (page mode) is intentionally disabled; do not persist it.

    if (isAyahByAyahHorizontal != null) {
      Hive.box("user").put("isAyahByAyahHorizontal", isAyahByAyahHorizontal);
    }
  }
}
