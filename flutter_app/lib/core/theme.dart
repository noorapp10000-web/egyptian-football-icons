import 'package:flutter/material.dart';

const kBackground = Color(0xff071912);
const kCard = Color(0xff0d271d);
const kCardAlt = Color(0xff133326);
const kPrimary = Color(0xff20c478);
const kGold = Color(0xffd6af2f);
const kLive = Color(0xfff0785d);

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: kPrimary,
        brightness: Brightness.dark,
        surface: kCard,
      ).copyWith(
        primary: kPrimary,
        onPrimary: const Color(0xff092017),
        secondary: kGold,
        surface: kCard,
        onSurface: const Color(0xfff2f7f3),
        outline: const Color(0xff2d4b3e),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBackground,
    fontFamily: 'Cairo',
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff2d4b3e)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff2d4b3e)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xffaec4b7)),
    ),
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xff254638)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 20,
          color: states.contains(WidgetState.selected) ? kPrimary : Colors.white54,
        ),
      ),
    ),
  );
}
