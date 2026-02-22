import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_translation_function.dart";
import "package:al_quran_v3/src/resources/quran_resources/models/translation_book_model.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class TranslationResourcesView extends StatefulWidget {
  const TranslationResourcesView({super.key});

  @override
  State<TranslationResourcesView> createState() =>
      _TranslationResourcesViewState();
}

class _TranslationResourcesViewState extends State<TranslationResourcesView> {
  List<TranslationBookModel> downloadedTranslation =
      QuranTranslationFunction.getDownloadedTranslationBooks();
  List<TranslationBookModel?>? selectedResources;

  TranslationBookModel? downloadingData;

  void _refreshData() async {
    selectedResources =
        await QuranTranslationFunction.getTranslationSelections();
    downloadedTranslation =
        QuranTranslationFunction.getDownloadedTranslationBooks();
    downloadingData = null;
    setState(() {});
  }

  @override
  void initState() {
    _refreshData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeState themeState = context.watch<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? const Color(0xFF2C2C2C) : themeState.primaryShade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? themeState.primary.withValues(alpha: 0.5) : themeState.primaryShade200),
            ),
            child: Text(
              "الترجمات هتتضاف في تحديثات قادمة إن شاء الله.",
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
