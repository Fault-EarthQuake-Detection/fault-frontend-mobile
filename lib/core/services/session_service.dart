import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {

  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUser = 'auth_user';

  static const _secureStorage = FlutterSecureStorage();

  static AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static String? cachedAccessToken;

  static Future<void> load() async {
    try {
      cachedAccessToken = await _secureStorage.read(
        key: _keyAccessToken,
        aOptions: _getAndroidOptions(),
      );
    } catch (e) {
      await clearSession();
    }
  }

  static Future<void> saveSession(Map<String, dynamic> session, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    final access = session['access_token'] ?? '';
    final refresh = session['refresh_token'] ?? '';

    await _secureStorage.write(
      key: _keyAccessToken,
      value: access,
      aOptions: _getAndroidOptions(),
    );
    await _secureStorage.write(
      key: _keyRefreshToken,
      value: refresh,
      aOptions: _getAndroidOptions(),
    );

    await prefs.setString(_keyUser, jsonEncode(userData));

    cachedAccessToken = access;
  }

  static Future<String?> getAccessToken() async {
    if (cachedAccessToken != null && cachedAccessToken!.isNotEmpty) {
      return cachedAccessToken;
    }
    return await _secureStorage.read(
      key: _keyAccessToken,
      aOptions: _getAndroidOptions(),
    );
  }

  static Future<String?> getToken() async => getAccessToken();

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(
      key: _keyRefreshToken,
      aOptions: _getAndroidOptions(),
    );
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr == null) return null;
    return jsonDecode(userStr) as Map<String, dynamic>;
  }


  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyUser);

    await _secureStorage.deleteAll(aOptions: _getAndroidOptions());

    cachedAccessToken = null;
  }

  static bool hasCachedToken() {
    return cachedAccessToken != null && cachedAccessToken!.isNotEmpty;
  }
}