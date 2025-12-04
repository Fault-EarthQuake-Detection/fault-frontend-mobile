import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/detection_repository.dart';
import '../data/detection_response.dart';

class DetectionState {
  final File? image;
  final double? lat;
  final double? lng;
  final bool isLoading;
  final DetectionResponse? result;
  final String? error;
  final bool isSaved;

  DetectionState({
    this.image,
    this.lat,
    this.lng,
    this.isLoading = false,
    this.result,
    this.error,
    this.isSaved = false,
  });

  DetectionState copyWith({
    File? image, double? lat, double? lng,
    bool? isLoading, DetectionResponse? result, String? error, bool? isSaved,
  }) {
    return DetectionState(
      image: image ?? this.image,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class DetectionViewModel extends StateNotifier<DetectionState> {
  final DetectionRepository _repository;

  DetectionViewModel(this._repository) : super(DetectionState());

  void setImage(File image) {
    state = state.copyWith(image: image, isSaved: false, result: null);
  }

  void setLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  void reset() {
    state = DetectionState();
  }

  Future<void> runAnalysis() async {
    if (state.image == null || state.lat == null || state.lng == null) {
      state = state.copyWith(error: "Data gambar atau lokasi belum lengkap");
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.analyze(
        image: state.image!,
        lat: state.lat!,
        lng: state.lng!,
      );
      state = state.copyWith(result: response, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> saveDetection() async {
    if (state.result == null || state.image == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final imageUrl = await _repository.uploadDetectionImage(state.image!);
      await _repository.saveDetectionResult(
        lat: state.lat!,
        lng: state.lng!,
        imageUrl: imageUrl,
        data: state.result!,
      );
      state = state.copyWith(isSaved: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: "Gagal menyimpan: $e", isLoading: false);
    }
  }
}

final detectionRepositoryProvider = Provider((ref) => DetectionRepository());
final detectionViewModelProvider = StateNotifierProvider<DetectionViewModel, DetectionState>((ref) {
  return DetectionViewModel(ref.read(detectionRepositoryProvider));
});