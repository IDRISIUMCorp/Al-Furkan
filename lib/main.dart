import "dart:developer";
import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/core/audio/cubit/audio_ui_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_position_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_state_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/segmented_quran_reciter_cubit.dart";
import "package:al_quran_v3/src/platform_services.dart" as platform_services;
import "package:al_quran_v3/src/resources/translation/languages.dart";
import "package:al_quran_v3/src/screen/quran_bootstrap/quran_bootstrap_page.dart";
import "package:al_quran_v3/src/screen/audio/download_screen/cubit/audio_download_cubit.dart";
import "package:al_quran_v3/src/screen/prayer_time/cubit/prayer_time_state.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_to_highlight.dart";
import "package:al_quran_v3/src/theme/wahy_theme_data.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/default_offline_resources.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_irab_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_translation_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/segmented_resources_manager.dart";
import "package:al_quran_v3/src/utils/quran_resources/word_by_word_function.dart";
import "package:al_quran_v3/src/resources/translation/language_cubit.dart";
import "package:al_quran_v3/src/screen/audio/cubit/audio_tab_screen_cubit.dart";

import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/screen/location_handler/cubit/location_data_qibla_data_cubit.dart";
import "package:al_quran_v3/src/screen/prayer_time/cubit/prayer_time_cubit.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_by_ayah_in_scroll_info_cubit.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/landscape_scroll_effect.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_cubit.dart";
import "package:al_quran_v3/src/screen/setup/cubit/resources_progress_cubit_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/theme/functions/theme_functions.dart";
import "package:al_quran_v3/src/core/notifications/khatma_notification_service.dart";
import "package:al_quran_v3/src/widget/history/cubit/quran_history_cubit.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:al_quran_v3/src/widget/quran_script_words/cubit/word_playing_state_cubit.dart";
import "package:al_quran_v3/src/screen/quran_reader/cubit/reader_ui_cubit.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_native_splash/flutter_native_splash.dart";
import "package:google_fonts/google_fonts.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:just_audio_background/just_audio_background.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:shared_preferences/shared_preferences.dart";

import "src/screen/location_handler/model/location_data_qibla_data_state.dart";

String? applicationDataPath;
platform_services.PlatformOwn platformOwn = platform_services.getPlatform();

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  platform_services.initializePlatform();

  await KhatmaNotificationService.instance.init();

  if (platformOwn != platform_services.PlatformOwn.isLinux &&
      platformOwn != platform_services.PlatformOwn.isWindows) {
    platform_services.initAwesomeNotification();

    JustAudioBackground.init(
      androidNotificationChannelId: "com.ryanheise.bg_demo.channel.audio",
      androidNotificationChannelName: "Audio playback",
      androidNotificationOngoing: true,
    );
  } else {
    // by default, windows and linux are enabled
    try {
      JustAudioMediaKit.ensureInitialized();
      JustAudioMediaKit.bufferSize = 8 * 1024 * 1024; // 8 MB
      JustAudioMediaKit.title = "Al Quran Audio";
    } catch (e) {
      log("Unable To Config JustAudioMediaKit with error: $e");
    }
  }
  applicationDataPath = await platform_services.getApplicationDataPath();

  if (platformOwn == platform_services.PlatformOwn.isWindows ||
      platformOwn == platform_services.PlatformOwn.isLinux) {
    Hive.init("${applicationDataPath!}/db");
  } else {
    await Hive.initFlutter();
  }

  await Hive.openBox("user");
  await Hive.openBox("pinned");
  await Hive.openBox("notes");

  final prefs = await SharedPreferences.getInstance();
  const firstRunKey = "idrisium_first_run_defaults_applied";
  final firstRunApplied = prefs.getBool(firstRunKey) ?? false;
  if (!firstRunApplied) {
    if (prefs.getString("selectedLanguageCode") == null) {
      await prefs.setString("selectedLanguageCode", "ar");
    }
    if (prefs.getString("app_theme_mode") == null) {
      await prefs.setString("app_theme_mode", ThemeMode.light.toString());
    }
    await prefs.setBool(firstRunKey, true);
  }

  await DefaultOfflineResources.ensureInstalled();

  await QuranTafsirFunction.init();

  // Initialize I'rab database so library tabs have data
  await QuranIrabFunction.setDefaultSelected();

  MyAppLocalization initialLocale = await LanguageCubit.getInitialLocale();

  QuranTranslationFunction.init(locale: initialLocale.locale);
  WordByWordFunction.init();
  SegmentedResourcesManager.init();

  final scriptOnDb = Hive.box("user").get(
    "selected_quran_script_type",
    defaultValue: QuranScriptType.values.first.name,
  );

  await QuranScriptFunction.initQuranScript(
    QuranScriptType.values.firstWhere((element) => scriptOnDb == element.name),
  );

  await loadMetaSurah();

  await ThemeFunctions.initThemeFunction();

  PrayerReminderState prayerReminderState = PrayerReminderState(
    prayerToRemember: [],
    previousReminderModes: {},
    reminderTimeAdjustment: {},
    enforceAlarmSound: false,
    soundVolume: 1.0,
  );

  LocationQiblaPrayerDataState locationQiblaPrayerDataState =
      await LocationQiblaPrayerDataCubit.getSavedState();
  log(locationQiblaPrayerDataState.madhab.toString(), name: "Madhab");

  runApp(
    MyApp(
      initialLocale: initialLocale,
      prayerReminderState: prayerReminderState,
      locationQiblaPrayerDataState: locationQiblaPrayerDataState,
    ),
  );
  platform_services.hideLoadingIndicator();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

TextTheme getTextTheme(Locale locale, bool isDarkMode) {
  final textTheme = isDarkMode
      ? ThemeData.dark().textTheme
      : ThemeData.light().textTheme;
  TextTheme baseTextTheme;
  switch (locale.languageCode) {
    case "ar":
    case "fa":
    case "ug": // Uighur
      baseTextTheme = GoogleFonts.notoSansArabicTextTheme(textTheme);
      break;
    case "ur":
      baseTextTheme = GoogleFonts.notoNastaliqUrduTextTheme(textTheme);
      break;
    case "bn":
    case "as": // Assamese
      baseTextTheme = GoogleFonts.notoSansBengaliTextTheme(textTheme);
      break;
    case "hi":
    case "mr": // Marathi
    case "ne": // Nepali
      baseTextTheme = GoogleFonts.notoSansDevanagariTextTheme(textTheme);
      break;
    case "ja":
      baseTextTheme = GoogleFonts.notoSansJpTextTheme(textTheme);
      break;
    case "ko":
      baseTextTheme = GoogleFonts.notoSansKrTextTheme(textTheme);
      break;
    case "zh":
      baseTextTheme = GoogleFonts.notoSansScTextTheme(textTheme);
      break;
    case "ta": // Tamil
      baseTextTheme = GoogleFonts.notoSansTamilTextTheme(textTheme);
      break;
    case "te": // Telugu
      baseTextTheme = GoogleFonts.notoSansTeluguTextTheme(textTheme);
      break;
    case "kn": // Kannada
      baseTextTheme = GoogleFonts.notoSansKannadaTextTheme(textTheme);
      break;
    case "ml": // Malayalam
      baseTextTheme = GoogleFonts.notoSansMalayalamTextTheme(textTheme);
      break;
    case "gu": // Gujarati
      baseTextTheme = GoogleFonts.notoSansGujaratiTextTheme(textTheme);
      break;
    case "si": // Sinhala
      baseTextTheme = GoogleFonts.notoSansSinhalaTextTheme(textTheme);
      break;
    case "th": // Thai
      baseTextTheme = GoogleFonts.notoSansThaiTextTheme(textTheme);
      break;
    case "km": // Khmer
      baseTextTheme = GoogleFonts.notoSansKhmerTextTheme(textTheme);
      break;
    case "he": // Hebrew
      baseTextTheme = GoogleFonts.notoSansHebrewTextTheme(textTheme);
      break;
    case "am": // Amharic
      baseTextTheme = GoogleFonts.notoSansEthiopicTextTheme(textTheme);
      break;
    case "dv": // Divehi
      baseTextTheme = GoogleFonts.notoSansThaanaTextTheme(textTheme);
      break;
    case "zgh": // Amazigh
      baseTextTheme = GoogleFonts.notoSansTifinaghTextTheme(textTheme);
      break;
    default:
      baseTextTheme = GoogleFonts.notoSansBengaliTextTheme(textTheme);
  }

  return baseTextTheme;
}

class MyApp extends StatelessWidget {
  final MyAppLocalization initialLocale;
  final PrayerReminderState prayerReminderState;
  final LocationQiblaPrayerDataState locationQiblaPrayerDataState;

  const MyApp({
    super.key,
    required this.initialLocale,
    required this.prayerReminderState,
    required this.locationQiblaPrayerDataState,
  });

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    final PageTransitionsTheme pageTransitionsTheme =
        const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        );
    return _UsageTimeTracker(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ResourcesProgressCubit()),
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(create: (context) => AudioUiCubit()),
          BlocProvider(create: (context) => PlayerPositionCubit()),
          BlocProvider(create: (context) => AyahKeyCubit()),
          BlocProvider(create: (context) => AyahByAyahInScrollInfoCubit()),
          BlocProvider(
            create: (context) => LocationQiblaPrayerDataCubit(
              initState: locationQiblaPrayerDataState,
            ),
          ),
          BlocProvider(create: (context) => SegmentedQuranReciterCubit()),
          BlocProvider(create: (context) => PlayerStateCubit(PlayerState())),
          BlocProvider(create: (context) => WordPlayingStateCubit()),
          BlocProvider(create: (context) => AudioTabReciterCubit()),
          BlocProvider(create: (context) => AyahByAyahInScrollInfoCubit()),
          BlocProvider(create: (context) => QuranViewCubit()),
          BlocProvider(
            create: (context) =>
                PrayerReminderCubit(initState: prayerReminderState),
          ),

          BlocProvider(create: (context) => LanguageCubit(initialLocale)),
          BlocProvider(create: (context) => LandscapeScrollEffect()),
          BlocProvider(create: (context) => QuranHistoryCubit()),
          BlocProvider(create: (context) => AudioDownloadCubit()),
          BlocProvider(create: (context) => AyahToHighlight(null)),
          BlocProvider(create: (context) => ReaderUICubit()),
        ],

        child: BlocBuilder<LanguageCubit, MyAppLocalization>(
          builder: (context, languageState) {
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp(
                  navigatorKey: navigatorKey,
                  debugShowCheckedModeBanner: false,
                  locale: languageState.locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  onGenerateTitle: (context) => "الفُرقان",
                  theme: WahyThemeData.lightTheme.copyWith(
                    pageTransitionsTheme: pageTransitionsTheme,
                    textTheme: getTextTheme(languageState.locale, false),
                  ),
                  darkTheme: WahyThemeData.darkTheme.copyWith(
                    pageTransitionsTheme: pageTransitionsTheme,
                    textTheme: getTextTheme(languageState.locale, true),
                  ),
                  themeMode: themeState.themeMode,
                  home: const QuranBootstrapPage(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UsageTimeTracker extends StatefulWidget {
  final Widget child;
  const _UsageTimeTracker({required this.child});

  @override
  State<_UsageTimeTracker> createState() => _UsageTimeTrackerState();
}

class _UsageTimeTrackerState extends State<_UsageTimeTracker>
    with WidgetsBindingObserver {
  static const _kUsageSeconds = "usage_time_seconds";
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();
  }

  @override
  void dispose() {
    _flush();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionStart ??= DateTime.now();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _flush();
    }
  }

  void _flush() {
    final start = _sessionStart;
    if (start == null) return;
    final seconds = DateTime.now().difference(start).inSeconds;
    _sessionStart = null;

    if (seconds <= 0) return;
    try {
      final box = Hive.box("user");
      final prev = (box.get(_kUsageSeconds, defaultValue: 0) as int?) ?? 0;
      box.put(_kUsageSeconds, prev + seconds);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
