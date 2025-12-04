import 'dart:convert';
import 'dart:typed_data'; // Import Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/detection_viewmodel.dart';

class DetectionResultPage extends ConsumerWidget {
  const DetectionResultPage({super.key});

  Uint8List _getImageBinary(String base64String) {
    if (base64String.contains(',')) {
      base64String = base64String.split(',').last;
    }
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detectionState = ref.watch(detectionViewModelProvider);
    final result = detectionState.result;

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Color statusColor = Colors.green;
    if (result.isDanger) {
      statusColor = Colors.red;
    } else if (result.isWarning) {
      statusColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD46E46),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text("Hasil Deteksi", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey.shade100,
                      child: result.overlayBase64 != null
                          ? Image.memory(
                        _getImageBinary(result.overlayBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text("Gagal memuat gambar overlay"));
                        },
                      )
                          : Image.file(detectionState.image!, fit: BoxFit.cover),
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
                            "Status Visual: ${result.visualStatus}",
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result.visualDescription,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF3E2723)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text("Detail Analisis", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF5D534A))),
            const SizedBox(height: 12),

            _buildDetailItem("Statement AI", result.statement),
            _buildDetailItem("Analisis Lokasi", "${result.locationStatus}\nSesar: ${result.faultName} (${result.distanceKm} km)"),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (detectionState.isLoading || detectionState.isSaved)
                    ? null
                    : () async {
                  await ref.read(detectionViewModelProvider.notifier).saveDetection();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Data berhasil disimpan ke riwayat!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: detectionState.isSaved ? Colors.green : const Color(0xFFD46E46),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: detectionState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(detectionState.isSaved ? Icons.check : Icons.save),
                label: Text(
                    detectionState.isSaved ? "Tersimpan" : "Simpan ke Riwayat",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(content, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}