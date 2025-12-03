import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../sidebar/view/sidebar_drawer.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil data user dari provider yang kita buat tadi
    final userAsync = ref.watch(currentUserProvider);

    // Default values jika data belum siap
    String displayName = "GeoValid User";
    String email = "user@geovalid.com";
    String? photoUrl;

    // 2. Ekstrak data jika user ada
    userAsync.whenData((user) {
      if (user != null) {
        email = user.email ?? "No Email";

        // Ambil nama dari metadata (biasanya dari Google Login atau update profile)
        // Cek 'full_name', kalau null cek 'name', kalau null pakai bagian depan email
        final metadata = user.userMetadata;
        displayName = metadata?['full_name'] ??
            metadata?['name'] ??
            email.split('@')[0];

        // Ambil foto profil
        photoUrl = metadata?['avatar_url'] ?? metadata?['picture'];
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD46E46),
        elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        title: SizedBox(
          height: 40,
          child: Image.asset(
            'assets/Logo.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER BACKGROUND
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 60),
              decoration: const BoxDecoration(
                color: Color(0xFFD46E46),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "Profil Pengguna",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // INFO USER (AVATAR & NAMA)
            Transform.translate(
              offset: const Offset(0, -70),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Lingkaran Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4), // Border putih tebal
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.grey.shade300,
                          // Logika Gambar: Jika ada URL -> Pakai NetworkImage, Jika tidak -> Icon
                          backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl!) : null,
                          child: (photoUrl == null)
                              ? const Icon(Icons.person, size: 70, color: Colors.white70)
                              : null,
                        ),
                      ),

                      // Tombol Ganti Foto
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () {
                            // TODO: Implementasi Image Picker & Upload ke Supabase Storage
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fitur ubah foto akan segera hadir!")),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD46E46),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nama User Dinamis
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3E2723),
                    ),
                  ),

                  // Email User Dinamis
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // MENU LIST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.edit,
                    title: "Edit Profil",
                    onTap: () => context.push('/edit-profile'),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileMenuItem(
                    icon: Icons.info_outline,
                    title: "Tentang Aplikasi",
                    onTap: () => context.push('/about'),
                  ),
                  const SizedBox(height: 12),

                  // 🔴 LOGOUT DENGAN DIALOG
                  _buildProfileMenuItem(
                    icon: Icons.logout,
                    title: "Keluar",
                    isLogout: true,
                    onTap: () {
                      _showLogoutDialog(context, ref);
                    },
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

  // 🔥 FUNGSI DIALOG LOGOUT
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Konfirmasi Keluar",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF3E2723)),
        ),
        content: Text(
          "Apakah Anda yakin ingin keluar dari akun ini?",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Tutup dialog
            child: Text(
              "Batal",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog dulu

              // Proses Logout
              await ref.read(authViewModelProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Ya, Keluar", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGET ITEM MENU
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
                    color: isLogout ? Colors.red.shade50 : const Color(0xFFD46E46).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isLogout ? Colors.red.shade600 : const Color(0xFFD46E46),
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
                      color: isLogout ? Colors.red.shade600 : const Color(0xFF3E2723),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isLogout ? Colors.red.shade200 : Colors.grey.shade400,
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