import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:flutter_animate/flutter_animate.dart';
// ignore: implementation_imports
import 'package:qcf_quran/src/data/page_font_size.dart';

class QcfVerse extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final double? fontSize;

  /// Optional theme configuration for customizing all visual aspects.
  /// If null, uses default theme values.
  final QcfThemeData? theme;

  /// Verse text color.
  /// DEPRECATED: Use theme.verseTextColor instead.
  final Color textColor;

  /// Background color for verse.
  /// DEPRECATED: Use theme.verseBackgroundColor instead.
  final Color backgroundColor;

  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressUp;

  final VoidCallback? onLongPressCancel;
  final Function(LongPressDownDetails)? onLongPressDown;
  
  /// Whether to render the verse using Tajweed colored text.
  final bool showTajweed;

  /// The list of tajweed words for this verse. If [showTajweed] is true and this is provided, 
  /// it will render a [TajweedVerse] instead of standard QCF.
  final List<String>? tajweedWords;

  /// Optional list of highlights to apply to specific words.
  final List<HighlightRange>? highlights;

  //sp (adding 1.sp to get the ratio of screen size for responsive font design)
  final double sp;

  //h (adding 1.h to get the ratio of screen size for responsive font design)
  final double h;

  const QcfVerse({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    this.fontSize,
    this.theme,
    this.textColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0x00000000),
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressDown,
    this.onLongPressCancel,
    this.showTajweed = false,
    this.tajweedWords,
    this.highlights,
    this.sp = 1,
    this.h = 1,
  });

  @override
  State<QcfVerse> createState() => _QcfVerseState();
}

class _QcfVerseState extends State<QcfVerse> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    var pageNumber = getPageNumber(widget.surahNumber, widget.verseNumber);

        final effectiveTheme = widget.theme ?? const QcfThemeData();

        final verseTextColor = widget.theme?.verseTextColor ?? widget.textColor;
        final verseBgColor =
            widget.theme?.verseBackgroundColor?.call(
              widget.surahNumber,
              widget.verseNumber,
            ) ??
            ((widget.backgroundColor.a * 255.0).round() > 0
                ? widget.backgroundColor
                : null);

        if (widget.showTajweed && widget.tajweedWords != null && widget.tajweedWords!.isNotEmpty) {
          return TajweedVerse(
            surahNumber: widget.surahNumber,
            verseNumber: widget.verseNumber,
            tajweedWords: widget.tajweedWords!,
            isLightMode: Theme.of(context).brightness == Brightness.light,
            enableTajweed: true,
            theme: effectiveTheme,
            highlights: widget.highlights,
            textStyle: TextStyle(
              fontSize: widget.fontSize?.sp ?? getFontSize(pageNumber, MediaQuery.of(context).size.width).sp,
              color: verseTextColor,
              height: effectiveTheme.verseHeight.h,
            ),
            onLongPress: widget.onLongPress,
            onLongPressDown: widget.onLongPressDown,
            onLongPressUp: widget.onLongPressUp,
            onLongPressCancel: widget.onLongPressCancel,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth =
                constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;

            var pageFontSize = getFontSize(pageNumber, maxWidth);
            
            final rawQcf = getVerseQCF(
              widget.surahNumber,
              widget.verseNumber,
              verseEndSymbol: false,
            );
            
            final List<InlineSpan> verseSpans = [];
            if (widget.highlights != null && widget.highlights!.isNotEmpty) {
              for (int i = 0; i < rawQcf.length; i++) {
                final hl = widget.highlights!.where((h) => h.wordIndex == i).firstOrNull;
                verseSpans.add(TextSpan(
                  text: rawQcf[i],
                  style: TextStyle(
                    backgroundColor: hl?.color,
                  ),
                ));
              }
            } else {
              verseSpans.add(TextSpan(text: rawQcf));
            }

            return SelectionArea(
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      recognizer:
                          LongPressGestureRecognizer()
                            ..onLongPress = widget.onLongPress
                            ..onLongPressDown = (d) {
                              setState(() => _isPressed = true);
                              widget.onLongPressDown?.call(d);
                            }
                            ..onLongPressUp = () {
                              setState(() => _isPressed = false);
                              widget.onLongPressUp?.call();
                            }
                            ..onLongPressCancel = () {
                              setState(() => _isPressed = false);
                              widget.onLongPressCancel?.call();
                            },
                      locale: const Locale("ar"),
                      children: [
                        ...verseSpans,
                        TextSpan(
                          text: getVerseNumberQCF(
                            widget.surahNumber,
                            widget.verseNumber,
                          ),
                          style: TextStyle(
                            fontFamily:
                                "QCF_P${pageNumber.toString().padLeft(3, '0')}",
                          package: 'qcf_quran',
                            color: effectiveTheme.verseNumberColor,
                            height: effectiveTheme.verseNumberHeight.h,
                            backgroundColor:
                                effectiveTheme.verseNumberBackgroundColor ??
                                verseBgColor,
                          ),
                        ),
                      ],
                      style: TextStyle(
                        color: verseTextColor,
                        height: effectiveTheme.verseHeight.h,
                        letterSpacing: effectiveTheme.letterSpacing,
                        wordSpacing: effectiveTheme.wordSpacing,
                        fontFamily:
                            "QCF_P${pageNumber.toString().padLeft(3, '0')}",
                        package: 'qcf_quran',
                        fontSize: widget.fontSize?.sp ?? pageFontSize.sp,
                        backgroundColor: verseBgColor,
                      ),
                    ),
                  ),
                )
                .animate(target: _isPressed ? 1 : 0)
                .scaleXY(end: 0.98, duration: 150.ms, curve: Curves.easeOut)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
          },
        );
  }
}
