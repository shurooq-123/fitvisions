import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

ThemeData fashionTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFFFF1F5) : const Color(0xFF382331);
  final muted = dark ? const Color(0xFFD6BDC9) : const Color(0xFF745D68);
  final surface = dark ? const Color(0xFF30242D) : const Color(0xFFFFFAF8);
  final border = dark ? const Color(0xFF624554) : const Color(0xFFE5CED7);
  final accent = dark ? const Color(0xFFF1B1CA) : AppColors.primary;
  final base = ThemeData(
      useMaterial3: false, brightness: brightness, fontFamily: 'sans-serif', fontFamilyFallback: const ['TimesNewRoman']);
  final rounded =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary, brightness: brightness)
        .copyWith(primary: accent, surface: surface),
    scaffoldBackgroundColor:
        dark ? const Color(0xFF211A20) : AppColors.background,
    canvasColor: surface,
    dividerColor: border,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    iconTheme: IconThemeData(color: accent, size: 23),
    appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF211A20) : AppColors.background,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            fontFamily: 'sans-serif',
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w600)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF3A2B35) : const Color(0xFFFFFCFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: TextStyle(color: muted, fontSize: 14),
      hintStyle: TextStyle(color: muted, fontSize: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB3263E))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 1,
            shadowColor: const Color(0x3385465F),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: rounded,
            textStyle: const TextStyle(
                fontFamily: 'sans-serif',
                fontWeight: FontWeight.w600,
                fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            minimumSize: const Size(48, 48),
            side: BorderSide(color: border),
            shape: rounded)),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: accent,
            minimumSize: const Size(48, 44),
            textStyle: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 14,
                fontWeight: FontWeight.w600))),
    chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: dark ? const Color(0xFF684354) : const Color(0xFFF0DCE5),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: TextStyle(color: ink, fontFamily: 'sans-serif'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        elevation: 0),
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: accent, linearTrackColor: border),
    dividerTheme: DividerThemeData(color: border, space: 24, thickness: 1),
  );
}
