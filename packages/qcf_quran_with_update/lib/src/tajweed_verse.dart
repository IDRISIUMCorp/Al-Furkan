import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qcf_quran/qcf_quran.dart';

class TajweedVerse extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final List<String> tajweedWords;
  final bool enableTajweed;
  final bool isLightMode;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;

  /// Optional theme configuration for customizing backgrounds.
  final QcfThemeData? theme;

  /// Word highlighting configuration (e.g., for word-by-word tracking)
  final List<HighlightRange>? highlights;

  final VoidCallback? onLongPress;
  final Function(LongPressDownDetails)? onLongPressDown;
  final VoidCallback? onLongPressUp;
  final VoidCallback? onLongPressCancel;
  final void Function(int wordIndex)? onWordTap;

  const TajweedVerse({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.tajweedWords,
    required this.isLightMode,
    this.enableTajweed = true,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.textDirection = TextDirection.rtl,
    this.theme,
    this.highlights,
    this.onLongPress,
    this.onLongPressDown,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onWordTap,
  });

  @override
  State<TajweedVerse> createState() => _TajweedVerseState();
}

class _TajweedVerseState extends State<TajweedVerse> {
  @override
  Widget build(BuildContext context) {
    if (widget.tajweedWords.isEmpty) return const SizedBox.shrink();

    final effectiveTheme = widget.theme ?? const QcfThemeData();
    final verseBgColor = effectiveTheme.verseBackgroundColor?.call(
      widget.surahNumber,
      widget.verseNumber,
    );

    final defaultStyle =
        widget.textStyle ??
        const TextStyle(fontFamily: "QPC_Hafs", fontSize: 24, height: 2.0);

    final spans = List<InlineSpan>.generate(widget.tajweedWords.length, (
      index,
    ) {
      return parseTajweedWord(
        wordWithTajweed: widget.tajweedWords[index],
        wordIndex: index,
        baseStyle: defaultStyle,
        isLight: widget.isLightMode,
        enableTajweed: widget.enableTajweed,
        highlights: widget.highlights,
        onTap: widget.onWordTap != null ? () => widget.onWordTap!(index) : null,
      );
    });

    final verseNumberGlyph = getVerseNumberQCF(
      widget.surahNumber,
      widget.verseNumber,
      verseEndSymbol: false,
    );
    final pageNumber = getPageNumber(widget.surahNumber, widget.verseNumber);

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onLongPressDown: widget.onLongPressDown,
      onLongPressUp: widget.onLongPressUp,
      onLongPressCancel: widget.onLongPressCancel,
      child: SelectionArea(
        child: Container(
          color: verseBgColor,
          child: Text.rich(
            TextSpan(
              children: [
                ...spans,
                if (verseNumberGlyph.isNotEmpty)
                  TextSpan(
                    text: "${verseNumberGlyph.trim()} ",
                    style: TextStyle(
                      fontFamily:
                          "QCF_P${pageNumber.toString().padLeft(3, '0')}",
                      color: effectiveTheme.verseNumberColor,
                      height: effectiveTheme.verseNumberHeight.h,
                      backgroundColor:
                          effectiveTheme.verseNumberBackgroundColor ??
                          verseBgColor,
                    ),
                  ),
              ],
            ),
            textAlign: widget.textAlign,
            textDirection: widget.textDirection,
          ),
        ),
      ),
    );
  }
}
