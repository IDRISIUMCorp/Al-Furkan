import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // AYA EXACT REPLICA PALETTE (Light / Beige)
  // ==========================================

  /// The main background color for the Mushaf pages and main screens (Light Beige)
  static const Color ayaBackground = Color(0xFFFCF6ED);

  /// Slightly darker beige used for top/bottom bars and sheets
  static const Color ayaSurface = Color(0xFFF5EEDF);

  /// Primary Interactive Color (The Signature Aya Teal/Green)
  static const Color ayaPrimary = Color(0xFF117865);
  static const Color ayaPrimaryLight = Color(0xFFE2EFEA); // For subtle backgrounds

  /// Highlight color for the currently reading ayah (Warm Toasted Beige)
  static const Color ayaAyahHighlight = Color(0xFFEADBC3);

  // --- Text Colors ---
  /// Main deep slate color for primary texts (Quran text, titles)
  static const Color ayaTextMain = Color(0xFF1E1E1E);
  
  /// Softer brownish-grey for subtitles, tafsir text, and inactive icons
  static const Color ayaTextSecondary = Color(0xFF6D675E);

  /// Border and Divider colors (Very subtle beige/brown)
  static const Color ayaBorder = Color(0xFFE5DCC9);

  // --- Floating Audio Player ---
  static const Color ayaAudioPlayerBg = Color(0xFFF0E5D3);

  // Legacy mappings for existing code compatibility (if requested before cleanup)
  static const Color primary = ayaPrimary;
  static const Color background = ayaBackground;
  static const Color surface = ayaSurface;

  /// Legacy Text Colors Light
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
}
