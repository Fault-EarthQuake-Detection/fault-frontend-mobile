import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';

class HistoryRepository {

  // Fungsi khusus untuk mengambil riwayat milik user yang sedang login
  Future<List<dynamic>> getUserHistory() async {
    try {
      final token = await SessionService.getAccessToken();
      final user = await SessionService.getUser(); // Ambil data user dari session lokal

      if (token == null || user == null) {
        print("HistoryRepo: Token atau User null");
        return [];
      }

      final currentUserId = user['id'];

      // Request ke backend (masih endpoint global)
      final url = Uri.parse("${AppConstants.apiBaseUrl}/detections?limit=100");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> allDetections = [];

        // Handle format response { data: [...] } atau [...]
        if (body is Map && body.containsKey('data')) {
          allDetections = body['data'];
        } else if (body is List) {
          allDetections = body;
        }

        // --- FILTERING LOGIC ---
        // Filter data agar hanya milik user yang sedang login
        final myDetections = allDetections.where((item) {
          // Cek field userId (backend biasanya kirim userId atau user_id)
          final itemUserId = item['userId'] ?? item['user_id'];
          return itemUserId == currentUserId;
        }).toList();

        return myDetections;
      } else {
        print("HistoryRepo Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("HistoryRepo Exception: $e");
      return [];
    }
  }
}