import 'package:flutter/material.dart';

class AppColors {
  // Light Summer Blues palette
  static const Color blue50  = Color(0xFFDEEEF8);
  static const Color blue100 = Color(0xFFB8D6EF);
  static const Color blue200 = Color(0xFF8FBDE6);
  static const Color blue300 = Color(0xFF6699CC);
  static const Color blue400 = Color(0xFF4A7FB5);
  static const Color blue500 = Color(0xFF3B6EA5);

  // Muted periwinkle/lavender blues (row 2 of palette)
  static const Color periwinkle100 = Color(0xFFBFC5DE);
  static const Color periwinkle200 = Color(0xFF9AA5C8);
  static const Color periwinkle300 = Color(0xFF7585B2);
  static const Color periwinkle400 = Color(0xFF5A6B9A);
  static const Color periwinkle500 = Color(0xFF455280);

  // Neutrals
  static const Color white       = Color(0xFFFFFFFF);
  static const Color surface     = Color(0xFFF4F7FB);
  static const Color surfaceCard = Color(0xFFEAF1F9);

  // Dark mode surfaces
  static const Color darkBg      = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard    = Color(0xFF1C2431);
  static const Color darkBorder  = Color(0xFF30363D);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary:          AppColors.blue400,
        onPrimary:        AppColors.white,
        primaryContainer: AppColors.blue50,
        onPrimaryContainer: AppColors.blue500,
        secondary:        AppColors.periwinkle400,
        onSecondary:      AppColors.white,
        secondaryContainer: AppColors.periwinkle100,
        onSecondaryContainer: AppColors.periwinkle500,
        surface:          AppColors.white,
        onSurface:        Color(0xFF1A2333),
        surfaceContainerHighest: AppColors.surfaceCard,
        onSurfaceVariant: Color(0xFF4A5568),
        outline:          Color(0xFFCBD5E0),
        outlineVariant:   Color(0xFFE2EAF4),
        error:            Color(0xFFE53E3E),
        onError:          AppColors.white,
        errorContainer:   Color(0xFFFED7D7),
        onErrorContainer: Color(0xFF742A2A),
        shadow:           Color(0x1A2D3748),
        scrim:            Color(0x802D3748),
        inverseSurface:   AppColors.darkSurface,
        onInverseSurface: AppColors.white,
        inversePrimary:   AppColors.blue200,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: Color(0xFF1A2333),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2333),
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFFDDE8F4), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue400,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue400,
          side: BorderSide(color: AppColors.blue300, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue400,
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFCBD5E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFDDE8F4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blue400, width: 2),
        ),
        labelStyle: TextStyle(color: Color(0xFF4A5568)),
        hintStyle: TextStyle(color: Color(0xFF90A3BF)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.blue400,
        unselectedItemColor: Color(0xFF90A3BF),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: Color(0xFFE2EAF4),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.blue50,
        labelStyle: TextStyle(color: AppColors.blue500, fontSize: 13),
        side: BorderSide(color: AppColors.blue200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: _lightTextTheme,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary:          AppColors.blue200,
        onPrimary:        AppColors.darkBg,
        primaryContainer: Color(0xFF1E3A5F),
        onPrimaryContainer: AppColors.blue100,
        secondary:        AppColors.periwinkle200,
        onSecondary:      AppColors.darkBg,
        secondaryContainer: Color(0xFF2A3354),
        onSecondaryContainer: AppColors.periwinkle100,
        surface:          AppColors.darkSurface,
        onSurface:        Color(0xFFE6EDF4),
        surfaceContainerHighest: AppColors.darkCard,
        onSurfaceVariant: Color(0xFF8B9BB4),
        outline:          AppColors.darkBorder,
        outlineVariant:   Color(0xFF21262D),
        error:            Color(0xFFFC8181),
        onError:          AppColors.darkBg,
        errorContainer:   Color(0xFF742A2A),
        onErrorContainer: Color(0xFFFEB2B2),
        shadow:           Colors.black,
        scrim:            Color(0x99000000),
        inverseSurface:   Color(0xFFE6EDF4),
        onInverseSurface: AppColors.darkBg,
        inversePrimary:   AppColors.blue400,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Color(0xFFE6EDF4),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE6EDF4),
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue300,
          foregroundColor: AppColors.darkBg,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue200,
          side: BorderSide(color: AppColors.blue300, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue200,
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.blue300, width: 2),
        ),
        labelStyle: TextStyle(color: Color(0xFF8B9BB4)),
        hintStyle: TextStyle(color: Color(0xFF4A5568)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.blue200,
        unselectedItemColor: Color(0xFF4A5568),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF1E3A5F),
        labelStyle: TextStyle(color: AppColors.blue100, fontSize: 13),
        side: BorderSide(color: Color(0xFF2D5A8E)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: _darkTextTheme,
    );
  }

  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1A2333), letterSpacing: -0.5),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A2333), letterSpacing: -0.5),
    displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1A2333), letterSpacing: -0.3),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF1A2333), letterSpacing: -0.3),
    headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A2333)),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A2333)),
    titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A2333)),
    titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
    titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF2D3748), height: 1.6),
    bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF4A5568), height: 1.5),
    bodySmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF718096), height: 1.4),
    labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3748), letterSpacing: 0.1),
    labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4A5568), letterSpacing: 0.2),
    labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF718096), letterSpacing: 0.3),
  );

  static const TextTheme _darkTextTheme = TextTheme(
    displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFE6EDF4), letterSpacing: -0.5),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFE6EDF4), letterSpacing: -0.5),
    displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF4), letterSpacing: -0.3),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF4), letterSpacing: -0.3),
    headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF4)),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF4)),
    titleLarge:    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF4)),
    titleMedium:   TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFC9D1D9)),
    titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC9D1D9)),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFC9D1D9), height: 1.6),
    bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF8B9BB4), height: 1.5),
    bodySmall:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF6B7A94), height: 1.4),
    labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC9D1D9), letterSpacing: 0.1),
    labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8B9BB4), letterSpacing: 0.2),
    labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7A94), letterSpacing: 0.3),
  );
}