// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../../../core/services/session_service.dart'; // Import SessionService
// import '../../../core/constants/app_constants.dart';
// import '../../detection/data/detection_model.dart';
//
// class MapsRepository {
//   // Tidak perlu Supabase Client di sini karena kita ambil data dari Backend
//
//   Future<List<DetectionModel>> getAllDetections() async {
//     try {
//       // 🔥 Ambil Token dari SessionService
//       final token = await SessionService.getAccessToken();
//       if (token == null) throw "Silakan login untuk melihat peta";
//
//       // Request ke Backend Teman
//       final url = Uri.parse('${AppConstants.apiBaseUrl}/detections');
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         return data.map((e) => DetectionModel.fromJson(e)).toList();
//       } else {
//         throw "Server Error (${response.statusCode}): ${response.body}";
//       }
//     } catch (e) {
//       throw Exception("Gagal memuat data peta: $e");
//     }
//   }
// }