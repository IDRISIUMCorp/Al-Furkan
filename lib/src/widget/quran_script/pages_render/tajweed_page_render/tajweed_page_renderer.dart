import "package:al_quran_v3/src/core/audio/cubit/audio_ui_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_position_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/segmented_quran_reciter_cubit.dart";
import "package:al_quran_v3/src/core/audio/model/audio_player_position_model.dart";
import "package:al_quran_v3/src/core/audio/model/recitation_info_model.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:al_quran_v3/src/widget/quran_script/script_view/tajweed_view/tajweed_text_preser.dart";
import "package:al_quran_v3/src/screen/collections/collection_page.dart";
import "package:al_quran_v3/src/screen/collections/models/note_collection_model.dart";
import "package:al_quran_v3/src/screen/collections/models/pinned_collection_model.dart";
import "package:dartx/dartx.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

import "../../../../theme/controller/theme_cubit.dart";
import "../../../../theme/controller/theme_state.dart";

class TajweedPageRenderer extends StatelessWidget {
  final List<String> ayahsKey;
  final TextStyle? baseTextStyle;
  final bool? enableWordByWordHighlight;

  const TajweedPageRenderer({
    super.key,
    required this.ayahsKey,
    this.baseTextStyle,
    this.enableWordByWordHighlight,
  });

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.read<ThemeCubit>().state;

    String? highlightingWord;

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: BlocBuilder<SegmentedQuranReciterCubit, ReciterInfoModel>(
        builder: (context, segmentsReciterState) {
          Map<String, List> audioSegmentsMap = {};

          for (final ayahKey in ayahsKey) {
            List<List>? segments = context
                .read<SegmentedQuranReciterCubit>()
                .getAyahSegments(ayahKey);

            if (segments != null) {
              audioSegmentsMap[ayahKey] = segments;
            }
          }

          return BlocBuilder<PlayerPositionCubit, AudioPlayerPositionModel>(
            buildWhen: (previous, current) {
              if (enableWordByWordHighlight != true) return false;
              if (context.read<AudioUiCubit>().state.isInsideQuranPlayer ==
                  false) {
                return false;
              }
              String? currentAyahKey =
                  context.read<AyahKeyCubit>().state.current;
              if (ayahsKey.contains(currentAyahKey)) {
                List? segments = audioSegmentsMap[currentAyahKey];
                if (segments != null) {
                  for (List word in segments) {
                    word = word.map((e) => e.toInt()).toList();
                    if (Duration(milliseconds: word[1]) <
                            (current.currentDuration ?? Duration.zero) &&
                        Duration(milliseconds: word[2]) >
                            (current.currentDuration ?? Duration.zero)) {
                      if (highlightingWord != "$currentAyahKey:${word[0]}") {
                        highlightingWord = "$currentAyahKey:${word[0]}";
                        return true;
                      }
                      return false;
                    }
                  }
                }
              } else {
                if (highlightingWord != null) {
                  highlightingWord = null;
                  return true;
                }
              }
              return false;
            },
            builder: (context, positionState) {
              final highlightingAyahKey =
                  context.read<AyahKeyCubit>().state.current;
              return Text.rich(
                TextSpan(
                  children:
                      ayahsKey.map((ayahKey) {
                        List words = QuranScriptFunction.getWordListOfAyah(
                          QuranScriptType.tajweed,
                          ayahKey.split(":").first,
                          ayahKey.split(":").last,
                        );
                        return TextSpan(
                          style: TextStyle(
                            backgroundColor:
                                highlightingAyahKey == ayahKey
                                    ? isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.08)
                                    : null,
                          ),
                          children:
                              List.generate(words.length, (index) {
                                final span = parseTajweedWord(
                                  wordIndex: index,
                                  baseStyle: TextStyle(
                                    fontSize: baseTextStyle?.fontSize ?? 24,
                                    fontFamily:
                                        baseTextStyle?.fontFamily ?? "QPC_Hafs",
                                    height: baseTextStyle?.height,
                                    backgroundColor:
                                        (highlightingWord ==
                                                    "$ayahKey:${index + 1}" &&
                                                enableWordByWordHighlight ==
                                                    true)
                                            ? themeState.primaryShade300
                                            : null,
                                  ),
                                  surahNumber: ayahKey.split(":").first.toInt(),
                                  ayahNumber: ayahKey.split(":").last.toInt(),
                                  skipWordTap: false,
                                  words: List<String>.from(words),
                                  context: context,
                                );

                                final bool isLast = index == (words.length - 1);
                                if (!isLast) return span;

                                return TextSpan(
                                  children: [
                                    span,
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.top,
                                      child: _AyahInlineStatusIndicator(
                                        ayahKey: ayahKey,
                                        color: themeState.primary,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        );
                      }).toList(),
                ),
                style: TextStyle(
                  fontSize: baseTextStyle?.fontSize ?? 24,
                  fontFamily: baseTextStyle?.fontFamily ?? "QPC_Hafs",
                  fontWeight: baseTextStyle?.fontWeight,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              );
            },
          );
        },
      ),
    );
  }
}

class _AyahInlineStatusIndicator extends StatelessWidget {
  final String ayahKey;
  final Color color;

  const _AyahInlineStatusIndicator({required this.ayahKey, required this.color});

  bool _isPinned(Iterable<dynamic> boxValues) {
    for (final value in boxValues) {
      try {
        final model = PinnedCollectionModel.fromJson(
          Map<String, dynamic>.from(value),
        );
        if (model.pinned.any((p) => p.ayahKey == ayahKey)) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  bool _isNoted(Iterable<dynamic> boxValues) {
    for (final value in boxValues) {
      try {
        final model = NoteCollectionModel.fromJson(
          Map<String, dynamic>.from(value),
        );
        for (final note in model.notes) {
          if (note.ayahKey.contains(ayahKey)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final pinnedBox = Hive.box(CollectionType.pinned.name);
    final notesBox = Hive.box(CollectionType.notes.name);

    return ValueListenableBuilder(
      valueListenable: pinnedBox.listenable(),
      builder: (context, _, __) {
        final isPinned = _isPinned(pinnedBox.values);
        return ValueListenableBuilder(
          valueListenable: notesBox.listenable(),
          builder: (context, __, ___) {
            final isNoted = _isNoted(notesBox.values);
            if (!isPinned && !isNoted) return const SizedBox.shrink();
            return Transform.translate(
              offset: const Offset(0, -6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPinned)
                    Icon(
                      FluentIcons.pin_24_filled,
                      size: 12,
                      color: color,
                    ),
                  if (isPinned && isNoted) const SizedBox(width: 4),
                  if (isNoted)
                    Icon(
                      FluentIcons.note_add_24_filled,
                      size: 12,
                      color: color,
                    ),
                  const SizedBox(width: 2),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
