import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';

class ProfileRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  Future<void> sendFeedback(String content) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw "Sesi habis";

      final url = Uri.parse("${AppConstants.apiBaseUrl}/feedback");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"content": content}),
      );

      if (response.statusCode != 201) {
        throw "Gagal mengirim: ${response.body}";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final ext = file.path.split('.').last;
    final fileName = "$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext";

    if (_supabase.auth.currentSession == null) {
      final token = await SessionService.getRefreshToken();
      if (token != null) {
        // [NOTE] Refresh session manual jika perlu
        try {
          await _supabase.auth.setSession(token);
        } catch (_) {}
      }
    }

    await _supabase.storage.from('avatar-profile').upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return _supabase.storage.from('avatar-profile').getPublicUrl(fileName);
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
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
        final currentAccess = await SessionService.getAccessToken();
        final currentRefresh = await SessionService.getRefreshToken();

        final sessionMap = {
          'access_token': currentAccess,
          'refresh_token': currentRefresh,
        };

        await SessionService.saveSession(sessionMap, supaUser.toJson());
      }
    } catch (e) {
      print("Gagal sync user local: $e");
    }
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
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