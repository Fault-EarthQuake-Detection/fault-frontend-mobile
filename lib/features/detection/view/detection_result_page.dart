import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/detection_viewmodel.dart';

class DetectionResultPage extends ConsumerWidget {
  // Terima data opsional dari history
  final Map<String, dynamic>? historyData;

  const DetectionResultPage({super.key, this.historyData});

  // Fungsi Helper untuk memetakan data DB (History) ke format UI Result
  Map<String, dynamic> _mapHistoryToUi(Map<String, dynamic> data) {
    String rawDesc = data['description'] ?? "";
    Map<String, dynamic> parsedDesc = {};
    String cleanDesc = "Tidak ada deskripsi.";

    try {
      if (rawDesc.trim().startsWith('{')) {
        parsedDesc = jsonDecode(rawDesc);
        cleanDesc = parsedDesc['visual_description'] ??
            parsedDesc['deskripsi_singkat'] ??
            parsedDesc['visual_statement'] ?? rawDesc;
      } else {
        cleanDesc = rawDesc;
      }
    } catch (e) {
      cleanDesc = rawDesc;
    }

    return {
      'status': data['statusLevel'] ?? data['status_level'] ?? "INFO",
      'faultType': data['faultType'] ?? data['fault_type'] ?? "Tidak Teridentifikasi",
      'description': cleanDesc,
      'locationStatus': parsedDesc['location_status'] ?? "-",
      'faultName': parsedDesc['fault_name'] ?? "-",
      'distanceKm': double.tryParse(parsedDesc['fault_distance']?.toString() ?? "0") ?? 0.0,
      'overlayUrl': data['overlayImageUrl'] ?? data['overlay_image_url'] ?? "",
      'originalUrl': data['originalImageUrl'] ?? data['original_image_url'] ?? "",
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(detectionViewModelProvider);
    Map<String, dynamic>? result;

    if (historyData != null) {
      result = _mapHistoryToUi(historyData!);
    } else {
      result = detectionState.result;
    }

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String status = result['status'] ?? "INFO";
    final String faultType = result['faultType'] ?? "Tidak Teridentifikasi";
    final String description = result['description'] ?? "Tidak ada deskripsi.";

    final String locationStatus = result['locationStatus'] ?? "-";
    final String faultName = result['faultName'] ?? "-";
    final double distanceKm = result['distanceKm'] ?? 0.0;

    final String overlayUrl = result['overlayUrl'] ?? "";
    final String originalUrl = result['originalUrl'] ?? "";
    final String displayImageUrl = (overlayUrl.isNotEmpty && overlayUrl != "null")
        ? overlayUrl
        : originalUrl;

    Color statusColor = Colors.green;
    if (status.toUpperCase().contains("BAHAYA") || status.toUpperCase().contains("TINGGI")) {
      statusColor = Colors.red;
    } else if (status.toUpperCase().contains("WASPADA") || status.toUpperCase().contains("PERINGATAN")) {
      statusColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD46E46),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (historyData != null) {
              context.pop(); // Back biasa kalau dari History
            } else {
              context.go('/home'); // Reset ke home kalau deteksi baru
            }
          },
        ),
        title: Text(
          "Hasil Analisis",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU GAMBAR & STATUS ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade200,
                      child: displayImageUrl.isNotEmpty
                          ? Image.network(
                        displayImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFD46E46)));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                        },
                      )
                          : const Center(child: Text("Gambar tidak tersedia")),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Status Akhir: $status",
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          faultType,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3E2723)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- DETAIL ANALISIS ---
            Text("Detail Analisis", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF5D534A))),
            const SizedBox(height: 12),

            _buildDetailItem(
                "Analisis Visual (AI)",
                description,
                Icons.remove_red_eye_outlined
            ),

            _buildDetailItem(
                "Analisis Geospasial",
                "Zona: $locationStatus\n"
                    "Sesar Terdekat: $faultName\n"
                    "Jarak: ${distanceKm.toStringAsFixed(2)} km",
                Icons.map_outlined
            ),

            const SizedBox(height: 32),

            // --- TOMBOL SELESAI (HANYA MUNCUL JIKA BUKAN DARI HISTORY) ---
            if (historyData == null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                      "Selesai & Kembali",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                historyData != null
                    ? "Menampilkan arsip riwayat deteksi."
                    : "Data hasil analisis telah tersimpan otomatis.",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFD46E46).withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(icon, color: const Color(0xFFD46E46), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(content, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}