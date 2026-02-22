import "dart:async";
import "dart:ui" as ui;

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/screen/location_handler/cubit/location_data_qibla_data_cubit.dart";
import "package:al_quran_v3/src/screen/location_handler/location_aquire.dart";
import "package:al_quran_v3/src/screen/location_handler/model/location_data_qibla_data_state.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_compass/flutter_compass.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:gap/gap.dart";
import "package:vibration/vibration.dart";

class ARQiblaScreen extends StatefulWidget {
  const ARQiblaScreen({super.key});

  @override
  State<ARQiblaScreen> createState() => _ARQiblaScreenState();
}

class _ARQiblaScreenState extends State<ARQiblaScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  double? _lastHeading;

  late bool hasVibrator;
  late bool hasSupportAmplitude;
  late AppLocalizations appLocalizations;

  @override
  void initState() {
    super.initState();
    _initVibration();
    _initCamera();
    Future.microtask(() => _showAccuracyWarning());
  }

  void _showAccuracyWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("تنبيه الدقة - AR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: const Text(
          "يرجى العلم أن تحديد اتجاه القبلة في الواقع المعزز (AR) يتطلب دقة عالية من حساسات الهاتف والكاميرا.\n\nمن الوارد وجود انحراف بسيط، ويتم العمل حالياً على تحسين الثبات. تأكد من تفعيل الموقع الجغرافي ومعايرة الحساسات.",
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً، فهمت", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _initVibration() async {
    hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator) {
      hasSupportAmplitude = await Vibration.hasCustomVibrationsSupport();
    }
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.read<ThemeCubit>().state;
    final cs = Theme.of(context).colorScheme;
    appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withValues(alpha: 0.3),
              child: Text(
                appLocalizations.qibla,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Camera Background
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. AR Overlay (Compass logic)
          Positioned.fill(
            child: BlocBuilder<LocationQiblaPrayerDataCubit, LocationQiblaPrayerDataState>(
              builder: (context, state) {
                if (state.latLon == null) {
                  return const Center(child: LocationAcquire());
                }
                if (state.kaabaAngle == null) {
                  return Center(
                    child: CircularProgressIndicator(color: themeState.primary),
                  );
                }

                return StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(appLocalizations.unableToGetCompassData, style: const TextStyle(color: Colors.white)));
                    }
                    if (snapshot.hasData) {
                      double? direction = snapshot.data?.heading;
                      if (direction == null) {
                        return Center(
                          child: Text(
                            appLocalizations.deviceDoesNotHaveSensors,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
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

                          // Calculate difference between facing direction and Qibla
                          final double qiblaAngle = state.kaabaAngle!;
                          
                          // Using shortest path math for the difference
                          double diff = qiblaAngle - _lastHeading!;
                          if (diff > 180) diff -= 360;
                          if (diff < -180) diff += 360;

                          final double absDiff = diff.abs();
                          final bool isFacingQibla = absDiff < 5;
                          
                          if (isFacingQibla) {
                            doVibrateThePhone();
                          } else {
                            vibrateOnceEnter = false;
                          }

                          return _buildAROverlay(diff, isFacingQibla, themeState);
                    }
                    return const SizedBox();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAROverlay(double difference, bool isFacingQibla, ThemeState themeState) {
    // difference: How far off from the exact Qibla the user is looking.
    // 0 = exact. Negative = Qibla is to the left. Positive = Qibla is to the right.

    final screenWidth = MediaQuery.of(context).size.width;
    
    // We visually map the 360 degree circle onto a horizontal line.
    // Let's say +/- 45 degrees fits comfortably in the viewport width.
    final horizontalOffset = (difference / 45.0) * (screenWidth / 2);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Center Target indicator (crosshair or circle telling you where the center of the phone points)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isFacingQibla ? themeState.primary : Colors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),

        // Kaaba Graphic translating horizontally based on difference
        Transform.translate(
          offset: Offset(horizontalOffset, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: SvgPicture.asset(
                  "assets/img/kaaba.svg",
                  colorFilter: ColorFilter.mode(
                    isFacingQibla ? themeState.primary : Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const Gap(16),
              if (isFacingQibla)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: themeState.primary.withValues(alpha: 0.8),
                      child: const Text(
                        "أنت في اتجاه القبلة",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Directional Arrows if the Kaaba is out of view (difference > 45 or < -45)
        if (difference > 45 || difference < -45)
          Positioned(
            left: difference < -45 ? 20 : null,
            right: difference > 45 ? 20 : null,
            child: Opacity(
              opacity: 0.8,
              child: Icon(
                difference < -45 ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
      ],
    );
  }
}
