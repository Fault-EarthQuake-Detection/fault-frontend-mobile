import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'locale_code';

  // --- TEMA ---
  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Default false (Light Mode) jika belum pernah diset
    return prefs.getBool(_themeKey) ?? false;
  }

  // --- BAHASA ---
  Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
  }

  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    // Default 'id' (Indonesia) jika belum pernah diset
    return prefs.getString(_localeKey) ?? 'id';
  }
}