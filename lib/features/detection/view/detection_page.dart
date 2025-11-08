import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  bool _isImageCaptured = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (_isImageCaptured) {
              setState(() => _isImageCaptured = false);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          if (!_isImageCaptured)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.flash_off, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          _isImageCaptured
              ? _buildCapturedImagePreview(size)
              : _buildCameraPreview(size),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _isImageCaptured
                ? _buildConfirmationControls(context)
                : _buildCameraControls(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(Size size) {
    return Container(
      height: size.height,
      width: size.width,
      color: Colors.grey.shade900,
      child: Stack(
        children: [
          Center(child: Icon(Icons.camera_alt, size: 80, color: Colors.white.withOpacity(0.3))),
          Center(
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8 * (4/3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImagePreview(Size size) {
    return Container(
      height: size.height,
      width: size.width,
      color: Colors.black,
      child: Image.asset(
        'assets/1666666488_71f2bcba014303390731.jpg',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildCameraControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () => print("Buka Galeri"),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.image, color: Colors.white),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isImageCaptured = true),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD46E46), width: 4),
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildConfirmationControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: Colors.black54,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _isImageCaptured = false),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text("Foto Ulang", style: GoogleFonts.poppins(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/location-picker'),
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: Text("Pilih Lokasi", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD46E46),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
