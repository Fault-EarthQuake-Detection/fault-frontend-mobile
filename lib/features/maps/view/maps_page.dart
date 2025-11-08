import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../sidebar/view/sidebar_drawer.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 18,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'assets/image 2.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapControl(Icons.layers, () {}),
                const SizedBox(height: 8),
                _buildMapControl(Icons.filter_alt, () {}),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {},
              child: const Icon(Icons.my_location, color: Color(0xFFD46E46)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
    );
  }
}
