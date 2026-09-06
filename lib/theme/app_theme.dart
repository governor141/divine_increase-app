import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors lifted directly from the Divine Increase mockup's CSS variables.
class AppColors {
  static const navy = Color(0xFF0A0E1A);
  static const navy2 = Color(0xFF141A2E);
  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFE9D28A);
  static const cream = Color(0xFFF3EEE4);
  static const cream2 = Color(0xFFFBF9F4);
  static const charcoal = Color(0xFF23262F);
  static const muted = Color(0xFF6B6F7A);
  static const sage = Color(0xFF4C7A63);
  static const line = Color(0xFFE7E0CF);
  static const danger = Color(0xFFC9524E);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.gold,
        secondary: AppColors.navy,
        surface: AppColors.cream,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
  }

  /// Serif heading style (matches the mockup's "Fraunces" font).
  static TextStyle heading({double size = 20, Color color = AppColors.charcoal, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color);

  /// Body/UI text style (matches the mockup's "Inter" font).
  static TextStyle body({double size = 14, Color color = AppColors.charcoal, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);
}
