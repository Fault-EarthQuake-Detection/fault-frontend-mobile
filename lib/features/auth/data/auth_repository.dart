// lib/features/auth/data/auth_repository.dart

import 'dart:convert';
import 'dart:io';
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

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.authBaseUrl}/login');
      print("Attempting login to: $url");

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print("Login Response: ${res.statusCode} - ${res.body}");

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw jsonDecode(res.body)['error'] ?? "Login gagal";
      }

      final data = jsonDecode(res.body);

      final sessionMap = data['session'];
      final userMap = data['user'];

      if (sessionMap == null || userMap == null) {
        throw "Format respon backend tidak valid (session/user null)";
      }

      final refreshToken = sessionMap['refresh_token'];

      if (refreshToken != null) {
        await _supabase.auth.setSession(refreshToken);
      }

      await SessionService.saveSession(sessionMap, userMap);

    } catch (e) {
      print("Error Login: $e");
      rethrow;
    }
  }

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
        'username': username,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw jsonDecode(response.body)['error'] ?? "Registrasi gagal";
    }
  }

  Future<void> googleSignIn() async {
    try {
      const webClientId =
          "204345218481-307nql93btdhpslm76jt8u6uumm2ti98.apps.googleusercontent.com";

      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? webClientId : null,
        serverClientId: webClientId,
      );

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

      await _syncGoogleUserToBackend(authSession.accessToken, supaUser);

      final rawSession = {
        "access_token": authSession.accessToken,
        "refresh_token": authSession.refreshToken,
        "expires_at": authSession.expiresAt,
        "token_type": authSession.tokenType,
        "user": authSession.user?.toJson(),
      };

      await SessionService.saveSession(rawSession, supaUser.toJson());

    } catch (e) {
      print("Error Google Sign In: $e");
      rethrow;
    }
  }

  Future<void> _syncGoogleUserToBackend(String accessToken, User user) async {
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}/profile');

      String username = user.userMetadata?['full_name'] ??
          user.email?.split('@')[0] ??
          "user_${user.id.substring(0,4)}";

      username = username.replaceAll(' ', '_');

      await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "username": username,
          "avatarUrl": user.userMetadata?['avatar_url'] ?? "",
        }),
      );
      print("Google User synced to Backend successfully.");
    } catch (e) {
      print("Warning: Gagal sync user Google ke backend, mungkin user sudah ada atau masalah koneksi. $e");
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}

    await SessionService.clearSession();

    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName =
        "$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext";

    if (_supabase.auth.currentSession == null) {
      final token = await SessionService.getRefreshToken();
      if (token != null) await _supabase.auth.setSession(token);
    }

    await _supabase.storage.from('avatar-profile').upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _supabase.storage.from('avatar-profile').getPublicUrl(fileName);
  }

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