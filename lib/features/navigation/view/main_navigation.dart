import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../detection/view/detection_page.dart';
import '../../home/view/home_page.dart';
import '../../maps/view/maps_page.dart';
import '../../profile/view/profile_page.dart';
import '../viewmodel/navigation_viewmodel.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {

  // List Halaman
  final List<Widget> _pages = [
    const HomePage(),
    const DetectionPage(),
    const MapsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Panggil logic permission dari ViewModel
    // Menggunakan addPostFrameCallback agar aman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mainNavigationViewModelProvider.notifier).requestInitialPermissions();
    });
  }

  void _onItemTapped(int index) {
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  // Helper untuk Icon agar kodenya lebih pendek
  Widget _buildIcon(String assetPath, bool isSelected) {
    return ImageIcon(
      AssetImage(assetPath),
      size: 24,
      // Icon putih jika selected, agak transparan jika tidak (sesuai desain background oranye)
      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final l10n = AppLocalizations.of(context)!;

    // Kita gunakan AppColors.primary untuk background navbar
    // Jika Dark Mode, mungkin kita ingin warna abu gelap?
    // Tapi untuk branding GeoValid, biasanya navbar tetap warna utama atau hitam.
    // Di sini saya buat adaptif:
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBackgroundColor = isDark ? const Color(0xFF1E1E1E) : AppColors.primary;
    final selectedItemColor = isDark ? AppColors.primary : Colors.white;
    final unselectedItemColor = isDark ? Colors.grey : Colors.white.withOpacity(0.6);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,

        backgroundColor: navBackgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,

        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),

        items: [
          BottomNavigationBarItem(
            icon: _buildIcon('assets/Home_fill.png', selectedIndex == 0),
            label: l10n.navHome, // [L10N]
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/Search_alt_fill@3x.png', selectedIndex == 1),
            label: l10n.navDetection, // [L10N]
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/Pin_alt_fill@3x.png', selectedIndex == 2),
            label: l10n.navMap, // [L10N]
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/User_fill@3x.png', selectedIndex == 3),
            label: l10n.navProfile, // [L10N]
          ),
        ],
      ),
    );
  }
}