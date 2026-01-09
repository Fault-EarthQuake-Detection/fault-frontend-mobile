import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> login({required String username, required String password}) async {
    try {
      final url = Uri.parse('${AppConstants.authBaseUrl}/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw jsonDecode(res.body)['error'] ?? "Login gagal";
      }

      final data = jsonDecode(res.body);
      final sessionMap = data['session'];
      final userMap = data['user'];

      if (sessionMap == null || userMap == null) throw "Data sesi tidak valid";

      final refreshToken = sessionMap['refresh_token'];
      if (refreshToken != null) await _supabase.auth.setSession(refreshToken);

      await SessionService.saveSession(sessionMap, userMap);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({required String email, required String password, required String username}) async {
    final url = Uri.parse('${AppConstants.authBaseUrl}/signup');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'username': username}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw jsonDecode(response.body)['error'] ?? "Registrasi gagal";
    }
  }

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

      final res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (res.session == null || res.user == null) throw "Google login gagal";

      try {
        await _syncGoogleUserToBackend(res.session!.accessToken);
      } catch (e) {
        debugPrint("Sync Backend Warning: $e");
      }

      final rawSession = {
        "access_token": res.session!.accessToken,
        "refresh_token": res.session!.refreshToken,
        "expires_at": res.session!.expiresAt,
        "token_type": res.session!.tokenType,
        "user": res.session!.user?.toJson(),
      };

      await SessionService.saveSession(rawSession, res.user!.toJson());
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

  Future<void> logout() async {
    try { await _supabase.auth.signOut(); } catch (_) {}
    await SessionService.clearSession();
    try { await GoogleSignIn().signOut(); } catch (_) {}
  }
}