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
import '../viewmodel/detection_viewmodel.dart';
import 'detection_page.dart';

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key});

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final MapController _mapController = MapController();

  bool _isMapReady = false;

  LatLng _center = const LatLng(-6.2088, 106.8456);

  LatLng? _myLocation;
  StreamSubscription<Position>? _positionStream;

  bool _isSatellite = false;
  bool _isLoadingLocation = true;
  List<Polyline> _faultLines = [];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (mounted) {
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
          _center = _myLocation!;
          _isLoadingLocation = false;
        });

        if (_isMapReady) {
          _mapController.move(_center, 16.0);
        }
      }

      _positionStream = Geolocator.getPositionStream().listen((Position pos) {
        if (mounted) {
          setState(() {
            _myLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadGeoJson() async {
    try {
      final String data = await rootBundle.loadString('assets/patahan_aktif.geojson');
      final json = jsonDecode(data);
      final features = json['features'] as List;

      List<Polyline> lines = [];
      for (var feature in features) {
        final geometry = feature['geometry'];
        if (geometry['type'] == 'LineString') {
          List<LatLng> points = [];
          for (var coord in geometry['coordinates']) {
            points.add(LatLng(coord[1], coord[0]));
          }
          lines.add(Polyline(
            points: points,
            color: Colors.red.withOpacity(0.6),
            strokeWidth: 4.0,
          ));
        }
      }
      setState(() {
        _faultLines = lines;
      });
    } catch (e) {
      debugPrint("Error loading GeoJSON: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final detectionState = ref.watch(detectionViewModelProvider);

    ref.listen(detectionViewModelProvider, (previous, next) {
      if (next.result != null && !next.isLoading && next.error == null) {
        ref.read(detectionImageProvider.notifier).state = null;
        context.go('/detection-result');
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Pilih Lokasi", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFFD46E46),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingLocation
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD46E46)),
            SizedBox(height: 16),
            Text("Mencari lokasi GPS...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,

              onMapReady: () {
                _isMapReady = true;
                if (_myLocation != null) {
                  _mapController.move(_myLocation!, 16.0);
                }
              },

              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _center = position.center!;
                }
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
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35.0),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Color(0xFFD46E46),
              ),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.circle, size: 6, color: Colors.black54),
            ),
          ),

          Positioned(
            top: 16, right: 16,
            child: InkWell(
              onTap: () => setState(() => _isSatellite = !_isSatellite),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                ),
                child: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: Colors.grey[800], size: 24),
              ),
            ),
          ),

          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              mini: false,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_myLocation != null) {
                  _mapController.move(_myLocation!, 16);
                  setState(() => _center = _myLocation!);
                } else {
                  setState(() => _isLoadingLocation = true);
                  _initLocation();
                }
              },
              child: const Icon(Icons.my_location, color: Color(0xFFD46E46)),
            ),
          ),

          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: Color(0xFFD46E46), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Geser peta untuk menyesuaikan lokasi",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Gambar hilang. Silakan foto ulang."))
                        );
                        context.pop();
                        return;
                      }

                      ref.read(detectionViewModelProvider.notifier).processDetection(
                        imageFile: imageFile,
                        latitude: _center.latitude,
                        longitude: _center.longitude,
                        address: "",
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD46E46),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: detectionState.isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Text("Gunakan Lokasi Ini", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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