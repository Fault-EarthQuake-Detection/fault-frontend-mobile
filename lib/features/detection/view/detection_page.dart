import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/view/main_navigation.dart';
import '../../navigation/viewmodel/navigation_viewmodel.dart';

final detectionImageProvider = StateProvider<File?>((ref) => null);

class DetectionPage extends ConsumerStatefulWidget {
  const DetectionPage({super.key});

  @override
  ConsumerState<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends ConsumerState<DetectionPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();

    if (!status.isGranted) {
      if (mounted) setState(() => _isPermissionDenied = true);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first),
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPermissionDenied = false;
        });
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) return;
    try {
      final image = await _cameraController!.takePicture();
      ref.read(detectionImageProvider.notifier).state = File(image.path);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      ref.read(detectionImageProvider.notifier).state = File(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final imageFile = ref.watch(detectionImageProvider);
    final isCaptured = imageFile != null;

    // View Izin Ditolak
    if (_isPermissionDenied && !isCaptured) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton(color: Colors.white)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l10n.cameraPermission, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text(l10n.openSettings, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (isCaptured) {
              ref.read(detectionImageProvider.notifier).state = null;
              _initializeCamera();
            } else {
              ref.read(bottomNavIndexProvider.notifier).state = 0; // Ke Home
            }
          },
        ),
        actions: [
          if (!isCaptured && _isCameraInitialized)
            IconButton(
              onPressed: () async {
                final newMode = _currentFlashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
                await _cameraController?.setFlashMode(newMode);
                setState(() => _currentFlashMode = newMode);
              },
              icon: Icon(_currentFlashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Preview Kamera / Gambar
          if (isCaptured)
            SizedBox(height: size.height, width: size.width, child: Image.file(imageFile, fit: BoxFit.contain))
          else if (_isCameraInitialized)
            SizedBox(height: size.height, width: size.width, child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // [FIX] KOTAK FOKUS DIHAPUS SESUAI PERMINTAAN

          // Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: isCaptured ? _buildConfirmControls(context, ref, l10n) : _buildCaptureControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent])),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(onTap: _pickFromGallery, child: const CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.image, color: Colors.white))),
          InkWell(
            onTap: _takePicture,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 4), color: Colors.white),
              child: const Icon(Icons.camera, color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildConfirmControls(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: Colors.black87,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(detectionImageProvider.notifier).state = null;
                _initializeCamera();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(l10n.retakePhoto, style: GoogleFonts.poppins(color: Colors.white)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _cameraController?.pausePreview();
                context.push('/location-picker');
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: Text(l10n.selectLocation, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }
}