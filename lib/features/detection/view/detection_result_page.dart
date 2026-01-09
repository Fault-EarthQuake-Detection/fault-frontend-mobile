import 'dart:convert';
import 'dart:typed_data'; // Untuk Base64 Image
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/detection_viewmodel.dart';

class DetectionResultPage extends ConsumerWidget {
  // Terima data opsional dari history (jika dibuka dari menu riwayat)
  final Map<String, dynamic>? historyData;

  const DetectionResultPage({super.key, this.historyData});

  // --- 1. LOGIC PARSING DATA (History vs Fresh AI) ---
  Map<String, dynamic> _parseResultData(Map<String, dynamic> data) {
    // A. Cek struktur "Fresh AI" (memiliki key fault_analysis)
    final faultAnalysis = data['fault_analysis'] as Map<String, dynamic>?;

    // B. Cek struktur "History DB" (deskripsi tersimpan sebagai JSON string)
    Map<String, dynamic> parsedDescJson = {};
    String cleanDesc = "";

    if (data['description'] != null) {
      String rawDesc = data['description'].toString();
      try {
        if (rawDesc.trim().startsWith('{')) {
          parsedDescJson = jsonDecode(rawDesc);
          cleanDesc = parsedDescJson['visual_description'] ??
              parsedDescJson['deskripsi_singkat'] ??
              parsedDescJson['visual_statement'] ?? rawDesc;
        } else {
          cleanDesc = rawDesc;
        }
      } catch (_) {
        cleanDesc = rawDesc;
      }
    }

    // --- Ekstrak Field ---

    // 1. Status
    String rawStatus = faultAnalysis?['status_level'] ??
        parsedDescJson['visual_status'] ??
        data['statusLevel'] ??
        data['status_level'] ??
        data['status'] ??
        "INFO";

    // Bersihkan status dari teks tambahan
    if (rawStatus.contains("AMAN")) rawStatus = "AMAN";
    if (rawStatus.contains("BAHAYA")) rawStatus = "BAHAYA";
    if (rawStatus.contains("WASPADA")) rawStatus = "WASPADA";

    // 2. Tipe Sesar / Deskripsi
    String faultType = faultAnalysis?['deskripsi_singkat'] ??
        data['faultType'] ??
        data['fault_type'] ??
        "Tidak Teridentifikasi";

    String description = faultAnalysis?['penjelasan_lengkap'] ??
        data['statement'] ??
        cleanDesc;
    if (description.isEmpty) description = "Tidak ada deskripsi.";

    // 3. Geospasial
    String locationStatus = parsedDescJson['location_status'] ?? "-";
    String faultName = data['nama_patahan'] ?? parsedDescJson['fault_name'] ?? "-";
    double distanceKm = double.tryParse(data['jarak_km']?.toString() ?? "0") ??
        double.tryParse(parsedDescJson['fault_distance']?.toString() ?? "0") ?? 0.0;

    // 4. Gambar (Prioritas: Base64 > URL Overlay > URL Original)
    Uint8List? imageBytes;
    String imageUrl = "";

    // Cek Base64 (Biasanya dari Fresh Result AI)
    if (data['images_base64'] != null && data['images_base64']['overlay'] != null) {
      try {
        String base64Str = data['images_base64']['overlay'];
        if (base64Str.contains(',')) base64Str = base64Str.split(',').last;
        imageBytes = base64Decode(base64Str);
      } catch (e) {
        print("Error decode base64: $e");
      }
    }

    // Cek URL (Biasanya dari History DB)
    if (imageBytes == null) {
      imageUrl = data['overlayImageUrl'] ??
          data['overlay_image_url'] ??
          data['originalImageUrl'] ??
          data['original_image_url'] ??
          "";
    }

    return {
      'status': rawStatus,
      'faultType': faultType,
      'description': description,
      'locationStatus': locationStatus,
      'faultName': faultName,
      'distanceKm': distanceKm,
      'imageBytes': imageBytes,
      'imageUrl': imageUrl,
    };
  }

  // --- 2. TRANSLATE STATUS (ID -> EN) ---
  String _getTranslatedStatus(String status, bool isEnglish) {
    if (!isEnglish) return status;
    final s = status.toUpperCase();
    if (s == 'AMAN') return "SAFE";
    if (s == 'BAHAYA') return "DANGER";
    if (s == 'WASPADA') return "WARNING";
    if (s == 'INFO') return "INFO";
    return status;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(detectionViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    // Gabungkan data (Priority: History > State)
    final rawData = historyData ?? detectionState.result;

    if (rawData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    // Parse Data
    final result = _parseResultData(rawData);

    // Ambil variabel hasil parsing
    String status = result['status'];
    String displayStatus = _getTranslatedStatus(status, isEnglish);

    String faultType = result['faultType'];
    // Translate tipe sesar sederhana
    if (isEnglish) {
      faultType = faultType.replaceAll("Sesar", "Fault");
      faultType = faultType.replaceAll("Tidak Teridentifikasi", l10n.unidentified);
    }

    final String description = result['description'];
    final String locationStatus = result['locationStatus'];
    final String faultName = result['faultName'];
    final double distanceKm = result['distanceKm'];
    final Uint8List? imageBytes = result['imageBytes'];
    final String imageUrl = result['imageUrl'];

    // Warna Status
    Color statusColor = Colors.green;
    if (status.contains("BAHAYA") || status.contains("TINGGI")) statusColor = Colors.red;
    else if (status.contains("WASPADA") || status.contains("PERINGATAN")) statusColor = Colors.orange;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Adaptif Theme
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (historyData != null) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          l10n.analysisResult, // [L10N]
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
                color: theme.cardColor, // Adaptif
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE AREA
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: _buildImage(imageBytes, imageUrl, l10n),
                    ),
                  ),

                  // STATUS INFO AREA
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
                            "${l10n.finalStatus}: $displayStatus", // [L10N]
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          faultType,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color // Adaptif
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- DETAIL ANALISIS ---
            Text(
                l10n.analysisDetail, // [L10N]
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color
                )
            ),
            const SizedBox(height: 12),

            _buildDetailItem(
                l10n.visualAnalysis, //
                description,
                Icons.remove_red_eye_outlined,
                theme
            ),

            _buildDetailItem(
                l10n.geoAnalysis, //
                "${l10n.zone}: $locationStatus\n"
                    "${l10n.nearestFault}: $faultName\n"
                    "${l10n.distance}: ${distanceKm.toStringAsFixed(2)} km",
                Icons.map_outlined,
                theme
            ),

            const SizedBox(height: 32),

            // --- TOMBOL SELESAI (Hanya jika data baru) ---
            if (historyData == null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                      l10n.doneReturn, // [L10N]
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                historyData != null ? l10n.showingArchive : l10n.dataSaved, // [L10N]
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildImage(Uint8List? bytes, String url, AppLocalizations l10n) {
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    } else if (url.isNotEmpty && url != "null") {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
        errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    }
    return Center(child: Text(l10n.imageNotAvailable, style: const TextStyle(color: Colors.grey)));
  }

  Widget _buildDetailItem(String title, String content, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor, // Adaptif
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                    content,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color, // Adaptif
                        height: 1.5
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}