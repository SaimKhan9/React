import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── DevArena Live Color Palette ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Dark theme (GitHub dark inspired)
  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkBorder = Color(0xFF30363D);
  static const darkText = Color(0xFFE6EDF3);
  static const darkTextMuted = Color(0xFF8B949E);
  static const darkSurface2 = Color(0xFF21262D);

  // Brand colors
  static const sky = Color(0xFF58A6FF);
  static const skyLight = Color(0xFF79C0FF);
  static const emerald = Color(0xFF3FB950);
  static const amber = Color(0xFFD29922);
  static const purple = Color(0xFFA371F7);
  static const red = Color(0xFFFF7B72);
  static const indigo = Color(0xFF6E76AE);

  // Light theme
  static const lightBg = Color(0xFFF6F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFD0D7DE);
  static const lightText = Color(0xFF1F2328);
  static const lightTextMuted = Color(0xFF656D76);
}

// ─── Typography ──────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  static TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.normal,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.normal,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}

// ─── Theme Data ───────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.sky,
      onPrimary: Colors.white,
      secondary: AppColors.purple,
      onSecondary: Colors.white,
      error: AppColors.red,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.inter(
          size: 15,
          weight: FontWeight.w600,
          color: text,
        ),
        iconTheme: IconThemeData(color: muted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.sky,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.inter(size: 11, weight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.inter(size: 11),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sky, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: AppTypography.inter(color: muted, size: 13),
        labelStyle: AppTypography.inter(color: muted, size: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sky,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.inter(size: 13, weight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.lightBg,
        selectedColor: AppColors.sky.withOpacity(0.15),
        labelStyle: AppTypography.inter(size: 12),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.sky,
        unselectedLabelColor: muted,
        indicatorColor: AppColors.sky,
        labelStyle: AppTypography.inter(size: 12, weight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.inter(size: 12),
        dividerColor: border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface2 : Colors.grey.shade900,
        contentTextStyle: AppTypography.inter(color: Colors.white, size: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
