import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:qcf_quran/qcf_quran.dart";

/// Options sheet that appears when long pressing on an Ayah
/// Contains: Share as image, Share with Tafsir, View Tafsir, Listen, Bookmark, Copy, Share as text
class AyahOptionsSheet extends StatelessWidget {
  final String ayahKey;
  final String ayahText;
  final VoidCallback? onShareAsImage;
  final VoidCallback? onShareWithTafsir;
  final VoidCallback? onViewTafsir;
  final VoidCallback? onWordsPronunciation;
  final VoidCallback? onNotes;
  final VoidCallback? onListen;
  final Future<void> Function()? onListenRange;
  final VoidCallback? onBookmark;
  final Future<void> Function(String colorId)? onSetBookmarkColor;
  final Future<void> Function()? onRemoveBookmark;
  final VoidCallback? onCopy;
  final VoidCallback? onShareAsText;

  const AyahOptionsSheet({
    super.key,
    required this.ayahKey,
    required this.ayahText,
    this.onShareAsImage,
    this.onShareWithTafsir,
    this.onViewTafsir,
    this.onWordsPronunciation,
    this.onNotes,
    this.onListen,
    this.onListenRange,
    this.onBookmark,
    this.onSetBookmarkColor,
    this.onRemoveBookmark,
    this.onCopy,
    this.onShareAsText,
  });

  /// Show the options sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String ayahKey,
    required String ayahText,
    VoidCallback? onShareAsImage,
    VoidCallback? onShareWithTafsir,
    VoidCallback? onViewTafsir,
    VoidCallback? onWordsPronunciation,
    VoidCallback? onNotes,
    VoidCallback? onListen,
    Future<void> Function()? onListenRange,
    VoidCallback? onBookmark,
    Future<void> Function(String colorId)? onSetBookmarkColor,
    Future<void> Function()? onRemoveBookmark,
    VoidCallback? onCopy,
    VoidCallback? onShareAsText,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AyahOptionsSheet(
        ayahKey: ayahKey,
        ayahText: ayahText,
        onShareAsImage: onShareAsImage,
        onShareWithTafsir: onShareWithTafsir,
        onViewTafsir: onViewTafsir,
        onWordsPronunciation: onWordsPronunciation,
        onNotes: onNotes,
        onListen: onListen,
        onListenRange: onListenRange,
        onBookmark: onBookmark,
        onSetBookmarkColor: onSetBookmarkColor,
        onRemoveBookmark: onRemoveBookmark,
        onCopy: onCopy,
        onShareAsText: onShareAsText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.read<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final setBookmarkColor = onSetBookmarkColor;
    final removeBookmark = onRemoveBookmark;

    const kWahyBookmarks = "wahy_bookmarks";
    final box = Hive.box("user");
    final rawBookmarks = box.get(kWahyBookmarks, defaultValue: const []) as List?;
    final bookmarks = (rawBookmarks ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final currentBookmark = bookmarks.firstWhere(
      (e) => (e["ayahKey"] as String?) == ayahKey,
      orElse: () => const <String, dynamic>{},
    );
    final currentColor = (currentBookmark["color"] as String?)?.trim();

    final parts = ayahKey.split(":");
    final surahNum = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final verseNum = parts.length == 2 ? int.tryParse(parts[1]) : null;

    final titleSurah = surahNum == null
        ? (parts.isNotEmpty ? parts[0] : "")
        : getSurahNameArabic(surahNum);
    final titleVerse = verseNum == null
        ? (parts.length == 2 ? parts[1] : "")
        : _toArabicDigits(verseNum.toString());
    final titleText = "${titleSurah.isEmpty ? "" : titleSurah}: ${titleVerse.isEmpty ? "" : titleVerse}".trim();

    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F1E6);
    final card = isDark ? const Color(0xFF252525) : const Color(0xFFFFF9F2);
    final onBg = isDark ? Colors.white : const Color(0xFF1B1B1B);
    final dividerColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06);
    final subtitleColor = onBg.withValues(alpha: 0.55);
    final green = themeState.primary;

    final colors = <String, ({String name, Color color})>{
      "red": (name: "الأحمر", color: const Color(0xFFB3261E)),
      "yellow": (name: "الأصفر", color: const Color(0xFFB68A00)),
      "green": (name: "الأخضر", color: themeState.primary),
      "blue": (name: "الأزرق", color: const Color(0xFF2962FF)),
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (currentColor != null && currentColor.isNotEmpty) {
                              await removeBookmark?.call();
                            } else {
                              if (setBookmarkColor != null) {
                                await setBookmarkColor("green");
                              } else {
                                onBookmark?.call();
                              }
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: Icon(
                            (currentColor != null && currentColor.isNotEmpty)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: (currentColor != null && currentColor.isNotEmpty)
                                ? const Color(0xFFFFB300)
                                : subtitleColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onShareAsImage?.call();
                          },
                          icon: Icon(
                            Icons.share_outlined,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        titleText,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: "Uthmanic",
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: onBg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(height: 1, color: dividerColor),
                const SizedBox(height: 12),

                _MenuGroup(
                  children: [
                    _MenuItem(
                      title: (currentColor != null && currentColor.isNotEmpty)
                          ? "إزالة الفاصل"
                          : "فاصل تلقائي",
                      subtitle: (currentColor != null && currentColor.isNotEmpty)
                          ? "إزالة الفاصل من هذه الآية"
                          : "يحط فاصل بسرعة بنفس النوع الافتراضي",
                      trailing: Icon(
                        (currentColor != null && currentColor.isNotEmpty)
                            ? Icons.delete_outline_rounded
                            : Icons.bookmark_rounded,
                      ),
                      trailingColor: (currentColor != null && currentColor.isNotEmpty)
                          ? const Color(0xFF8F8F8F)
                          : green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: () async {
                        Navigator.pop(context);
                        if (currentColor != null && currentColor.isNotEmpty) {
                          await removeBookmark?.call();
                          return;
                        }
                        if (setBookmarkColor != null) {
                          await setBookmarkColor("green");
                          return;
                        }
                        onBookmark?.call();
                      },
                    ),
                    _MenuItem(
                      title: "اختيار نوع الفاصل",
                      subtitle: "يفتح نافذة لاختيار لون/نوع الفاصل",
                      trailing: const Icon(Icons.tune_rounded),
                      trailingColor: green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: (setBookmarkColor == null && onBookmark == null)
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await showModalBottomSheet(
                                context: context,
                                useRootNavigator: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) {
                                  return Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(22),
                                          topRight: Radius.circular(22),
                                        ),
                                      ),
                                      child: SafeArea(
                                        top: false,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "أنواع الفواصل",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: onBg,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              _MenuGroup(
                                                cardColor: card,
                                                dividerColor: dividerColor,
                                                children: [
                                                  ...colors.entries.map((entry) {
                                                    final isSelected = currentColor == entry.key;
                                                    return _MenuItem(
                                                      title: entry.value.name,
                                                      trailing: isSelected
                                                          ? const Icon(Icons.check_circle_rounded)
                                                          : const Icon(Icons.bookmark_rounded),
                                                      trailingColor: entry.value.color,
                                                      onBg: onBg,
                                                      subtitleColor: subtitleColor,
                                                      onTap: () async {
                                                        Navigator.pop(ctx);
                                                        if (setBookmarkColor != null) {
                                                          await setBookmarkColor(entry.key);
                                                          return;
                                                        }
                                                        onBookmark?.call();
                                                      },
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                    ),
                  ],
                  cardColor: card,
                  dividerColor: dividerColor,
                ),
                const SizedBox(height: 12),

                _MenuGroup(
                  children: [
                    _MenuItem(
                      title: "تلاوة",
                      trailing: const Icon(Icons.play_arrow_rounded),
                      trailingColor: green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: onListen == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onListen?.call();
                            },
                    ),
                    _MenuItem(
                      title: "تشغيل إلى...",
                      trailing: const Icon(Icons.playlist_play_rounded),
                      trailingColor: green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: onListenRange == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onListenRange?.call();
                            },
                    ),
                  ],
                  cardColor: card,
                  dividerColor: dividerColor,
                ),
                const SizedBox(height: 12),

                _MenuGroup(
                  children: [
                    _MenuItem(
                      title: "المكتبة",
                      subtitle: "التفسير ومعاني الكلمات",
                      trailing: const Icon(Icons.menu_book_outlined),
                      trailingColor: green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: onViewTafsir == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onViewTafsir?.call();
                            },
                    ),
                    _MenuItem(
                      title: "نطق الكلمات",
                      subtitle: "عرض كلمات الآية وتشغيل نطق كل كلمة",
                      trailing: const Icon(Icons.record_voice_over_outlined),
                      trailingColor: green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: onWordsPronunciation == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onWordsPronunciation?.call();
                            },
                    ),
                  ],
                  cardColor: card,
                  dividerColor: dividerColor,
                ),
                const SizedBox(height: 12),

                _MenuGroup(
                  children: [
                    _MenuItem(
                      title: "الملاحظات",
                      trailing: const Icon(Icons.edit_outlined),
                      trailingColor: green,
                      onBg: onBg,
                      subtitleColor: subtitleColor,
                      onTap: onNotes == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              onNotes?.call();
                            },
                    ),
                  ],
                  cardColor: card,
                  dividerColor: dividerColor,
                ),

                const SizedBox(height: 6),
                SafeArea(
                  top: false,
                  child: SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ThemeState themeState,
    required VoidCallback onTap,
  }) {
    return const SizedBox.shrink();
  }

  String _formatAyahKey(String key) {
    final parts = key.split(":");
    if (parts.length == 2) {
      return "سورة ${parts[0]} - آية ${parts[1]}";
    }
    return key;
  }

  String _getVerseNumberInBrackets(String key) {
    final parts = key.split(":");
    if (parts.length != 2) return "";
    final verse = parts[1].trim();
    if (verse.isEmpty) return "";
    return "﴿${_toArabicDigits(verse)}﴾";
  }

  String _toArabicDigits(String number) {
    const arabics = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final buffer = StringBuffer();
    for (final ch in number.split('')) {
      final digit = int.tryParse(ch);
      if (digit == null) {
        buffer.write(ch);
      } else {
        buffer.write(arabics[digit]);
      }
    }
    return buffer.toString();
  }

  String _stripTrailingVerseNumber(String text) {
    var t = text.trimRight();
    t = t.replaceAll(RegExp(r"[\s\u06DD۝]+$"), "");
    t = t.replaceAll(RegExp(r"[\s0-9٠-٩۰-۹]+$"), "");
    return t.trimRight();
  }

  void _showShareOptions(
    BuildContext context,
    VoidCallback? onShareAsText,
    VoidCallback? onShareAsImage,
    VoidCallback? onShareWithTafsir,
    Color bg, Color card, Color onBg, Color subtitleColor, Color dividerColor, Color green,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "خيارات المشاركة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: onBg,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuGroup(
                      cardColor: card,
                      dividerColor: dividerColor,
                      children: [
                        _MenuItem(
                          title: "كنص",
                          subtitle: "ينسخ الآية + كل التفاسير المختارة بشكل مرتب",
                          trailing: const Icon(Icons.copy_rounded),
                          trailingColor: green,
                          onBg: onBg,
                          subtitleColor: subtitleColor,
                          onTap: onShareAsText == null ? null : () {
                            Navigator.pop(ctx);
                            onShareAsText();
                          },
                        ),
                        _MenuItem(
                          title: "كصورة (بدون تفسير)",
                          subtitle: "مشاركة الاية فقط كصورة - مناسب للآيات الطويلة",
                          trailing: const Icon(Icons.image_outlined),
                          trailingColor: green,
                          onBg: onBg,
                          subtitleColor: subtitleColor,
                          onTap: onShareAsImage == null ? null : () {
                            Navigator.pop(ctx);
                            onShareAsImage();
                          },
                        ),
                        _MenuItem(
                          title: "كصورة",
                          subtitle: "يصنع صورة بنفس تنسيق المكتبة (التفسير الميسر)",
                          trailing: const Icon(Icons.image_rounded),
                          trailingColor: green,
                          onBg: onBg,
                          subtitleColor: subtitleColor,
                          onTap: onShareWithTafsir == null ? null : () {
                            Navigator.pop(ctx);
                            onShareWithTafsir();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  final Color cardColor;
  final Color dividerColor;

  const _MenuGroup({
    required this.children,
    required this.cardColor,
    this.dividerColor = const Color(0x10000000),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _withDividers(children),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    if (items.length <= 1) return items;
    final out = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) {
        out.add(
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: dividerColor,
          ),
        );
      }
    }
    return out;
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final Color trailingColor;
  final Color onBg;
  final Color subtitleColor;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.onBg,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: onBg,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconTheme(
              data: IconThemeData(color: trailingColor, size: 22),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}
