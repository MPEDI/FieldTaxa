import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Light mode
  static const bgLight = Color(0xFFEEEEE5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF5F6EF);
  static const lineLight = Color(0xFFE3E4D9);
  static const primaryLight = Color(0xFF2D5016);
  static const primary2Light = Color(0xFF5A8A3C);
  static const accentLight = Color(0xFFA3C46C);
  static const tintLight = Color(0xFFE8F0D8);
  static const fgLight = Color(0xFF1B2410);
  static const mutedLight = Color(0xFF74795F);
  static const chromeLight = Color(0xFFFFFFFF);
  static const deleteColor = Color(0xFFC84040);

  // Dark mode
  static const bgDark = Color(0xFF12140D);
  static const surfaceDark = Color(0xFF1E221A);
  static const surface2Dark = Color(0xFF262B1E);
  static const lineDark = Color(0xFF313625);
  static const primaryDark = Color(0xFFB6D481);
  static const primary2Dark = Color(0xFF90BC5C);
  static const accentDark = Color(0xFF5A8A3C);
  static const tintDark = Color(0xFF283019);
  static const fgDark = Color(0xFFEAEFDC);
  static const mutedDark = Color(0xFF9AA384);
  static const chromeDark = Color(0xFF171A12);

  static const rollDot = Color(0xFFA3C46C);
}

ThemeData lightTheme() {
  const primary = AppColors.primaryLight;
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: AppColors.primary2Light,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.fgLight,
      outline: AppColors.lineLight,
      error: AppColors.deleteColor,
    ),
    textTheme: _buildTextTheme(AppColors.fgLight, AppColors.mutedLight),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.chromeLight,
      foregroundColor: AppColors.fgLight,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: _newsreader(17, AppColors.fgLight, FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.chromeLight,
      indicatorColor: AppColors.tintLight,
      labelTextStyle: WidgetStateProperty.all(
        _jakarta(10, AppColors.mutedLight, FontWeight.w600),
      ),
    ),
    dividerColor: AppColors.lineLight,
    cardColor: AppColors.surfaceLight,
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.tintLight,
      labelStyle: _jakarta(12, primary, FontWeight.w600),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
  );
}

ThemeData darkTheme() {
  const primary = AppColors.primaryDark;
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: AppColors.primary2Dark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.fgDark,
      outline: AppColors.lineDark,
      error: AppColors.deleteColor,
    ),
    textTheme: _buildTextTheme(AppColors.fgDark, AppColors.mutedDark),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.chromeDark,
      foregroundColor: AppColors.fgDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: _newsreader(17, AppColors.fgDark, FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.chromeDark,
      indicatorColor: AppColors.tintDark,
      labelTextStyle: WidgetStateProperty.all(
        _jakarta(10, AppColors.mutedDark, FontWeight.w600),
      ),
    ),
    dividerColor: AppColors.lineDark,
    cardColor: AppColors.surfaceDark,
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.tintDark,
      labelStyle: _jakarta(12, primary, FontWeight.w600),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
  );
}

TextTheme _buildTextTheme(Color fg, Color muted) {
  return TextTheme(
    displayLarge: _newsreader(30, fg, FontWeight.w600),
    displayMedium: _newsreader(24, fg, FontWeight.w600),
    displaySmall: _newsreader(22, fg, FontWeight.w600),
    headlineLarge: _newsreader(22, fg, FontWeight.w600),
    headlineMedium: _newsreader(19, fg, FontWeight.w600),
    headlineSmall: _newsreader(17, fg, FontWeight.w600),
    titleLarge: _jakarta(16, fg, FontWeight.w600),
    titleMedium: _jakarta(14.5, fg, FontWeight.w600),
    titleSmall: _jakarta(13, fg, FontWeight.w600),
    bodyLarge: _jakarta(14.5, fg, FontWeight.w500),
    bodyMedium: _jakarta(13, fg, FontWeight.w500),
    bodySmall: _jakarta(12, muted, FontWeight.w500),
    labelLarge: _jakarta(14, fg, FontWeight.w700),
    labelMedium: _jakarta(12, fg, FontWeight.w600),
    labelSmall: _jakarta(10.5, muted, FontWeight.w600),
  );
}

TextStyle _newsreader(double size, Color color, FontWeight weight) =>
    GoogleFonts.newsreader(fontSize: size, color: color, fontWeight: weight);

TextStyle _jakarta(double size, Color color, FontWeight weight) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, color: color, fontWeight: weight);

// Helper extension for easy access to custom colors in context
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBg =>
      isDark ? AppColors.bgDark : AppColors.bgLight;
  Color get appSurface =>
      isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get appSurface2 =>
      isDark ? AppColors.surface2Dark : AppColors.surface2Light;
  Color get appLine =>
      isDark ? AppColors.lineDark : AppColors.lineLight;
  Color get appPrimary =>
      isDark ? AppColors.primaryDark : AppColors.primaryLight;
  Color get appPrimary2 =>
      isDark ? AppColors.primary2Dark : AppColors.primary2Light;
  Color get appAccent =>
      isDark ? AppColors.accentDark : AppColors.accentLight;
  Color get appTint =>
      isDark ? AppColors.tintDark : AppColors.tintLight;
  Color get appFg =>
      isDark ? AppColors.fgDark : AppColors.fgLight;
  Color get appMuted =>
      isDark ? AppColors.mutedDark : AppColors.mutedLight;
  Color get appChrome =>
      isDark ? AppColors.chromeDark : AppColors.chromeLight;
}

TextStyle newsreaderStyle(double size, Color color,
        {FontWeight weight = FontWeight.w600}) =>
    GoogleFonts.newsreader(fontSize: size, color: color, fontWeight: weight);

TextStyle jakartaStyle(double size, Color color,
        {FontWeight weight = FontWeight.w500}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, color: color, fontWeight: weight);
