import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/viewmodel/home_viewmodel.dart';
import '../../sidebar/view/sidebar_drawer.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../sidebar/viewmodel/history_viewmodel.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProvider);

    // Ambil Theme Data
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String displayName = "GeoValid User";
    String email = "user@geovalid.com";
    String? photoUrl;

    userAsync.whenData((userData) {
      if (userData != null) {
        email = userData['email'] ?? "No Email";
        final metadata = userData['user_metadata'] as Map<String, dynamic>?;
        if (metadata != null) {
          displayName = metadata['full_name'] ?? metadata['name'] ?? metadata['username'] ?? email.split('@')[0];
          photoUrl = metadata['avatar_url'] ?? metadata['picture'];
        } else {
          displayName = email.split('@')[0];
        }
      }
    });

    return Scaffold(
      // Background otomatis ikut tema (putih/hitam)
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        title: SizedBox(
          height: 40,
          child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER LENGKUNG ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 60),
              decoration: const BoxDecoration(
                color: AppColors.primary, // Tetap oranye branding
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    l10n.profileTitle,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- AVATAR & INFO ---
            Transform.translate(
              offset: const Offset(0, -70),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 4), // Border ikut warna background
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                      child: (photoUrl == null)
                          ? const Icon(Icons.person, size: 70, color: Colors.white70) : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color // Adaptif
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, // Adaptif
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- MENU ITEMS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildProfileMenuItem(context, Icons.edit, l10n.editProfile, () => context.push('/edit-profile')),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(context, Icons.feedback_outlined, l10n.sendFeedback, () => context.push('/feedback')),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(context, Icons.info_outline, l10n.aboutApp, () => context.push('/about')),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(context, Icons.settings, l10n.settingsTitle, () => context.push('/settings')),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(
                      context,
                      Icons.logout,
                      l10n.logout,
                          () => _showLogoutDialog(context, ref, l10n),
                      isLogout: true
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // Adaptif
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          l10n.logoutConfirmTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          l10n.logoutConfirmMsg,
          style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authViewModelProvider.notifier).logout();
              ref.invalidate(historyViewModelProvider);
              ref.invalidate(homeViewModelProvider);
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.yesLogout, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor, // [PENTING] Gunakan warna kartu tema
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLogout ? Colors.red.shade50 : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isLogout ? Colors.red.shade600 : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? Colors.red.shade600 : theme.textTheme.bodyLarge?.color, // Adaptif
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isLogout ? Colors.red.shade200 : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}