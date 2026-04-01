// lib/theme/app_theme.dart
// Centralized theme configuration for the MedApp.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Palette ──────────────────────────────────────────────────────────
  static const Color primaryTeal  = Color(0xFF00838F); // Medical Teal
  static const Color primaryLight = Color(0xFF4FB3BF); // Lighter teal
  static const Color primaryDark  = Color(0xFF005662); // Darker teal
  static const Color accentMint   = Color(0xFFE0F7FA); // Mint surface tint
  static const Color scaffoldBg   = Color(0xFFF8FAFB); // Off-white background
  static const Color cardBg       = Color(0xFFFFFFFF); // Pure white (explicit const)
  static const Color textDark     = Color(0xFF1A2E35); // Near-black text
  static const Color textMedium   = Color(0xFF546E7A); // Secondary text
  static const Color textLight    = Color(0xFF90A4AE); // Hint text
  static const Color success      = Color(0xFF26A69A); // Teal-green success
  static const Color warning      = Color(0xFFFFB300); // Amber warning
  static const Color error        = Color(0xFFEF5350); // Medical red
  static const Color divider      = Color(0xFFECEFF1);

  // ─── Light ThemeData ────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.light(
        primary:     primaryTeal,
        onPrimary:   Colors.white,
        secondary:   primaryLight,
        onSecondary: Colors.white,
        surface:     cardBg,
        onSurface:   textDark,
        error:       error,
        onError:     Colors.white,
      ),

      // ── Typography ──
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge:   GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800, color: textDark),
        headlineMedium: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        titleLarge:     GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: textDark),
        titleMedium:    GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge:      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w500, color: textDark),
        bodyMedium:     GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: textMedium),
        labelLarge:     GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation:       0,
        centerTitle:     true,
        titleTextStyle:  GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      cardBg,
        selectedItemColor:    primaryTeal,
        unselectedItemColor:  textLight,
        elevation:            12,
        type:                 BottomNavigationBarType.fixed,
        selectedLabelStyle:   TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color:       cardBg,
        elevation:   2,
        shadowColor: Color(0x1A00838F), // primaryTeal @ ~10% opacity as const-safe value
        shape:       RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        margin:      EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation:       2,
          padding:         const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          textStyle:       GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side:            const BorderSide(color: primaryTeal, width: 1.5),
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          textStyle:       GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider)),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: divider, width: 1.2)),
        focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryTeal, width: 1.8)),
        errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error, width: 1.5)),
        labelStyle:     GoogleFonts.nunito(color: textMedium, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle:      GoogleFonts.nunito(color: textLight, fontSize: 14),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor:     accentMint,
        selectedColor:       primaryTeal,
        labelStyle:          GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: primaryDark),
        secondaryLabelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        padding:             const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape:               RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        side:                BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    );
  }
}