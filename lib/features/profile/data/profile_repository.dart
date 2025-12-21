import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';

class ProfileRepository {
  // Method khusus untuk update profile, change password, dan feedback ada di sini

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
}