import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';

// --- REPOSITORY PROVIDER ---
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// ==========================================
// 1. THEME VIEWMODEL
// ==========================================
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repo;

  ThemeNotifier(this._repo) : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _repo.getThemeMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await _repo.saveThemeMode(isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return ThemeNotifier(repo);
});

// ==========================================
// 2. LANGUAGE VIEWMODEL
// ==========================================
class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsRepository _repo;

  LocaleNotifier(this._repo) : super(const Locale('id')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final code = await _repo.getLocale();
    state = Locale(code);
  }

  Future<void> changeLocale(String code) async {
    state = Locale(code);
    await _repo.saveLocale(code);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final repo = ref.read(settingsRepositoryProvider);
  return LocaleNotifier(repo);
});