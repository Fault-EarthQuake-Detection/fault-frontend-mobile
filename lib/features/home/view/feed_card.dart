import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/feed_item.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;

  const FeedCard({super.key, required this.item});

  // Helper Warna Status
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.blue;
    final s = status.toUpperCase();
    if (s.contains("BAHAYA") || s.contains("DANGER") || s.contains("AWAS")) return Colors.red;
    if (s.contains("WASPADA") || s.contains("WARNING") || s.contains("PERINGATAN")) return Colors.orange;
    return Colors.green;
  }

  // [LOGIC TRANSLATE 1] Translate Title BMKG & Deteksi
  String _getDisplayTitle(BuildContext context, AppLocalizations l10n) {
    if (item.type == 'news') {
      final rawMag = item.originalData?['Magnitude'] ?? '-';
      final rawWilayah = item.originalData?['Wilayah'] ?? '-';
      return l10n.earthquakeInfo(rawMag, rawWilayah);
    } else {
      String title = item.title;
      if (Localizations.localeOf(context).languageCode == 'en') {
        title = title.replaceAll("Sesar", "Fault");
        title = title.replaceAll("Tidak ada", "No Fault");
      }
      return title;
    }
  }

  // [LOGIC TRANSLATE 2] Translate Status Level
  String _getDisplayStatus(BuildContext context, String status) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (!isEnglish) return status;

    final s = status.toUpperCase();
    if (s == 'BAHAYA') return 'DANGER';
    if (s == 'WASPADA') return 'WARNING';
    if (s == 'AMAN') return 'SAFE';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isNews = item.type == 'news';
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', Localizations.localeOf(context).languageCode);

    final sourceDisplay = item.isMine ? l10n.you : item.source;
    final sourceSubtitle = isNews ? l10n.bmkgOfficial : l10n.citizenReport;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (isNews) {
              context.push('/bmkg-detail', extra: item);
            } else if (!isNews && item.originalData != null) {
              context.push('/detection-result', extra: item.originalData);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildAvatar(isNews),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sourceDisplay,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                          ),
                          Text(
                            "$sourceSubtitle • ${dateFormat.format(item.timestamp)}",
                            style: GoogleFonts.poppins(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- CONTENT ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayTitle(context, l10n),
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 8),
                    if (item.statusLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.statusLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getDisplayStatus(context, item.statusLevel!),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(item.statusLevel)
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- IMAGE (OPTIMIZED) ---
              if (item.imageUrl != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // [OPTIMASI UTAMA] Ganti Image.network dengan CachedNetworkImage
                        CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          // Resize gambar di memori (PENTING untuk performa scroll)
                          memCacheHeight: 600,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: Center(
                              child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary.withOpacity(0.5)
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                          ),
                          fadeInDuration: const Duration(milliseconds: 300),
                        ),

                        // Gradient Overlay
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isNews) {
    if (isNews) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
        child: const Icon(Icons.waves, color: Colors.blue, size: 20),
      );
    } else if (item.userAvatarUrl != null && item.userAvatarUrl!.isNotEmpty) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          image: DecorationImage(
            // [OPTIMASI] Gunakan CachedNetworkImageProvider untuk Avatar
              image: CachedNetworkImageProvider(item.userAvatarUrl!),
              fit: BoxFit.cover
          ),
        ),
      );
    } else {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
        child: const Icon(Icons.person, color: Colors.orange, size: 20),
      );
    }
  }
}