import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../viewmodel/history_viewmodel.dart';

class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyViewModelProvider);
    final historyNotifier = ref.read(historyViewModelProvider.notifier);

    return Drawer(
      backgroundColor: const Color(0xFFD46E46),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER & SEARCH ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Menu",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (value) => historyNotifier.search(value), // Ini sudah benar
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Cari riwayat saya...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFD46E46)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, thickness: 1),

            // --- LIST RIWAYAT ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Riwayat Deteksi Saya",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => historyNotifier.loadMyHistory(),
                    child: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                  )
                ],
              ),
            ),

            Expanded(
              child: historyState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
              // [FIX 2] Gunakan displayHistory, bukan history
                  : historyState.displayHistory.isEmpty
                  ? Center(
                child: Text(
                  "Tidak ditemukan",
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                // [FIX 3] Gunakan length dari displayHistory
                itemCount: historyState.displayHistory.length,
                itemBuilder: (context, index) {
                  // [FIX 4] Ambil item dari displayHistory
                  final item = historyState.displayHistory[index];

                  final title = item['faultType'] ?? item['fault_type'] ?? "Tidak diketahui";
                  final status = item['statusLevel'] ?? item['status_level'] ?? "-";

                  String dateStr = "";
                  try {
                    final date = DateTime.parse(item['createdAt'] ?? item['created_at']);
                    const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agust", "Sep", "Okt", "Nov", "Des"];
                    dateStr = "${date.day} ${months[date.month - 1]}";
                  } catch (e) {
                    dateStr = "-";
                  }

                  return _buildDrawerItem(
                    icon: Icons.history,
                    title: "$title - $status",
                    subtitle: dateStr,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/detection-result', extra: item);
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "GeoValid v1.0.0",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
      ) : null,
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      hoverColor: Colors.white12,
    );
  }
}