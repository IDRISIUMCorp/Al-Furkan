import "package:al_quran_v3/src/screen/location_handler/cubit/location_data_qibla_data_cubit.dart";
import "package:al_quran_v3/src/screen/location_handler/location_aquire.dart";
import "package:al_quran_v3/src/screen/location_handler/model/location_data_qibla_data_state.dart";
import "package:al_quran_v3/src/screen/prayer_time/time_list_of_prayers.dart";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class PrayerTimePage extends StatefulWidget {
  const PrayerTimePage({super.key});

  @override
  State<PrayerTimePage> createState() => _PrayerTimePageState();
}

class _PrayerTimePageState extends State<PrayerTimePage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "مواقيت الصلاة",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_rounded, color: cs.primary),
        ),
      ),
      body: BlocBuilder<
        LocationQiblaPrayerDataCubit,
        LocationQiblaPrayerDataState
      >(
        builder: (context, state) {
          if (state.latLon == null) {
            return const LocationAcquire();
          } else {
            return const TimeListOfPrayers();
          }
        },
      ),
    );
  }
}
