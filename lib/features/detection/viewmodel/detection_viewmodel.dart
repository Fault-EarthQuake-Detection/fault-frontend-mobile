import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/detection_repository.dart';

class DetectionState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  final bool isSaving;
  final bool isSavedSuccess;

  DetectionState({
    this.isLoading = false,
    this.error,
    this.result,
    this.isSaving = false,
    this.isSavedSuccess = false,
  });

  DetectionState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? result,
    bool? isSaving,
    bool? isSavedSuccess,
  }) {
    return DetectionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
      isSaving: isSaving ?? this.isSaving,
      isSavedSuccess: isSavedSuccess ?? this.isSavedSuccess,
    );
  }
}

class DetectionViewModel extends StateNotifier<DetectionState> {
  final DetectionRepository _repo;

  DetectionViewModel(this._repo) : super(DetectionState());

  Future<void> analyzeOnly({
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    state = DetectionState(isLoading: true);
    try {
      // 1. Upload Original, Analisis AI, Cek Lokasi
      final results = await Future.wait([
        _repo.analyzeImage(imageFile),
        _repo.checkLocationRisk(latitude, longitude),
        _repo.uploadImageToStorage(imageFile, "originals")
      ]);

      final aiResult = results[0] as Map<String, dynamic>;
      final locResult = results[1] as Map<String, dynamic>;
      final originalUrl = results[2] as String;

      // 2. Parsing Data AI
      final faultAnalysis = aiResult['fault_analysis'] as Map<String, dynamic>? ?? {};
      final imagesBase64 = aiResult['images_base64'] as Map<String, dynamic>? ?? {};

      String visualStatus = faultAnalysis['status_level'] ?? "INFO";
      if (visualStatus.contains("AMAN")) visualStatus = "AMAN";

      final faultType = faultAnalysis['deskripsi_singkat'] ?? "Tidak Teridentifikasi";
      final visualDesc = faultAnalysis['penjelasan_lengkap'] ?? aiResult['statement'] ?? "-";

      // Ambil Base64 Overlay & Mask
      final rawBase64Overlay = imagesBase64['overlay'];
      final rawBase64Mask = imagesBase64['mask']; // [BARU] Ambil key 'mask'

      // 3. Parsing Data Lokasi
      String locationStatus = locResult['status'] ?? "AMAN";
      if (locationStatus.contains("PERINGATAN")) locationStatus = "PERINGATAN";
      if (locationStatus.contains("BAHAYA")) locationStatus = "BAHAYA";

      final faultName = locResult['nama_patahan'] ?? "-";
      final distanceKm = double.tryParse(locResult['jarak_km'].toString()) ?? 0.0;

      // 4. Logika Final Status
      String finalStatus = visualStatus;
      if (locationStatus.contains("BAHAYA") || locationStatus.contains("PERINGATAN")) {
        if (visualStatus == "AMAN" || visualStatus == "INFO") {
          finalStatus = "WASPADA (LOKASI)";
        } else {
          finalStatus = "BAHAYA TINGGI";
        }
      }

      // 5. Upload Overlay (Jika ada)
      String overlayUrl = "";
      if (rawBase64Overlay != null && rawBase64Overlay.toString().isNotEmpty) {
        overlayUrl = await _repo.uploadBase64ToStorage(rawBase64Overlay, "overlays");
      }

      // [BARU] 6. Upload Mask (Jika ada)
      String maskImageUrl = "";
      if (rawBase64Mask != null && rawBase64Mask.toString().isNotEmpty) {
        // Upload ke folder 'masks' di storage
        maskImageUrl = await _repo.uploadBase64ToStorage(rawBase64Mask, "masks");
      }

      // 7. Simpan Hasil Sementara di STATE
      final tempResult = {
        "latitude": latitude,
        "longitude": longitude,
        "originalUrl": originalUrl,
        "overlayUrl": overlayUrl,
        "maskImageUrl": maskImageUrl, // [BARU] Masukkan ke result
        "faultType": faultType,
        "status": finalStatus,
        "description": visualDesc,
        "images_base64": imagesBase64,
        "nama_patahan": faultName,
        "jarak_km": distanceKm,
        "locationStatus": locationStatus,
        "visualStatus": visualStatus,
      };

      state = DetectionState(
        isLoading: false,
        result: tempResult,
      );

    } catch (e) {
      state = DetectionState(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveResultToDatabase() async {
    if (state.result == null) return;

    state = state.copyWith(isSaving: true);

    try {
      final res = state.result!;

      final fullDescMap = {
        "visual_description": res['description'],
        "visual_status": res['visualStatus'],
        "location_status": res['locationStatus'],
        "fault_name": res['nama_patahan'],
        "fault_distance": res['jarak_km'],
      };

      await _repo.saveDetectionResult(
        latitude: res['latitude'],
        longitude: res['longitude'],
        originalImageUrl: res['originalUrl'],
        overlayImageUrl: res['overlayUrl'],
        // [BARU] Kirim maskImageUrl ke repository
        maskImageUrl: res['maskImageUrl'] ?? "",
        detectionResult: res['faultType'],
        statusLevel: res['status'],
        descriptionMap: fullDescMap,
        address: "${res['nama_patahan']} (${(res['jarak_km'] as double).toStringAsFixed(1)} km)",
      );

      state = state.copyWith(isSaving: false, isSavedSuccess: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: "Gagal menyimpan: $e");
    }
  }

  void resetState() {
    state = DetectionState();
  }
}

final detectionRepositoryProvider = Provider((ref) => DetectionRepository());
final detectionViewModelProvider = StateNotifierProvider<DetectionViewModel, DetectionState>((ref) {
  return DetectionViewModel(ref.read(detectionRepositoryProvider));
});