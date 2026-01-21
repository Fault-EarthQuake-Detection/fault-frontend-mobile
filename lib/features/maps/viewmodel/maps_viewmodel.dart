import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/session_service.dart'; // [WAJIB]
import '../data/maps_repository.dart';

class MapsState {
  final List<List<LatLng>> faultLines;
  final List<dynamic> allMarkers; // Semua marker (Raw)
  final bool isLoading;
  final String? currentUserId;

  MapsState({
    this.faultLines = const [],
    this.allMarkers = const [],
    this.isLoading = true,
    this.currentUserId,
  });

  MapsState copyWith({
    List<List<LatLng>>? faultLines,
    List<dynamic>? allMarkers,
    bool? isLoading,
    String? currentUserId
  }) {
    return MapsState(
      faultLines: faultLines ?? this.faultLines,
      allMarkers: allMarkers ?? this.allMarkers,
      isLoading: isLoading ?? this.isLoading,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class MapsViewModel extends StateNotifier<MapsState> {
  final MapsRepository _repo;

  MapsViewModel(this._repo) : super(MapsState()) {
    loadMapData();
  }

  Future<void> loadMapData() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Ambil User ID & Data
      final user = await SessionService.getUser();
      final myId = user?['id']; // Pastikan key id sesuai session kamu

      final results = await Future.wait([
        rootBundle.loadString('assets/patahan_aktif.geojson'),
        _repo.getDetectionHistory(),
      ]);

      final geoJsonString = results[0] as String;
      final rawHistoryData = results[1] as List<dynamic>;

      // 2. Filter Logika: Tampilkan jika VALID atau PUNYA SAYA
      final displayMarkers = rawHistoryData.where((item) {
        if (item is Map<String, dynamic>) {
          final isValid = item['isValidated'] ?? item['is_validated'] ?? false;
          final ownerId = item['userId'] ?? item['user_id'];

          // Tampilkan jika Valid ATAU Punya Saya (meski belum valid)
          return isValid == true || (myId != null && ownerId == myId);
        }
        return false;
      }).toList();

      // 3. Parse GeoJSON
      final geoJson = jsonDecode(geoJsonString);
      List<List<LatLng>> lines = [];
      if (geoJson['features'] != null) {
        for (var feature in geoJson['features']) {
          if (feature['geometry']['type'] == 'LineString') {
            List coords = feature['geometry']['coordinates'];
            lines.add(coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList());
          }
        }
      }

      state = state.copyWith(
        faultLines: lines,
        allMarkers: displayMarkers,
        isLoading: false,
        currentUserId: myId,
      );
    } catch (e) {
      print("MapsViewModel Error: $e");
      state = state.copyWith(isLoading: false);
    }
  }
}

final mapsRepositoryProvider = Provider((ref) => MapsRepository());
final mapsViewModelProvider = StateNotifierProvider<MapsViewModel, MapsState>((ref) {
  return MapsViewModel(ref.read(mapsRepositoryProvider));
});