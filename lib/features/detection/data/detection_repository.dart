import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';

class DetectionRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  Future<String> uploadImageToStorage(File file, String folder) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final path = "$folder/$fileName";
      await _supabase.storage.from('detection-image').upload(path, file);
      return _supabase.storage.from('detection-image').getPublicUrl(path);
    } catch (e) {
      throw "Gagal upload gambar: $e";
    }
  }

  Future<String> uploadBase64ToStorage(String base64String, String folder) async {
    try {
      final cleanBase64 = base64String.replaceAll(RegExp(r'data:image\/[^;]+;base64,'), '');
      Uint8List bytes = base64Decode(cleanBase64);
      final fileName = "overlay_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final path = "$folder/$fileName";

      await _supabase.storage.from('detection-image').uploadBinary(
          path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true)
      );
      return _supabase.storage.from('detection-image').getPublicUrl(path);
    } catch (e) {
      if (kDebugMode) {
        print("Warning Upload Overlay: $e");
      }
      return "";
    }
  }

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final url = Uri.parse("${AppConstants.aiApiUrl}/predict");
      var request = http.MultipartRequest('POST', url);

      final ext = imageFile.path.split('.').last.toLowerCase();
      final contentType = (ext == 'png') ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path, contentType: contentType));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) throw "AI Error (${response.statusCode}): ${response.body}";
      return jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkLocationRisk(double lat, double long) async {
    try {
      final url = Uri.parse("${AppConstants.aiApiUrl}/cek_lokasi");
      final response = await http.post(url, body: {'latitude': '$lat', 'longitude': '$long'});

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": "Info Lokasi Tidak Tersedia", "nama_patahan": "-", "jarak_km": 0.0};
    } catch (e) {
      return {"status": "Offline", "nama_patahan": "-", "jarak_km": 0.0};
    }
  }

  Future<void> saveDetectionResult({
    required double latitude,
    required double longitude,
    required String originalImageUrl,
    required String overlayImageUrl,
    required String maskImageUrl,
    required String detectionResult,
    required String statusLevel,
    required Map<String, dynamic> descriptionMap,
    required String address,
  }) async {
    final token = await SessionService.getAccessToken();
    if (token == null) throw "Sesi habis. Silakan login ulang.";

    final url = Uri.parse("${AppConstants.apiBaseUrl}/detections");

    final descriptionString = jsonEncode(descriptionMap);

    final body = {
      "latitude": latitude,
      "longitude": longitude,
      "originalImageUrl": originalImageUrl,
      "overlayImageUrl": overlayImageUrl,
      "maskImageUrl": maskImageUrl,
      "detectionResult": detectionResult,
      "statusLevel": statusLevel,
      "description": descriptionString,
      "address": address,
    };

    if (kDebugMode) {
      print("Sending Body: $body");
    }

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 300) {
      String errorMessage = "Gagal menyimpan data";
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['details'] != null) {
          errorMessage = errJson['details'];
        } else if (errJson['error'] != null) {
          errorMessage = errJson['error'];
        }
      } catch (_) {}

      throw "$errorMessage (Kode: ${response.statusCode})";
    }
  }
}