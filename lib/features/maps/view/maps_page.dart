import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/maps_viewmodel.dart';
import '../../sidebar/view/sidebar_drawer.dart';

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});
  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _myLocation;
  StreamSubscription<Position>? _positionStream;
  List<dynamic> _searchResults = [];

  // [BARU] State untuk Mode Satelit
  bool _isSatellite = false;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // 1. Inisialisasi Lokasi Realtime
  Future<void> _initLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}

    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position pos) {
      if (mounted) {
        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  // 2. Fungsi Search
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");
      final response = await http.get(url, headers: {'User-Agent': 'GeoValidApp'});

      if (response.statusCode == 200) {
        setState(() => _searchResults = jsonDecode(response.body));
      }
    } catch (e) {
      print("Search Error: $e");
    }
  }

  void _onSearchResultTap(dynamic place) {
    double lat = double.parse(place['lat']);
    double lon = double.parse(place['lon']);
    LatLng target = LatLng(lat, lon);

    _mapController.move(target, 15.0);

    setState(() {
      _searchResults = [];
      _searchController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Color _getStatusColor(String? status) {
    final s = (status ?? "").toUpperCase();
    if (s.contains("BAHAYA") || s.contains("AWAS") || s.contains("DANGER")) return Colors.red;
    if (s.contains("WASPADA") || s.contains("PERINGATAN") || s.contains("WARNING")) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapsViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const SidebarDrawer(),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(l10n.mapDistribution, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // --- PETA ---
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-2.5489, 118.0149), // Center Indonesia
              initialZoom: 5.0,
              onTap: null,
            ),
            children: [
              // [UPDATE] Tile Layer Dinamis (Satelit vs Jalan)
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}' // Satelit
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Jalan Biasa
                userAgentPackageName: 'com.example.geovalid',
              ),

              // Garis Patahan (GeoJSON)
              PolylineLayer(
                polylines: mapState.faultLines.map((points) =>
                    Polyline(points: points, color: Colors.red.withOpacity(0.5), strokeWidth: 3.0)
                ).toList(),
              ),

              // Marker Riwayat Deteksi
              MarkerLayer(
                markers: mapState.historyMarkers.map((data) {
                  final lat = data['latitude'];
                  final lng = data['longitude'];
                  if (lat == null || lng == null) return const Marker(point: LatLng(0,0), child: SizedBox());

                  return Marker(
                    point: LatLng(lat is double ? lat : double.parse(lat.toString()),
                        lng is double ? lng : double.parse(lng.toString())),
                    width: 40, height: 40,
                    child: GestureDetector(
                      onTap: () => _showDetail(context, data, l10n, theme),
                      child: Icon(Icons.location_on, color: _getStatusColor(data['status_level']), size: 40),
                    ),
                  );
                }).toList(),
              ),

              // Marker Lokasi Saya (Blue Dot)
              if (_myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myLocation!,
                      width: 20, height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (mapState.isLoading) const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // --- SEARCH BAR ---
          Positioned(
            top: 16, left: 16, right: 70, // Beri jarak kanan untuk tombol layer
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchPlace,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (val) {
                      _searchPlace(val);
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
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

          // --- [BARU] TOMBOL GANTI LAYER (SATELIT/MAP) ---
          Positioned(
            top: 16, right: 16,
            child: InkWell(
              onTap: () => setState(() => _isSatellite = !_isSatellite),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                ),
                // Icon berubah (Map vs Satellite)
                child: Icon(
                    _isSatellite ? Icons.map : Icons.satellite_alt,
                    color: Colors.grey[800],
                    size: 24
                ),
              ),
            ),
          ),

          // --- TOMBOL MY LOCATION ---
          Positioned(
            bottom: 30, right: 20,
            child: FloatingActionButton(
                heroTag: 'gps',
                onPressed: () {
                  if (_myLocation != null) _mapController.move(_myLocation!, 15.0);
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: AppColors.primary)
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET DETAIL (Sama seperti sebelumnya) ---
  void _showDetail(BuildContext context, dynamic data, AppLocalizations l10n, ThemeData theme) {
    String rawDesc = data['description'] ?? "";
    String displayDesc = l10n.noDescription;

    try {
      if (rawDesc.isNotEmpty) {
        if (rawDesc.trim().startsWith('{')) {
          final parsed = jsonDecode(rawDesc);
          displayDesc = parsed['visual_description'] ??
              parsed['deskripsi_singkat'] ??
              parsed['visual_statement'] ??
              rawDesc;
        } else {
          displayDesc = rawDesc;
        }
      }
    } catch (_) {
      displayDesc = rawDesc;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 10),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.detectionDetail, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(l10n.verified, style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    data['originalImageUrl'] ?? data['original_image_url'] ?? '',
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(height: 200, width: double.infinity, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInfoRow(Icons.warning_amber_rounded, l10n.status, (data['statusLevel'] ?? "-").toString().toUpperCase(), theme, color: _getStatusColor(data['statusLevel'])),
                _buildInfoRow(Icons.analytics_outlined, l10n.type, data['faultType'] ?? "-", theme),
                if (data['validatedAt'] != null)
                  _buildInfoRow(Icons.verified_user_outlined, l10n.validatedAt, data['validatedAt'].toString().substring(0, 10), theme),

                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),

                Text(l10n.aiAnalysis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: Text(
                    displayDesc,
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: theme.textTheme.bodyMedium?.color),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color ?? theme.textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }
}