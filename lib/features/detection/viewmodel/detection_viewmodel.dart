import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/detection_repository.dart';

class DetectionState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  DetectionState({
    this.isLoading = false,
    this.error,
    this.result
  });
}

class DetectionViewModel extends StateNotifier<DetectionState> {
  final DetectionRepository _repo;

  DetectionViewModel(this._repo) : super(DetectionState());

  Future<void> processDetection({
    required File imageFile,
    required double latitude,
    required double longitude,
    String? address,
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

      final visualStatus = faultAnalysis['status_level'] ?? "INFO";
      final faultType = faultAnalysis['deskripsi_singkat'] ?? "Tidak Teridentifikasi";
      final visualDesc = faultAnalysis['penjelasan_lengkap'] ?? (aiResult['statement'] ?? "-");

      final rawBase64 = imagesBase64['overlay'];

      final locationStatusFull = locResult['status'] as String? ?? "Zona Tidak Diketahui";

      String locationStatusShort = "AMAN";
      if (locationStatusFull.contains("ZONA PERINGATAN")) {
        locationStatusShort = "ZONA PERINGATAN";
      } else if (locationStatusFull.contains("BAHAYA")) {
        locationStatusShort = "ZONA BAHAYA";
      }

      final faultName = locResult['nama_patahan'] ?? "-";
      final distanceKm = double.tryParse(locResult['jarak_km'].toString()) ?? 0.0;

      String finalStatus = visualStatus;

      bool isLocDanger = locationStatusShort.contains("BAHAYA") ||
          locationStatusShort.contains("PERINGATAN");

      if (isLocDanger) {
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

      await _repo.saveDetectionResult(
        lat: latitude,
        long: longitude,
        originalUrl: originalUrl,
        overlayUrl: overlayUrl,
        faultType: faultType,
        description: visualDesc,
        status: finalStatus,
        locationStatus: locationStatusShort,
        faultName: faultName,
        faultDistance: distanceKm,
      );

      state = DetectionState(
          isLoading: false,
          result: {
            "status": finalStatus,
            "visualStatus": visualStatus,
            "faultType": faultType,
            "description": visualDesc,
            "originalUrl": originalUrl,
            "overlayUrl": overlayUrl,
            "locationStatus": locationStatusShort,
            "faultName": faultName,
            "distanceKm": distanceKm,
          }
      );

    } catch (e) {
      print("Error Processing: $e");
      state = DetectionState(isLoading: false, error: e.toString());
    }
  }
}

// Providers
final detectionRepositoryProvider = Provider<DetectionRepository>((ref) {
  return DetectionRepository();
});

final detectionViewModelProvider = StateNotifierProvider<DetectionViewModel, DetectionState>((ref) {
  final repo = ref.read(detectionRepositoryProvider);
  return DetectionViewModel(repo);
});