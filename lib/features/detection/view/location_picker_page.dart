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

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({super.key});

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  final MapController _mapController = MapController();

  LatLng _center = const LatLng(-6.9175, 107.6191); // Default Bandung

  LatLng? _myLocation;
  StreamSubscription<Position>? _positionStream;

  bool _isSatellite = false;
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
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _myLocation = LatLng(position.latitude, position.longitude);
      _center = _myLocation!;
    });

    _mapController.move(_center, 15.0);

    _positionStream = Geolocator.getPositionStream().listen((Position pos) {
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
      });
    });
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
            color: Colors.red.withOpacity(0.7),
            strokeWidth: 3.0,
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
        context.go('/result');
      }
      if (next.error != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Pilih Lokasi Sesar", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFFD46E46),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
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
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                            )
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
              padding: EdgeInsets.only(bottom: 40.0),
              child: Icon(Icons.location_on, size: 50, color: Color(0xFFD46E46)),
            ),
          ),

          Positioned(
            top: 16, right: 16,
            child: InkWell(
              onTap: () => setState(() => _isSatellite = !_isSatellite),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                ),
                child: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: Colors.grey[800]),
              ),
            ),
          ),

          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_myLocation != null) {
                  _mapController.move(_myLocation!, 15);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Mencari lokasi GPS...")),
                  );
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
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFD46E46), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Geser peta agar marker merah tepat berada di lokasi temuan.",
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: detectionState.isLoading
                        ? null
                        : () {
                      ref.read(detectionViewModelProvider.notifier)
                          .setLocation(_center.latitude, _center.longitude);

                      ref.read(detectionViewModelProvider.notifier).runAnalysis();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD46E46),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: detectionState.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Konfirmasi & Analisis", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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