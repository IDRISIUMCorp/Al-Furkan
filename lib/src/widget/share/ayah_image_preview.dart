import "package:al_quran_v3/l10n/app_localizations.dart";
import "package:al_quran_v3/src/model/ayah_image_settings.dart";
import "package:al_quran_v3/src/resources/quran_resources/meaning_of_surah.dart";
import "package:al_quran_v3/src/screen/surah_list_view/model/surah_info_model.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/utils/get_localized_ayah_key.dart";
import "package:flutter/material.dart";

/// Widget لمعاينة صورة الآية قبل المشاركة
/// يعرض الآية بالإعدادات المختارة مع تحديث حي
class AyahImagePreview extends StatelessWidget {
  final String ayahKey;
  final String ayahText;
  final SurahInfoModel surahInfo;
  final AyahImageSettings settings;
  final String? translationText;
  final String? tafsirText;
  final String? footnotesText;
  final ThemeState themeState;

  const AyahImagePreview({
    super.key,
    required this.ayahKey,
    required this.ayahText,
    required this.surahInfo,
    required this.settings,
    required this.themeState,
    this.translationText,
    this.tafsirText,
    this.footnotesText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background = settings.background;
    final gradient = background.getGradient();
    final textColor = background.getTextColor();
    final fontSize = settings.fontSize.getValue();

    final ratio = settings.aspectRatio.getValue();

    final content = Container(
      constraints: const BoxConstraints(
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: gradient == null ? background.getBackgroundColor() : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: _buildBorder(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // الإطار المزخرف (إذا كان مفعل)
          if (settings.frameStyle == AyahImageFrameStyle.islamic)
            _buildIslamicFrame(),
          
          // المحتوى الرئيسي
          Padding(
            padding: EdgeInsets.all(
              (settings.frameStyle == AyahImageFrameStyle.islamic ? 24 : 16) +
                  settings.contentPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اسم السورة ورقم الآية
                if (settings.headerStyle != AyahImageHeaderStyle.none &&
                    (settings.showSurahName || settings.showAyahNumber))
                  settings.headerStyle == AyahImageHeaderStyle.banner
                      ? _buildBannerHeader(context, textColor)
                      : _buildHeader(context, textColor),
                
                const SizedBox(height: 16),
                
                // نص الآية
                _buildAyahText(textColor, fontSize),
                
                // الترجمة
                if (settings.showTranslation && translationText != null) ...[
                  const SizedBox(height: 12),
                  _buildTranslation(l10n, textColor),
                ],
                
                // التفسير (مختصر — max 3 سطور عشان الصورة متبوظش)
                if (settings.showTafsir && tafsirText != null) ...[
                  const SizedBox(height: 12),
                  _buildTafsir(l10n, textColor),
                ],

                // الحواشي (من الترجمة)
                if (settings.showFootnotes && footnotesText != null) ...[
                  const SizedBox(height: 12),
                  _buildFootnotes(l10n, textColor),
                ],
                
                const SizedBox(height: 12),
              ],
            ),
          ),
          
          // العلامة المائية
          if (settings.watermark.enabled)
            _buildWatermark(textColor),
        ],
      ),
    );

    if (ratio == null) return content;
    return AspectRatio(aspectRatio: ratio, child: content);
  }

  Widget _buildBannerHeader(BuildContext context, Color textColor) {
    final title = settings.showSurahName ? getSurahName(context, surahInfo.id) : "";
    final meaning = settings.showSurahMeaning ? getSurahMeaning(context, surahInfo.id) : "";
    final align = settings.headerBannerAlign.toTextAlign();

    return SizedBox(
      height: settings.headerBannerHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: themeState.primary.withValues(alpha: settings.headerBannerOpacity),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: themeState.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: align == TextAlign.right
                    ? CrossAxisAlignment.end
                    : (align == TextAlign.left
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center),
                children: [
                  Text(
                    title,
                    textAlign: align,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textColor.withValues(alpha: 0.95),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meaning.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: align,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (settings.showAyahNumber) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeState.primary.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  getAyahLocalized(context, ayahKey),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Border? _buildBorder() {
    switch (settings.frameStyle) {
      case AyahImageFrameStyle.none:
        return null;
      case AyahImageFrameStyle.simple:
        return Border.all(
          color: themeState.primary.withValues(alpha: 0.3),
          width: 2,
        );
      case AyahImageFrameStyle.decorated:
        return Border.all(
          color: themeState.primary,
          width: 3,
        );
      case AyahImageFrameStyle.islamic:
        return null; // يتم رسم الإطار بشكل منفصل
    }
  }

  Widget _buildIslamicFrame() {
    return Positioned.fill(
      child: CustomPaint(
        painter: IslamicFramePainter(
          color: themeState.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeState.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (settings.showSurahName)
            Text(
              getSurahName(context, surahInfo.id),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          if (settings.showAyahNumber)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: themeState.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getAyahLocalized(context, ayahKey),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAyahText(Color textColor, double fontSize) {
    return Text(
      ayahText,
      textAlign: settings.ayahTextAlign.toTextAlign(),
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: settings.fontType.getFontFamily(),
        fontSize: fontSize,
        height: settings.ayahLineHeight,
        letterSpacing: settings.ayahLetterSpacing,
        color: textColor,
      ),
    );
  }

  Widget _buildTranslation(AppLocalizations l10n, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 2,
              color: themeState.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.translation,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          translationText!,
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: settings.translationFontSize,
            height: settings.translationLineHeight,
            color: textColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildFootnotes(AppLocalizations l10n, Color textColor) {
    final footnotesBody = Text(
      footnotesText!,
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontSize: settings.footnotesFontSize,
        height: settings.footnotesLineHeight,
        color: textColor.withValues(alpha: 0.78),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 2,
              color: themeState.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.footNoteTitle,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (settings.footnotesBoxed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeState.primary.withValues(alpha: 0.20),
              ),
            ),
            child: footnotesBody,
          )
        else
          footnotesBody,
      ],
    );
  }

  Widget _buildTafsir(AppLocalizations l10n, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 2,
              color: themeState.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.tafsir,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          tafsirText!,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: settings.tafsirFontSize,
            height: settings.tafsirLineHeight,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWatermark(Color textColor) {
    final position = settings.watermark.position;
    final text = settings.watermark.customText ?? "القرآن الكريم";

    Alignment alignment;
    switch (position) {
      case WatermarkPosition.topLeft:
        alignment = Alignment.topLeft;
        break;
      case WatermarkPosition.topRight:
        alignment = Alignment.topRight;
        break;
      case WatermarkPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        break;
      case WatermarkPosition.bottomRight:
        alignment = Alignment.bottomRight;
        break;
      case WatermarkPosition.center:
        alignment = Alignment.center;
        break;
    }

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Opacity(
            opacity: settings.watermark.opacity,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter للإطار الإسلامي المزخرف
class IslamicFramePainter extends CustomPainter {
  final Color color;

  IslamicFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // الإطار الخارجي
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(16),
    );
    canvas.drawRRect(outerRect, paint);

    // الإطار الداخلي
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(innerRect, paint);

    // زخارف الأركان
    _drawCornerOrnament(canvas, const Offset(8, 8), paint);
    _drawCornerOrnament(canvas, Offset(size.width - 8, 8), paint);
    _drawCornerOrnament(canvas, Offset(8, size.height - 8), paint);
    _drawCornerOrnament(canvas, Offset(size.width - 8, size.height - 8), paint);
  }

  void _drawCornerOrnament(Canvas canvas, Offset center, Paint paint) {
    final ornamentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, ornamentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
