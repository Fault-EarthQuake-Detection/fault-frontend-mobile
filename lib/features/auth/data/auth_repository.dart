// lib/features/auth/data/auth_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  User? get currentUser => _supabase.auth.currentUser;

  // ----------------------
  // REGISTER
  // ----------------------
  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw jsonDecode(response.body)['error'] ?? "Registrasi gagal";
    }
  }

  // ----------------------
  // LOGIN (backend)
  // ----------------------
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('${AppConstants.authBaseUrl}/login');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw jsonDecode(res.body)['error'] ?? "Login gagal";
    }

    final data = jsonDecode(res.body);

    final session = data['session'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;

    final refreshToken = session['refresh_token'];

    if (refreshToken == null || refreshToken.toString().isEmpty) {
      throw "Refresh token tidak ditemukan pada response backend";
    }

    // ----------------------------
    // Supabase v2.x → setSession(refresh_token)
    // ----------------------------
    await _supabase.auth.setSession(refreshToken);

    // simpan ke SharedPreferences
    await SessionService.saveSession(session, user);
  }

  // ----------------------
  // LOGIN GOOGLE (Native)
  // ----------------------
  Future<void> googleSignIn() async {
    const webClientId =
        "204345218481-307nql93btdhpslm76jt8u6uumm2ti98.apps.googleusercontent.com";

    final googleSignIn = GoogleSignIn(serverClientId: webClientId);

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    if (googleAuth == null) throw "Login Google dibatalkan";

    final res = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    if (res.session == null || res.user == null) {
      throw "Google login gagal (session tidak dikembalikan)";
    }

    final authSession = res.session!;
    final supaUser = res.user!;

    final rawSession = {
      "access_token": authSession.accessToken,
      "refresh_token": authSession.refreshToken,
      "expires_at": authSession.expiresAt,
      "token_type": authSession.tokenType,
      "user": authSession.user?.toJson(),
    };

    // Supabase v2 setSession(refreshToken)
    if (authSession.refreshToken != null &&
        authSession.refreshToken!.isNotEmpty) {
      await _supabase.auth.setSession(authSession.refreshToken!);
    }

    await SessionService.saveSession(rawSession, supaUser.toJson());
  }

  // ----------------------
  // LOGOUT
  // ----------------------
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    await SessionService.clearSession();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // ----------------------
  // UPLOAD AVATAR
  // ----------------------
  Future<String> uploadAvatar(File file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName =
        "$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext";

    await _supabase.storage.from('avatar-profile').upload(
      fileName,
      file,
    );

    return _supabase.storage.from('avatar-profile').getPublicUrl(fileName);
  }

  // ----------------------
  // UPDATE PROFILE
  // ----------------------
  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final token = await SessionService.getAccessToken();
    if (token == null || token.isEmpty) throw "Sesi habis, login ulang";

    final url = Uri.parse('${AppConstants.apiBaseUrl}/profile');

    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "username": username,
        "avatarUrl": avatarUrl,
      }),
    );

    if (res.statusCode >= 300) {
      throw jsonDecode(res.body)['error'] ?? "Update profile gagal";
    }

    // reload user
    try {
      final userResp = await _supabase.auth.getUser();
      final supaUser = userResp.user;

      if (supaUser != null) {
        final session = await SessionService.getSession();
        await SessionService.saveSession(
          session!,
          supaUser.toJson(),
        );
      }
    } catch (_) {}
  }

  // ----------------------
  // CHANGE PASSWORD
  // ----------------------
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await SessionService.getAccessToken();
    if (token == null || token.isEmpty) throw "Harap login kembali";

    final url = Uri.parse('${AppConstants.apiBaseUrl}/change-password');

    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    if (res.statusCode >= 300) {
      throw jsonDecode(res.body)['error'] ?? "Gagal ganti password";
    }
  }
}
