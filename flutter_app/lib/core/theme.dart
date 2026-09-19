import 'package:flutter/material.dart';

const kBackground = Color(0xff071912);
const kCard = Color(0xff0d271d);
const kCardAlt = Color(0xff133326);
const kPrimary = Color(0xff20c478);
const kGold = Color(0xffd6af2f);
const kLive = Color(0xfff0785d);
const kInk = Color(0xffeaf4ee);
const kMuted = Color(0xff91aa9c);
const kLine = Color(0xff244738);

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
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kInk,
        fontSize: 17,
        fontWeight: FontWeight.w900,
        fontFamily: 'Cairo',
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kLine),
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
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kLine),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: Color(0xff091d15),
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      indicatorShape: StadiumBorder(),
      indicatorColor: kPrimary.withValues(alpha: .18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kInk),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 21,
          color: states.contains(WidgetState.selected)
              ? kPrimary
              : Colors.white54,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kLine, space: 1, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kCardAlt,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kCard,
      selectedColor: kPrimary,
      side: const BorderSide(color: kLine),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}
