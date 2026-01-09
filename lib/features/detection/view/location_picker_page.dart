import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http; // [BARU] Untuk search

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/detection_viewmodel.dart';
import 'detection_page.dart';

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key});

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  bool _isMapReady = false;
  LatLng _center = const LatLng(-6.2088, 106.8456);
  LatLng? _myLocation;

  bool _isSatellite = false;
  bool _isLoadingLocation = true;
  List<Polyline> _faultLines = [];
  List<dynamic> _searchResults = []; // [BARU] Hasil pencarian

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // ... Logic Geolocator tetap sama ...
    // (Singkatnya: Ambil lokasi saat ini, set _center & _myLocation)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _isLoadingLocation = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false); return;
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _myLocation = LatLng(pos.latitude, pos.longitude);
          _center = _myLocation!;
          _isLoadingLocation = false;
        });
        if (_isMapReady) _mapController.move(_center, 16.0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadGeoJson() async {
    // ... Logic load polyline tetap sama ...
    try {
      final String data = await rootBundle.loadString('assets/patahan_aktif.geojson');
      final json = jsonDecode(data);
      final features = json['features'] as List;
      List<Polyline> lines = [];
      for (var feature in features) {
        if (feature['geometry']['type'] == 'LineString') {
          List<LatLng> points = [];
          for (var coord in feature['geometry']['coordinates']) points.add(LatLng(coord[1], coord[0]));
          lines.add(Polyline(points: points, color: Colors.red.withOpacity(0.6), strokeWidth: 4.0));
        }
      }
      setState(() => _faultLines = lines);
    } catch (_) {}
  }

  // [BARU] Fungsi Search Place Nominatim
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");
      final response = await http.get(url, headers: {'User-Agent': 'GeoValidApp'});

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Search error: $e");
    }
  }

  void _onSearchResultTap(dynamic place) {
    double lat = double.parse(place['lat']);
    double lon = double.parse(place['lon']);
    LatLng newLoc = LatLng(lat, lon);

    _mapController.move(newLoc, 16.0);
    setState(() {
      _center = newLoc;
      _searchResults = []; // Tutup list
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final detectionState = ref.watch(detectionViewModelProvider);
    final l10n = AppLocalizations.of(context)!;

    // Listener State
    ref.listen(detectionViewModelProvider, (prev, next) {
      if (next.result != null && !next.isLoading && next.error == null) {
        ref.read(detectionImageProvider.notifier).state = null;
        context.go('/detection-result');
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(l10n.selectLocation, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
        children: [
          // 1. PETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,
              onMapReady: () => _isMapReady = true,
              onPositionChanged: (pos, _) {
                if (pos.center != null) _center = pos.center!;
              },
              onTap: (_, __) {
                // Tutup search keyboard jika tap peta
                setState(() => _searchResults = []);
                FocusManager.instance.primaryFocus?.unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.geovalid',
              ),
              PolylineLayer(polylines: _faultLines),
              if (_myLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _myLocation!,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                  )
                ]),
            ],
          ),

          // 2. PIN TENGAH (Lokasi Terpilih)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35.0),
              child: Icon(Icons.location_on, size: 50, color: AppColors.primary),
            ),
          ),

          // 3. SEARCH BAR [BARU]
          Positioned(
            top: 16, left: 16, right: 70, // Sisakan ruang untuk tombol layer
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchLocation,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: _searchPlace,
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, i) {
                        final place = _searchResults[i];
                        return ListTile(
                          dense: true,
                          title: Text(place['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => _onSearchResultTap(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. TOGGLE SATELLITE
          Positioned(
            top: 16, right: 16,
            child: InkWell(
              onTap: () => setState(() => _isSatellite = !_isSatellite),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: Colors.grey[800], size: 24),
              ),
            ),
          ),

          // 5. TOMBOL AKSI
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                  child: Text(l10n.dragMap, style: GoogleFonts.poppins(fontSize: 12)),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: detectionState.isLoading
                        ? null
                        : () {
                      final imageFile = ref.read(detectionImageProvider);
                      if (imageFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noImage)));
                        context.pop();
                        return;
                      }
                      ref.read(detectionViewModelProvider.notifier).processDetection(
                        imageFile: imageFile,
                        latitude: _center.latitude,
                        longitude: _center.longitude,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: detectionState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.useThisLocation, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}