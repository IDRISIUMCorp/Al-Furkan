import "package:al_quran_v3/src/core/audio/model/recitation_info_model.dart";
import "package:al_quran_v3/src/utils/quran_resources/segmented_resources_manager.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

import "../../../utils/get_segments_supported_reciters.dart";

class SegmentedQuranReciterCubit extends Cubit<ReciterInfoModel> {
  SegmentedQuranReciterCubit()
    : super(
        (() {
          ReciterInfoModel? fromHive;
          try {
            final raw = Hive.box("user").get(
              "last_selected_reciter",
              defaultValue: null,
            );
            if (raw != null) {
              fromHive = ReciterInfoModel.fromMap(
                Map<String, dynamic>.from(raw),
              );
            }
          } catch (_) {}

          // Segmented reciter must support segmentsUrl.
          if (fromHive != null && fromHive.segmentsUrl != null) {
            return fromHive;
          }

          return SegmentedResourcesManager.getOpenSegmentsReciter() ??
              getSegmentsSupportedReciters().first;
        })(),
      );

  Future<bool> changeReciter(
    BuildContext context,
    ReciterInfoModel reciter,
  ) async {
    if (reciter.segmentsUrl == null) {
      // Just emit the reciter because it doesn't support segmentation.
      // Normal audio playback will handle the basic URL link instead.
      emit(reciter);
      try {
        Hive.box("user").put("last_selected_reciter", reciter.toMap());
      } catch (_) {}
      return true;
    }

    ReciterInfoModel previousReciter = state.copyWith(isDownloading: false);
    emit(reciter.copyWith(isDownloading: true));
    bool isSuccess = await SegmentedResourcesManager.downloadResources(
      context,
      reciter.segmentsUrl!,
    );
    emit(state.copyWith(isDownloading: false));
    if (isSuccess) {
      emit(reciter);

      // Keep global reciter selection in sync for playback everywhere.
      try {
        Hive.box("user").put("last_selected_reciter", reciter.toMap());
      } catch (_) {}

      return true;
    }
    emit(previousReciter);
    return false;
  }

  List<List>? getAyahSegments(String ayahKey) {
    List? segments = SegmentedResourcesManager.getAyahSegments(ayahKey);
    return segments == null ? null : List<List>.from(segments);
  }

  void temporaryHilightAyah(String ayah) async {
    emit(state.copyWith(showAyahHilight: ayah));
  }

  void refresh() {
    emit(state.copyWith());
  }
}
