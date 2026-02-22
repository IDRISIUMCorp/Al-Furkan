import "package:al_quran_v3/l10n/app_localizations.dart";
import "dart:async";
import "dart:math" as math;

import "package:al_quran_v3/src/screen/location_handler/cubit/location_data_qibla_data_cubit.dart";
import "package:al_quran_v3/src/screen/location_handler/location_aquire.dart";
import "package:al_quran_v3/src/screen/location_handler/model/location_data_qibla_data_state.dart";
import "package:al_quran_v3/src/screen/qibla/ar_qibla_screen.dart";
import "package:al_quran_v3/src/screen/qibla/compass_view/compass_view.dart";

import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_compass/flutter_compass.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:gap/gap.dart";
import "package:vector_math/vector_math.dart" as vector;
import "package:vibration/vibration.dart";

const double kaabaLatDegrees = 21.422487;
const double kaabaLonDegrees = 39.826206;

class QiblaDirection extends StatefulWidget {
  final bool showAppBar;
  const QiblaDirection({super.key, this.showAppBar = false});

  @override
  State<QiblaDirection> createState() => _QiblaDirectionState();
}

class _QiblaDirectionState extends State<QiblaDirection> {
  late bool hasVibrator;
  late bool hasSupportAmplitude;
  late AppLocalizations appLocalizations;
  double? _lastHeading;

  @override
  void initState() {
    initStateCall();
    Future.microtask(() => _showAccuracyWarning());
    super.initState();
  }

  void _showAccuracyWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("تنبيه الدقة", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "يرجى العلم أن تحديد اتجاه القبلة يعتمد على حساسات الهاتف، وقد لا تكون دقيقة بنسبة 100% في بعض الأجهزة أو الظروف الجوية.\n\nنعمل حالياً على تحسين الخوارزميات في التحديثات القادمة. يرجى التأكد من معايرة البوصلة (تحريك الهاتف بشكل رقم 8) والابتعاد عن المعادن.",
          style: TextStyle(fontSize: 14, height: 1.5),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً، فهمت", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> initStateCall() async {
    hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      hasSupportAmplitude = await Vibration.hasCustomVibrationsSupport();
    }
  }

  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.read<ThemeCubit>().state;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    bool isLandScape = width > height;
    appLocalizations = AppLocalizations.of(context);

    final body = _buildBody(themeState, width, height, isLandScape);

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          appLocalizations.qibla,
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ARQiblaScreen()),
              );
            },
            icon: Icon(Icons.view_in_ar_rounded, color: cs.primary),
            tooltip: "القبلة بالواقع المعزز (AR)",
          ),
          const Gap(8),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(
    ThemeState themeState,
    double width,
    double height,
    bool isLandScape,
  ) {
    return Center(
      child: BlocBuilder<
        LocationQiblaPrayerDataCubit,
        LocationQiblaPrayerDataState
      >(
        builder: (context, state) {
          LocationQiblaPrayerDataState? dataState =
              context.read<LocationQiblaPrayerDataCubit>().state;
          Widget compassView = const SizedBox();
          if (dataState.kaabaAngle != null) {
            compassView = SizedBox(
              width: isLandScape ? height * 0.6 : width * 0.8,
              height: isLandScape ? height * 0.6 : width * 0.8,
              child: CustomPaint(
                painter: CompassView(
                  themeState,
                  context: context,
                  kaabaAngle: dataState.kaabaAngle!,
                  appLocalizations: appLocalizations,
                ),
              ),
            );
          }
          return state.latLon == null
              ? const LocationAcquire()
              : state.kaabaAngle == null
              ? Center(
                child: CircularProgressIndicator(
                  color: themeState.primary,
                  backgroundColor:
                      context.read<ThemeCubit>().state.primaryShade100,
                ),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Gap(20),
                  Center(
                    child: StreamBuilder<CompassEvent>(
                      stream: FlutterCompass.events,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(appLocalizations.unableToGetCompassData);
                        }
                        if (snapshot.hasData) {
                          double? direction = snapshot.data?.heading;
                          if (direction == null) {
                            return Center(
                              child: Text(
                                appLocalizations.deviceDoesNotHaveSensors,
                              ),
                            );
                          }

                          // Normalize to [0, 360)
                          if (direction < 0) {
                            direction = direction + 360;
                          }

                          // ──── Low Pass Filter (Smoothing) ────
                          if (_lastHeading == null) {
                            _lastHeading = direction;
                          } else {
                            // Shortest path interpolation for 360 wrap around
                            double diff = direction - _lastHeading!;
                            if (diff > 180) diff -= 360;
                            if (diff < -180) diff += 360;
                            
                            const double k = 0.12; // Smoothing factor
                            _lastHeading = (_lastHeading! + k * diff) % 360;
                          }
                          
                          return getCompassRotationView(
                            _lastHeading!,
                            state.kaabaAngle!,
                            compassView,
                            themeState,
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                ],
              );
        },
      ),
    );
  }

  bool vibrateOnceEnter = false;
  void doVibrateThePhone() async {
    if (hasVibrator && !vibrateOnceEnter) {
      await Vibration.vibrate(
        amplitude: hasSupportAmplitude ? 200 : -1,
        duration: 100,
      );
      vibrateOnceEnter = true;
    }
  }

  Widget getCompassRotationView(
    double direction,
    double kaabaAngle,
    Widget compassView,
    ThemeState themeState,
  ) {
    Color kaabaColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white;
    double angleDiff = (direction - kaabaAngle).abs();
    if (angleDiff > 180) angleDiff = 360 - angleDiff;

    if (angleDiff < 5) {
      kaabaColor = themeState.primary;
      doVibrateThePhone();
    } else {
      vibrateOnceEnter = false;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: SizedBox(
            height: 50,
            width: 50,
            // ignore: deprecated_member_use
            child: SvgPicture.asset("assets/img/kaaba.svg", color: kaabaColor),
          ),
        ),
        const Gap(50),
        Transform.rotate(
          angle: vector.radians(360 - direction),
          child: compassView,
        ),
      ],
    );
  }
}

double calculateQiblaAngle(double userLat, double userLon) {
  if (userLat == kaabaLatDegrees && userLon == kaabaLonDegrees) {
    return -1.0;
  }

  final double userLatRad = vector.radians(userLat);
  final double userLonRad = vector.radians(userLon);
  final double kaabaLatRad = vector.radians(kaabaLatDegrees);
  final double kaabaLonRad = vector.radians(kaabaLonDegrees);

  final double deltaLon = kaabaLonRad - userLonRad;

  final double y = math.sin(deltaLon) * math.cos(kaabaLatRad);
  final double x =
      math.cos(userLatRad) * math.sin(kaabaLatRad) -
      math.sin(userLatRad) * math.cos(kaabaLatRad) * math.cos(deltaLon);

  final double bearingRad = math.atan2(y, x);

  final double bearingDeg = vector.degrees(bearingRad);

  final double qiblaAngle = (bearingDeg + 360) % 360;

  return qiblaAngle;
}

double transformAngle(double inputAngle) {
  // Normalize to [0, 360) without inverting
  return (inputAngle % 360 + 360) % 360;
}
