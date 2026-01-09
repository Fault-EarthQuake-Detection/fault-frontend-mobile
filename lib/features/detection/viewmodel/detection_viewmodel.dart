import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/detection_repository.dart';

class DetectionState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  DetectionState({this.isLoading = false, this.error, this.result});
}

class DetectionViewModel extends StateNotifier<DetectionState> {
  final DetectionRepository _repo;

  DetectionViewModel(this._repo) : super(DetectionState());

  Future<void> processDetection({
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    state = DetectionState(isLoading: true);
    try {
      final results = await Future.wait([
        _repo.analyzeImage(imageFile),
        _repo.checkLocationRisk(latitude, longitude),
        _repo.uploadImageToStorage(imageFile, "originals")
      ]);

      final aiResult = results[0] as Map<String, dynamic>;
      final locResult = results[1] as Map<String, dynamic>;
      final originalUrl = results[2] as String;

      final faultAnalysis = aiResult['fault_analysis'] as Map<String, dynamic>? ?? {};
      final imagesBase64 = aiResult['images_base64'] as Map<String, dynamic>? ?? {};

      String visualStatus = faultAnalysis['status_level'] ?? "INFO";
      if (visualStatus.contains("AMAN")) visualStatus = "AMAN";

      final faultType = faultAnalysis['deskripsi_singkat'] ?? "Tidak Teridentifikasi";
      final visualDesc = faultAnalysis['penjelasan_lengkap'] ?? aiResult['statement'] ?? "-";
      final rawBase64 = imagesBase64['overlay'];

      String locationStatus = locResult['status'] ?? "AMAN";
      if (locationStatus.contains("PERINGATAN")) locationStatus = "PERINGATAN";
      if (locationStatus.contains("BAHAYA")) locationStatus = "BAHAYA";

      final faultName = locResult['nama_patahan'] ?? "-";
      final distanceKm = double.tryParse(locResult['jarak_km'].toString()) ?? 0.0;

      String finalStatus = visualStatus;
      if (locationStatus.contains("BAHAYA") || locationStatus.contains("PERINGATAN")) {
        if (visualStatus == "AMAN" || visualStatus == "INFO") {
          finalStatus = "WASPADA (LOKASI)";
        } else {
          finalStatus = "BAHAYA TINGGI";
        }
      }

      String overlayUrl = "";
      if (rawBase64 != null && rawBase64.toString().isNotEmpty) {
        overlayUrl = await _repo.uploadBase64ToStorage(rawBase64, "overlays");
      }

      String maskImageUrl = "";
      if (rawBase64 != null && rawBase64.toString().isNotEmpty) {
        overlayUrl = await _repo.uploadBase64ToStorage(rawBase64, "mask");
      }

      final fullDescMap = {
        "visual_description": visualDesc,
        "visual_status": visualStatus,
        "location_status": locationStatus,
        "fault_name": faultName,
        "fault_distance": distanceKm,
      };

      await _repo.saveDetectionResult(
        latitude: latitude,
        longitude: longitude,
        originalImageUrl: originalUrl,
        overlayImageUrl: overlayUrl,
        maskImageUrl: maskImageUrl,
        detectionResult: faultType,
        statusLevel: finalStatus,
        descriptionMap: fullDescMap,
        address: "$faultName (${distanceKm.toStringAsFixed(1)} km)",
      );

      state = DetectionState(
          isLoading: false,
          result: {
            "status": finalStatus,
            "faultType": faultType,
            "description": visualDesc,
            "originalUrl": originalUrl,
            "overlayUrl": overlayUrl,
            "images_base64": imagesBase64,
            "nama_patahan": faultName,
            "jarak_km": distanceKm,
            "locationStatus": locationStatus,
          }
      );

    } catch (e) {
      state = DetectionState(isLoading: false, error: e.toString());
    }
  }
}

final detectionRepositoryProvider = Provider((ref) => DetectionRepository());
final detectionViewModelProvider = StateNotifierProvider<DetectionViewModel, DetectionState>((ref) {
  return DetectionViewModel(ref.read(detectionRepositoryProvider));
});