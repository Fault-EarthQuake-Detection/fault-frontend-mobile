import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import '../../auth/viewmodel/auth_viewmodel.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isGoogleUser = false; // Flag untuk cek login Google
  File? _selectedImage; // Untuk menampung gambar baru sementara

  final Color _earthyColor = const Color(0xFF8D8D8D);
  final Color _labelColor = const Color(0xFF5D534A);

  @override
  void initState() {
    super.initState();
    // Inisialisasi data awal
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      _emailController.text = user.email ?? "";

      final metadata = user.userMetadata;
      _usernameController.text = metadata?['full_name'] ?? metadata?['name'] ?? "";

      // Cek apakah login via Google (identities provider = google)
      final identities = user.identities;
      if (identities != null && identities.isNotEmpty) {
        // Cek jika salah satu providernya google
        _isGoogleUser = identities.any((element) => element.provider == 'google');
      }
    }
  }

  // Fungsi Pilih Gambar
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

    // Ambil foto saat ini untuk ditampilkan jika belum pilih gambar baru
    final currentUser = ref.watch(currentUserProvider).value;
    final currentPhotoUrl = currentUser?.userMetadata?['avatar_url'] ?? currentUser?.userMetadata?['picture'];

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        context.pop(); // Kembali ke profil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
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

            // 🔹 AVATAR SECTION
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
                          ? FileImage(_selectedImage!) as ImageProvider // Foto baru dari galeri
                          : (currentPhotoUrl != null
                          ? NetworkImage(currentPhotoUrl) // Foto lama dari URL
                          : null),
                      child: (_selectedImage == null && currentPhotoUrl == null)
                          ? const Icon(Icons.person, size: 70, color: Colors.white70)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: InkWell(
                      onTap: _pickImage, // Panggil fungsi pick image
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

            // 🔹 INPUT FIELDS
            _buildInputLabel("Nama Lengkap"),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Nama Lengkap",
              controller: _usernameController,
            ),

            const SizedBox(height: 20),
            _buildInputLabel("Email (Tidak dapat diubah)"),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Email",
              controller: _emailController,
              readOnly: true, // Email sebaiknya tidak diubah sembarangan di edit profile sederhana
              enabled: false,
            ),

            // 🔹 PASSWORD SECTION (HANYA MUNCUL JIKA BUKAN GOOGLE USER)
            if (!_isGoogleUser) ...[
              const SizedBox(height: 20),
              _buildInputLabel("Password Baru (Opsional)"),
              const SizedBox(height: 8),
              _buildPasswordField(
                hint: "Biarkan kosong jika tidak ingin ubah",
                controller: _passwordController,
                isVisible: _isPasswordVisible,
                onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),

              const SizedBox(height: 20),
              _buildInputLabel("Ulangi Password Baru"),
              const SizedBox(height: 8),
              _buildPasswordField(
                hint: "********",
                controller: _confirmPasswordController,
                isVisible: _isConfirmPasswordVisible,
                onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ],

            const SizedBox(height: 40),

            // 🔹 TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : () {
                  // Validasi Password jika diisi
                  if (!_isGoogleUser &&
                      _passwordController.text.isNotEmpty &&
                      _passwordController.text != _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password konfirmasi tidak cocok!")),
                    );
                    return;
                  }

                  // Panggil Update Profil
                  ref.read(authViewModelProvider.notifier).updateProfile(
                    fullName: _usernameController.text.trim(),
                    imageFile: _selectedImage, // Kirim file gambar jika ada
                    password: _passwordController.text.isNotEmpty
                        ? _passwordController.text
                        : null,
                  );
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

  // Helper Widgets
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