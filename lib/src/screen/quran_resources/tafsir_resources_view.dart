import "dart:developer";

import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_tafsir_function.dart";
import "package:al_quran_v3/src/utils/quran_resources/default_offline_resources.dart";
import "package:al_quran_v3/src/resources/quran_resources/language_resources.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/tafsir_book_model.dart";
import "package:al_quran_v3/src/resources/quran_resources/tafsir_info_with_score.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/widget/components/get_score_widget.dart";
import "package:dartx/dartx.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

class TafsirResourcesView extends StatefulWidget {
  const TafsirResourcesView({super.key});

  @override
  State<TafsirResourcesView> createState() => _TafsirResourcesViewState();
}

class _TafsirResourcesViewState extends State<TafsirResourcesView> {
  late List<TafsirBookModel> downloadedTafsirs;

  List<TafsirBookModel>? selectedTafsir;

  TafsirBookModel? downloadingData;

  void _refreshData() async {
    downloadedTafsirs = QuranTafsirFunction.getDownloadedTafsirBooks();
    selectedTafsir = await QuranTafsirFunction.getTafsirSelections();
    downloadingData = null;
    setState(() {});
  }

  @override
  void initState() {
    downloadedTafsirs = QuranTafsirFunction.getDownloadedTafsirBooks();
    QuranTafsirFunction.getTafsirSelections().then((value) {
      int previousLen = selectedTafsir?.length ?? 0;
      selectedTafsir = value;
      if (previousLen == 0) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.watch<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppLocalizations appLocalizations = AppLocalizations.of(context);

    final userBox = Hive.box("user");

    return ValueListenableBuilder(
      valueListenable: userBox.listenable(keys: const [
        QuranTafsirFunction.selectedTafsirListKey,
        QuranTafsirFunction.downloadedTafsirBooksKey,
      ]),
      builder: (context, _, __) {
        downloadedTafsirs = QuranTafsirFunction.getDownloadedTafsirBooks();
        final rawSelected =
            userBox.get(QuranTafsirFunction.selectedTafsirListKey) as List?;
        selectedTafsir = rawSelected
            ?.map((e) => TafsirBookModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: List.generate(tafsirInformationWithScore.length, (index) {
              String languageKey = tafsirInformationWithScore.keys.elementAt(
                index,
              );
              List<TafsirBookModel> booksInLanguage =
                  tafsirInformationWithScore[languageKey]
                      ?.map((e) => TafsirBookModel.fromMap(e))
                      .toList() ??
                  [];

              if (languageKey.toLowerCase() != "arabic") {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          languageNativeNames[languageKey] ?? languageKey,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "تفاسير اللغات غير العربية هتتضاف في تحديثات قادمة إن شاء الله.",
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w700,
                            color: themeState.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (languageKey.toLowerCase() == "arabic") {
                booksInLanguage = booksInLanguage
                    .map((b) {
                      final name = b.name.trim();
                      final isMuyassarByName = name == "التفسير الميسر";
                      final isMuyassarByPath = b.fullPath == DefaultOfflineResources.remoteMuyassarFullPath;
                      if (isMuyassarByName || isMuyassarByPath) {
                        return DefaultOfflineResources.defaultTafsirMuyassar;
                      }
                      return b;
                    })
                    .where((b) =>
                        b.fullPath != DefaultOfflineResources.remoteMuyassarFullPath)
                    .toList();

                final seen = <String>{};
                booksInLanguage = booksInLanguage.where((b) => seen.add(b.fullPath)).toList();
              }

              booksInLanguage.sort((a, b) => b.score.compareTo(a.score));

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 0,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: ExpansionTile(
                  key: PageStorageKey(languageKey),
                  title: Text(
                    languageNativeNames[languageKey] ?? languageKey,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  children:
                      booksInLanguage.map((bookData) {
                        TafsirBookModel? matchedTafsir = downloadedTafsirs
                            .firstOrNullWhere(
                              (element) =>
                                  element.fullPath == bookData.fullPath,
                            );
                        bool needDownload = matchedTafsir == null;
                        bool isSelected = false;
                        if (!needDownload && selectedTafsir != null) {
                          if (selectedTafsir?.any(
                                (element) =>
                                    element.fullPath == matchedTafsir.fullPath,
                              ) ==
                              true) {
                            isSelected = true;
                          }
                        }

                        bool isDownloading = false;
                        if (downloadingData != null) {
                          if (downloadingData?.fullPath == bookData.fullPath) {
                            isDownloading = true;
                          }
                        }
                        return _buildBookListTile(
                          appLocalizations,
                          bookData,
                          isSelected,
                          needDownload,
                          isDownloading,
                          themeState,
                        );
                      }).toList(),
                ),
              );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookListTile(
    AppLocalizations appLocalizations,
    TafsirBookModel tafsirBook,
    bool isSelected,
    bool needDownload,
    bool isDownloading,
    ThemeState themeState,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 2.0,
      ),
      leading: buildScoreIndicator(percentage: tafsirBook.score, size: 32),
      title: Text(tafsirBook.name),
      trailing: SizedBox(
        height: 30,
        width: 30,
        child:
            isDownloading
                ? CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(themeState.primary),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : context.read<ThemeCubit>().state.primaryShade100,
                )
                : needDownload
                ? Icon(
                  FluentIcons.arrow_download_24_regular,
                  color: themeState.primary,
                )
                : isSelected
                ? Icon(
                  Icons.check_circle_rounded,
                  color: themeState.primary,
                  size: 26,
                )
                : Icon(
                  Icons.circle_outlined,
                  color: Colors.grey[600],
                  size: 26,
                ),
      ),
      onTap: () async {
        if (isDownloading) return;

        if (!isSelected && !needDownload) {
          await QuranTafsirFunction.setTafsirSelection(tafsirBook);
          _refreshData();
        } else if (isSelected) {
          await QuranTafsirFunction.removeTafsirSelection(tafsirBook);
          _refreshData();
        } else {
          setState(() {
            downloadingData = tafsirBook;
          });
          log(
            "Downloading Tafsir: ${tafsirBook.name}",
            name: "TafsirResourcesViewUI",
          );
          await QuranTafsirFunction.downloadResources(
            context: context,
            isSetupProcess: false,
            tafsirBook: tafsirBook,
          );

          if (await QuranTafsirFunction.isAlreadyDownloaded(tafsirBook)) {
            await QuranTafsirFunction.setTafsirSelection(tafsirBook);
          }
          _refreshData();
        }
      },
    );
  }
}
