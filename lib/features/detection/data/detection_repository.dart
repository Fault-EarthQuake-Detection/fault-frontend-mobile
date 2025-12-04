import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // 👈 1. TAMBAHKAN IMPORT INI
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import 'detection_response.dart';

class DetectionRepository {
  final SupabaseClient _supabase = SupabaseService().client;
  final String _aiApiUrl = 'https://fikalalif-fault-detection-api.hf.space';

  Future<DetectionResponse> analyze({required File image, required double lat, required double lng}) async {
    try {
      final isPng = image.path.toLowerCase().endsWith('.png');
      final mediaType = isPng ? MediaType('image', 'png') : MediaType('image', 'jpeg');

      var requestPredict = http.MultipartRequest('POST', Uri.parse('$_aiApiUrl/predict'));

      requestPredict.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: mediaType,
      ));

      var requestLocation = http.MultipartRequest('POST', Uri.parse('$_aiApiUrl/cek_lokasi'));
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
          throw "AI Error (${respPredict.statusCode}): ${respPredict.body}";
        }
      }

      if (respLocation.statusCode != 200) {
        try {
          final errJson = jsonDecode(respLocation.body);
          throw errJson['detail'] ?? respLocation.body;
        } catch (_) {
          throw "Location Error (${respLocation.statusCode}): ${respLocation.body}";
        }
      }

      return DetectionResponse(
        predictData: jsonDecode(respPredict.body),
        locationData: jsonDecode(respLocation.body),
      );
    } catch (e) {
      throw Exception("Gagal menganalisis: $e");
    }
  }

  Future<String> uploadDetectionImage(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "User belum login";

    final fileExt = file.path.split('.').last;
    final fileName = '${user.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage.from('detection-image').upload(fileName, file);
    return _supabase.storage.from('detection-image').getPublicUrl(fileName);
  }

  Future<void> saveDetectionResult({
    required double lat,
    required double lng,
    required String imageUrl,
    required DetectionResponse data,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "User belum login";

    final payload = {
      'user_id': user.id,
      'latitude': lat,
      'longitude': lng,
      'image_url': imageUrl,
      'original_image_url': imageUrl,
      'overlay_image_url': data.overlayBase64 ?? "",
      'detection_result': data.visualDescription,
      'description': jsonEncode({
        'visual_statement': data.statement,
        'visual_status': data.visualStatus,
        'location_status': data.locationStatus,
        'fault_name': data.faultName,
        'fault_distance': data.distanceKm,
        'analysis_timestamp': DateTime.now().toIso8601String(),
      })
    };

    await _supabase.from('detections').insert(payload);
  }
}