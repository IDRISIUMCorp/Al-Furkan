import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qcf_quran/qcf_quran.dart';
// ignore: implementation_imports
import 'package:qcf_quran/src/data/page_font_size.dart';

///
/// Use this if you want to build your own [PageView] or layout
/// and need granular control over each page's state and rendering.
class QcfPage extends StatelessWidget {
  /// The 1-based page number (1..604).
  final int pageNumber;

  /// Theme configuration for styling the page.
  final QcfThemeData theme;

  /// Optional font size override.
  final double? fontSize;

  /// Scaling factor for screen width/pixel density (default 1.0).
  /// Used for responsive sizing of fonts and layout.
  final double sp;

  /// Scaling factor for screen height (default 1.0).
  /// Used for responsive vertical spacing.
  final double h;

  /// Callback when a verse is long-pressed.
  final void Function(int surahNumber, int verseNumber)? onLongPress;

  /// Callback when long-press ends.
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;

  /// Callback when long-press is cancelled.
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;

  /// Callback when long-press starts (includes details).
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;

  /// Callback when a verse is tapped.
  final void Function(int surahNumber, int verseNumber)? onTap;

  /// Callback when a verse is double-tapped.
  final void Function(int surahNumber, int verseNumber)? onDoubleTap;

  /// Callback when a verse is touched down (finger placed).
  /// Useful for immediate highlighting.
  final void Function(int surahNumber, int verseNumber, TapDownDetails details)?
  onTapDown;

  /// Optional callback to customize verse background color dynamically.
  /// This takes precedence over [theme.verseBackgroundColor] if provided.
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;

  /// Whether to render the page using Tajweed colored text.
  final bool showTajweed;

  /// Callback to get Tajweed words list for a specific verse.
  final List<String> Function(int surahNumber, int verseNumber)? tajweedWordsBuilder;

  /// Callback to get highlights for a specific verse.
  final List<HighlightRange> Function(int surahNumber, int verseNumber)? highlightsBuilder;

  const QcfPage({
    super.key,
    required this.pageNumber,
    this.theme = const QcfThemeData(),
    this.fontSize,
    this.sp = 1.0,
    this.h = 1.0,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.onTap,
    this.onDoubleTap,
    this.onTapDown,
    this.verseBackgroundColor,
    this.showTajweed = false,
    this.tajweedWordsBuilder,
    this.highlightsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Validate page number
    if (pageNumber < 1 || pageNumber > 604) {
      return Center(child: Text('Invalid page number: $pageNumber'));
    }

    final ranges = getPageData(pageNumber);
    final pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";

    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;

    final double _baselineWidth = isTablet ? 640 : 470;
    final double _fontScale = isTablet ? 1.30 : 1.18;
    final double baseFontSize =
        (fontSize ?? getFontSize(pageNumber, _baselineWidth)) * _fontScale;

    final double minAllPagesFontSize =
        (size.width * (isTablet ? 0.048 : 0.045)).clamp(18.0, 34.0);
    final double minFirstPagesFontSize =
        (size.width * 0.075).clamp(26.0, 36.0);

    final bool isFirstPages = pageNumber == 1 || pageNumber == 2;
    final double finalFontSize = isFirstPages
        ? baseFontSize.clamp(minFirstPagesFontSize, 44.0)
        : baseFontSize.clamp(minAllPagesFontSize, 44.0);
    final double finalHeight =
        isFirstPages ? 2.15 : (theme.verseHeight * (isTablet ? 0.93 : 0.96));

        final verseSpans = <InlineSpan>[];
        final firstPagesSpacer =
            (pageNumber == 1 || pageNumber == 2)
                ? theme.firstPagesTopSpacerFactor
                : 0.0;
        if (firstPagesSpacer > 0) {
          verseSpans.add(
            WidgetSpan(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * firstPagesSpacer,
              ),
            ),
          );
        }
        for (final r in ranges) {
          final surah = int.parse(r['surah'].toString());
          final start = int.parse(r['start'].toString());
          final end = int.parse(r['end'].toString());

          for (int v = start; v <= end; v++) {
            if (v == start && v == 1) {
              if (theme.showHeader) {
                verseSpans.add(
                  WidgetSpan(
                    child: HeaderWidget(suraNumber: surah, theme: theme),
                  ),
                );
              }
              if (theme.showBasmala && pageNumber != 1 && pageNumber != 187) {
                // Check for custom Basmala builder
                if (theme.basmalaBuilder != null) {
                  verseSpans.add(
                    WidgetSpan(
                      child: theme.basmalaBuilder!(surah),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  );
                  // Add a newline after custom builder to maintain layout flow if needed
                  // or let the builder handle it. Usually basmala is a block.
                  // We'll add a newline ensuring separation.
                  verseSpans.add(const TextSpan(text: "\n"));
                } else {
                  if (surah != 97 && surah != 95) {
                    verseSpans.add(
                      TextSpan(
                        text: " ﱁ  ﱂﱃﱄ\n",
                        style: TextStyle(
                          fontFamily: "QCF_P001",
                          package: 'qcf_quran',
                          fontSize:
                              getScreenType(context) == ScreenType.large
                                  ? (theme.basmalaFontSizeLarge * sp).sp
                                  : (theme.basmalaFontSizeSmall * sp).sp,
                          color: theme.basmalaColor,
                        ),
                      ),
                    );
                  } else {
                    verseSpans.add(
                      TextSpan(
                        text: "齃𧻓𥳐龎\n",
                        style: TextStyle(
                          fontFamily: "QCF_BSML",
                          package: 'qcf_quran',
                          fontSize:
                              getScreenType(context) == ScreenType.large
                                  ? (theme.basmalaSpecialFontSizeLarge * sp).sp
                                  : (theme.basmalaSpecialFontSizeSmall * sp).sp,
                          color: theme.basmalaColor,
                        ),
                      ),
                    );
                  }
                }
              }
            }

            // Gesture Handling
            GestureRecognizer? recognizer;
            final bool hasAnyGesture =
                onTap != null ||
                onTapDown != null ||
                onDoubleTap != null ||
                onLongPress != null ||
                onLongPressDown != null ||
                onLongPressUp != null ||
                onLongPressCancel != null;
            if (hasAnyGesture) {
              recognizer = _VerseGestureRecognizer(
                onTap: onTap != null ? () => onTap!.call(surah, v) : null,
                onDoubleTap:
                    onDoubleTap != null
                        ? () => onDoubleTap!.call(surah, v)
                        : null,
                onTapDown:
                    onTapDown != null
                        ? (d) => onTapDown!.call(surah, v, d)
                        : null,
                onLongPress:
                    onLongPress != null
                        ? () => onLongPress!.call(surah, v)
                        : null,
                onLongPressDown:
                    onLongPressDown != null
                        ? (d) => onLongPressDown!.call(surah, v, d)
                        : null,
                onLongPressUp:
                    onLongPressUp != null
                        ? () => onLongPressUp!.call(surah, v)
                        : null,
                onLongPressCancel:
                    onLongPressCancel != null
                        ? () => onLongPressCancel!.call(surah, v)
                        : null,
              );
            }

            final verseBgColor =
                theme.verseBackgroundColor?.call(surah, v) ??
                verseBackgroundColor?.call(surah, v);

            // Verse Number Logic
            InlineSpan verseNumberSpan;
            if (theme.verseNumberBuilder != null) {
              verseNumberSpan = theme.verseNumberBuilder!(
                surah,
                v,
                getVerseNumberQCF(surah, v),
              );
            } else {
              verseNumberSpan = TextSpan(
                text: getVerseNumberQCF(surah, v),
                style: TextStyle(
                  fontFamily: pageFont,
                  package: 'qcf_quran',
                  color: theme.verseNumberColor,
                  height: (theme.verseNumberHeight * h).h,
                  backgroundColor:
                      theme.verseNumberBackgroundColor ?? verseBgColor,
                ),
              );
            }

            if (showTajweed && tajweedWordsBuilder != null) {
              final words = tajweedWordsBuilder!(surah, v);

              // Important: if tajweed words aren't available (empty), fallback to
              // standard QCF rendering. Otherwise only the verse number glyph will
              // be rendered which makes the mushaf look like "numbers only".
              if (words.isNotEmpty) {
                final isLightMode =
                    Theme.of(context).brightness == Brightness.light;
                final defaultStyle = TextStyle(
                  fontFamily: "QPC_Hafs",
                  fontSize: finalFontSize,
                  height: finalHeight.h,
                  color: theme.verseTextColor,
                );

                final highlights = highlightsBuilder?.call(surah, v);
                final spans = List<InlineSpan>.generate(words.length, (index) {
                  final hl =
                      highlights?.where((h) => h.wordIndex == index).firstOrNull;

                  final tajweedSpan = parseTajweedWord(
                    wordWithTajweed: words[index],
                    wordIndex: index,
                    baseStyle: defaultStyle.copyWith(
                      backgroundColor: hl?.color,
                    ),
                    isLight: isLightMode,
                    enableTajweed: true, // It is already checked by showTajweed
                  );

                  return TextSpan(
                    children: [tajweedSpan, const TextSpan(text: " ")],
                    recognizer: recognizer,
                    style:
                        verseBgColor != null
                            ? TextStyle(backgroundColor: verseBgColor)
                            : null,
                  );
                });

                verseSpans.addAll(spans);
              } else {
                final highlights = highlightsBuilder?.call(surah, v);
                final rawQcf = getVerseQCF(surah, v, verseEndSymbol: false);
                final isFirstVerseOnPage = (v == ranges[0]["start"]);
                final String qcfText = isFirstVerseOnPage
                    ? "${rawQcf.substring(0, 1)}\u200A${rawQcf.substring(1)}"
                    : rawQcf;

                if (highlights != null && highlights.isNotEmpty) {
                  int charIndex = 0;
                  for (int i = 0; i < qcfText.length; i++) {
                    final char = qcfText[i];
                    final isSpacer = isFirstVerseOnPage && i == 1;
                    final hl = isSpacer
                        ? null
                        : highlights
                            .where((h) => h.wordIndex == charIndex)
                            .firstOrNull;

                    verseSpans.add(
                      TextSpan(
                        text: char,
                        recognizer: recognizer,
                        style: TextStyle(
                          fontFamily: pageFont,
                          package: 'qcf_quran',
                          fontSize: finalFontSize,
                          color: theme.verseTextColor,
                          height: finalHeight,
                          backgroundColor: hl?.color ?? verseBgColor,
                        ),
                      ),
                    );

                    if (!isSpacer) {
                      charIndex++;
                    }
                  }
                } else {
                  verseSpans.add(
                    TextSpan(
                      text: qcfText,
                      recognizer: recognizer,
                      style: TextStyle(
                        fontFamily: pageFont,
                        package: 'qcf_quran',
                        fontSize: finalFontSize,
                        color: theme.verseTextColor,
                        height: finalHeight,
                        backgroundColor: verseBgColor,
                      ),
                    ),
                  );
                }
              }
            } else {
              final highlights = highlightsBuilder?.call(surah, v);
              final rawQcf = getVerseQCF(surah, v, verseEndSymbol: false);
              final isFirstVerseOnPage = (v == ranges[0]['start']);
              final String qcfText = isFirstVerseOnPage
                  ? "${rawQcf.substring(0, 1)}\u200A${rawQcf.substring(1)}"
                  : rawQcf;

              if (highlights != null && highlights.isNotEmpty) {
                // Since QCF font maps 1 char to 1 word approximately, we split by characters.
                int charIndex = 0;
                for (int i = 0; i < qcfText.length; i++) {
                  final char = qcfText[i];
                  // If it's the zero-width space we added for the first verse, skip highlight indexing
                  final isSpacer = isFirstVerseOnPage && i == 1;
                  final hl = isSpacer ? null : highlights.where((h) => h.wordIndex == charIndex).firstOrNull;
                  
                  verseSpans.add(
                    TextSpan(
                      text: char,
                      recognizer: recognizer,
                      style: TextStyle(
                        fontFamily: pageFont,
                        package: 'qcf_quran',
                        fontSize: finalFontSize,
                        color: theme.verseTextColor,
                        height: finalHeight,
                        backgroundColor: hl?.color ?? verseBgColor,
                      ),
                    ),
                  );
                  
                  if (!isSpacer) {
                    charIndex++;
                  }
                }
              } else {
                verseSpans.add(
                  TextSpan(
                    text: qcfText,
                    recognizer: recognizer,
                    style: TextStyle(
                        fontFamily: pageFont,
                        package: 'qcf_quran',
                        fontSize: finalFontSize,
                        color: theme.verseTextColor,
                        height: finalHeight,
                        backgroundColor: verseBgColor,
                      ),
                  ),
                );
              }
            }

            verseSpans.add(verseNumberSpan);
          }
        }

        final pageOverlayTop = theme.pageTopOverlayBuilder?.call(
          pageNumber,
          int.parse(ranges.first['surah'].toString()),
          int.parse(ranges.first['start'].toString()),
        );

        final pageOverlayBottom = theme.pageBottomOverlayBuilder?.call(
          pageNumber,
          int.parse(ranges.first['surah'].toString()),
          int.parse(ranges.first['start'].toString()),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            // Using a fixed standard width (400) creates a perfect baseline rendering 
            // that FittedBox will then cleanly scale to any screen (tablet, web, mobile).
            return ColoredBox(
              color: theme.pageBackgroundColor,
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: _baselineWidth,
                        child: ColoredBox(
                          color: theme.pageBackgroundColor,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 4.0,
                              right: 4.0,
                              top: 0.0,
                              bottom: 8.0,
                            ),
                            child: ExcludeSemantics(
                              child: Text.rich(
                                TextSpan(children: verseSpans),
                                locale: const Locale("ar"),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: finalFontSize,
                                  color: theme.verseTextColor,
                                  height: finalHeight,
                                  letterSpacing: theme.letterSpacing,
                                  wordSpacing: theme.wordSpacing,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (pageOverlayTop != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: pageOverlayTop,
                      ),
                    if (pageOverlayBottom != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: pageOverlayBottom,
                      ),
                  ],
                ),
              ),
            );
          },
        );
  }
}

class _VerseGestureRecognizer extends GestureRecognizer {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final GestureTapDownCallback? onTapDown;
  final VoidCallback? onLongPress;
  final GestureLongPressStartCallback? onLongPressDown;
  final VoidCallback? onLongPressUp;
  final VoidCallback? onLongPressCancel;

  late final TapGestureRecognizer _tap;
  late final DoubleTapGestureRecognizer _doubleTap;
  late final LongPressGestureRecognizer _longPress;
  late final GestureArenaTeam _team;

  _VerseGestureRecognizer({
    this.onTap,
    this.onDoubleTap,
    this.onTapDown,
    this.onLongPress,
    this.onLongPressDown,
    this.onLongPressUp,
    this.onLongPressCancel,
  }) {
    _team = GestureArenaTeam();

    _tap =
        TapGestureRecognizer()
          ..team = _team
          ..onTap = onTap
          ..onTapDown = onTapDown;

    _doubleTap = DoubleTapGestureRecognizer()..onDoubleTap = onDoubleTap;

    _longPress =
        LongPressGestureRecognizer(duration: const Duration(milliseconds: 160))
          ..team = _team
          ..onLongPress = onLongPress
          ..onLongPressStart = onLongPressDown
          ..onLongPressUp = onLongPressUp
          ..onLongPressCancel = onLongPressCancel;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _tap.addPointer(event);
    _doubleTap.addPointer(event);
    _longPress.addPointer(event);
  }

  @override
  void acceptGesture(int pointer) {
    // No-op: inner recognizers participate in the arena.
  }

  @override
  void rejectGesture(int pointer) {
    // No-op: inner recognizers participate in the arena.
  }

  void handleEvent(PointerEvent event) {
    // no-op: inner recognizers handle events
  }

  void didStopTrackingLastPointer(int pointer) {
    // no-op
  }

  @override
  void dispose() {
    _tap.dispose();
    _doubleTap.dispose();
    _longPress.dispose();
    super.dispose();
  }

  @override
  String get debugDescription => '_VerseGestureRecognizer';
}
