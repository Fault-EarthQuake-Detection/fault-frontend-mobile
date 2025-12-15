// lib/core/services/session_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keySession = 'auth_session';
  static const String _keyUser = 'auth_user';

  // Cached values to allow synchronous router redirect logic
  static String? cachedAccessToken;
  static String? cachedRefreshToken;

  /// Call this at startup to populate cached tokens synchronously for router.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    cachedAccessToken = prefs.getString(_keyAccessToken);
    cachedRefreshToken = prefs.getString(_keyRefreshToken);
  }

  /// Save raw session map (from backend) and user JSON (from backend or supabase)
  static Future<void> saveSession(Map<String, dynamic> session, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    final access = session['access_token'] ?? '';
    final refresh = session['refresh_token'] ?? '';

    await prefs.setString(_keyAccessToken, access);
    await prefs.setString(_keyRefreshToken, refresh);
    await prefs.setString(_keySession, jsonEncode(session));
    await prefs.setString(_keyUser, jsonEncode(userData));

    // update cached
    cachedAccessToken = access;
    cachedRefreshToken = refresh;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Backwards-compatible name (some files use getToken)
  static Future<String?> getToken() async => getAccessToken();

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStr = prefs.getString(_keySession);
    if (sessionStr == null) return null;
    return jsonDecode(sessionStr) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keySession);
    await prefs.remove(_keyUser);

    cachedAccessToken = null;
    cachedRefreshToken = null;
  }

  // Synchronous check helper (uses cached value set by load())
  static bool hasCachedToken() {
    return cachedAccessToken != null && cachedAccessToken!.isNotEmpty;
  }
}
