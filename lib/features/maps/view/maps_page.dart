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

// Helper Class untuk Optimasi
class FaultLineItem {
  final List<LatLng> points;
  final LatLngBounds bounds;
  FaultLineItem(this.points) : bounds = LatLngBounds.fromPoints(points);
}

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});
  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // State Map
  LatLng? _myLocation;
  List<dynamic> _searchResults = [];
  bool _isSatellite = false;
  bool _isMapReady = false;
  double _currentRotation = 0.0; // Untuk tombol kompas

  // Data Render (Optimasi)
  List<FaultLineItem> _allFaultItems = [];
  List<List<LatLng>> _visibleFaultLines = [];
  List<dynamic> _visibleMarkers = [];

  @override
  void initState() {
    super.initState();
    _initLocationAndMap();
  }

  // 1. Init Location
  Future<void> _initLocationAndMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) p = await Geolocator.requestPermission();

        if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition();
          if (mounted) {
            setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
            if (_isMapReady) _mapController.move(_myLocation!, 12.0);
          }
        }
      }
    } catch (_) {}
  }

  // 2. Pre-process Data
  void _processData(List<List<LatLng>> rawLines) {
    if (_allFaultItems.isNotEmpty) return;
    _allFaultItems = rawLines.map((points) => FaultLineItem(points)).toList();
    if (_isMapReady) _updateVisibleItems();
  }

  // 3. Logic Filter Render
  void _updateVisibleItems() {
    if (!_isMapReady) return;
    final bounds = _mapController.camera.visibleBounds;
    final mapState = ref.read(mapsViewModelProvider);

    // Filter Garis Sesar (Patahan)
    final visibleLines = _allFaultItems.where((item) {
      return bounds.south <= item.bounds.north &&
          bounds.north >= item.bounds.south &&
          bounds.west <= item.bounds.east &&
          bounds.east >= item.bounds.west;
    }).map((e) => e.points).toList();

    // Filter Marker
    final visibleMarks = mapState.allMarkers.where((data) {
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat == null || lng == null) return false;

      final mLat = (lat is num) ? lat.toDouble() : double.tryParse(lat.toString()) ?? 0;
      final mLng = (lng is num) ? lng.toDouble() : double.tryParse(lng.toString()) ?? 0;

      return bounds.contains(LatLng(mLat, mLng));
    }).toList();

    setState(() {
      _visibleFaultLines = visibleLines;
      _visibleMarkers = visibleMarks;
    });
  }

  // 4. Search (Nama Tempat & Koordinat)
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _searchResults = []);

    // A. Cek Koordinat (Regex: -7.123, 110.123)
    final coordRegex = RegExp(r'^([-+]?\d{1,2}(\.\d+)?)[,\s]+([-+]?\d{1,3}(\.\d+)?)$');
    final match = coordRegex.firstMatch(query.trim());

    if (match != null) {
      try {
        final lat = double.parse(match.group(1)!);
        final lng = double.parse(match.group(3)!);
        _moveToLocation(LatLng(lat, lng));
        return;
      } catch (_) {}
    }

    // B. Nominatim API
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");
      final response = await http.get(url, headers: {'User-Agent': 'GeoValidApp'});
      if (response.statusCode == 200) {
        setState(() => _searchResults = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  void _moveToLocation(LatLng target) {
    _mapController.move(target, 15.0);
    _searchController.clear();
    setState(() => _searchResults = []);

    // Tunggu animasi map selesai baru update item visible
    Future.delayed(const Duration(milliseconds: 500), _updateVisibleItems);
  }

  Color _getMarkerColor(dynamic data, String? myId) {
    final ownerId = data['userId'] ?? data['user_id'];
    final isValid = data['isValidated'] ?? data['is_validated'] ?? false;

    if (myId != null && ownerId == myId && !isValid) return Colors.blue;

    final s = (data['statusLevel'] ?? data['status_level'] ?? "").toString().toUpperCase();
    if (s.contains("BAHAYA") || s.contains("AWAS")) return Colors.red;
    if (s.contains("WASPADA") || s.contains("PERINGATAN")) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapsViewModelProvider);
    final l10n = AppLocalizations.of(context)!;

    if (mapState.faultLines.isNotEmpty && _allFaultItems.isEmpty) {
      _processData(mapState.faultLines);
    }

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
            options: MapOptions(
              initialCenter: _myLocation ?? const LatLng(-2.5489, 118.0149),
              initialZoom: _myLocation != null ? 12.0 : 5.0,

              // Interaksi Rotasi Aktif
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),

              onMapReady: () {
                _isMapReady = true;
                if (_myLocation != null) _mapController.move(_myLocation!, 12.0);
                _updateVisibleItems();
              },

              // Update saat berhenti geser/putar
              onMapEvent: (evt) {
                if (evt is MapEventMoveEnd || evt is MapEventRotateEnd || evt is MapEventFlingAnimationEnd) {
                  setState(() => _currentRotation = _mapController.camera.rotation);
                  _updateVisibleItems();
                }
              },

              onTap: (_, __) {
                setState(() { _searchResults = []; FocusManager.instance.primaryFocus?.unfocus(); });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.geovalid',
              ),

              // Garis Patahan
              PolylineLayer(
                polylines: _visibleFaultLines.map((points) =>
                    Polyline(points: points, color: Colors.red.withOpacity(0.5), strokeWidth: 3.0)
                ).toList(),
              ),

              // Marker
              MarkerLayer(
                markers: _visibleMarkers.map((data) {
                  final lat = data['latitude'];
                  final lng = data['longitude'];
                  final mLat = (lat is num) ? lat.toDouble() : double.parse(lat.toString());
                  final mLng = (lng is num) ? lng.toDouble() : double.parse(lng.toString());

                  return Marker(
                    point: LatLng(mLat, mLng),
                    width: 40, height: 40,
                    child: GestureDetector(
                      onTap: () => _showDetailSheet(context, data, mapState.currentUserId, l10n),
                      child: Icon(Icons.location_on, color: _getMarkerColor(data, mapState.currentUserId), size: 40),
                    ),
                  );
                }).toList(),
              ),

              // Lokasi Saya
              if (_myLocation != null)
                MarkerLayer(markers: [
                  Marker(point: _myLocation!, width: 20, height: 20,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    ),
                  ),
                ]),
            ],
          ),

          if (mapState.isLoading) const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // --- SEARCH BAR & TOGGLE ---
          Positioned(
            top: 16, left: 16, right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.searchPlace, // "Cari lokasi / koordinat..."
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (val) {
                        _searchPlace(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _isSatellite = !_isSatellite),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _isSatellite ? Colors.blue.shade50 : Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)], border: _isSatellite ? Border.all(color: Colors.blue) : null),
                    child: Icon(_isSatellite ? Icons.map : Icons.satellite_alt, color: _isSatellite ? Colors.blue : Colors.grey[800], size: 24),
                  ),
                ),
              ],
            ),
          ),

          if (_searchResults.isNotEmpty)
            Positioned(
              top: 70, left: 16, right: 70,
              child: Container(
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
                      onTap: () {
                        final lat = double.parse(place['lat']);
                        final lon = double.parse(place['lon']);
                        _moveToLocation(LatLng(lat, lon));
                      },
                    );
                  },
                ),
              ),
            ),

          // --- FLOATING ACTION BUTTONS (Reset Rotation & My Location) ---
          Positioned(
            top: 80, right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol RESET ROTATION (Hanya muncul jika peta miring)
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

                // Tombol MY LOCATION
                InkWell(
                  onTap: () {
                    if (_myLocation != null) {
                      _mapController.move(_myLocation!, 15.0);
                      _updateVisibleItems();
                    } else {
                      _initLocationAndMap();
                    }
                  },
                  child: Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: Icon(Icons.my_location, color: _myLocation != null ? AppColors.primary : Colors.grey, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DETAIL SHEET (SAMA SEPERTI SEBELUMNYA) ---
  void _showDetailSheet(BuildContext context, dynamic data, String? myId, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetectionDetailSheet(data: data, myId: myId, l10n: l10n),
    );
  }
}

// --- WIDGET DETAIL SHEET ---
// (Tidak ada perubahan di widget detail, tetap gunakan yang sudah ada)
enum ImageMode { original, overlay, mask }

class _DetectionDetailSheet extends StatefulWidget {
  final dynamic data;
  final String? myId;
  final AppLocalizations l10n;

  const _DetectionDetailSheet({required this.data, required this.myId, required this.l10n});

  @override
  State<_DetectionDetailSheet> createState() => _DetectionDetailSheetState();
}

class _DetectionDetailSheetState extends State<_DetectionDetailSheet> {
  ImageMode _selectedMode = ImageMode.overlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.data;
    final ownerId = data['userId'] ?? data['user_id'];
    final isValid = data['isValidated'] ?? data['is_validated'] ?? false;
    final isMine = widget.myId != null && ownerId == widget.myId;

    String description = "";
    try {
      final descRaw = data['description'];
      if (descRaw != null && descRaw.toString().trim().startsWith('{')) {
        final parsed = jsonDecode(descRaw);
        description = parsed['visual_description'] ?? parsed['visual_statement'] ?? "";
      } else {
        description = descRaw ?? widget.l10n.noDescription;
      }
    } catch (_) { description = widget.l10n.noDescription; }

    final originalUrl = data['originalImageUrl'] ?? data['original_image_url'];
    final overlayUrl = data['overlayImageUrl'] ?? data['overlay_image_url'];
    final maskUrl = data['maskImageUrl'] ?? data['mask_image_url'];

    String? currentUrl;
    if (_selectedMode == ImageMode.original) currentUrl = originalUrl;
    if (_selectedMode == ImageMode.overlay) currentUrl = overlayUrl;
    if (_selectedMode == ImageMode.mask) currentUrl = maskUrl;
    if (currentUrl == null || currentUrl.isEmpty) currentUrl = originalUrl;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.l10n.detectionDetail, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isMine && !isValid)
                  _buildBadge("MILIK ANDA", Colors.blue)
                else if (isValid)
                  _buildBadge(widget.l10n.verified, Colors.green)
                else
                  _buildBadge("BELUM VALID", Colors.grey),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Image Switcher
                Container(
                  decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            _buildTab(ImageMode.original, "Asli"),
                            const SizedBox(width: 4),
                            _buildTab(ImageMode.overlay, "Overlay"),
                            const SizedBox(width: 4),
                            _buildTab(ImageMode.mask, "Masker"),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showZoomImage(context, currentUrl!),
                        child: Container(
                          height: 220, width: double.infinity, color: Colors.black,
                          child: Stack(
                            children: [
                              Center(child: Image.network(currentUrl ?? "", fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey), loadingBuilder: (_,child,prog) => prog == null ? child : const Center(child: CircularProgressIndicator(color: AppColors.primary)))),
                              const Positioned(bottom: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black54, radius: 14, child: Icon(Icons.zoom_out_map, color: Colors.white, size: 16)))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildInfoRow(Icons.warning_amber_rounded, widget.l10n.status, (data['statusLevel'] ?? "-").toString().toUpperCase()),
                _buildInfoRow(Icons.analytics_outlined, widget.l10n.type, data['faultType'] ?? "-"),
                const SizedBox(height: 10), const Divider(), const SizedBox(height: 10),
                Text(widget.l10n.aiAnalysis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(description, style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Colors.grey[600]), textAlign: TextAlign.justify),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(ImageMode mode, String label) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)), child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold)));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children: [Icon(icon, size: 20, color: Colors.grey), const SizedBox(width: 8), Text(label, style: GoogleFonts.poppins(color: Colors.grey)), const SizedBox(width: 8), Expanded(child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)))]));
  }

  void _showZoomImage(BuildContext context, String url) {
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero, child: Stack(children: [InteractiveViewer(maxScale: 5.0, child: Center(child: Image.network(url, fit: BoxFit.contain))), Positioned(top: 40, right: 20, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 30), style: IconButton.styleFrom(backgroundColor: Colors.black54)))])));
  }
}