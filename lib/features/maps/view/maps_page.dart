// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
//
// import '../../detection/data/detection_model.dart';
// import '../../sidebar/view/sidebar_drawer.dart';
// import '../../auth/viewmodel/auth_viewmodel.dart';
// import '../viewmodel/maps_viewmodel.dart';
//
// class MapsPage extends ConsumerStatefulWidget {
//   const MapsPage({super.key});
//
//   @override
//   ConsumerState<MapsPage> createState() => _MapsPageState();
// }
//
// class _MapsPageState extends ConsumerState<MapsPage> {
//   final MapController _mapController = MapController();
//
//   LatLng _center = const LatLng(-6.9175, 107.6191);
//   bool _isSatellite = false;
//   List<Polyline> _faultLines = [];
//
//   LatLng? _myLocation;
//   StreamSubscription<Position>? _positionStream;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadGeoJson();
//     _initLocation();
//
//     Future.microtask(() => ref.read(mapsControllerProvider.notifier).fetchDetections());
//   }
//
//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _loadGeoJson() async {
//     try {
//       final String data = await rootBundle.loadString('assets/patahan_aktif.geojson');
//       final json = jsonDecode(data);
//       final features = json['features'] as List;
//
//       List<Polyline> lines = [];
//       for (var feature in features) {
//         final geometry = feature['geometry'];
//         if (geometry['type'] == 'LineString') {
//           List<LatLng> points = [];
//           for (var coord in geometry['coordinates']) {
//             points.add(LatLng(coord[1], coord[0]));
//           }
//           lines.add(Polyline(
//             points: points,
//             color: Colors.red.withOpacity(0.6),
//             strokeWidth: 2.0,
//           ));
//         }
//       }
//       setState(() {
//         _faultLines = lines;
//       });
//     } catch (e) {
//       debugPrint("Error GeoJSON: $e");
//     }
//   }
//
//   Future<void> _initLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return;
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return;
//     }
//
//     Position position = await Geolocator.getCurrentPosition();
//     if(mounted) {
//       setState(() {
//         _myLocation = LatLng(position.latitude, position.longitude);
//         _center = _myLocation!;
//       });
//       _mapController.move(_center, 12.0);
//     }
//
//     // Listen
//     _positionStream = Geolocator.getPositionStream().listen((Position pos) {
//       if(mounted) {
//         setState(() {
//           _myLocation = LatLng(pos.latitude, pos.longitude);
//         });
//       }
//     });
//   }
//
//   void _showDetectionDetail(BuildContext context, DetectionModel data) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Container(
//                   width: 40, height: 4,
//                   decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   height: 180,
//                   width: double.infinity,
//                   color: Colors.grey[100],
//                   child: Image.network(
//                     data.imageUrl,
//                     fit: BoxFit.cover,
//                     errorBuilder: (ctx, _, __) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       data.result,
//                       style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3E2723)),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     DateFormat('dd MMM yyyy').format(data.createdAt),
//                     style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//
//               Row(
//                 children: [
//                   const CircleAvatar(
//                     radius: 12,
//                     backgroundColor: Color(0xFFD46E46),
//                     child: Icon(Icons.person, size: 14, color: Colors.white),
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     "Dideteksi oleh User #${data.userId.substring(0, 5)}", // Tampilkan sebagian ID untuk privasi jika nama tidak ada
//                     style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFD46E46),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text("Tutup"),
//                 ),
//               )
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // 1. Ambil Data User (untuk AppBar)
//     final userAsync = ref.watch(currentUserProvider);
//     String displayName = "";
//     String? photoUrl;
//     userAsync.whenData((userData) {
//       // userData adalah Map<String, dynamic>?
//       if (userData != null) {
//         final email = userData['email'] ?? "No Email";
//
//         // Ambil metadata dari Map
//         final metadata = userData['user_metadata'] as Map<String, dynamic>?;
//
//         if (metadata != null) {
//           displayName = metadata['full_name'] ?? metadata['name'] ?? email.split('@')[0];
//           photoUrl = metadata['avatar_url'] ?? metadata['picture'];
//         } else {
//           displayName = email.split('@')[0];
//         }
//       }
//     });
//
//     final markersAsync = ref.watch(mapsControllerProvider);
//
//     return Scaffold(
//       drawer: const SidebarDrawer(),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFD46E46),
//         elevation: 0,
//         leading: Builder(builder: (context) => IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () => Scaffold.of(context).openDrawer(),
//         )),
//         title: SizedBox(height: 40, child: Image.asset('assets/Logo.png', fit: BoxFit.contain)),
//         centerTitle: true,
//         actions: [
//           Row(
//             children: [
//               if (displayName.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: Text(
//                     displayName.length > 10 ? '${displayName.substring(0, 10)}...' : displayName,
//                     style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
//                   ),
//                 ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 16.0),
//                 child: Container(
//                   decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
//                   child: CircleAvatar(
//                     backgroundColor: Colors.grey.shade300,
//                     radius: 16,
//                     backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
//                     child: (photoUrl == null) ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: _center,
//               initialZoom: 13.0,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: _isSatellite
//                     ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
//                     : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.example.geovalid',
//               ),
//
//               PolylineLayer(polylines: _faultLines),
//
//               markersAsync.when(
//                 data: (detections) => MarkerLayer(
//                   markers: detections.map((data) => Marker(
//                     point: LatLng(data.lat, data.lng),
//                     width: 40,
//                     height: 40,
//                     child: GestureDetector(
//                       onTap: () => _showDetectionDetail(context, data),
//                       child: Image.asset('assets/icons/detection.png', color: Colors.red), // Atau Icon custom
//                     ),
//                   )).toList(),
//                 ),
//                 loading: () => const MarkerLayer(markers: []),
//                 error: (_,__) => const MarkerLayer(markers: []),
//               ),
//
//               if (_myLocation != null)
//                 MarkerLayer(markers: [
//                   Marker(
//                     point: _myLocation!,
//                     width: 24, height: 24,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.9),
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 3),
//                         boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
//                       ),
//                     ),
//                   )
//                 ]),
//             ],
//           ),
//
//           Positioned(
//             top: 16, right: 16,
//             child: Column(
//               children: [
//                 _buildMapControl(_isSatellite ? Icons.map : Icons.satellite_alt, () {
//                   setState(() => _isSatellite = !_isSatellite);
//                 }),
//                 const SizedBox(height: 8),
//                 _buildMapControl(Icons.refresh, () {
//                   ref.read(mapsControllerProvider.notifier).fetchDetections();
//                 }),
//               ],
//             ),
//           ),
//
//           Positioned(
//             bottom: 32, right: 16,
//             child: FloatingActionButton(
//               mini: true,
//               backgroundColor: Colors.white,
//               onPressed: () {
//                 if (_myLocation != null) {
//                   _mapController.move(_myLocation!, 15);
//                 } else {
//                   _initLocation();
//                 }
//               },
//               child: const Icon(Icons.my_location, color: Color(0xFFD46E46)),
//             ),
//           ),
//
//           if (markersAsync.isLoading)
//             const Positioned(
//               top: 20, left: 0, right: 0,
//               child: Center(
//                 child: Card(
//                   child: Padding(
//                     padding: EdgeInsets.all(8.0),
//                     child: Text("Memuat data...", style: TextStyle(fontSize: 12)),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMapControl(IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 40, height: 40,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
//         ),
//         child: Icon(icon, color: Colors.grey.shade700, size: 20),
//       ),
//     );
//   }
// }