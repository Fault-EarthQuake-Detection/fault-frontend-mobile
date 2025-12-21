import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodel/maps_viewmodel.dart';
import '../../sidebar/view/sidebar_drawer.dart';
import 'dart:convert';

class MapsPage extends ConsumerStatefulWidget {
  const MapsPage({super.key});
  @override
  ConsumerState<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends ConsumerState<MapsPage> {
  final MapController _mapController = MapController();

  Future<void> _moveToMyLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    final pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
  }

  Color _getStatusColor(String? status) {
    final s = (status ?? "").toUpperCase();
    if (s.contains("BAHAYA") || s.contains("AWAS")) return Colors.red;
    if (s.contains("WASPADA") || s.contains("PERINGATAN")) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapsViewModelProvider);

    return Scaffold(
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        title: Text("Peta Persebaran", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFFD46E46),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: LatLng(-2.5489, 118.0149), initialZoom: 5.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              PolylineLayer(
                polylines: mapState.faultLines.map((points) =>
                    Polyline(points: points, color: Colors.red.withOpacity(0.5), strokeWidth: 3.0)
                ).toList(),
              ),
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
                      onTap: () => _showDetail(context, data),
                      child: Icon(Icons.location_on, color: _getStatusColor(data['status_level']), size: 40),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (mapState.isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(bottom: 30, right: 20, child: FloatingActionButton(heroTag: 'gps', onPressed: _moveToMyLocation, backgroundColor: Colors.white, child: const Icon(Icons.my_location, color: Color(0xFFD46E46)))),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, dynamic data) {
    String rawDesc = data['description'] ?? "";
    String displayDesc = "Tidak ada deskripsi.";

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
    } catch (e) {
      displayDesc = rawDesc;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Detail Deteksi", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text("Terverifikasi", style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
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
                    errorBuilder: (_,__,___) => Container(
                      height: 200, width: double.infinity, color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInfoRow(Icons.warning_amber_rounded, "Status:",
                    (data['statusLevel'] ?? "-").toString().toUpperCase(),
                    color: _getStatusColor(data['statusLevel'])
                ),

                _buildInfoRow(Icons.analytics_outlined, "Jenis:", data['faultType'] ?? "-"),

                if (data['validatedAt'] != null)
                  _buildInfoRow(Icons.verified_user_outlined, "Divalidasi:",
                      data['validatedAt'].toString().substring(0, 10)
                  ),

                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),

                Text("Analisis AI:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Text(
                    displayDesc,
                    style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Colors.grey[800]),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
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
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}