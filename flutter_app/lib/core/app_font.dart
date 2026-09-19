import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFont {
  tajawal(
    key: 'tajawal',
    label: 'تجوال',
    family: 'Tajawal',
  ),
  amiri(
    key: 'amiri',
    label: 'أميري',
    family: 'Amiri',
  ),
  arefRuqaa(
    key: 'aref_ruqaa',
    label: 'عارف رقعة',
    family: 'ArefRuqaa',
  ),
  rakkas(
    key: 'rakkas',
    label: 'رقاص',
    family: 'Rakkas',
  );

  const AppFont({
    required this.key,
    required this.label,
    required this.family,
  });

  final String key;
  final String label;
  final String family;

  static AppFont fromKey(String? key) {
    return AppFont.values.firstWhere(
      (font) => font.key == key,
      orElse: () => AppFont.tajawal,
    );
  }
}

class AppFontController extends ValueNotifier<AppFont> {
  AppFontController._() : super(AppFont.tajawal);

  static final instance = AppFontController._();
  static const _storageKey = 'selected_app_font';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = AppFont.fromKey(prefs.getString(_storageKey));
  }

  Future<void> setFont(AppFont font) async {
    if (value != font) value = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, font.key);
  }
}