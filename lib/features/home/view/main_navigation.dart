import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart'; // Import ini

import 'home_page.dart';
import '../../detection/view/detection_page.dart';
import '../../maps/view/maps_page.dart';
import '../../profile/view/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DetectionPage(),
    const Column(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _requestInitialPermissions();
  }

  Future<void> _requestInitialPermissions() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.photos,
    ].request();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildIcon(String assetPath, bool isSelected) {
    return ImageIcon(
      AssetImage(assetPath),
      size: 24,
      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFD46E46),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon('assets/Home_fill.png', _selectedIndex == 0),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/Search_alt_fill@3x.png', _selectedIndex == 1),
            label: 'Deteksi',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/Pin_alt_fill@3x.png', _selectedIndex == 2),
            label: 'Peta',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon('assets/User_fill@3x.png', _selectedIndex == 3),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
