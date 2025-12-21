import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';
import '../data/maps_repository.dart';

class MapsState {
  final List<List<LatLng>> faultLines;
  final List<dynamic> historyMarkers;
  final bool isLoading;

  MapsState({
    this.faultLines = const [],
    this.historyMarkers = const [],
    this.isLoading = true,
  });

  MapsState copyWith({List<List<LatLng>>? faultLines, List<dynamic>? historyMarkers, bool? isLoading}) {
    return MapsState(
      faultLines: faultLines ?? this.faultLines,
      historyMarkers: historyMarkers ?? this.historyMarkers,
      isLoading: isLoading ?? this.isLoading,
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
      final results = await Future.wait([
        rootBundle.loadString('assets/patahan_aktif.geojson'),
        _repo.getDetectionHistory(),
      ]);

      final geoJsonString = results[0] as String;
      final rawHistoryData = results[1] as List<dynamic>;

      print("🔍 TOTAL DATA DARI API: ${rawHistoryData.length}");
      if (rawHistoryData.isNotEmpty) {
        print("🔍 CONTOH DATA PERTAMA: ${rawHistoryData.first}");
      }

      final validatedHistory = rawHistoryData.where((item) {
        if (item is Map<String, dynamic>) {
          final isValid = item['isValidated'] ?? item['is_validated'];

          return isValid == true;
        }
        return false;
      }).toList();

      print("✅ DATA TERVALIDASI YANG AKAN DITAMPILKAN: ${validatedHistory.length}");

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
        historyMarkers: validatedHistory,
        isLoading: false,
      );
    } catch (e) {
      print("❌ MapsViewModel Error: $e");
      state = state.copyWith(isLoading: false);
    }
  }
}

final mapsRepositoryProvider = Provider<MapsRepository>((ref) => MapsRepository());

final mapsViewModelProvider = StateNotifierProvider<MapsViewModel, MapsState>((ref) {
  final repo = ref.read(mapsRepositoryProvider);
  return MapsViewModel(repo);
});