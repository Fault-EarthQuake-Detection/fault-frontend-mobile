import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart'; // [WAJIB]

class AuthRepository {
  // [FIX] Gunakan SupabaseService agar konsisten dengan arsitektur
  final SupabaseClient _supabase = SupabaseService().client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> login({required String username, required String password}) async {
    try {
      // 1. Tembak API Backend Node.js
      final url = Uri.parse('${AppConstants.authBaseUrl}/login');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      // 2. Handle Error Backend
      if (res.statusCode >= 400) {
        String errorMessage = "Login gagal";
        try {
          final errBody = jsonDecode(res.body);
          errorMessage = errBody['error'] ?? res.body;
        } catch (_) {
          errorMessage = "Server Error (${res.statusCode}): Cek koneksi backend.";
        }
        throw errorMessage;
      }

      // 3. Parse Response
      final data = jsonDecode(res.body);
      final sessionMap = data['session'];
      final userMap = data['user'];

      if (sessionMap == null) throw "Data sesi tidak valid dari server";

      // 4. [PENTING] Inject Token ke Supabase SDK di Flutter
      // Agar Chatbot/Storage/RLS bisa jalan
      final refreshToken = sessionMap['refresh_token'];
      if (refreshToken != null) {
        await _supabase.auth.setSession(refreshToken);
      }

      // 5. Simpan Session ke Local Storage
      await SessionService.saveSession(sessionMap, userMap);

    } catch (e) {
      debugPrint("AuthRepo Login Error: $e");
      rethrow;
    }
  }

  Future<void> register({required String email, required String password, required String username}) async {
    try {
      final url = Uri.parse('${AppConstants.authBaseUrl}/signup');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username
        }),
      );

      if (response.statusCode >= 400) {
        String errorMessage = "Registrasi gagal";
        try {
          final errBody = jsonDecode(response.body);
          errorMessage = errBody['error'] ?? response.body;
        } catch (_) {
          errorMessage = "Server Error (${response.statusCode})";
        }
        throw errorMessage;
      }

      // Sukses (201 Created)

    } catch (e) {
      debugPrint("AuthRepo Register Error: $e");
      rethrow;
    }
  }

  // --- Google Sign In ---

  Future<void> googleSignIn() async {
    try {
      const webClientId = AppConstants.webClientId;
      final googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? webClientId : null,
          serverClientId: webClientId
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth == null) throw "Login Google dibatalkan";

      // Login ke Supabase via SDK
      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (res.session == null || res.user == null) throw "Google login gagal";

      // Sync user ke Backend Prisma (Opsional)
      try {
        await _syncGoogleUserToBackend(res.session!.accessToken);
      } catch (e) {
        debugPrint("Sync Backend Gagal: $e");
        // [SOLUSI] Logout paksa jika sync gagal agar user harus login ulang
        await _supabase.auth.signOut();
        await GoogleSignIn().signOut();
        await SessionService.clearSession();

        // Lempar error ke UI agar user tau koneksi bermasalah
        throw "Gagal sinkronisasi data ke server. Coba lagi.";
      }

      await SessionService.saveSession(
          {
            "access_token": res.session!.accessToken,
            "refresh_token": res.session!.refreshToken,
          },
          res.user!.toJson()
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncGoogleUserToBackend(String accessToken) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/sync-user');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken"
      },
    );
    if (response.statusCode >= 300) {
      throw "Gagal sinkronisasi user: ${response.body}";
    }
  }

  // --- Logout ---

  Future<void> logout() async {
    // 1. Logout dari Supabase SDK
    try { await _supabase.auth.signOut(); } catch (_) {}

    // 2. Hapus Session Login
    await SessionService.clearSession();

    // 3. [FIX] Hapus History Chatbot dari HP
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history_local');
    } catch (e) {
      debugPrint("Gagal menghapus history chat: $e");
    }

    // 4. Logout dari Google (jika ada)
    try { await GoogleSignIn().signOut(); } catch (_) {}
  }
}