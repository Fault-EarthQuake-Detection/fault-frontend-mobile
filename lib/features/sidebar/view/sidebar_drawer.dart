import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/history_viewmodel.dart';

class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyViewModelProvider);
    final historyNotifier = ref.read(historyViewModelProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final dateFormat = DateFormat('dd MMM', Localizations.localeOf(context).languageCode);

    return Drawer(
      backgroundColor: AppColors.primary,
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
                  // Tombol Back
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
                    l10n.menu,
                    style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
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
                      onChanged: (value) => historyNotifier.search(value),
                      textInputAction: TextInputAction.search, // Keyboard Search

                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.searchHistory,
                        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      // Tutup keyboard saat enter ditekan
                      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, thickness: 1),

            // --- LIST HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.myDetectionHistory,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  // [PERBAIKAN TOMBOL REFRESH]
                  GestureDetector(
                    onTap: () {
                      // Panggil dengan forceRefresh: true agar loading muncul visualnya
                      historyNotifier.loadMyHistory(forceRefresh: true);
                    },
                    child: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                  )
                ],
              ),
            ),

            // --- LIST CONTENT ---
            Expanded(
              child: historyState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : historyState.displayHistory.isEmpty
                  ? Center(
                child: Text(
                  l10n.notFound,
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: historyState.displayHistory.length,
                itemBuilder: (context, index) {
                  final item = historyState.displayHistory[index];

                  final title = item['faultType'] ?? item['fault_type'] ?? l10n.unknown;
                  final status = item['statusLevel'] ?? item['status_level'] ?? "-";

                  String dateStr = "-";
                  try {
                    final date = DateTime.parse(item['createdAt'] ?? item['created_at']);
                    dateStr = dateFormat.format(date);
                  } catch (_) {}

                  return _buildDrawerItem(
                    icon: Icons.history,
                    title: "$title - $status",
                    subtitle: dateStr,
                    onTap: () {
                      Navigator.pop(context); // Tutup drawer dulu
                      context.push('/detection-result', extra: item);
                    },
                  );
                },
              ),
            ),

            // --- FOOTER ---
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
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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