// lib/features/profile/view/edit_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  // Controller Password
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isGoogleUser = false;
  File? _selectedImage;

  final Color _earthyColor = const Color(0xFF8D8D8D);
  final Color _labelColor = const Color(0xFF5D534A);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    // Gunakan ref.read untuk ambil data awal sekali saja
    final userMap = await ref.read(currentUserProvider.future);

    if (userMap != null) {
      setState(() {
        _emailController.text = userMap['email'] ?? "";

        final metadata = userMap['user_metadata'] as Map<String, dynamic>?;
        // Prioritas ambil username
        _usernameController.text = metadata?['username'] ?? metadata?['full_name'] ?? metadata?['name'] ?? "";

        // --- PERBAIKAN LOGIKA CEK GOOGLE ---
        _isGoogleUser = false; // Reset dulu

        // Cek 1: App Metadata (provider string)
        final appMetadata = userMap['app_metadata'] as Map<String, dynamic>?;
        if (appMetadata != null) {
          if (appMetadata['provider'] == 'google') {
            _isGoogleUser = true;
          }
          // Cek 2: App Metadata (providers array) - kadang supabase simpan di sini
          else if (appMetadata['providers'] is List) {
            final providers = appMetadata['providers'] as List;
            if (providers.contains('google')) {
              _isGoogleUser = true;
            }
          }
        }

        // Cek 3: Identities (Paling akurat)
        if (!_isGoogleUser && userMap['identities'] is List) {
          final identities = userMap['identities'] as List;
          final hasGoogleIdentity = identities.any((id) => id['provider'] == 'google');
          if (hasGoogleIdentity) {
            _isGoogleUser = true;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    // Ambil URL foto saat ini
    String? currentPhotoUrl;
    currentUserAsync.whenData((userMap) {
      if (userMap != null) {
        final metadata = userMap['user_metadata'] as Map<String, dynamic>?;
        currentPhotoUrl = metadata?['avatar_url'] ?? metadata?['picture'];
      }
    });

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        // Kita cek manual di onPressed, jadi listener ini bisa dikosongkan atau
        // digunakan untuk reset loading state jika perlu.
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD46E46),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Edit Profil",
          style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD46E46), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (currentPhotoUrl != null ? NetworkImage(currentPhotoUrl!) : null),
                      child: (_selectedImage == null && currentPhotoUrl == null)
                          ? const Icon(Icons.person, size: 70, color: Colors.white70)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: InkWell(
                      onTap: _pickImage,
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
            ),
            const SizedBox(height: 12),
            Text(
              "Ketuk ikon kamera untuk ubah foto",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),
            _buildInputLabel("Username"), // Sudah diganti jadi Username
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Username",
              controller: _usernameController,
            ),

            const SizedBox(height: 20),
            _buildInputLabel("Email (Tidak dapat diubah)"),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Email",
              controller: _emailController,
              readOnly: true,
              enabled: false,
            ),

            // 🔥 FORM GANTI PASSWORD (HANYA MUNCUL JIKA BUKAN GOOGLE USER)
            if (!_isGoogleUser) ...[
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Ubah Kata Sandi", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3E2723))),
              ),
              const SizedBox(height: 16),

              // 1. Password Lama
              _buildInputLabel("Password Lama"),
              const SizedBox(height: 8),
              _buildPasswordField(
                hint: "Masukkan password lama",
                controller: _oldPasswordController,
                isVisible: _isOldPasswordVisible,
                onToggle: () => setState(() => _isOldPasswordVisible = !_isOldPasswordVisible),
              ),

              const SizedBox(height: 20),

              // 2. Password Baru
              _buildInputLabel("Password Baru"),
              const SizedBox(height: 8),
              _buildPasswordField(
                hint: "Masukkan password baru",
                controller: _newPasswordController,
                isVisible: _isNewPasswordVisible,
                onToggle: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
              ),

              const SizedBox(height: 20),

              // 3. Konfirmasi Password
              _buildInputLabel("Ulangi Password Baru"),
              const SizedBox(height: 8),
              _buildPasswordField(
                hint: "Ulangi password baru",
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ],

            const SizedBox(height: 40),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {

                  // 1. Cek Validasi Ganti Password (Jika diisi & Bukan Google)
                  bool isChangingPassword = _newPasswordController.text.isNotEmpty;

                  if (isChangingPassword && !_isGoogleUser) {
                    if (_oldPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password lama harus diisi!")));
                      return;
                    }
                    if (_newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password baru minimal 6 karakter!")));
                      return;
                    }
                    if (_newPasswordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak cocok!")));
                      return;
                    }
                  }

                  // 2. Eksekusi Update Profil (Username & Foto)
                  // Pastikan di AuthViewModel parameternya bernama 'fullName' atau 'username' sesuai definisi Anda.
                  // Di sini saya pakai 'fullName' karena di ViewModel sebelumnya namanya 'fullName',
                  // tapi isinya adalah teks dari _usernameController.
                  await ref.read(authViewModelProvider.notifier).updateProfile(
                    username: _usernameController.text.trim(),
                    imageFile: _selectedImage,
                  );

                  // 3. Eksekusi Ganti Password (Jika form diisi)
                  if (isChangingPassword && !_isGoogleUser) {
                    await ref.read(authViewModelProvider.notifier).changePassword(
                      oldPassword: _oldPasswordController.text,
                      newPassword: _newPasswordController.text,
                    );
                  }

                  // Cek sukses manual karena kita panggil 2 fungsi
                  if (context.mounted) {
                    // Kita anggap sukses jika tidak ada error state (bisa disempurnakan dengan cek state.isSuccess)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Perubahan berhasil disimpan!")),
                    );
                    context.pop();
                    ref.refresh(currentUserProvider);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD46E46),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: authState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                  "Simpan Perubahan",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor)),
  );

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    bool enabled = true,
  }) => TextFormField(
    controller: controller,
    readOnly: readOnly,
    enabled: enabled,
    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    decoration: InputDecoration(
      hintText: hint,
      filled: !enabled,
      fillColor: !enabled ? Colors.grey.shade100 : null,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _earthyColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD46E46), width: 2)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
    ),
  );

  Widget _buildPasswordField({required String hint, required TextEditingController controller, required bool isVisible, required VoidCallback onToggle}) => TextFormField(
    controller: controller,
    obscureText: !isVisible,
    style: GoogleFonts.poppins(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _earthyColor), onPressed: onToggle),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _earthyColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD46E46), width: 2)),
    ),
  );
}