import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/detection_viewmodel.dart';

// [BARU] Enum untuk Mode Gambar
enum ImageMode { original, overlay, mask }

class DetectionResultPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? historyData;

  const DetectionResultPage({super.key, this.historyData});

  @override
  ConsumerState<DetectionResultPage> createState() => _DetectionResultPageState();
}

class _DetectionResultPageState extends ConsumerState<DetectionResultPage> {
  // [BARU] State lokal untuk mode gambar yang aktif
  ImageMode _selectedMode = ImageMode.overlay;

  // --- 1. LOGIC PARSING DATA ---
  Map<String, dynamic> _parseResultData(Map<String, dynamic> data) {
    // ... (Logic parsing SAMA persis dengan sebelumnya) ...
    // A. Cek struktur "Fresh AI"
    final faultAnalysis = data['fault_analysis'] as Map<String, dynamic>?;

    // B. Cek struktur "History DB"
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

    String rawStatus = faultAnalysis?['status_level'] ??
        parsedDescJson['visual_status'] ??
        data['statusLevel'] ?? data['status_level'] ?? data['status'] ?? "INFO";

    if (rawStatus.contains("AMAN")) rawStatus = "AMAN";
    if (rawStatus.contains("BAHAYA")) rawStatus = "BAHAYA";
    if (rawStatus.contains("WASPADA")) rawStatus = "WASPADA";

    String faultType = faultAnalysis?['deskripsi_singkat'] ??
        data['faultType'] ?? data['fault_type'] ?? "Tidak Teridentifikasi";

    String description = faultAnalysis?['penjelasan_lengkap'] ??
        data['statement'] ?? cleanDesc;
    if (description.isEmpty) description = "Tidak ada deskripsi.";

    String locationStatus = parsedDescJson['location_status'] ?? "-";
    String faultName = data['nama_patahan'] ?? parsedDescJson['fault_name'] ?? "-";
    double distanceKm = double.tryParse(data['jarak_km']?.toString() ?? "0") ??
        double.tryParse(parsedDescJson['fault_distance']?.toString() ?? "0") ?? 0.0;

    // --- [UPDATE] AMBIL SEMUA JENIS GAMBAR (ORIGINAL, OVERLAY, MASK) ---
    // Kita simpan dalam Map biar mudah diakses berdasarkan Enum

    // 1. ORIGINAL
    Uint8List? originalBytes;
    String originalUrl = data['originalImageUrl'] ?? data['original_image_url'] ?? "";
    // Note: Original biasanya url, jarang base64 di response akhir, tapi kalau ada base64 logic tambahkan di sini

    // 2. OVERLAY
    Uint8List? overlayBytes;
    String overlayUrl = data['overlayImageUrl'] ?? data['overlay_image_url'] ?? "";
    if (data['images_base64'] != null && data['images_base64']['overlay'] != null) {
      try {
        String base64Str = data['images_base64']['overlay'];
        if (base64Str.contains(',')) base64Str = base64Str.split(',').last;
        overlayBytes = base64Decode(base64Str);
      } catch (_) {}
    }

    // 3. MASK
    Uint8List? maskBytes;
    String maskUrl = data['maskImageUrl'] ?? data['mask_image_url'] ?? "";
    if (data['images_base64'] != null && data['images_base64']['mask'] != null) {
      try {
        String base64Str = data['images_base64']['mask'];
        if (base64Str.contains(',')) base64Str = base64Str.split(',').last;
        maskBytes = base64Decode(base64Str);
      } catch (_) {}
    }

    return {
      'status': rawStatus,
      'faultType': faultType,
      'description': description,
      'locationStatus': locationStatus,
      'faultName': faultName,
      'distanceKm': distanceKm,

      // Return Map Images
      'images': {
        ImageMode.original: {'bytes': originalBytes, 'url': originalUrl},
        ImageMode.overlay: {'bytes': overlayBytes, 'url': overlayUrl},
        ImageMode.mask: {'bytes': maskBytes, 'url': maskUrl},
      }
    };
  }

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
  Widget build(BuildContext context) {
    final detectionState = ref.watch(detectionViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    final isHistoryMode = widget.historyData != null;
    final rawData = widget.historyData ?? detectionState.result;

    ref.listen(detectionViewModelProvider, (prev, next) {
      if (next.isSavedSuccess && !next.isSaving) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil disimpan ke riwayat!"), backgroundColor: Colors.green),
        );
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    if (rawData == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final result = _parseResultData(rawData);
    String displayStatus = _getTranslatedStatus(result['status'], isEnglish);

    // Ambil data gambar sesuai mode yang dipilih user
    final imagesMap = result['images'] as Map<ImageMode, Map<String, dynamic>>;
    final currentImageData = imagesMap[_selectedMode]!;
    final Uint8List? currentBytes = currentImageData['bytes'];
    final String currentUrl = currentImageData['url'];

    Color statusColor = Colors.green;
    if (result['status'].contains("BAHAYA") || result['status'].contains("TINGGI")) statusColor = Colors.red;
    else if (result['status'].contains("WASPADA") || result['status'].contains("PERINGATAN")) statusColor = Colors.orange;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () {
            if (isHistoryMode) context.pop();
            else _handleExit(context, ref);
          },
        ),
        title: Text(l10n.analysisResult, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- [BARU] IMAGE HEADER (SWITCHER) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Visualisasi:", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                        Row(
                          children: [
                            _buildModeButton(ImageMode.original, "Asli", isDark),
                            const SizedBox(width: 4),
                            _buildModeButton(ImageMode.overlay, "Overlay", isDark),
                            const SizedBox(width: 4),
                            _buildModeButton(ImageMode.mask, "Masker", isDark),
                          ],
                        )
                      ],
                    ),
                  ),

                  // IMAGE AREA (Clickable for Zoom)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, currentBytes, currentUrl),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.black, // Background hitam agar kontras
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildImage(currentBytes, currentUrl, l10n, BoxFit.contain)),
                          const Positioned(
                              bottom: 8, right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 14,
                                child: Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                              )
                          )
                        ],
                      ),
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
                            "${l10n.finalStatus}: $displayStatus",
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result['faultType'],
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ... (Sisa Widget Detail & Tombol Aksi SAMA seperti sebelumnya) ...
            Text(l10n.analysisDetail, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 12),
            _buildDetailItem(l10n.visualAnalysis, result['description'], Icons.remove_red_eye_outlined, theme),
            _buildDetailItem(l10n.geoAnalysis, "${l10n.zone}: ${result['locationStatus']}\n${l10n.nearestFault}: ${result['faultName']}\n${l10n.distance}: ${result['distanceKm'].toStringAsFixed(2)} km", Icons.map_outlined, theme),

            const SizedBox(height: 32),
            // ... (Tombol Simpan/Selesai/Kembali SAMA - Silakan copy dari kode sebelumnya) ...
            // Agar tidak terlalu panjang, saya persingkat bagian tombol ini.
            // Gunakan logika tombol yang sama persis dengan DetectionResultPage sebelumnya.
            if (isHistoryMode)
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => context.pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), icon: const Icon(Icons.arrow_back), label: Text("Kembali", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)))),
            if (!isHistoryMode) ...[
              if (!detectionState.isSavedSuccess)
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: detectionState.isSaving ? null : () => ref.read(detectionViewModelProvider.notifier).saveResultToDatabase(), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), icon: detectionState.isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_alt), label: Text("Simpan ke Riwayat", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)))),
              if (detectionState.isSavedSuccess) Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 8), Text("Data tersimpan", style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w600))]))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: () => _handleExit(context, ref), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), foregroundColor: theme.textTheme.bodyLarge?.color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text("Selesai (Ke Beranda)", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)))),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: TOMBOL SWITCH MODE ---
  Widget _buildModeButton(ImageMode mode, String label, bool isDark) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade400)
        ),
        child: Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.black87)
            )
        ),
      ),
    );
  }

  // --- FULL SCREEN ZOOM ---
  void _showFullScreenImage(BuildContext context, Uint8List? bytes, String url) {
    showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // Fullscreen
          child: Stack(
            children: [
              // InteractiveViewer untuk Zoom & Pan
              InteractiveViewer(
                maxScale: 5.0,
                minScale: 0.5,
                child: Center(
                    child: _buildImage(bytes, url, AppLocalizations.of(context)!, BoxFit.contain)
                ),
              ),
              // Tombol Close
              Positioned(
                  top: 40, right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  )
              ),
            ],
          ),
        )
    );
  }

  void _handleExit(BuildContext context, WidgetRef ref) {
    ref.read(detectionViewModelProvider.notifier).resetState();
    context.go('/home');
  }

  Widget _buildImage(Uint8List? bytes, String url, AppLocalizations l10n, BoxFit fit) {
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
      );
    } else if (url.isNotEmpty && url != "null") {
      return Image.network(
        url,
        fit: fit,
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
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(content, style: GoogleFonts.poppins(fontSize: 14, color: theme.textTheme.bodyLarge?.color, height: 1.5))]))]),
    );
  }
}