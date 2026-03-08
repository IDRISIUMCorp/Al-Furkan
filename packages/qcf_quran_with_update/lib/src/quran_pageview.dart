import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

/// A horizontally swipeable Quran mushaf using internal QCF fonts.
///
/// - Uses `pageData` to determine surah/verse ranges for each page.
/// - Renders each verse with `QcfVerse`, which applies the correct per-page font.
/// - Supports RTL page order via `reverse: true` and `Directionality.rtl`.
/// - Supports **Auto-Scroll** mode for hands-free reading.
class PageviewQuran extends StatefulWidget {
  /// 1-based initial page number (1..604)
  final int initialPageNumber;

  /// Optional external controller. If not provided, an internal one is created.
  final PageController? controller;

  //sp (adding 1.sp to get the ratio of screen size for responsive font design)
  final double sp;

  //h (adding 1.h to get the ratio of screen size for responsive font design)
  final double h;

  /// Optional callback when page changes. Provides 1-based page number.
  final ValueChanged<int>? onPageChanged;

  /// Optional override font size passed to each `QcfVerse`.
  final double? fontSize;

  /// Optional theme configuration for customizing all visual aspects.
  /// If null, uses default theme values.
  final QcfThemeData? theme;

  /// Verse text color.
  /// DEPRECATED: Use theme.verseTextColor instead.
  final Color textColor;

  /// Background color for the whole page container.
  /// DEPRECATED: Use theme.pageBackgroundColor instead.
  final Color pageBackgroundColor;

  /// Optional callback to get background color for individual verses.
  /// DEPRECATED: Use theme.verseBackgroundColor instead.
  /// Returns a Color for the verse, or null for no background color.
  /// Useful for highlighting selected verses.
  final Color? Function(int surahNumber, int verseNumber)? verseBackgroundColor;

  /// Long-press callbacks that include the pressed verse info.
  final void Function(int surahNumber, int verseNumber)? onLongPress;
  final void Function(int surahNumber, int verseNumber)? onLongPressUp;
  final void Function(int surahNumber, int verseNumber)? onLongPressCancel;
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPressDown;
  
  /// Whether to render the page using Tajweed colored text.
  final bool showTajweed;

  /// Callback to get Tajweed words list for a specific verse.
  final List<String> Function(int surahNumber, int verseNumber)? tajweedWordsBuilder;

  /// Callback to get highlights for a specific verse.
  final List<HighlightRange> Function(int surahNumber, int verseNumber)? highlightsBuilder;

  /// Callback when a verse is tapped.
  final void Function(int surahNumber, int verseNumber)? onTap;

  /// Callback when a verse is double-tapped.
  final void Function(int surahNumber, int verseNumber)? onDoubleTap;

  /// Callback when a verse is touched down (finger placed).
  final void Function(int surahNumber, int verseNumber, TapDownDetails details)?
  onTapDown;

  /// Custom scroll physics for the PageView (e.g., BouncingScrollPhysics, ClampingScrollPhysics).
  final ScrollPhysics? physics;

  /// Whether auto-scroll is initially enabled.
  final bool autoScrollEnabled;

  /// Duration between each automatic page turn. Defaults to 30 seconds.
  final Duration autoScrollInterval;

  /// Called when auto-scroll state changes (started / stopped).
  final ValueChanged<bool>? onAutoScrollChanged;

  const PageviewQuran({
    super.key,
    this.initialPageNumber = 1,
    this.controller,
    this.onPageChanged,
    this.fontSize,
    this.sp = 1,
    this.h = 1,
    this.theme,
    this.textColor = const Color(0xFF000000),
    this.pageBackgroundColor = const Color(0xFFFFFFFF),
    this.verseBackgroundColor,
    this.onLongPress,
    this.onLongPressUp,
    this.onLongPressCancel,
    this.onLongPressDown,
    this.onTap,
    this.onDoubleTap,
    this.onTapDown,
    this.physics,
    this.autoScrollEnabled = false,
    this.autoScrollInterval = const Duration(seconds: 30),
    this.onAutoScrollChanged,
    this.showTajweed = false,
    this.tajweedWordsBuilder,
    this.highlightsBuilder,
  }) : assert(initialPageNumber >= 1 && initialPageNumber <= totalPagesCount);

  @override
  State<PageviewQuran> createState() => PageviewQuranState();
}

class PageviewQuranState extends State<PageviewQuran> {
  PageController? _internalController;

  PageController get _controller => widget.controller ?? _internalController!;

  bool get _ownsController => widget.controller == null;

  // ── Auto-Scroll ──
  Timer? _autoScrollTimer;
  bool _autoScrollActive = false;

  /// Programmatic API to toggle auto-scroll from outside.
  void toggleAutoScroll() {
    _autoScrollActive ? _stopAutoScroll() : _startAutoScroll();
  }

  /// Whether auto-scroll is currently running.
  bool get isAutoScrollActive => _autoScrollActive;

  void _startAutoScroll() {
    if (_autoScrollActive) return;
    setState(() => _autoScrollActive = true);
    widget.onAutoScrollChanged?.call(true);
    _autoScrollTimer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!_controller.hasClients) return;
      final currentPage = _controller.page?.round() ?? 0;
      if (currentPage >= totalPagesCount - 1) {
        _stopAutoScroll();
        return;
      }
      _controller.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (_autoScrollActive) {
      setState(() => _autoScrollActive = false);
      widget.onAutoScrollChanged?.call(false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (_ownsController) {
      _internalController = PageController(
        initialPage: widget.initialPageNumber - 1,
      );
    }
    if (widget.autoScrollEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  void didUpdateWidget(covariant PageviewQuran oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScrollEnabled != oldWidget.autoScrollEnabled) {
      widget.autoScrollEnabled ? _startAutoScroll() : _stopAutoScroll();
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    if (_ownsController) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = widget.theme ?? const QcfThemeData();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: widget.theme?.pageBackgroundColor ?? widget.pageBackgroundColor,
        child: PageView.builder(
          physics: widget.physics,
          controller: _controller,
          reverse: false, // right-to-left paging order
          itemCount: totalPagesCount,
          onPageChanged:
              (index) => widget.onPageChanged?.call(index + 1), // 1-based
          itemBuilder: (context, index) {
            final pageNumber = index + 1; // 1-based page
            return QcfPage(
              pageNumber: pageNumber,
              fontSize: widget.fontSize,
              // textColor: widget.textColor // Deprecated and unused in modern renderer
              verseBackgroundColor: widget.verseBackgroundColor,
              onLongPress: widget.onLongPress,
              onLongPressUp: widget.onLongPressUp,
              onLongPressCancel: widget.onLongPressCancel,
              onLongPressDown: widget.onLongPressDown,
              onTap: widget.onTap,
              onDoubleTap: widget.onDoubleTap,
              onTapDown: widget.onTapDown,
              sp: widget.sp,
              h: widget.h,
              theme: effectiveTheme,
              showTajweed: widget.showTajweed,
              tajweedWordsBuilder: widget.tajweedWordsBuilder,
              highlightsBuilder: widget.highlightsBuilder,
            );
          },
        ),
      ),
    );
  }
}
