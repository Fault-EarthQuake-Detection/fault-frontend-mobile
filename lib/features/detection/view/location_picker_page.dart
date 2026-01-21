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
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/detection_viewmodel.dart';
import 'detection_page.dart';

// [HELPER CLASS] Untuk menyimpan Polyline beserta batas areanya (Caching)
class FaultItem {
  final Polyline polyline;
  final LatLngBounds bounds;
  FaultItem(this.polyline, this.bounds);
}

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key});

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // State Map
  bool _isMapReady = false;
  bool _isDragging = false;
  double _currentRotation = 0.0;

  // Data Lokasi
  LatLng _center = const LatLng(-6.2088, 106.8456);
  LatLng? _myLocation;

  // Layer & Data
  bool _isSatellite = false;
  bool _isLoadingLocation = true;

  // [OPTIMASI] Gunakan FaultItem
  List<FaultItem> _allFaultItems = [];
  List<Polyline> _visibleFaultLines = [];

  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
    _initLocation();
  }

  // --- 1. LOGIC LOKASI & GPS ---
  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
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
        if (_isMapReady) {
          _mapController.move(_center, 15.0);
          _updateVisibleFaults();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // --- 2. OPTIMASI GEOJSON ---
  Future<void> _loadGeoJson() async {
    try {
      final String data = await rootBundle.loadString('assets/patahan_aktif.geojson');
      final json = jsonDecode(data);
      final features = json['features'] as List;
      List<FaultItem> items = [];

      for (var feature in features) {
        if (feature['geometry']['type'] == 'LineString') {
          List<LatLng> points = [];
          for (var coord in feature['geometry']['coordinates']) {
            points.add(LatLng(coord[1], coord[0]));
          }

          if (points.isEmpty) continue;

          // Buat Polyline
          final polyline = Polyline(
            points: points,
            color: Colors.red.withOpacity(0.6),
            strokeWidth: 4.0,
          );

          // Hitung Bounds Manual (Agar 100% Akurat)
          final bounds = LatLngBounds.fromPoints(points);

          items.add(FaultItem(polyline, bounds));
        }
      }

      _allFaultItems = items;

      // Jika map belum siap, tampilkan semua dulu (biar gak blank)
      // Nanti onMapReady akan memfilter ulang
      setState(() {
        _visibleFaultLines = items.map((e) => e.polyline).toList();
      });

    } catch (_) {}
  }

  void _updateVisibleFaults() {
    if (!_isMapReady || _allFaultItems.isEmpty) return;

    // Ambil batas layar saat ini
    final mapBounds = _mapController.camera.visibleBounds;

    // Filter Logic: Cek persinggungan kotak
    final filtered = _allFaultItems.where((item) {
      final itemBounds = item.bounds;

      // Rumus AABB (Axis-Aligned Bounding Box) Intersection
      // Apakah kotak A (Layar) bersinggungan dengan kotak B (Garis)?
      bool isOverlapping =
          mapBounds.south <= itemBounds.north &&
              mapBounds.north >= itemBounds.south &&
              mapBounds.west <= itemBounds.east &&
              mapBounds.east >= itemBounds.west;

      return isOverlapping;
    }).map((e) => e.polyline).toList();

    setState(() {
      _visibleFaultLines = filtered;
    });
  }

  // --- 3. SEARCH ---
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _searchResults = []);

    final coordRegex = RegExp(r'^([-+]?\d{1,2}(\.\d+)?)[,\s]+([-+]?\d{1,3}(\.\d+)?)$');
    final match = coordRegex.firstMatch(query.trim());

    if (match != null) {
      try {
        final lat = double.parse(match.group(1)!);
        final lng = double.parse(match.group(3)!);
        final newLoc = LatLng(lat, lng);
        _mapController.move(newLoc, 16.0);
        setState(() => _center = newLoc);

        // Tunggu sebentar agar map settle baru filter
        Future.delayed(const Duration(milliseconds: 300), _updateVisibleFaults);
        return;
      } catch (_) {}
    }

    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");
      final response = await http.get(url, headers: {'User-Agent': 'GeoValidApp'});

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  void _onSearchResultTap(dynamic place) {
    double lat = double.parse(place['lat']);
    double lon = double.parse(place['lon']);
    LatLng newLoc = LatLng(lat, lon);

    _mapController.move(newLoc, 16.0);
    setState(() {
      _center = newLoc;
      _searchResults = [];
      _searchController.clear();
    });
    Future.delayed(const Duration(milliseconds: 300), _updateVisibleFaults);
  }

  @override
  Widget build(BuildContext context) {
    final detectionState = ref.watch(detectionViewModelProvider);
    final l10n = AppLocalizations.of(context)!;

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
      body: Stack(
        children: [
          // 1. PETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              // [UX MAPS] Default interaction itu smooth.
              // Jika ingin rotasi lebih 'berat', tidak ada setting sensitivitas langsung,
              // tapi InteractiveFlag.all sudah settingan paling balanced.
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),

              onMapReady: () {
                _isMapReady = true;
                _updateVisibleFaults();
              },

              onMapEvent: (evt) {
                // Deteksi User Interaction
                if (evt is MapEventMoveStart || evt is MapEventRotateStart) {
                  setState(() => _isDragging = true);
                }
                else if (evt is MapEventMoveEnd || evt is MapEventRotateEnd || evt is MapEventFlingAnimationEnd) {
                  setState(() {
                    _isDragging = false;
                    _currentRotation = _mapController.camera.rotation;
                  });
                  // Trigger filter saat user berhenti interaksi
                  _updateVisibleFaults();
                }
              },

              onPositionChanged: (pos, hasGesture) {
                if (pos.center != null) _center = pos.center!;
              },
              onTap: (_, __) {
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
              PolylineLayer(polylines: _visibleFaultLines),

              if (_myLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _myLocation!,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.my_location, color: Colors.blue, size: 20)),
                    ),
                  )
                ]),
            ],
          ),

          // 2. PIN TENGAH (Static)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35.0),
              child: Icon(Icons.location_on, size: 50, color: AppColors.primary),
            ),
          ),

          // 3. SEARCH BAR & SATELLITE
          Positioned(
            top: 16, left: 16, right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]),
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
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _isSatellite = !_isSatellite),
                      child: Container(
                        height: 50, width: 50,
                        decoration: BoxDecoration(color: _isSatellite ? Colors.blue.shade50 : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))], border: _isSatellite ? Border.all(color: Colors.blue) : null),
                        child: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: _isSatellite ? Colors.blue : Colors.grey[800], size: 24),
                      ),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, i) {
                        final place = _searchResults[i];
                        return ListTile(
                          dense: true,
                          title: Text(place['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13)),
                          leading: const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                          onTap: () => _onSearchResultTap(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. FLOATING ACTION BUTTONS (Reset Rotation & My Location)
          Positioned(
            top: 80, right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Reset Rotation
                if (_currentRotation != 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        _mapController.rotate(0);
                        setState(() => _currentRotation = 0);
                      },
                      child: Container(
                        height: 40, width: 40,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: Transform.rotate(
                          angle: -_currentRotation * (3.14159 / 180),
                          child: const Icon(Icons.navigation, color: Colors.red, size: 20),
                        ),
                      ),
                    ),
                  ),

                // Tombol Lokasi Saya
                InkWell(
                  onTap: () {
                    if (_myLocation != null) {
                      _mapController.move(_myLocation!, 16.0);
                      setState(() => _center = _myLocation!);
                      _updateVisibleFaults();
                    } else {
                      _initLocation();
                    }
                  },
                  child: Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: _isLoadingLocation
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : Icon(Icons.my_location, color: _myLocation != null ? Colors.blue : Colors.grey, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // 5. TEKS PETUNJUK (DINAMIS)
          Positioned(
            bottom: 100, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _isDragging ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Text(l10n.dragMap, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),

          // 6. TOMBOL AKSI UTAMA
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: SizedBox(
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

                  ref.read(detectionViewModelProvider.notifier).analyzeOnly(
                    imageFile: imageFile,
                    latitude: _center.latitude,
                    longitude: _center.longitude,
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.4)
                ),
                child: detectionState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.useThisLocation, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}