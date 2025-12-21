import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';

class MapsRepository {
  Future<List<dynamic>> getDetectionHistory() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) return [];

      final url = Uri.parse("${AppConstants.apiBaseUrl}/detections");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return data['data'];
        } else if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print("MapsRepo Error: $e");
      return [];
    }
  }
}