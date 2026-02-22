
import "dart:ui" as ui;
import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/core/audio/cubit/audio_ui_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_position_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/segmented_quran_reciter_cubit.dart";
import "package:al_quran_v3/src/core/audio/model/audio_controller_ui.dart";
import "package:al_quran_v3/src/core/audio/model/audio_player_position_model.dart";
import "package:al_quran_v3/src/core/audio/model/ayahkey_management.dart";
import "package:al_quran_v3/src/core/audio/model/recitation_info_model.dart";
import "package:al_quran_v3/src/core/audio/player/audio_player_manager.dart";
import "package:al_quran_v3/src/screen/audio/change_reciter/popup_change_reciter.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/gen_ayahs_key.dart";
import "package:al_quran_v3/src/resources/quran_resources/quran_ayah_count.dart";
import "package:al_quran_v3/src/theme/values/values.dart";
import "package:audio_video_progress_bar/audio_video_progress_bar.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:just_audio/just_audio.dart" as just_audio;

import "../../core/audio/cubit/player_state_cubit.dart";
import "../../theme/controller/theme_cubit.dart";
import "../../theme/controller/theme_state.dart";
import "package:al_quran_v3/src/theme/app_colors.dart";

class AudioControllerUi extends StatefulWidget {
  const AudioControllerUi({super.key});

  @override
  State<AudioControllerUi> createState() => _AudioControllerUiState();
}

class _AudioControllerUiState extends State<AudioControllerUi> {
  AudioUiCubit? _myCubitInstance; // Cache the Cubit instance

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myCubitInstance ??= context.read<AudioUiCubit>();
  }

  @override
  void dispose() {
    _myCubitInstance = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.read<ThemeCubit>().state;
    AppLocalizations l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    bool isLandscapeViewNeedToShow = screenWidth > 600;

    return BlocBuilder<AudioUiCubit, AudioControllerUiState>(
      builder: (context, state) {
        double height =
            (state.showUi && state.isInsideQuranPlayer)
                ? state.isExpanded
                    ? isLandscapeViewNeedToShow
                        ? 66
                        : 120
                    : 72
                : 0;
        double width =
            (state.showUi && state.isInsideQuranPlayer)
                ? state.isExpanded
                    ? screenWidth
                    : screenWidth
                : 0;

        return GestureDetector(
          onTap: () {
            if (!state.isExpanded) {
              context.read<AudioUiCubit>().expand(true);
            }
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 1000,
              end: state.isExpanded ? roundedRadius : 1000,
            ),
            duration: const Duration(milliseconds: 300),
            builder: (context, radius, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final Color collapsedSurface = isDark ? const Color(0xFF1B1B1F) : AppColors.ayaAudioPlayerBg;
              return Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: height,
                      width: width,
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1B1B1F) : AppColors.ayaAudioPlayerBg).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: isDark ? Colors.white10 : AppColors.ayaBorder.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          children: [
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child:
                              (state.showUi && state.isInsideQuranPlayer)
                                  ? Stack(
                                    children: [
                                      if (!state.isExpanded)
                                        BlocBuilder<
                                          SegmentedQuranReciterCubit,
                                          ReciterInfoModel
                                        >(
                                          builder: (context, reciter) {
                                            return BlocBuilder<
                                              PlayerStateCubit,
                                              PlayerState
                                            >(
                                              builder: (context, playerState) {
                                                final isLoading =
                                                    playerState.state ==
                                                        just_audio
                                                            .ProcessingState
                                                            .loading ||
                                                    playerState.state ==
                                                        just_audio
                                                            .ProcessingState
                                                            .buffering;

                                                final onSurface = isDark ? Colors.white : AppColors.ayaTextMain;

                                                final isPlaylist =
                                                    context.read<AudioUiCubit>().state.isPlayList;

                                                Future<void> openReciterPicker() async {
                                                  if (!context.mounted) return;
                                                  popupChangeReciter(
                                                    context,
                                                    reciter,
                                                    (ReciterInfoModel reciterInfoModel) async {
                                                      Navigator.pop(context);
                                                      bool isSuccess = await context
                                                          .read<SegmentedQuranReciterCubit>()
                                                          .changeReciter(context, reciterInfoModel);

                                                      if (!isSuccess) return;

                                                      if (AudioPlayerManager.audioPlayer.playing) {
                                                        final ayahState =
                                                            context.read<AyahKeyCubit>().state;
                                                        if (ayahState.ayahList.length > 1) {
                                                          await AudioPlayerManager.playMultipleAyahAsPlaylist(
                                                            startAyahKey: ayahState.start,
                                                            endAyahKey: ayahState.end,
                                                            isInsideQuran: true,
                                                            reciterInfoModel: reciterInfoModel,
                                                            initialIndex: ayahState.ayahList
                                                                .indexOf(ayahState.current),
                                                            instantPlay: true,
                                                          );
                                                        } else {
                                                          await AudioPlayerManager.playSingleAyah(
                                                            ayahKey: ayahState.current,
                                                            reciterInfoModel: reciterInfoModel,
                                                            instantPlay: true,
                                                            isInsideQuran: true,
                                                          );
                                                        }
                                                      }
                                                    },
                                                    isWordByWord: false,
                                                  );
                                                }

                                                return SizedBox(
                                                  height: 64,
                                                  width: double.infinity,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          mainAxisSize: MainAxisSize.min, // Let it shrink
                                                          children: [
                                                            InkWell(
                                                              borderRadius: BorderRadius.circular(999),
                                                              onTap: openReciterPicker,
                                                              child: Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Flexible(
                                                                      child: Text(
                                                                        reciter.name,
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.w800,
                                                                          fontSize: 13,
                                                                          color: onSurface.withValues(alpha: 0.85),
                                                                        ),
                                                                        overflow: TextOverflow.ellipsis,
                                                                        maxLines: 1,
                                                                        textAlign: TextAlign.center,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    Icon(
                                                                      Icons.keyboard_arrow_down_rounded,
                                                                      size: 18,
                                                                      color: themeState.primary,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              isLoading
                                                                  ? "جاري التحميل"
                                                                  : (playerState.isPlaying ? "يتم التشغيل" : "متوقف"),
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                                color: themeState.primary,
                                                              ),
                                                              textDirection: TextDirection.rtl,
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: isPlaylist
                                                            ? () {
                                                              AudioPlayerManager
                                                                  .audioPlayer
                                                                  .seekToPrevious();
                                                            }
                                                            : null,
                                                        icon: Icon(
                                                          Icons
                                                              .skip_previous_rounded,
                                                          color:
                                                              themeState.primary,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () async {
                                                          if (isLoading) return;

                                                          final player =
                                                              AudioPlayerManager.audioPlayer;
                                                          final hasSource =
                                                              player.audioSource != null;
                                                          final isIdle =
                                                              player.processingState ==
                                                                  just_audio
                                                                      .ProcessingState
                                                                      .idle;
                                                          final noDuration =
                                                              player.duration == null;

                                                          if (!player.playing &&
                                                              (!hasSource ||
                                                                  isIdle ||
                                                                  noDuration)) {
                                                            // Ensure cubits/listeners are active so loading/playing state appears.
                                                            AudioPlayerManager
                                                                .startListeningAudioPlayerState();

                                                            final ayahKey = context
                                                                .read<AyahKeyCubit>()
                                                                .state
                                                                .current;
                                                            final reciter = context
                                                                .read<SegmentedQuranReciterCubit>()
                                                                .state;
                                                            await AudioPlayerManager
                                                                .playSingleAyah(
                                                              ayahKey: ayahKey,
                                                              reciterInfoModel:
                                                                  reciter,
                                                              instantPlay: true,
                                                              isInsideQuran: true,
                                                            );
                                                            return;
                                                          }

                                                          player.playing
                                                              ? player.pause()
                                                              : player.play();
                                                        },
                                                        iconSize: 34,
                                                        icon: AnimatedSwitcher(
                                                          duration: const Duration(
                                                            milliseconds: 180,
                                                          ),
                                                          switchInCurve:
                                                              Curves.easeOutCubic,
                                                          switchOutCurve:
                                                              Curves.easeOutCubic,
                                                          child: isLoading
                                                              ? SizedBox(
                                                                key: const ValueKey(
                                                                  "loading",
                                                                ),
                                                                width: 22,
                                                                height: 22,
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  strokeWidth: 2.4,
                                                                  color: themeState
                                                                      .primary,
                                                                ),
                                                              )
                                                              : Icon(
                                                                playerState.isPlaying
                                                                    ? Icons
                                                                        .pause_rounded
                                                                    : Icons
                                                                        .play_arrow_rounded,
                                                                key: ValueKey(
                                                                  playerState
                                                                      .isPlaying,
                                                                ),
                                                                color: themeState
                                                                    .primary,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: isPlaylist
                                                            ? () {
                                                              AudioPlayerManager
                                                                  .audioPlayer
                                                                  .seekToNext();
                                                            }
                                                            : null,
                                                        icon: Icon(
                                                          Icons
                                                              .skip_next_rounded,
                                                          color:
                                                              themeState.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      if (state.isExpanded)
                                        Stack(
                                          children: [
                                            getFullAudioControllerUI(
                                              l10n,
                                              isLandscapeViewNeedToShow,
                                            ),
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: SizedBox(
                                                height: 30,
                                                width: 30,
                                                child: IconButton(
                                                  style: IconButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    iconSize: 15,
                                                  ),
                                                  onPressed: () {
                                                    if (state.isExpanded) {
                                                      context
                                                          .read<AudioUiCubit>()
                                                          .expand(false);
                                                    }
                                                  },
                                                  tooltip:
                                                      l10n.closeAudioController,
                                                  icon: const Icon(
                                                    Icons
                                                        .close_fullscreen_rounded,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  )
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget getFullAudioControllerUI(AppLocalizations l10n, bool isLandscapeView) {
    return isLandscapeView
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: playerSliders()),
            const VerticalDivider(width: 8),
            Expanded(child: playerControllers(l10n)),
          ],
        )
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [playerSliders(), playerControllers(l10n), const Gap(5)],
        );
  }

  Widget playerSliders() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<PlayerPositionCubit, AudioPlayerPositionModel>(
          builder: (context, state) {
            return ProgressBar(
              progress: state.currentDuration ?? Duration.zero,
              buffered: state.bufferDuration ?? Duration.zero,
              total: state.totalDuration ?? Duration.zero,
              thumbCanPaintOutsideBar: false,
              barHeight: 6,
              timeLabelLocation: TimeLabelLocation.sides,
              onSeek: (duration) {
                AudioPlayerManager.audioPlayer.seek(duration);
              },
            );
          },
        ),

        BlocBuilder<AyahKeyCubit, AyahKeyManagement?>(
          builder: (context, state) {
            if (state?.current != null &&
                state?.end != null &&
                state?.start != null) {
              int currentSurahNumber = int.parse(state!.current.split(":")[0]);
              List ayahList = getListOfAyahKey(
                startAyahKey: "$currentSurahNumber:1",
                endAyahKey: getEndAyahKeyFromSurahNumber(currentSurahNumber),
              );
              ayahList.removeWhere((element) => element.runtimeType == int);

              return ayahList.length > 1
                  ? Row(
                    children: [
                      Text(state.current),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            padding: const EdgeInsets.only(
                              top: 3,
                              bottom: 5,
                              left: 10,
                              right: 10,
                            ),
                          ),

                          child: Slider(
                            value: ayahList.indexOf(state.current).toDouble(),
                            max: ayahList.length.toDouble() - 1,
                            min: 0,

                            divisions: ayahList.length - 1,
                            onChanged: (value) {
                              String ayahKey = ayahList[value.toInt()];
                              if ((state.ayahList.length) == 1) {
                                AudioPlayerManager.playSingleAyah(
                                  ayahKey: ayahKey,
                                  reciterInfoModel:
                                      context
                                          .read<SegmentedQuranReciterCubit>()
                                          .state,
                                  isInsideQuran: true,
                                );
                              }
                              AudioPlayerManager.audioPlayer.seek(
                                Duration.zero,
                                index: value.toInt(),
                              );
                            },
                          ),
                        ),
                      ),
                      Text(ayahList.last!),
                    ],
                  )
                  : const SizedBox();
            }
            {
              return const SizedBox();
            }
          },
        ),
      ],
    );
  }

  SingleChildScrollView playerControllers(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 15),
      child: BlocBuilder<AyahKeyCubit, AyahKeyManagement?>(
        builder: (context, state) {
          List ayahList = state?.ayahList ?? [];
          ayahList.removeWhere((element) => element.runtimeType == int);
          int currentPlayingIndex = ayahList.indexOf(state?.current);
          if (currentPlayingIndex == -1) currentPlayingIndex = 0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed:
                    int.parse(state?.current.split(":").last ?? "0") > 1
                        ? () {
                          if (state?.ayahList.length == 1) {
                            int? currentSurahNumber = int.tryParse(
                              state?.current.split(":").first ?? "",
                            );
                            if (currentSurahNumber == null) return;
                            List tempAyahList = getListOfAyahKey(
                              startAyahKey: "$currentSurahNumber:1",
                              endAyahKey: getEndAyahKeyFromSurahNumber(
                                currentSurahNumber,
                              ),
                            );
                            tempAyahList.removeWhere(
                              (element) => element.runtimeType == int,
                            );
                            int index = tempAyahList.indexOf(
                              state?.current ?? "",
                            );
                            if (index != -1) {
                              AudioPlayerManager.playSingleAyah(
                                ayahKey: tempAyahList[index - 1],
                                reciterInfoModel:
                                    context
                                        .read<SegmentedQuranReciterCubit>()
                                        .state,
                                isInsideQuran: true,
                              );
                            }
                          } else {
                            AudioPlayerManager.audioPlayer.seekToPrevious();
                          }
                        }
                        : null,
                tooltip: l10n.previous,
                style: IconButton.styleFrom(padding: EdgeInsets.zero),

                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton(
                onPressed: () {
                  Duration duration = AudioPlayerManager.audioPlayer.position;
                  int inMilSec = duration.inMilliseconds - 5000;
                  if (inMilSec < 0) inMilSec = 0;
                  AudioPlayerManager.audioPlayer.seek(
                    Duration(milliseconds: inMilSec),
                  );
                },
                tooltip: l10n.rewind,
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.replay_5_rounded),
              ),
              BlocBuilder<PlayerStateCubit, PlayerState>(
                builder: (context, state) {
                  final isLoading =
                      state.state == just_audio.ProcessingState.loading ||
                      state.state == just_audio.ProcessingState.buffering;
                  return IconButton(
                    onPressed: () async {
                      if (isLoading) return;

                      final player = AudioPlayerManager.audioPlayer;
                      final hasSource = player.audioSource != null;
                      final isIdle =
                          player.processingState == just_audio.ProcessingState.idle;
                      final noDuration = player.duration == null;

                      if (!player.playing && (!hasSource || isIdle || noDuration)) {
                        final ayahKey = context.read<AyahKeyCubit>().state.current;
                        final reciter =
                            context.read<SegmentedQuranReciterCubit>().state;
                        await AudioPlayerManager.playSingleAyah(
                          ayahKey: ayahKey,
                          reciterInfoModel: reciter,
                          instantPlay: true,
                          isInsideQuran: true,
                        );
                        return;
                      }

                      player.playing ? player.pause() : player.play();
                    },
                    tooltip: state.isPlaying ? l10n.pause : l10n.play,
                    iconSize: 40,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(5),
                    ),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: isLoading
                          ? const SizedBox(
                              key: ValueKey("loading"),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : Icon(
                              state.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(state.isPlaying),
                            ),
                    ),
                  );
                },
              ),

              IconButton(
                onPressed: () {
                  Duration? position = AudioPlayerManager.audioPlayer.position;

                  Duration? maxDuration =
                      AudioPlayerManager.audioPlayer.duration;

                  AudioPlayerManager.audioPlayer.duration;
                  int inMilSec = position.inMilliseconds + 5000;
                  if ((maxDuration?.inMilliseconds ??
                          MediaQuery.of(context).size.width) <
                      inMilSec) {
                    inMilSec = maxDuration?.inMilliseconds ?? 0;
                  }
                  AudioPlayerManager.audioPlayer.seek(
                    Duration(milliseconds: inMilSec),
                  );
                },
                tooltip: l10n.fastForward,
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.forward_5_rounded),
              ),

              IconButton(
                onPressed:
                    (ayahList.isNotEmpty &&
                            int.parse(state?.current.split(":").last ?? "0") <
                                quranAyahCount[int.parse(
                                      ayahList.first.split(":").first,
                                    ) -
                                    1])
                        ? () {
                          if (state?.ayahList.length == 1) {
                            int? currentSurahNumber = int.tryParse(
                              state?.current.split(":").first ?? "",
                            );
                            if (currentSurahNumber == null) return;
                            List tempAyahList = getListOfAyahKey(
                              startAyahKey: "$currentSurahNumber:1",
                              endAyahKey: getEndAyahKeyFromSurahNumber(
                                currentSurahNumber,
                              ),
                            );
                            tempAyahList.removeWhere(
                              (element) => element.runtimeType == int,
                            );
                            int index = tempAyahList.indexOf(
                              state?.current ?? "",
                            );
                            if (index != -1) {
                              AudioPlayerManager.playSingleAyah(
                                ayahKey: tempAyahList[index + 1],
                                reciterInfoModel:
                                    context
                                        .read<SegmentedQuranReciterCubit>()
                                        .state,
                                isInsideQuran: true,
                              );
                            }
                          } else {
                            AudioPlayerManager.audioPlayer.seekToNext();
                          }
                        }
                        : null,
                tooltip: l10n.playNextAyah,
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.skip_next_rounded),
              ),

              if (ayahList.length != 1)
                IconButton(
                  onPressed: () {
                    if (AudioPlayerManager.audioPlayer.loopMode ==
                        just_audio.LoopMode.one) {
                      AudioPlayerManager.audioPlayer.setLoopMode(
                        just_audio.LoopMode.all,
                      );
                    } else if (AudioPlayerManager.audioPlayer.loopMode ==
                        just_audio.LoopMode.all) {
                      AudioPlayerManager.audioPlayer.setLoopMode(
                        just_audio.LoopMode.off,
                      );
                    } else {
                      AudioPlayerManager.audioPlayer.setLoopMode(
                        just_audio.LoopMode.one,
                      );
                    }
                  },
                  tooltip: l10n.repeat,
                  style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  icon: switch (AudioPlayerManager.audioPlayer.loopMode) {
                    just_audio.LoopMode.one => const Icon(
                      Icons.repeat_one_rounded,
                    ),
                    just_audio.LoopMode.all => const Icon(Icons.repeat_rounded),
                    just_audio.LoopMode.off => Icon(
                      Icons.repeat_rounded,
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                  },
                ),

              if (ayahList.length == 1)
                IconButton(
                  onPressed: () {
                    int surahNumber = int.parse(
                      ayahList.first.split(":").first,
                    );
                    int currentAyahNumber = int.parse(
                      ayahList.first.split(":").last,
                    );
                    String endAyahKey = getEndAyahKeyFromSurahNumber(
                      surahNumber,
                    );

                    String startAyahKey = "$surahNumber:1";

                    AudioPlayerManager.playMultipleAyahAsPlaylist(
                      startAyahKey: startAyahKey,
                      endAyahKey: endAyahKey,
                      reciterInfoModel:
                          context.read<SegmentedQuranReciterCubit>().state,
                      initialIndex: currentAyahNumber - 1,
                      instantPlay: AudioPlayerManager.audioPlayer.playing,
                      isInsideQuran: true,
                    );
                  },
                  tooltip: l10n.playAsPlaylist,
                  style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  icon: const Icon(Icons.playlist_play_rounded),
                ),
            ],
          );
        },
      ),
    );
  }
}
