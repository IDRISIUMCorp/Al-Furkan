import "dart:ui";
import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/screen/collections/collection_page.dart";
import "package:al_quran_v3/src/screen/collections/models/note_collection_model.dart";
import "package:al_quran_v3/src/screen/collections/models/note_model.dart";
import "package:fluentui_system_icons/fluentui_system_icons.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:gap/gap.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:uuid/uuid.dart";

import "../../screen/collections/common_function.dart";
import "../../theme/controller/theme_cubit.dart";
import "../../theme/controller/theme_state.dart";

var uuid = const Uuid();

Future<void> showAddNotePopup(BuildContext context, String ayahKey) async {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: AddNoteWidget(ayahKey: ayahKey, isDark: isDark),
      );
    },
  );
}

class AddNoteWidget extends StatefulWidget {
  final String ayahKey;
  final bool isDark;

  const AddNoteWidget({super.key, required this.ayahKey, required this.isDark});

  @override
  State<AddNoteWidget> createState() => _AddNoteWidgetState();
}

class _AddNoteWidgetState extends State<AddNoteWidget> {
  final _noteEditingController = TextEditingController();
  final _newCollectionNameController = TextEditingController();

  bool _selectNoteCollectionStep = false;
  bool _addNewNoteCollectionStep = false;

  List<NoteCollectionModel> _availableNoteCollections = [];
  final Set<String> _selectedNoteCollectionIds = {};

  @override
  void initState() {
    super.initState();
    fetchNoteCollections().then((value) {
      if (mounted) {
        setState(() {
          _availableNoteCollections = value;
        });
      }
    });
  }

  void _handleSaveNote() {
    if (_noteEditingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noteContentCannotBeEmpty),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    String newNoteId = uuid.v4();

    final newNote = NoteModel(
      id: newNoteId,
      ayahKey: [widget.ayahKey],
      text: _noteEditingController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final notesBox = Hive.box(CollectionType.notes.name);
    for (String collectionID in _selectedNoteCollectionIds) {
      NoteCollectionModel collection = NoteCollectionModel.fromJson(
        Map<String, dynamic>.from(notesBox.get(collectionID)),
      );
      collection.updatedAt = now;
      collection.notes.add(newNote);
      notesBox.put(collectionID, collection.toJson());
    }

    Navigator.pop(context); // Close the dialog
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context).noteSavedSuccessfully,
    );
  }

  @override
  void dispose() {
    _noteEditingController.dispose();
    _newCollectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeState themeState = context.read<ThemeCubit>().state;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = widget.isDark;

    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color inputBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeState.primaryShade100.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: themeState.primaryShade100.withValues(alpha: 0.3),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       _selectNoteCollectionStep ? FluentIcons.folder_add_24_filled : FluentIcons.note_add_24_filled,
                       color: themeState.primary,
                       size: 20,
                     ),
                   ),
                  const Gap(12),
                  Text(
                    _selectNoteCollectionStep ? l10n.selectCollections : l10n.addNote,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  if (_selectNoteCollectionStep && !_addNewNoteCollectionStep)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _addNewNoteCollectionStep = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: themeState.primary,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(FluentIcons.add_24_regular, size: 18),
                      label: Text(l10n.newText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const Gap(16),
              if (_selectNoteCollectionStep)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _addNewNoteCollectionStep ? 300 : 250,
                  child: Column(
                    children: [
                      if (_addNewNoteCollectionStep) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: inputBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: themeState.primaryShade100.withValues(alpha: 0.3)),
                                ),
                                child: TextFormField(
                                  controller: _newCollectionNameController,
                                  autofocus: true,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: l10n.writeCollectionName,
                                    hintStyle: TextStyle(color: subtitleColor),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const Gap(10),
                            Container(
                              decoration: BoxDecoration(
                                color: themeState.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  NoteCollectionModel? newCollection = await handleAddNewNoteCollection(
                                    _newCollectionNameController.text.trim(),
                                    l10n,
                                  );
                                  if (newCollection != null) {
                                    setState(() {
                                      _availableNoteCollections.add(newCollection);
                                      _selectedNoteCollectionIds.add(newCollection.id);
                                      _newCollectionNameController.clear();
                                      _addNewNoteCollectionStep = false;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.done_rounded, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const Gap(10),
                      ],
                      Expanded(
                        child: (_availableNoteCollections.isEmpty && !_addNewNoteCollectionStep && _addNewNoteCollectionStep)
                            ? Center(child: Text(l10n.noCollectionsYetAddANewOne, style: TextStyle(color: subtitleColor)))
                            : ListView.separated(
                                separatorBuilder: (_, __) => const Gap(8),
                                itemCount: _availableNoteCollections.length,
                                itemBuilder: (context, index) {
                                  final collection = _availableNoteCollections[index];
                                  final isSelected = _selectedNoteCollectionIds.contains(collection.id);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? themeState.primaryShade100.withValues(alpha: 0.15) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: isSelected ? themeState.primary : themeState.primaryShade100.withValues(alpha: 0.3)),
                                    ),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      minTileHeight: 48,
                                      leading: Icon(
                                        FluentIcons.folder_24_filled,
                                        color: Color(int.parse("0xFF${collection.colorHex}")),
                                      ),
                                      title: Text(collection.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                                      subtitle: Text("${collection.notes.length} notes", style: TextStyle(color: subtitleColor, fontSize: 12)),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? themeState.primary : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: isSelected ? themeState.primary : Colors.grey.shade400),
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: isSelected ? Colors.white : Colors.transparent,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedNoteCollectionIds.remove(collection.id);
                                          } else {
                                            _selectedNoteCollectionIds.add(collection.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              if (!_selectNoteCollectionStep)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeState.primaryShade100.withValues(alpha: 0.3)),
                  ),
                  child: TextFormField(
                    controller: _noteEditingController,
                    maxLines: 10,
                    minLines: 5,
                    autofocus: true,
                    autocorrect: true,
                    style: TextStyle(color: textColor, height: 1.5),
                    decoration: InputDecoration(
                      hintText: "أكتب ملاحظتك هنا...",
                      hintStyle: TextStyle(color: subtitleColor),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              const Gap(20),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    if (_selectNoteCollectionStep) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: inputBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: textColor),
                          onPressed: () {
                            setState(() {
                              _selectNoteCollectionStep = false;
                              _addNewNoteCollectionStep = false;
                            });
                          },
                        ),
                      ),
                      const Gap(10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeState.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (!_selectNoteCollectionStep) {
                            if (_noteEditingController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.pleaseWriteYourNoteFirst, style: const TextStyle(color: Colors.white)),
                                  backgroundColor: themeState.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _selectNoteCollectionStep = true;
                            });
                          } else {
                            if (_selectedNoteCollectionIds.isEmpty) {
                              Fluttertoast.showToast(msg: l10n.noCollectionSelected);
                            } else {
                              _handleSaveNote();
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectNoteCollectionStep) ...[
                              const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
                              const Gap(8),
                            ],
                            Text(
                              _selectNoteCollectionStep ? l10n.saveNote : l10n.nextSelectCollections,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!_selectNoteCollectionStep) ...[
                              const Gap(8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> saveDemoNoteCollection() async {
  final box = Hive.box(CollectionType.notes.name);
  if (box.values.isEmpty) {
    List<NoteCollectionModel> collections = [
      NoteCollectionModel(
        id: "col1",
        name: "Reflections",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: [],
      ),
      NoteCollectionModel(
        id: "col2",
        name: "Favourites",
        colorHex: "FFAB00",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: [],
      ),
    ];
    for (NoteCollectionModel model in collections) {
      await box.put(model.id, model.toJson());
    }
  }
}
