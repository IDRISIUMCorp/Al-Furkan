import "package:al_quran_v3/src/core/audio/model/recitation_info_model.dart";
import "package:al_quran_v3/src/core/audio/resources/recitations.dart";

List<ReciterInfoModel> getSegmentsSupportedReciters() {
  List<ReciterInfoModel> recitations =
      recitationsInfoList.map((e) => ReciterInfoModel.fromMap(e)).toList();
  recitations =
      recitations
          .map((e) => e.copyWith(supportWordSegmentation: e.segmentsUrl != null))
          .toList();
  return recitations;
}
