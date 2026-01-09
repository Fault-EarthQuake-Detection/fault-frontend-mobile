import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/profile_viewmodel.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Status apakah user login via Google
  bool _isGoogleUser = false;

  String? _userId;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  void _loadUserData() async {
    final userMap = await ref.read(currentUserProvider.future);
    if (userMap != null) {
      if (mounted) {
        setState(() {
          _userId = userMap['id'];
          _emailController.text = userMap['email'] ?? "";

          final metadata = userMap['user_metadata'] as Map<String, dynamic>?;
          _usernameController.text = metadata?['username'] ?? metadata?['full_name'] ?? "";

          // Cek Provider (Google atau Email)
          final appMetadata = userMap['app_metadata'] as Map<String, dynamic>?;
          final provider = appMetadata?['provider'];
          final providers = appMetadata?['providers'] as List?;

          // Logic deteksi Google User
          if (provider == 'google' || (providers != null && providers.contains('google'))) {
            _isGoogleUser = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(profileViewModelProvider, (prev, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.saveChanges}!")));
        context.pop();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: Colors.red));
      }
    });

    final currentUserAsync = ref.watch(currentUserProvider);
    String? currentPhotoUrl;
    currentUserAsync.whenData((user) => currentPhotoUrl = user?['user_metadata']?['avatar_url']);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- FOTO PROFIL ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (currentPhotoUrl != null ? NetworkImage(currentPhotoUrl!) : null),
                    child: (_selectedImage == null && currentPhotoUrl == null)
                        ? const Icon(Icons.person, size: 70, color: Colors.white70) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 4,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.changePhoto, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 32),

            // --- USERNAME (Bisa Diedit) ---
            _buildTextField(
                label: l10n.username,
                controller: _usernameController,
                isDark: isDark
            ),

            const SizedBox(height: 16),

            // --- EMAIL (DIBEKUKAN / READ ONLY) ---
            _buildTextField(
              label: l10n.email,
              controller: _emailController,
              readOnly: true, // Bekukan email untuk semua user (karena backend tidak update email)
              isDark: isDark,
              suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey), // Indikator gembok
            ),

            // --- GANTI PASSWORD (Hanya jika BUKAN user Google) ---
            if (!_isGoogleUser) ...[
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: Text("Ubah Password", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),

              _buildPasswordField(l10n.oldPassword, _oldPasswordController, _isOldPasswordVisible, () => setState(() => _isOldPasswordVisible = !_isOldPasswordVisible), isDark),
              const SizedBox(height: 16),
              _buildPasswordField(l10n.newPassword, _newPasswordController, _isNewPasswordVisible, () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible), isDark),
              const SizedBox(height: 16),
              _buildPasswordField(l10n.repeatPassword, _confirmPasswordController, _isConfirmPasswordVisible, () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible), isDark),
            ],

            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: profileState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: profileState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.saveChanges, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final isChangingPass = _newPasswordController.text.isNotEmpty;

    // Validasi Password hanya jika bukan user Google
    if (isChangingPass && !_isGoogleUser) {
      if (_oldPasswordController.text.isEmpty) return _showError(l10n.fieldRequired);
      if (_newPasswordController.text.length < 6) return _showError(l10n.passwordLength);
      if (_newPasswordController.text != _confirmPasswordController.text) return _showError(l10n.passwordMismatch);
    }

    // Update Profil (Username & Foto)
    await ref.read(profileViewModelProvider.notifier).updateProfile(
      username: _usernameController.text.trim(),
      imageFile: _selectedImage,
      currentUserId: _userId,
    );

    // Update Password (Jika diisi & bukan Google user)
    if (isChangingPass && !_isGoogleUser) {
      await ref.read(profileViewModelProvider.notifier).changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // --- WIDGET HELPER ---

  // Update: Menambahkan parameter suffixIcon
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: readOnly,
            // Warna abu-abu jika readOnly (dibekukan)
            fillColor: readOnly ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon, // Ikon gembok masuk sini
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController ctrl, bool visible, VoidCallback toggle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: !visible,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: toggle),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}