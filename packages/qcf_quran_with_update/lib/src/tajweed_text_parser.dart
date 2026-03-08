import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parseFragment;
import 'package:html/dom.dart' as dom;
import 'tajweed_rules.dart';
import 'highlight_range.dart';

TextSpan parseTajweedWord({
  required String wordWithTajweed,
  required int wordIndex,
  required TextStyle baseStyle,
  required bool isLight,
  required bool enableTajweed,
  List<HighlightRange>? highlights,
  VoidCallback? onTap,
}) {
  List<TextSpan> spans = [];

  // Determine if this specific word is highlighted
  Color? highlightColor;
  if (highlights != null) {
    for (var h in highlights) {
      if (h.wordIndex == wordIndex) {
        highlightColor = h.color;
        break;
      }
    }
  }

  // Set the default text color (highlight overrides it if no specific tajweed rule or tajweed is disabled)
  final defaultColor =
      baseStyle.color ?? (isLight ? Colors.black : Colors.white);

  // Set the background color if highlighted
  final TextStyle processingStyle = baseStyle.copyWith(
    color: defaultColor,
    backgroundColor: highlightColor ?? baseStyle.backgroundColor,
  );

  final Map<String, Color> currentThemeColors = {
    GhunnahRule.key: isLight ? GhunnahRule.lightColor : GhunnahRule.darkColor,
    IdghamShafawiRule.key:
        isLight ? IdghamShafawiRule.lightColor : IdghamShafawiRule.darkColor,
    IqlabRule.key: isLight ? IqlabRule.lightColor : IqlabRule.darkColor,
    IkhafaShafawiRule.key:
        isLight ? IkhafaShafawiRule.lightColor : IkhafaShafawiRule.darkColor,
    QalqalahRule.key:
        isLight ? QalqalahRule.lightColor : QalqalahRule.darkColor,
    IdghamGhunnahRule.key:
        isLight ? IdghamGhunnahRule.lightColor : IdghamGhunnahRule.darkColor,
    IdghamWoGhunnahRule.key:
        isLight
            ? IdghamWoGhunnahRule.lightColor
            : IdghamWoGhunnahRule.darkColor,
    IkhafaRule.key: isLight ? IkhafaRule.lightColor : IkhafaRule.darkColor,
    MaddTabiiRule.key:
        isLight ? MaddTabiiRule.lightColor : MaddTabiiRule.darkColor,
    MaddLazimRule.key:
        isLight ? MaddLazimRule.lightColor : MaddLazimRule.darkColor,
    MaddLeenRule.key:
        isLight ? MaddLeenRule.lightColor : MaddLeenRule.darkColor,
    MaddWajibMuttasilRule.key:
        isLight
            ? MaddWajibMuttasilRule.lightColor
            : MaddWajibMuttasilRule.darkColor,
    MaddJaizMunfasilRule.key:
        isLight
            ? MaddJaizMunfasilRule.lightColor
            : MaddJaizMunfasilRule.darkColor,
    HamWaslRule.key: isLight ? HamWaslRule.lightColor : HamWaslRule.darkColor,
    LaamShamsiyahRule.key:
        isLight ? LaamShamsiyahRule.lightColor : LaamShamsiyahRule.darkColor,
    SlntRule.key: isLight ? SlntRule.lightColor : SlntRule.darkColor,
    IdghamMutajanisaynRule.key:
        isLight
            ? IdghamMutajanisaynRule.lightColor
            : IdghamMutajanisaynRule.darkColor,
    IdghamMutaqaribaynRule.key:
        isLight
            ? IdghamMutaqaribaynRule.lightColor
            : IdghamMutaqaribaynRule.darkColor,
    CustomAlefMaksoraRule.key:
        isLight
            ? CustomAlefMaksoraRule.lightColor
            : CustomAlefMaksoraRule.darkColor,
  };

  void processNode(dom.Node node, Color currentColor) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      spans.add(
        TextSpan(
          text: node.text,
          style: processingStyle.copyWith(color: currentColor),
          recognizer:
              onTap != null ? (TapGestureRecognizer()..onTap = onTap) : null,
        ),
      );
    } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
      dom.Element element = node as dom.Element;
      Color nextColor = currentColor;

      if (enableTajweed && element.localName == "rule") {
        String? ruleClass = element.attributes["class"];
        if (ruleClass != null && currentThemeColors.containsKey(ruleClass)) {
          nextColor = currentThemeColors[ruleClass]!;
        }
      }

      if (element.nodes.isNotEmpty) {
        for (var childNode in element.nodes) {
          processNode(childNode, nextColor);
        }
      }
    }
  }

  for (var node in parseFragment("$wordWithTajweed ").nodes) {
    processNode(node, defaultColor);
  }

  return TextSpan(children: spans, style: processingStyle);
}

String getPlainTextFromTajweedWord(String wordWithTajweed) {
  final documentFragment = parseFragment(wordWithTajweed);
  String textContent = "";

  void extractText(dom.Node node) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      textContent += node.text ?? "";
    } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
      for (var childNode in node.nodes) {
        extractText(childNode);
      }
    }
  }

  for (var node in documentFragment.nodes) {
    extractText(node);
  }

  return textContent.trim();
}
