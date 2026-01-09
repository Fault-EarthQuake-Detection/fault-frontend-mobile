import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/feed_item.dart';

class BMKGDetailPage extends StatelessWidget {
  final FeedItem item;

  const BMKGDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Ambil data mentah dari BMKG
    final data = item.originalData ?? {};

    // Data BMKG (Default Indonesia)
    String magnitude = data['Magnitude'] ?? "-";
    String depth = data['Kedalaman'] ?? "-";
    String potential = data['Potensi'] ?? "-";
    String felt = data['Dirasakan'] ?? "-";

    // --- LOGIC MANUAL TRANSLATION (Hanya untuk BMKG) ---
    // Jika Locale Inggris, kita coba terjemahkan kata kunci sederhana
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    if (isEnglish) {
      if (potential.toLowerCase().contains("tidak berpotensi")) {
        potential = "No Tsunami Potential";
      } else if (potential.toLowerCase().contains("tsunami")) {
        potential = "Potential Tsunami";
      }

      // Kedalaman "10 km" tetap sama, tidak perlu translate
    }

    // Warna status
    final bool isTsunami = potential.toLowerCase().contains("tsunami") ||
        potential.toLowerCase().contains("berpotensi");

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- APP BAR & GAMBAR ---
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageUrl != null)
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(color: Colors.grey),
                    )
                  else
                    Container(color: Colors.grey, child: const Center(child: Icon(Icons.map, size: 50, color: Colors.white))),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black45, Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isTsunami ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${l10n.magnitude.toUpperCase()} $magnitude",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title, // Judul Wilayah biasanya nama kota, aman tidak ditranslate
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- CONTENT BODY ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Grid Statistik
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.vertical_align_bottom, l10n.depth, depth, theme),
                        _buildStatItem(Icons.waves, l10n.potential, isTsunami ? l10n.tsunamiAlert : l10n.safe, theme,
                            color: isTsunami ? Colors.red : Colors.green),
                        _buildStatItem(Icons.access_time, l10n.time, item.timestamp.toString().substring(11, 16), theme),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(l10n.analysisDetail, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 12),

                  _buildDetailRow(Icons.location_on, l10n.coordinates, "${data['Lintang']} - ${data['Bujur']}", theme),
                  _buildDetailRow(Icons.vibration, l10n.felt, felt, theme),
                  _buildDetailRow(Icons.warning_amber, l10n.potential, potential, theme),
                  _buildDetailRow(Icons.calendar_today, l10n.date, item.timestamp.toString().substring(0, 10), theme),

                  const SizedBox(height: 30),

                  // 3. Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.bmkgDisclaimer,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, ThemeData theme, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? theme.textTheme.bodyLarge?.color)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String content, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(content, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}