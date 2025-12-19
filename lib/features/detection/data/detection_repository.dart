import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/supabase_service.dart';
import 'package:http_parser/http_parser.dart';

class DetectionRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  // 1. Upload Gambar Asli ke Supabase
  Future<String> uploadImageToStorage(File file, String folder) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final path = "$folder/$fileName";

      // Pastikan nama bucket sesuai dengan settingan Supabase kamu ('detection-image' atau 'detection-images')
      await _supabase.storage.from('detection-image').upload(path, file);

      return _supabase.storage.from('detection-image').getPublicUrl(path);
    } catch (e) {
      throw "Gagal upload gambar ke storage: $e";
    }
  }

  // 2. Upload Base64 (Overlay) ke Supabase
  Future<String> uploadBase64ToStorage(String base64String, String folder) async {
    try {
      final cleanBase64 = base64String.replaceAll(RegExp(r'data:image\/[^;]+;base64,'), '');
      Uint8List bytes = base64Decode(cleanBase64);

      final fileName = "overlay_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final path = "$folder/$fileName";

      await _supabase.storage.from('detection-image').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true)
      );

      return _supabase.storage.from('detection-image').getPublicUrl(path);
    } catch (e) {
      print("Warning: Gagal upload overlay: $e");
      return "";
    }
  }

  // 3. KIRIM KE AI VISUAL
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      final url = Uri.parse("${AppConstants.aiApiUrl}/predict");

      var request = http.MultipartRequest('POST', url);

      // --- TENTUKAN CONTENT-TYPE ---
      final String extension = imageFile.path.split('.').last.toLowerCase();
      MediaType contentType;

      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else {
        contentType = MediaType('image', 'jpeg');
      }

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: contentType,
      );

      request.files.add(multipartFile);

      print("Mengirim gambar ke AI: ${imageFile.path} sebagai $contentType");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw "AI Visual Error (${response.statusCode}): ${response.body}";
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("Error analyzing image: $e");
      rethrow;
    }
  }

  // 4. Cek Resiko Lokasi (/cek_lokasi)
  Future<Map<String, dynamic>> checkLocationRisk(double lat, double long) async {
    try {
      final url = Uri.parse("${AppConstants.aiApiUrl}/cek_lokasi");

      var request = http.MultipartRequest('POST', url);
      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = long.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Gagal cek lokasi: ${response.body}");
        return {
          "status": "Info Lokasi Tidak Tersedia",
          "nama_patahan": "-",
          "jarak_km": 0.0
        };
      }
    } catch (e) {
      print("Error checking location: $e");
      return {
        "status": "Offline",
        "nama_patahan": "-",
        "jarak_km": 0.0
      };
    }
  }

  // 5. Simpan Hasil ke Backend (DENGAN VALIDASI TOKEN)
  Future<void> saveDetectionResult({
    required double lat,
    required double long,
    required String originalUrl,
    required String overlayUrl,
    required String faultType,
    required String description,
    required String status,
    required String locationStatus,
    required String faultName,
    required double faultDistance,
  }) async {
    final token = await SessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw "Sesi habis. Silakan Logout dan Login kembali.";
    }

    final url = Uri.parse("${AppConstants.apiBaseUrl}/detections");

    final fullDescriptionJson = jsonEncode({
      "visual_description": description,
      "visual_status": status,
      "location_status": locationStatus,
      "fault_name": faultName,
      "fault_distance": faultDistance,
      "timestamp": DateTime.now().toIso8601String(),
    });

    final bodyData = {
      "latitude": lat,
      "longitude": long,
      "originalImageUrl": originalUrl,
      "overlayImageUrl": overlayUrl,
      "detectionResult": faultType,
      "statusLevel": status,
      "description": fullDescriptionJson,
      "address": "$faultName (${faultDistance.toStringAsFixed(1)} km)",
    };

    print("Mengirim Data ke Backend...");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw "Akses ditolak: Token tidak valid atau kadaluarsa. Silakan Login ulang.";
    }

    if (response.statusCode >= 300) {
      throw jsonDecode(response.body)['error'] ?? "Gagal menyimpan data (Error ${response.statusCode})";
    }
  }
}