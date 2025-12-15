import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/constants/app_constants.dart';
import 'detection_response.dart';

class DetectionRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  Future<DetectionResponse> analyze({required File image, required double lat, required double lng}) async {
    try {
      final isPng = image.path.toLowerCase().endsWith('.png');
      final mediaType = isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      var requestPredict = http.MultipartRequest('POST', Uri.parse('${AppConstants.aiApiUrl}/predict'));
      requestPredict.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: mediaType,
      ));

      var requestLocation = http.MultipartRequest('POST', Uri.parse('${AppConstants.aiApiUrl}/cek_lokasi'));
      requestLocation.fields['latitude'] = lat.toString();
      requestLocation.fields['longitude'] = lng.toString();

      final responses = await Future.wait([
        requestPredict.send(),
        requestLocation.send(),
      ]);

      final respPredict = await http.Response.fromStream(responses[0]);
      final respLocation = await http.Response.fromStream(responses[1]);

      if (respPredict.statusCode != 200) {
        try {
          final errJson = jsonDecode(respPredict.body);
          throw errJson['detail'] ?? respPredict.body;
        } catch (_) {
          throw "AI Error: ${respPredict.body}";
        }
      }
      if (respLocation.statusCode != 200) throw "Location Error: ${respLocation.body}";

      return DetectionResponse(
        predictData: jsonDecode(respPredict.body),
        locationData: jsonDecode(respLocation.body),
      );
    } catch (e) {
      throw Exception("Gagal menganalisis: $e");
    }
  }

  Future<String> uploadDetectionImage(File file) async {
    final user = await SessionService.getUser();
    if (user == null) throw "User belum login";
    final userId = user['id'];

    final fileExt = file.path.split('.').last;
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage.from('detection-image').upload(fileName, file);
    return _supabase.storage.from('detection-image').getPublicUrl(fileName);
  }

  Future<void> saveDetectionResult({
    required double lat,
    required double lng,
    required String imageUrl,
    required DetectionResponse data,
  }) async {
    final token = await SessionService.getAccessToken();
    if (token == null) throw "Sesi habis, silakan login ulang";

    final body = jsonEncode({
      'latitude': lat,
      'longitude': lng,
      'imageUrl': imageUrl,
      'originalImageUrl': imageUrl,
      'overlayImageUrl': data.overlayBase64 ?? "",
      'detectionResult': data.visualDescription,
      'description': jsonEncode({
        'visual_statement': data.statement,
        'visual_status': data.visualStatus,
        'location_status': data.locationStatus,
        'fault_name': data.faultName,
        'fault_distance': data.distanceKm,
        'analysis_timestamp': DateTime.now().toIso8601String(),
      })
    });

    final url = Uri.parse('${AppConstants.apiBaseUrl}/detections');

    print("Mengirim data ke: $url");
    print("Payload: $body");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw "Gagal menyimpan ke server: ${response.body}";
    }
  }
}