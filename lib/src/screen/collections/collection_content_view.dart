
import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/screen/collections/models/note_collection_model.dart";
import "package:al_quran_v3/src/screen/collections/models/note_model.dart";
import "package:al_quran_v3/src/screen/collections/models/pinned_collection_model.dart";
import "package:al_quran_v3/src/theme/values/values.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:al_quran_v3/src/utils/quran_ayahs_function/get_page_number.dart";
import "package:al_quran_v3/src/utils/quran_resources/get_translation_with_word_by_word.dart";
import "package:al_quran_v3/src/utils/quran_resources/quran_script_function.dart";
import "package:al_quran_v3/src/widget/ayah_by_ayah/ayah_by_ayah_card.dart";
import "package:al_quran_v3/src/widget/quran_script/model/script_info.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:gap/gap.dart";
import "package:qcf_quran/qcf_quran.dart" hide getPageNumber;

class CollectionContentView extends StatefulWidget {
  final NoteCollectionModel? noteCollectionModel;
  final PinnedCollectionModel? pinnedCollectionModel;
  final Function(int, String)? onOpenLocation;

  const CollectionContentView({
    super.key,
    this.noteCollectionModel,
    this.pinnedCollectionModel,
    this.onOpenLocation,
  });

  @override
  State<CollectionContentView> createState() => _CollectionContentViewState();
}

class _CollectionContentViewState extends State<CollectionContentView> {
  late Future<void> _scriptInitFuture;

  @override
  void initState() {
    assert(
      !(widget.noteCollectionModel == null &&
          widget.pinnedCollectionModel == null),
      "NoteCollectionModel or PinnedCollectionModel must be provided",
    );
    assert(
      !(widget.noteCollectionModel != null &&
          widget.pinnedCollectionModel != null),
      "NoteCollectionModel & PinnedCollectionModel both cannot be provided",
    );
    // Ensure Quran script Hive boxes are open so _getAyahPreview works
    _scriptInitFuture =
        QuranScriptFunction.initQuranScript(QuranScriptType.uthmani);
    super.initState();
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FluentIcons.info_24_regular,
              size: 50,
              color: Colors.grey,
            ),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getAyahPreview(String ayahKey) {
    final parts = ayahKey.split(":");
    if (parts.length != 2) return "";
    try {
      final words = QuranScriptFunction.getWordListOfAyah(
        QuranScriptType.tajweed,
        parts[0],
        parts[1],
      );
      final clean = words
          .map((w) => w
              .replaceAll(RegExp(r"<[^>]+>"), "")
              .replaceAll("\uFD3E", "")
              .replaceAll("\uFD3F", "")
              .replaceAll(RegExp(r"[0-9\u0660-\u0669]+"), "")
              .trim())
          .where((w) => w.isNotEmpty)
          .toList();
      if (clean.isEmpty) return "";
      final joined = clean.join(" ");
      return joined.length > 120 ? "${joined.substring(0, 120)}…" : joined;
    } catch (_) {
      return "";
    }
  }

  Widget _buildNoteItem(NoteModel noteModel, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(roundedRadius),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              l10n.note,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Gap(4),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(roundedRadius - 4),
            ),
            child: Text(noteModel.text, style: textTheme.bodyMedium),
          ),
          if (noteModel.ayahKey.isNotEmpty) ...[
            const Gap(12),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                l10n.linkedAyahs,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(4),
            Column(
              children: noteModel.ayahKey.map((key) {
                final parts = key.split(":");
                final surahNum = int.tryParse(parts[0]) ?? 1;
                final surahName = getSurahNameArabic(surahNum);
                final verseNum = parts.length == 2
                    ? localizedNumber(context, int.tryParse(parts[1]) ?? 1)
                    : key;
                final ayahPreview = _getAyahPreview(key);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(roundedRadius - 4),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    title: Text(
                      "$surahName: الآية $verseNum",
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: ayahPreview.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              ayahPreview,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: "KFGQPC-Uthmanic-HAFS-Regular",
                                fontSize: 15,
                                height: 1.8,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          )
                        : null,
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      if (widget.onOpenLocation != null) {
                        final page = getPageNumber(key) ?? 1;
                        widget.onOpenLocation!(page, key);
                      } else {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.noteCollectionModel != null
                  ? FluentIcons.note_24_regular
                  : FluentIcons.pin_24_filled,
            ),
            const Gap(10),
            Expanded(
              child: Text(
                widget.noteCollectionModel?.name ??
                    widget.pinnedCollectionModel!.name,
                style: textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _scriptInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(context, l10n);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (widget.noteCollectionModel != null) {
      if (widget.noteCollectionModel!.notes.isEmpty) {
        return _buildEmptyState(l10n.emptyNoteCollection);
      }
      return ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: widget.noteCollectionModel!.notes.length,
        itemBuilder: (context, index) {
          NoteModel noteModel = widget.noteCollectionModel!.notes[index];
          return _buildNoteItem(noteModel, context);
        },
        separatorBuilder: (context, index) => const Gap(0),
      );
    } else if (widget.pinnedCollectionModel != null) {
      if (widget.pinnedCollectionModel!.pinned.isEmpty) {
        return _buildEmptyState(l10n.emptyPinnedCollection);
      }
      return ListView.builder(
        itemCount: widget.pinnedCollectionModel!.pinned.length,
        itemBuilder: (context, index) {
          final TranslationWithWordByWord? translationData =
              getTranslationFromCache(
            widget.pinnedCollectionModel!.pinned[index].ayahKey,
          );
          return translationData != null
              ? getAyahByAyahCard(
                  ayahKey:
                      widget.pinnedCollectionModel!.pinned[index].ayahKey,
                  context: context,
                  showFullKey: true,
                  translationListWithInfo:
                      translationData.translationList,
                  wordByWord: translationData.wordByWord ?? [],
                )
              : FutureBuilder(
                  future: getTranslationWithWordByWord(
                    widget.pinnedCollectionModel!.pinned[index].ayahKey,
                  ),
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const SizedBox(height: 250);
                    }
                    return getAyahByAyahCard(
                      ayahKey: widget
                          .pinnedCollectionModel!
                          .pinned[index]
                          .ayahKey,
                      context: context,
                      showFullKey: true,
                      translationListWithInfo:
                          asyncSnapshot.data?.translationList ?? [],
                      wordByWord:
                          asyncSnapshot.data?.wordByWord ?? [],
                    );
                  },
                );
        },
      );
    }
    return _buildEmptyState(l10n.noContentAvailable);
  }
}
