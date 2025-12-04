import 'dart:io';
import 'package:camera/camera.dart'; // Package Kamera
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Untuk Galeri
import 'package:permission_handler/permission_handler.dart'; // Untuk Izin
import '../viewmodel/detection_viewmodel.dart';

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
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }

    if (!status.isGranted) {
      setState(() {
        _isPermissionDenied = true;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final firstCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      await _cameraController!.setFlashMode(FlashMode.off);

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isPermissionDenied = false;
      });
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    FlashMode newMode = _currentFlashMode == FlashMode.off ? FlashMode.always : FlashMode.off;

    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() {
        _currentFlashMode = newMode;
      });
    } catch (e) {
      debugPrint("Error switching flash mode: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      ref.read(detectionViewModelProvider.notifier).setImage(File(image.path));
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    if (await Permission.storage.isDenied && await Permission.photos.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos
      ].request();

      if (statuses[Permission.storage]!.isDenied && statuses[Permission.photos]!.isDenied) {
        _showOpenSettingsDialog();
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      ref.read(detectionViewModelProvider.notifier).setImage(File(pickedFile.path));
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Izin Diperlukan"),
        content: const Text("Aplikasi membutuhkan izin akses untuk fitur ini."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("Buka Pengaturan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final detectionState = ref.watch(detectionViewModelProvider);
    final imageFile = detectionState.image;
    final isImageCaptured = imageFile != null;

    if (_isPermissionDenied && !isImageCaptured) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Izin Kamera Diperlukan", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD46E46)),
                child: const Text("Buka Pengaturan", style: TextStyle(color: Colors.white)),
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
            if (isImageCaptured) {
              ref.read(detectionViewModelProvider.notifier).reset();
              _initializeCamera();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          if (!isImageCaptured && _isCameraInitialized)
            IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                  _currentFlashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                  color: Colors.white
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (isImageCaptured)
            _buildCapturedImagePreview(size, imageFile)
          else if (_isCameraInitialized && _cameraController != null)
            SizedBox(
              height: size.height,
              width: size.width,
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFFD46E46))),

          if (!isImageCaptured && _isCameraInitialized)
            Center(
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8 * (4/3),
              ),
            ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: isImageCaptured
                ? _buildConfirmationControls(context, ref)
                : _buildCameraControls(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImagePreview(Size size, File image) {
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Image.file(
        image,
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
            onTap: _pickFromGallery,
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(Icons.image, color: Colors.white),
            ),
          ),
          InkWell(
            onTap: _takePicture,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD46E46), width: 4),
                color: Colors.white,
              ),
              child: const Icon(Icons.camera, color: Color(0xFFD46E46), size: 30),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildConfirmationControls(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: Colors.black87,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(detectionViewModelProvider.notifier).reset();
                _initializeCamera();
              },
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
              onPressed: () {
                _cameraController?.pausePreview();
                context.push('/location-picker');
              },
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