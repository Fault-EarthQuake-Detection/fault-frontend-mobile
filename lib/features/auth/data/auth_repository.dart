import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  // Kita butuh client ini untuk inject session setelah login via backend
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> login({required String username, required String password}) async {
    try {
      // Pastikan route backend benar.
      // Jika di index.ts backend kamu pakai app.use('/auth', authRoutes), maka URLnya:
      final url = Uri.parse('${AppConstants.authBaseUrl}/login');

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      // Handle Error dari Backend
      if (res.statusCode >= 400) {
        String errorMessage = "Login gagal";
        try {
          final errBody = jsonDecode(res.body);
          errorMessage = errBody['error'] ?? res.body;
        } catch (_) {
          // Jika response bukan JSON (misal HTML error 404/500)
          errorMessage = "Server Error (${res.statusCode}): Cek koneksi backend.";
        }
        throw errorMessage;
      }

      // Parse Response Sukses
      final data = jsonDecode(res.body);

      // Struktur Backend: { "session": {...}, "user": {...} }
      // Pastikan backend me-return 'session' yang berisi access_token & refresh_token dari Supabase
      final sessionMap = data['session'];
      final userMap = data['user'];

      if (sessionMap == null) throw "Data sesi tidak valid dari server";

      // [PENTING] Sinkronisasi token ke Supabase SDK di Flutter
      // Ini membuat aplikasi 'sadar' bahwa user sudah login, meski loginnya via API Node.js
      final refreshToken = sessionMap['refresh_token'];
      if (refreshToken != null) {
        await _supabase.auth.setSession(refreshToken);
      }

      // Simpan sesi ke Local Storage
      await SessionService.saveSession(sessionMap, userMap);

    } catch (e) {
      debugPrint("AuthRepo Login Error: $e");
      rethrow;
    }
  }

  Future<void> register({required String email, required String password, required String username}) async {
    try {
      // Endpoint register backend
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

      // Backend return 201 Created. User berhasil dibuat di Prisma & Supabase.
      // Kita tidak login otomatis di sini, biarkan user login manual di step berikutnya.

    } catch (e) {
      debugPrint("AuthRepo Register Error: $e");
      rethrow;
    }
  }

  // --- Google Sign In & Logout (Tetap Sama) ---

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

      // Login ke Supabase via SDK (karena Google Auth langsung ke Supabase)
      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (res.session == null || res.user == null) throw "Google login gagal";

      // Sync user ke Backend Prisma (Opsional, sesuai kebutuhan backendmu)
      try {
        await _syncGoogleUserToBackend(res.session!.accessToken);
      } catch (e) {
        debugPrint("Sync Backend Warning: $e");
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
    final url = Uri.parse('${AppConstants.authBaseUrl}/sync-user'); // Sesuaikan path backend
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

  Future<void> logout() async {
    try { await _supabase.auth.signOut(); } catch (_) {}
    await SessionService.clearSession();
    try { await GoogleSignIn().signOut(); } catch (_) {}
  }
}