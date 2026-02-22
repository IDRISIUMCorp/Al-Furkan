import "dart:async";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/core/audio/cubit/ayah_key_cubit.dart";
import "package:al_quran_v3/src/core/audio/cubit/player_state_cubit.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/meta/meta_data_surah.dart";
import "package:al_quran_v3/src/resources/quran_resources/quran_pages_info.dart";
import "package:al_quran_v3/src/screen/mushaf/mushaf_screen.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_by_ayah_in_scroll_info_cubit.dart";
import "package:al_quran_v3/src/screen/quran_script_view/cubit/ayah_to_highlight.dart";
import "package:al_quran_v3/src/screen/quran_script_view/model/surah_header_info.dart";
import "package:al_quran_v3/src/screen/quran_script_view/settings/quran_script_settings.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/page_info_model.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/screen/quran_reader/cubit/reader_ui_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/gen_ayahs_key.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/get_page_number.dart";
import "package:al_quran_v3/src/widget/ayah_by_ayah/ayah_by_ayah_card.dart";
import "package:al_quran_v3/src/widget/surah_info_header/surah_info_header_builder.dart";
import "package:dartx/dartx_io.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

import "../../widget/audio/audio_controller_ui.dart";

class QuranScriptView extends StatefulWidget {
  final String startKey;
  final String endKey;
  final String? toScrollKey;
  final bool embedded;
  final double? topPaddingOverride;
  final bool showAudioController;
  const QuranScriptView({
    super.key,
    required this.startKey,
    required this.endKey,
    this.toScrollKey,
    this.embedded = false,
    this.topPaddingOverride,
    this.showAudioController = true,
  });

  @override
  State<QuranScriptView> createState() => _QuranScriptViewState();
}

class _QuranScriptViewState extends State<QuranScriptView> {
  ItemScrollController itemScrollControllerSurahList = ItemScrollController();
  ItemScrollController itemScrollControllerAyahByAyah = ItemScrollController();
  ItemScrollController itemScrollControllerAyahList = ItemScrollController();
  ItemPositionsListener itemPositionsListenerAyahList =
      ItemPositionsListener.create();

  bool _isMushafMode = false;

  PageController? _ayahByAyahPageController;
  int? _lastAyahByAyahPageIndex;
  int _currentHorizontalIndex = 0;

  StreamSubscription? _ayahKeyCubitSubscription;
  String? scrolledAyahOnAudioPlay;

  late List<String> ayahsList;

  Future<void> _persistLastRead(String ayahKey) async {
    final page = getPageNumber(ayahKey);
    if (page == null) return;
    await context.read<ReaderUICubit>().saveLastReadPosition(
          pageNumber: page,
          ayahKey: ayahKey,
        );
  }

  Future<void> scrollToAyah(String key) async {
    if (itemScrollControllerAyahByAyah.isAttached) {
      itemScrollControllerAyahByAyah.scrollTo(
        index: ayahsList.indexOf(key),
        alignment: 0.15,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  void _animateToAyahPage(String ayahKey) {
    final controller = _ayahByAyahPageController;
    if (controller == null || !controller.hasClients) return;

    final index = ayahsList.indexOf(ayahKey);
    if (index == -1) return;
    if (_lastAyahByAyahPageIndex == index) return;

    _lastAyahByAyahPageIndex = index;
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ayahKeyCubitSubscription?.cancel();
    _ayahByAyahPageController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    ayahsList = getListOfAyahKeyExperimental(
      startAyahKey: widget.startKey,
      endAyahKey: widget.endKey,
    );

    final String? savedAyahKey = context.read<ReaderUICubit>().lastReadAyahKey;
    final String initialAyahKey = widget.toScrollKey ??
        (savedAyahKey != null && ayahsList.contains(savedAyahKey)
            ? savedAyahKey
            : context.read<AyahKeyCubit>().state.current);
    final int initialPageIndex =
        ayahsList.contains(initialAyahKey) ? ayahsList.indexOf(initialAyahKey) : 0;
    _lastAyahByAyahPageIndex = initialPageIndex;
    _currentHorizontalIndex = initialPageIndex;
    _ayahByAyahPageController = PageController(initialPage: initialPageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final safeKey = ayahsList.isNotEmpty ? ayahsList[initialPageIndex] : null;
      if (safeKey != null) _persistLastRead(safeKey);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<AyahByAyahInScrollInfoCubit>().stream.listen((event) {
        if (!isLandScape) return;
        if (previousDropdownAyahKey != event.dropdownAyahKey) {
          final dynamic dropdownAyahKey = event.dropdownAyahKey;
          if (dropdownAyahKey != null && dropdownAyahKey is String) {
            final index = ayahsList.indexOf(dropdownAyahKey);
            if (index != -1) {
              bool isVisible = isItemVisible(
                itemPositionsListenerAyahList,
                index,
              );
              if (!isVisible && itemScrollControllerAyahList.isAttached) {
                itemScrollControllerAyahList.scrollTo(
                  index: index,
                  duration: const Duration(milliseconds: 200),
                  alignment: 0.5,
                );
              }
            }
          }
        }
        previousDropdownAyahKey = event.dropdownAyahKey;
      });
    });

    _ayahKeyCubitSubscription = context.read<AyahKeyCubit>().stream.listen((
      event,
    ) {
      if (context.read<PlayerStateCubit>().state.isPlaying) {
        context.read<AyahToHighlight>().changeAyah(event.current);
      }
      if (scrolledAyahOnAudioPlay != null &&
          event.current == scrolledAyahOnAudioPlay) {
        return;
      }
      final isHorizontal =
          context.read<AyahByAyahInScrollInfoCubit>().state.isAyahByAyahHorizontal;
      if (isHorizontal) {
        _animateToAyahPage(event.current);
      } else {
        scrollToAyah(event.current);
      }

      _persistLastRead(event.current);

      scrolledAyahOnAudioPlay = event.current;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.toScrollKey != null) {
        scrollToAyah(widget.toScrollKey!);
      }
    });

    super.initState();
  }

  dynamic previousDropdownAyahKey;
  bool isLandScape = false;
  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context);
    ThemeState themeState = context.read<ThemeCubit>().state;
    double width = MediaQuery.of(context).size.width;
    isLandScape = width > 600;

    final Widget content = _isMushafMode
        ? MushafView(
          useDefaultAppBar: false,
          initialPageNumber:
              getPageNumber(context.read<AyahKeyCubit>().state.current),
        )
        : quranScriptWidget(l10n);

    final body = isLandScape
        ? Row(
          children: [
            SafeArea(
              right: false,
              bottom: false,
              top: true,
              left: true,
              child: sideBarOfSurahAndAyah(themeState, context),
            ),
            Expanded(
              child: Stack(
                children: [
                  content,
                  if (widget.showAudioController)
                    const SafeArea(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: AudioControllerUi(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        )
        : Stack(
          children: [
            content,
            if (widget.showAudioController)
              const SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: AudioControllerUi(),
                ),
              ),
          ],
        );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isLandScape
          ? null
          : AppBar(
            title: appBarTitle(),
            actions: [
              getAyahsDropDown(themeState),
              getMushafButton(themeState, context),
              getSettingsButton(themeState, context),
            ],
          ),
      body: body,
    );
  }

  Column sideBarOfSurahAndAyah(ThemeState themeState, BuildContext context) {
    return Column(
      children: [
        Container(
          width: 210,
          height: 45,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: themeState.primaryShade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              BackButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: themeState.primaryShade100,
                ),
              ),
              const Gap(5),
              getMushafButton(themeState, context),
              const Gap(5),
              getSettingsButton(themeState, context),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 120,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: themeState.primaryShade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BlocBuilder<
                  AyahByAyahInScrollInfoCubit,
                  AyahByAyahInScrollInfoState
                >(
                  builder: (context, ayahState) {
                    return ScrollablePositionedList.builder(
                      itemScrollController: itemScrollControllerSurahList,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemCount: 114,
                      itemBuilder: (context, index) {
                        bool isCurrent =
                            (index + 1) == ayahState.surahInfoModel?.id;
                        return OutlinedButton(
                          style: outlineButtonDesignSidebar(
                            isCurrent,
                            themeState,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => QuranScriptView(
                                      startKey: "${index + 1}:1",
                                      endKey: getEndAyahKeyFromSurahNumber(
                                        index + 1,
                                      ),
                                    ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                getSurahName(context, index + 1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isCurrent
                                          ? themeState.primary
                                          : Colors.grey,
                                ),
                              ),
                              if (isCurrent) const Gap(5),
                              if (isCurrent)
                                const Icon(
                                  Icons.radio_button_checked,
                                  size: 12,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Container(
                width: 80,
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: themeState.primaryShade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BlocBuilder<
                  AyahByAyahInScrollInfoCubit,
                  AyahByAyahInScrollInfoState
                >(
                  builder: (context, ayahState) {
                    return ScrollablePositionedList.builder(
                      itemScrollController: itemScrollControllerAyahList,
                      itemPositionsListener: itemPositionsListenerAyahList,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      itemCount: ayahsList.length,
                      itemBuilder: (context, index) {
                        bool isCurrent =
                            ayahState.dropdownAyahKey == ayahsList[index];

                        return OutlinedButton(
                          style: outlineButtonDesignSidebar(
                            isCurrent,
                            themeState,
                          ),
                          onPressed: () {
                            scrollToAyah(ayahsList[index]);
                            WidgetsBinding.instance.addPostFrameCallback((
                              _,
                            ) async {
                              context
                                  .read<AyahByAyahInScrollInfoCubit>()
                                  .setData(dropdownAyahKey: ayahsList[index]);
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              Text(
                                "${localizedNumber(context, ayahsList[index].split(":").first.toInt())}:${localizedNumber(context, ayahsList[index].split(":").last.toInt())}",
                              ),
                              if (isCurrent) const Gap(5),
                              if (isCurrent)
                                const Icon(
                                  Icons.radio_button_checked,
                                  size: 12,
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle outlineButtonDesignSidebar(
    bool isCurrent,
    ThemeState themeState,
  ) {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: isCurrent ? themeState.primary : themeState.mutedGray,
        width: isCurrent ? 1.5 : 1,
      ),
    );
  }

  Widget quranScriptWidget(AppLocalizations l10n) {
    final double topPadding =
        widget.topPaddingOverride ??
        (() {
          double padding = 10;
          if (!isLandScape) {
            padding += MediaQuery.of(context).padding.top + kToolbarHeight;
          }
          return padding;
        })();

    return BlocBuilder<
      AyahByAyahInScrollInfoCubit,
      AyahByAyahInScrollInfoState
    >(
      builder: (context, state) {
        // Page-mode is removed. Keep only ayah-by-ayah scroll.

        Widget buildAyahItem(BuildContext context, int index) {
          final ayahKey = ayahsList[index];
          final ayahKeySplit = ayahKey.split(":");
          int surahNumber = ayahKeySplit.first.toInt();

          int ayahNumber = ayahKeySplit.last.toInt();
          String surahEndAyahKey =
              surahNumber == ayahsList.last.split(":").last.toInt()
                  ? ayahsList.last
                  : getEndAyahKeyFromSurahNumber(surahNumber);
          bool isSurahHeadingIncluded = ayahNumber == 1;
          int pageNumber = getPageNumber(ayahKey) ?? 0;
          PageInfoModel? pageInfo;
          try {
            pageInfo = PageInfoModel.fromMap(
              quranPagesInfo[pageNumber - 1],
            );
          } catch (_) {}

          bool isPageStart = pageInfo?.start == ayahNumber || index == 0;

          return Column(
            children: [
              if (isSurahHeadingIncluded)
                SurahInfoHeaderBuilder(
                  headerInfoModel: SurahHeaderInfoModel(
                    SurahInfoModel.fromMap(metaDataSurah["$surahNumber"]!),
                    ayahKey,
                    surahEndAyahKey,
                  ),
                ),
              if (isPageStart) pageLabelOfQuran(context, l10n, pageNumber),
              getAyahByAyahTafsirCard(
                ayahKey: ayahKey,
                context: context,
              ),
            ],
          );
        }

        if (state.isAyahByAyahHorizontal) {
          final themeState = context.read<ThemeCubit>().state;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          Widget buildIndicator() {
            final ayahKey = ayahsList[_currentHorizontalIndex];
            final ayahNumber = ayahKey.split(":").last;

            final double progress = (ayahsList.isEmpty)
                ? 0
                : (_currentHorizontalIndex + 1) / ayahsList.length;
            final Color surface =
                isDark ? const Color(0xFF141414) : const Color(0xFFF3EDE2);
            final Color onSurface = isDark ? Colors.white : Colors.black87;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "آية $ayahNumber",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: themeState.primary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 3,
                      backgroundColor: onSurface.withValues(alpha: 0.12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(themeState.primary),
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _ayahByAyahPageController,
                itemCount: ayahsList.length,
                reverse: true,
                allowImplicitScrolling: true,
                physics: const BouncingScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                onPageChanged: (pageIndex) {
                  final normalizedIndex = (ayahsList.length - 1) - pageIndex;
                  final ayahKey = ayahsList[normalizedIndex];
                  _lastAyahByAyahPageIndex = normalizedIndex;
                  setState(() {
                    _currentHorizontalIndex = normalizedIndex;
                  });
                  context.read<AyahKeyCubit>().changeCurrentAyahKey(ayahKey);
                  _persistLastRead(ayahKey);
                },
                itemBuilder: (context, pageIndex) {
                  final normalizedIndex = (ayahsList.length - 1) - pageIndex;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(top: topPadding, bottom: 100),
                    child: buildAyahItem(context, normalizedIndex),
                  );
                },
              ),
              Positioned(
                top: topPadding + 8,
                left: 16,
                right: 16,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: buildIndicator(),
                ),
              ),
            ],
          );
        }

        return ScrollablePositionedList.builder(
          itemScrollController: itemScrollControllerAyahByAyah,
          itemCount: ayahsList.length,
          padding: EdgeInsets.only(top: topPadding, bottom: 100),
          itemBuilder: (context, index) => buildAyahItem(context, index),
        );
      },
    );
  }

  Widget appBarTitle() {
    return BlocBuilder<
      AyahByAyahInScrollInfoCubit,
      AyahByAyahInScrollInfoState
    >(
      buildWhen: (previous, current) {
        return previous.surahInfoModel != current.surahInfoModel;
      },
      builder: (context, state) {
        return Text(
          state.surahInfoModel == null
              ? ""
              : AppLocalizations.of(
                context,
              ).surahName(getSurahName(context, state.surahInfoModel!.id)),
          style: const TextStyle(fontSize: 18),
        );
      },
    );
  }

  Container getAyahsDropDown(ThemeState themeState) {
    return Container(
      width: 94,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: themeState.primaryShade100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: BlocBuilder<
        AyahByAyahInScrollInfoCubit,
        AyahByAyahInScrollInfoState
      >(
        builder: (context, ayahScrollInfoState) {
          List<DropdownMenuItem> dropdownItems =
              List.generate(ayahsList.length, (index) {
                List<String> ayahData = ayahsList[index].toString().split(
                  ":",
                );
                return DropdownMenuItem(
                  value: ayahsList[index],
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      "${localizedNumber(context, ayahData.first.toInt())}:${localizedNumber(context, ayahData.last.toInt())}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              });
          final value = ayahScrollInfoState.dropdownAyahKey;
          final isValidValue = dropdownItems.any((item) => item.value == value);
          return DropdownButtonHideUnderline(
            child: DropdownButton(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              isExpanded: true,
              value: isValidValue ? value : null,
              selectedItemBuilder: (context) {
                return dropdownItems.map((item) {
                  final child = item.child;
                  return Align(
                    alignment: Alignment.center,
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: child,
                    ),
                  );
                }).toList();
              },
              items: dropdownItems,
              onChanged: (value) async {
                if (value is String) {
                  scrollToAyah(value);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  context.read<AyahByAyahInScrollInfoCubit>().setData(
                    dropdownAyahKey: value,
                  );
                });
              },
            ),
          );
        },
      ),
    );
  }

  IconButton getMushafButton(ThemeState themeState, BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: themeState.primaryShade100,
        foregroundColor: themeState.primary,
      ),
      onPressed: () {
        setState(() {
          _isMushafMode = !_isMushafMode;
        });
      },
      icon: Icon(
        _isMushafMode
            ? FluentIcons.text_font_size_24_filled
            : FluentIcons.book_24_filled,
      ),
    );
  }

  IconButton getSettingsButton(ThemeState themeState, BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: themeState.primaryShade100,
        foregroundColor: themeState.primary,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuranScriptSettings(asPage: true),
          ),
        );
      },
      icon: const Icon(FluentIcons.settings_24_filled),
    );
  }

  Container pageLabelOfQuran(
    BuildContext context,
    AppLocalizations l10n,
    int pageNumber,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      width: MediaQuery.of(context).size.width,
      height: 30,
      color: context.read<ThemeCubit>().state.primaryShade300,
      alignment: Alignment.center,
      child: Text("${l10n.page} - ${localizedNumber(context, pageNumber)}"),
    );
  }

  bool isItemVisible(ItemPositionsListener listener, int index) {
    final positions = listener.itemPositions.value;
    for (final position in positions) {
      if (position.index == index) {
        return position.itemLeadingEdge >= 0 && position.itemTrailingEdge <= 1;
      }
    }
    return false;
  }
}
