import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';

List<dynamic> _processHistoryData(Map<String, dynamic> params) {
  final String responseBody = params['body'];
  final String currentUserId = params['currentUserId'];

  try {
    final body = jsonDecode(responseBody);
    List<dynamic> allDetections = [];

    if (body is Map && body.containsKey('data')) {
      allDetections = body['data'];
    } else if (body is List) {
      allDetections = body;
    }

    final userHistory = allDetections.where((item) {
      final itemUserId = item['userId'] ?? item['user_id'];
      return itemUserId.toString() == currentUserId.toString();
    }).toList();

    userHistory.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt'] ?? a['created_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['createdAt'] ?? b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return userHistory;
  } catch (e) {
    return [];
  }
}

class HistoryRepository {
  Future<List<dynamic>> getUserHistory() async {
    try {
      final token = await SessionService.getAccessToken();
      final user = await SessionService.getUser();

      if (token == null || user == null) return [];

      final currentUserId = user['id'];

      // [OPTIMASI 1] Turunkan limit.
      // Mengambil 100 data jika payloadnya besar itu bunuh diri di mobile.
      // Coba 50 dulu. Jika backend tidak support filter by user, ini kelemahan arsitekturnya.
      final url = Uri.parse("${AppConstants.apiBaseUrl}/detections?limit=50");

      // [DEBUGGING] Catat waktu mulai
      final stopwatch = Stopwatch()..start();
      print("History: Mulai Request ke $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // [DEBUGGING] Cek durasi & ukuran
      stopwatch.stop();
      final kbSize = (response.bodyBytes.length / 1024).toStringAsFixed(2);
      print("History: Selesai dalam ${stopwatch.elapsedMilliseconds}ms. Ukuran: $kbSize KB");

      if (double.parse(kbSize) > 5000) {
        print("⚠️ PERINGATAN: Ukuran data > 5MB! Ini penyebab lemotnya.");
      }

      if (response.statusCode == 200) {
        return await compute(_processHistoryData, {
          'body': response.body,
          'currentUserId': currentUserId,
        });
      }
      return [];
    } catch (e) {
      print("HistoryRepo Exception: $e");
      return [];
    }
  }
}