import 'package:flutter/material.dart';

const kBackground = Color(0xff071a15);
const kCard = Color(0xff102821);
const kCardAlt = Color(0xff15352b);
const kPrimary = Color(0xff5fce93);
const kGold = Color(0xffe9c76b);
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
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff2d4b3e)),
      ),
    ),
  );
}
