import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart'; // Untuk compute
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import 'feed_item.dart';

// --- FUNGSI PARSING DI LUAR CLASS (GLOBAL) ---
// Agar bisa dijalankan di background isolate

// 1. Parsing Deteksi di Background
List<FeedItem> _parseDetectionsInIsolate(Map<String, dynamic> params) {
  final String responseBody = params['body'];
  final String? currentUserId = params['currentUserId'];

  final body = jsonDecode(responseBody);
  List<dynamic> data = (body is Map && body.containsKey('data')) ? body['data'] : body;

  return data.map((item) {
    final String ownerId = item['userId'] ?? item['user_id'] ?? "";
    final bool isMine = (currentUserId != null && ownerId == currentUserId);

    return FeedItem(
      id: "det-${item['id']}",
      type: 'detection',
      title: item['faultType'] ?? item['fault_type'] ?? "Fault Detection",
      source: item['user']?['username'] ?? "GeoValid User",
      timestamp: DateTime.tryParse(item['createdAt'] ?? item['created_at']) ?? DateTime.now(),
      imageUrl: item['originalImageUrl'] ?? item['original_image_url'],
      statusLevel: item['statusLevel'] ?? item['status_level'],
      originalData: item,
      userAvatarUrl: item['user']?['avatarUrl'] ?? item['user']?['avatar_url'],
      isMine: isMine,
    );
  }).toList();
}

// 2. Helper Math (Harus di luar class juga agar bisa diakses isolate)
String? _getGoogleSatelliteUrl(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  const int zoom = 12;
  final int x = ((lng + 180.0) / 360.0 * pow(2, zoom)).floor();
  final int y = ((1.0 - log(tan(lat * pi / 180.0) + 1.0 / cos(lat * pi / 180.0)) / pi) / 2.0 * pow(2, zoom)).floor();
  return 'https://mt1.google.com/vt/lyrs=y&x=$x&y=$y&z=$zoom';
}

// 3. Parsing BMKG di Background
List<FeedItem> _parseBMKGInIsolate(String responseBody) {
  final data = jsonDecode(responseBody);
  final List gempaList = data['Infogempa']['gempa'];

  return gempaList.map((g) {
    double? lat, lng;
    try {
      final latParts = (g['Lintang'] as String).split(' ');
      lat = double.parse(latParts[0]);
      if (latParts[1].contains('LS')) lat = -lat;

      final lngParts = (g['Bujur'] as String).split(' ');
      lng = double.parse(lngParts[0]);
      if (lngParts[1].contains('BB')) lng = -lng;
    } catch (_) {}

    // Hitung URL Maps di background juga biar UI ga ngelag
    String? image = _getGoogleSatelliteUrl(lat, lng);
    if (g['Shakemap'] != null && g['Shakemap'].toString().isNotEmpty) {
      image = "https://data.bmkg.go.id/DataMKG/TEWS/${g['Shakemap']}";
    }

    return FeedItem(
      id: "bmkg-${g['DateTime']}",
      type: 'news',
      title: "Gempa Mag ${g['Magnitude']} di ${g['Wilayah']}",
      source: "BMKG Indonesia",
      timestamp: DateTime.tryParse(g['DateTime']) ?? DateTime.now(),
      imageUrl: image,
      statusLevel: "WASPADA",
      url: "https://www.bmkg.go.id/gempabumi/gempabumi-dirasakan.bmkg",
      originalData: g,
      isMine: false,
    );
  }).toList();
}

// --- REPOSITORY UTAMA ---

class HomeRepository {
  Future<List<FeedItem>> fetchDetections({int page = 1}) async {
    try {
      final token = await SessionService.getAccessToken();
      final currentUser = await SessionService.getUser(); // Ini cuma baca string, aman
      final currentUserId = currentUser?['id'];

      final url = Uri.parse("${AppConstants.apiBaseUrl}/detections?page=$page&limit=20");

      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        // [OPTIMASI] Gunakan compute untuk parsing di background thread
        return await compute(_parseDetectionsInIsolate, {
          'body': response.body,
          'currentUserId': currentUserId,
        });
      }
    } catch (e) {
      print("HomeRepo Detection Error: $e");
    }
    return [];
  }

  Future<List<FeedItem>> fetchBMKG() async {
    try {
      final url = Uri.parse(AppConstants.bmkgUrl);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // [OPTIMASI] Gunakan compute untuk parsing di background thread
        return await compute(_parseBMKGInIsolate, response.body);
      }
    } catch (e) {
      print("HomeRepo BMKG Error: $e");
    }
    return [];
  }
}