import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/utils/quran_resources/word_by_word_function.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/translation_book_model.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class WordByWordResourcesView extends StatefulWidget {
  const WordByWordResourcesView({super.key});

  @override
  State<WordByWordResourcesView> createState() =>
      _WordByWordResourcesViewState();
}

class _WordByWordResourcesViewState extends State<WordByWordResourcesView> {
  List<TranslationBookModel> downloadedWbW = [];
  TranslationBookModel? selectedWbw;
  TranslationBookModel? downloadingWbW;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await WordByWordFunction.init();
    setState(() {
      downloadedWbW = WordByWordFunction.getDownloadedWordByWordBooks();
      selectedWbw = WordByWordFunction.getSelectedWordByWordBook();
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.watch<ThemeCubit>().state;
    AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: themeState.primaryShade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: themeState.primaryShade200),
            ),
            child: Text(
              "ميزة كلمة بكلمة هتتضاف في تحديثات قادمة إن شاء الله.",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: themeState.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
