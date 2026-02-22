import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_position_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_state_cubit.dart";
import "package:al_quran_v3/src/core/audio/model/audio_player_position_model.dart";
import "package:al_quran_v3/src/core/audio/model/ayahkey_management.dart";
import "package:al_quran_v3/src/core/audio/model/recitation_info_model.dart";
import "package:al_quran_v3/src/core/audio/player/audio_player_manager.dart";
import "package:al_quran_v3/src/screen/audio/change_reciter/popup_change_reciter.dart";
import "package:al_quran_v3/src/screen/audio/settings/audio_settings.dart";
import "package:al_quran_v3/src/screen/audio/download_screen/audio_download_screen.dart";
import "package:al_quran_v3/src/screen/audio/cubit/audio_tab_screen_cubit.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_translation_function.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/gen_ayahs_key.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/widget/jump_to_ayah/popup_jump_to_ayah.dart";
import "package:al_quran_v3/src/widget/quran_script_words/cubit/word_playing_state_cubit.dart";
import "package:al_quran_v3/src/screen/settings/cubit/quran_script_view_cubit.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:qcf_quran/qcf_quran.dart" as qcf;
import "package:al_quran_v3/src/utils/quran_ayahs_function/get_page_number.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:audio_video_progress_bar/audio_video_progress_bar.dart";
import "package:dartx/dartx.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:just_audio/just_audio.dart" hide PlayerState;
import "package:al_quran_v3/src/core/navigation/wahy_page_route.dart";

import "../../theme/controller/theme_cubit.dart";
import "../../theme/controller/theme_state.dart";

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  bool _showPlaylist = false;

  @override
  void initState() {
    if (surahNameLocalization.isEmpty || surahMeaningLocalization.isEmpty) {
      loadMetaSurah().then((value) => setState(() {}));
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ─── Color helpers ──────────────────────────────────────────
  Color get _glassColor => Theme.of(context).cardColor.withValues(alpha: 0.5);
  Color get _glassBorder => Theme.of(context).dividerColor.withValues(alpha: 0.1);
  Color get _textPrimary => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  Color get _textSecondary => Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    return (surahNameLocalization.isEmpty || surahMeaningLocalization.isEmpty)
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<AyahKeyCubit, AyahKeyManagement>(
                buildWhen: (p, c) => p.current != c.current,
                builder: (context, ayahKeyState) {
                  final parts = ayahKeyState.current.split(":");
                  if (parts.length < 2 ||
                      parts[0].isEmpty ||
                      parts[1].isEmpty) {
                    return Scaffold(body: _buildEmptyState(themeState));
                  }
                  final surahNum = int.parse(parts[0]);
                  final ayahNum = int.parse(parts[1]);
                  final currentIndex = ayahNum - 1;

                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    body: SafeArea(
                      child: Column(
                        children: [
                          // ── Top Bar ──
                          _buildTopBar(themeState),
                          // ── Main Content ──
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _showPlaylist
                                  ? _buildPlaylistView(
                                      ayahKeyState, themeState, currentIndex)
                                  : _buildPlayerView(
                                      themeState,
                                      ayahKeyState,
                                      surahNum,
                                      ayahNum,
                                      currentIndex,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
  }

  // ════════════════════════════════════════════════════════════════
  //  EMPTY STATE
  // ════════════════════════════════════════════════════════════════
  Widget _buildEmptyState(ThemeState themeState) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeState.primary.withValues(alpha: 0.05),
            ),
            child: Icon(
              FluentIcons.headphones_48_regular,
              size: 72,
              color: themeState.primary.withValues(alpha: 0.4),
            ),
          ),
          const Gap(28),
          Text(
            "ابدأ الاستماع الآن",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _textPrimary,
            ),
          ),
          const Gap(12),
          Text(
            "اختر سورة من المصحف لبدء التلاوة",
            style: TextStyle(fontSize: 15, color: _textSecondary),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
  }

  // ════════════════════════════════════════════════════════════════
  //  TOP BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildTopBar(ThemeState themeState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "تلاوة عطرة",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                  letterSpacing: 2.0,
                ),
              ),
              const Gap(2),
              Text(
                "القرآن الكريم",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Playlist toggle
          _GlassButton(
            icon: _showPlaylist
                ? FluentIcons.music_note_2_24_filled
                : FluentIcons.list_24_filled,
            onTap: () => setState(() => _showPlaylist = !_showPlaylist),
            isDark: _isDark,
          ),
          const Gap(10),
          _GlassButton(
            icon: FluentIcons.settings_24_filled,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                WahyPageRoute(page: const AudioSettings(needAppBar: true)),
              );
            },
            isDark: _isDark,
          ),
          if (!kIsWeb) ...[
            const Gap(10),
            _GlassButton(
              icon: FluentIcons.arrow_download_24_filled,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  WahyPageRoute(page: const AudioDownloadScreen()),
                );
              },
              isDark: _isDark,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }

  // ════════════════════════════════════════════════════════════════
  //  MAIN PLAYER VIEW
  // ════════════════════════════════════════════════════════════════
  Widget _buildPlayerView(
    ThemeState themeState,
    AyahKeyManagement ayahKeyState,
    int surahNum,
    int ayahNum,
    int currentIndex,
  ) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey("player"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              const Gap(8),
              // ── Album Art ──
              _buildAlbumArt(themeState, ayahKeyState, currentIndex),
              const Gap(16),
              // ── Surah Info ──
              _buildSurahInfo(ayahKeyState, themeState),
              const Gap(16),
              // ── Ayah Display (Scrollable & Expanded) ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildAyahDisplay(ayahKeyState, themeState, surahNum, ayahNum),
                ),
              ),
              const Gap(12),
              // ── Progress Bar ──
              _buildProgressBar(themeState),
              const Gap(12),
              // ── Controls ──
              _buildControls(currentIndex, ayahKeyState, l10n, themeState),
              const Gap(16),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ALBUM ART
  // ════════════════════════════════════════════════════════════════
  Widget _buildAlbumArt(
    ThemeState themeState,
    AyahKeyManagement ayahKeyState,
    int currentIndex,
  ) {
    final size = MediaQuery.of(context).size.width * 0.35;
    return BlocBuilder<AudioTabReciterCubit, ReciterInfoModel>(
      builder: (context, reciter) {
        return GestureDetector(
          onTap: () => _changeReciter(reciter, ayahKeyState, currentIndex),
          child: AnimatedBuilder(
            animation: _breatheController,
            builder: (context, child) {
              final scale = 1.0 + (_breatheController.value * 0.015);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: themeState.primary.withValues(alpha: 0.2),
                    blurRadius: 50,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    reciter.img != null
                        ? CachedNetworkImage(
                            imageUrl: reciter.img!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _buildDefaultReciterImage(themeState),
                          )
                        : _buildDefaultReciterImage(themeState),
                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Change reciter badge
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.mic_sparkle_24_filled,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 14,
                            ),
                            const Gap(6),
                            Text(
                              "تغيير القارئ",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildDefaultReciterImage(ThemeState themeState) {
    return Container(
      color: _isDark ? const Color(0xFF1E1E2E) : themeState.primaryShade100,
      child: Center(
        child: Icon(
          FluentIcons.person_48_filled,
          size: 72,
          color: themeState.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SURAH INFO
  // ════════════════════════════════════════════════════════════════
  Widget _buildSurahInfo(AyahKeyManagement ayahKeyState, ThemeState themeState) {
    final surahNum = ayahKeyState.current.split(":")[0].toInt();
    return GestureDetector(
      onTap: () => _jumpToAyah(ayahKeyState),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getSurahNameArabic(surahNum),
                style: TextStyle(
                  fontFamily: "surah-name-v1",
                  fontSize: 32,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: themeState.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeState.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FluentIcons.book_search_20_regular,
                  color: themeState.primary,
                  size: 16,
                ),
                const Gap(8),
                Text(
                  "تغيير السورة / الآية",
                  style: TextStyle(
                    color: themeState.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Gap(4),
          Text(
            getSurahMeaning(context, surahNum),
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.15);
  }

  // ════════════════════════════════════════════════════════════════
  //  AYAH DISPLAY (Minimal & Elegant)
  // ════════════════════════════════════════════════════════════════
  Widget _buildAyahDisplay(
    AyahKeyManagement ayahKeyState,
    ThemeState themeState,
    int surahNum,
    int ayahNum,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey("ayah_$surahNum:$ayahNum"),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Synchronized Arabic Text
            Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  final QuranScriptType scriptType =
                      context.read<QuranViewCubit>().state.quranScriptType;
                      
                  List<String> words = QuranScriptFunction.getWordListOfAyah(
                    scriptType,
                    surahNum.toString(),
                    ayahNum.toString(),
                  ).map((e) => e.toString()).toList();
                  QuranScriptType activeScriptType = scriptType;
                  
                  // Fallback to Uthmani if needed
                  if (words.isEmpty) {
                    activeScriptType = QuranScriptType.uthmani;
                    words = QuranScriptFunction.getWordListOfAyah(
                      activeScriptType,
                      surahNum.toString(),
                      ayahNum.toString(),
                    ).map((e) => e.toString()).toList();
                  }

                  bool isQcfFallback = false;
                  String qcfFontFamily = "QPC_Hafs";
                  
                  // Ultimate Fallback to QCF
                  if (words.isEmpty) {
                    isQcfFallback = true;
                    final ayahKey = "$surahNum:$ayahNum";
                    final pageNumber = getPageNumber(ayahKey) ?? 1;
                    qcfFontFamily = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
                    
                    String qcfText = qcf.getVerseQCF(
                      surahNum,
                      ayahNum,
                      verseEndSymbol: false,
                    );
                    
                    words = qcfText.trim().split(" ").where((w) => w.isNotEmpty).toList();
                  }

                  if (words.isEmpty) return const SizedBox.shrink();

                  return BlocBuilder<WordPlayingStateCubit, String?>(
                    builder: (context, playingWordState) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        textDirection: TextDirection.rtl,
                        spacing: 8,
                        runSpacing: 16,
                        children: List.generate(words.length, (index) {
                          String word = words[index];
                          // Identify end of Ayah marker
                          bool isLastWord =
                              index == (words.length - 1) && word.length < 3;
                          String currentWordKey =
                              "$surahNum:$ayahNum:${index + 1}";
                          bool isHighlight =
                              playingWordState == currentWordKey;

                          String fontFamily = isQcfFallback 
                              ? qcfFontFamily 
                              : (isLastWord 
                                  ? "QPC_Hafs" 
                                  : (activeScriptType == QuranScriptType.uthmani ? "QPC_Hafs" : "AlQuranNeov5x1"));

                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuart,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              package: isQcfFallback ? "qcf_quran" : null,
                              fontSize: isHighlight ? 34 : 26,
                              height: 1.8,
                              color: isHighlight
                                  ? themeState.primary
                                  : _textPrimary.withValues(alpha: 0.85),
                              shadows: isHighlight
                                  ? [
                                      Shadow(
                                        color: themeState.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 16,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(word),
                          );
                        }),
                      );
                    },
                  );
                },
              ),
            ),
            const Gap(24),
            // Minimalist Divider
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                color: themeState.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Gap(24),
            // Translation
            FutureBuilder(
              future: QuranTranslationFunction.getTranslation(
                  ayahKeyState.current),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                String translation = snapshot.data!.isNotEmpty
                    ? (snapshot.data!.first.translation?["t"] ?? "")
                    : "";
                return Text(
                  translation,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.15);
  }

  // ════════════════════════════════════════════════════════════════
  //  PROGRESS BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildProgressBar(ThemeState themeState) {
    return BlocBuilder<PlayerPositionCubit, AudioPlayerPositionModel>(
      builder: (context, state) {
        return ProgressBar(
          progress: state.currentDuration ?? Duration.zero,
          buffered: state.bufferDuration ?? Duration.zero,
          total: state.totalDuration ?? Duration.zero,
          barHeight: 5,
          thumbRadius: 7,
          barCapShape: BarCapShape.round,
          baseBarColor: _isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          progressBarColor: themeState.primary,
          bufferedBarColor: themeState.primary.withValues(alpha: 0.2),
          thumbColor: themeState.primary,
          thumbGlowColor: themeState.primary.withValues(alpha: 0.25),
          thumbGlowRadius: 14,
          timeLabelTextStyle: TextStyle(
            color: _textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          onSeek: (d) => AudioPlayerManager.audioPlayer.seek(d),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PLAYBACK CONTROLS
  // ════════════════════════════════════════════════════════════════
  Widget _buildControls(
    int currentIndex,
    AyahKeyManagement ayahKeyState,
    AppLocalizations l10n,
    ThemeState themeState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous
        _ControlButton(
          icon: FluentIcons.previous_24_filled,
          size: 28,
          color: _textPrimary,
          enabled: currentIndex > 0,
          onTap: () => _seekPrevious(ayahKeyState, currentIndex),
        ),
        // Rewind 5s
        _ControlButton(
          icon: Icons.replay_5_rounded,
          size: 30,
          color: _textPrimary,
          enabled: AudioPlayerManager.audioPlayer.audioSource != null,
          onTap: _rewind5,
        ),
        // MAIN PLAY
        _buildMainPlayButton(themeState, ayahKeyState, currentIndex, l10n),
        // Forward 5s
        _ControlButton(
          icon: Icons.forward_5_rounded,
          size: 30,
          color: _textPrimary,
          enabled: AudioPlayerManager.audioPlayer.audioSource != null,
          onTap: _forward5,
        ),
        // Next
        _ControlButton(
          icon: FluentIcons.next_24_filled,
          size: 28,
          color: _textPrimary,
          enabled: currentIndex < (ayahKeyState.ayahList.length - 1),
          onTap: () => _seekNext(ayahKeyState, currentIndex),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.25, end: 0);
  }

  Widget _buildMainPlayButton(
    ThemeState themeState,
    AyahKeyManagement ayahKeyState,
    int currentIndex,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<PlayerStateCubit, PlayerState>(
      builder: (context, state) {
        final isPlaying = state.isPlaying;
        return GestureDetector(
          onTap: () => _togglePlayPause(ayahKeyState, currentIndex),
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeState.primary,
                  themeState.primary.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeState.primary.withValues(alpha: 0.45),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Center(
              child: state.state == ProcessingState.loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PLAYLIST VIEW
  // ════════════════════════════════════════════════════════════════
  Widget _buildPlaylistView(
    AyahKeyManagement ayahKeyState,
    ThemeState themeState,
    int currentIndex,
  ) {
    if (ayahKeyState.ayahList.isEmpty) {
      return Center(
        child: Text(
          "قائمة التشغيل فارغة",
          style: TextStyle(color: _textSecondary, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey("playlist"),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: ayahKeyState.ayahList.length,
      itemBuilder: (context, index) {
        final key = ayahKeyState.ayahList[index];
        final parts = key.split(":");
        final surahNum = int.tryParse(parts[0]) ?? 1;
        final ayahNum = int.tryParse(parts.length > 1 ? parts[1] : "1") ?? 1;
        final isActive = index == currentIndex;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isActive
                ? themeState.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            leading: SizedBox(
               width: 32,
               height: 32,
               child: Center(
                  child: isActive
                     ? Icon(Icons.play_arrow_rounded,
                          color: themeState.primary, size: 24)
                     : Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: _textSecondary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
               ),
            ),
            title: Text(
              "${getSurahNameArabic(surahNum)} ─ الآية $ayahNum",
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
                color: isActive ? themeState.primary : _textPrimary.withValues(alpha: 0.9),
              ),
            ),
            onTap: () {
              if (AudioPlayerManager.audioPlayer.audioSource == null) {
                AudioPlayerManager.playMultipleAyahAsPlaylist(
                  startAyahKey: ayahKeyState.ayahList.first,
                  endAyahKey: ayahKeyState.ayahList.last,
                  isInsideQuran: true,
                  reciterInfoModel:
                      context.read<AudioTabReciterCubit>().state,
                  instantPlay: true,
                  initialIndex: index,
                );
              } else {
                AudioPlayerManager.audioPlayer
                    .seek(Duration.zero, index: index);
              }
            },
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════════════════════════
  void _changeReciter(
    ReciterInfoModel reciter,
    AyahKeyManagement ayahKeyState,
    int currentIndex,
  ) {
    popupChangeReciter(
      context,
      reciter,
      (ReciterInfoModel newReciter) async {
        context.read<AudioTabReciterCubit>().changeReciter(newReciter);
        if (ayahKeyState.ayahList.isNotEmpty) {
          AudioPlayerManager.playMultipleAyahAsPlaylist(
            startAyahKey: ayahKeyState.ayahList.first,
            endAyahKey: ayahKeyState.ayahList.last,
            isInsideQuran: false,
            reciterInfoModel: newReciter,
            initialIndex: currentIndex,
            instantPlay: AudioPlayerManager.audioPlayer.playing,
          );
        }
        Navigator.pop(context);
      },
      isWordByWord: false,
    );
  }

  void _jumpToAyah(AyahKeyManagement ayahKeyState) async {
    int surahNumber = ayahKeyState.current.split(":")[0].toInt();
    int ayahNumber = ayahKeyState.current.split(":")[1].toInt();
    await popupJumpToAyah(
      context: context,
      initAyahKey: "$surahNumber:$ayahNumber",
      isAudioPlayer: true,
      onPlaySelected: (ayahKey) {
        String startAyahKey = "${ayahKey.split(":")[0]}:1";
        String endAyahKey =
            getEndAyahKeyFromSurahNumber(int.parse(ayahKey.split(":")[0]));
        int toStartIndex = ayahKey.split(":")[1].toInt() - 1;
        AudioPlayerManager.playMultipleAyahAsPlaylist(
          startAyahKey: startAyahKey,
          endAyahKey: endAyahKey,
          isInsideQuran: false,
          instantPlay: true,
          initialIndex: toStartIndex,
          reciterInfoModel:
              context.read<AudioTabReciterCubit>().state,
        );
      },
    );
  }

  void _togglePlayPause(AyahKeyManagement ayahKeyState, int currentIndex) {
    if (AudioPlayerManager.audioPlayer.audioSource == null) {
      List<String> keys = List.from(ayahKeyState.ayahList);
      if (keys.isEmpty) return;
      if (keys.length == 1) {
        String surahNum = keys.first.split(":")[0];
        keys = List<String>.from(getListOfAyahKey(
          startAyahKey: "$surahNum:1",
          endAyahKey: getEndAyahKeyFromSurahNumber(int.parse(surahNum)),
        )..removeWhere((e) => e.runtimeType != String));
      }
      
      AudioPlayerManager.playMultipleAyahAsPlaylist(
        startAyahKey: keys.first,
        endAyahKey: keys.last,
        isInsideQuran: false, // Since we are in Audio tab
        initialIndex: currentIndex.clamp(0, keys.length - 1),
        instantPlay: true,
        reciterInfoModel: context.read<AudioTabReciterCubit>().state,
      );
      return;
    }
    
    if (!AudioPlayerManager.isListening) {
      AudioPlayerManager.startListeningAudioPlayerState();
    }
    
    AudioPlayerManager.audioPlayer.playing
        ? AudioPlayerManager.audioPlayer.pause()
        : AudioPlayerManager.audioPlayer.play();
  }

  void _seekPrevious(AyahKeyManagement ayahKeyState, int currentIndex) {
    if (AudioPlayerManager.audioPlayer.audioSource == null) {
      if (ayahKeyState.ayahList.isNotEmpty) {
        AudioPlayerManager.playMultipleAyahAsPlaylist(
          startAyahKey: ayahKeyState.ayahList.first,
          endAyahKey: ayahKeyState.ayahList.last,
          isInsideQuran: false, // Changed from true
          reciterInfoModel:
              context.read<AudioTabReciterCubit>().state,
          instantPlay: true,
          initialIndex: currentIndex - 1,
        );
      }
    } else {
      AudioPlayerManager.audioPlayer.seekToPrevious();
    }
  }

  void _seekNext(AyahKeyManagement ayahKeyState, int currentIndex) {
    if (AudioPlayerManager.audioPlayer.audioSource == null) {
      if (ayahKeyState.ayahList.isNotEmpty) {
        AudioPlayerManager.playMultipleAyahAsPlaylist(
          startAyahKey: ayahKeyState.ayahList.first,
          endAyahKey: ayahKeyState.ayahList.last,
          isInsideQuran: false, // Changed from true
          reciterInfoModel:
              context.read<AudioTabReciterCubit>().state,
          instantPlay: true,
          initialIndex: currentIndex + 1,
        );
      }
    } else {
      AudioPlayerManager.audioPlayer.seekToNext();
    }
  }

  void _rewind5() {
    Duration pos = AudioPlayerManager.audioPlayer.position -
        const Duration(seconds: 5);
    AudioPlayerManager.audioPlayer
        .seek(pos < Duration.zero ? Duration.zero : pos);
  }

  void _forward5() {
    Duration total =
        AudioPlayerManager.audioPlayer.duration ?? Duration.zero;
    Duration pos = AudioPlayerManager.audioPlayer.position +
        const Duration(seconds: 5);
    AudioPlayerManager.audioPlayer.seek(pos > total ? total : pos);
  }
}

// ════════════════════════════════════════════════════════════════
//  REUSABLE: Glass Button
// ════════════════════════════════════════════════════════════════
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  REUSABLE: Control Button
// ════════════════════════════════════════════════════════════════
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(
        icon,
        size: size,
        color: enabled ? color : color.withValues(alpha: 0.2),
      ),
    );
  }
}
