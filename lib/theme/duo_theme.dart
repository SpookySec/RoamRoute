import 'package:flutter/material.dart';

class DuoColors {
  static const Color duoGreen = Color(0xFF58CC02);
  static const Color duoGreenDark = Color(0xFF46A302);
  static const Color duoBlue = Color(0xFF1CB0F6);
  static const Color duoBlueDark = Color(0xFF1899D6);
  static const Color duoOrange = Color(0xFFFC8F21);
  static const Color duoOrangeDark = Color(0xFFE3801D);
  static const Color duoRed = Color(0xFFFF4B4B);
  static const Color duoRedDark = Color(0xFFD33131);
  static const Color duoCardBorder = Color(0xFFE5E5E5);
  static const Color duoCardBorderDark = Color(0xFF3B3B3B);
  static const Color duoTextMain = Color(0xFF4B4B4B);
  static const Color duoTextMainDark = Color(0xFFE5E5E5);
  static const Color duoGray = Color(0xFFAFAFAF);
}

class DuoTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DuoColors.duoGreen,
      primary: DuoColors.duoGreen,
      secondary: DuoColors.duoBlue,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: DuoColors.duoTextMain,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: DuoColors.duoGray),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DuoColors.duoCardBorder, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: DuoColors.duoGreen.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: DuoColors.duoGreen, fontWeight: FontWeight.w900);
        }
        return const TextStyle(color: DuoColors.duoGray, fontWeight: FontWeight.bold);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: DuoColors.duoGreen);
        }
        return const IconThemeData(color: DuoColors.duoGray);
      }),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111111),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: DuoColors.duoGreen,
      primary: DuoColors.duoGreen,
      secondary: DuoColors.duoBlue,
      surface: const Color(0xFF1A1A1A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111111),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: DuoColors.duoTextMainDark,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: DuoColors.duoGray),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: DuoColors.duoCardBorderDark, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF111111),
      indicatorColor: DuoColors.duoGreen.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: DuoColors.duoGreen, fontWeight: FontWeight.w900);
        }
        return const TextStyle(color: DuoColors.duoGray, fontWeight: FontWeight.bold);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: DuoColors.duoGreen);
        }
        return const IconThemeData(color: DuoColors.duoGray);
      }),
    ),
  );
}
