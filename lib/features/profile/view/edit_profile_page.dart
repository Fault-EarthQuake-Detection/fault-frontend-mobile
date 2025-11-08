import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final Color _earthyColor = const Color(0xFF8D8D8D);
  final Color _labelColor = const Color(0xFF5D534A);

  @override
  Widget build(BuildContext context) {
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
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 70, color: Colors.white70),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: InkWell(
                      onTap: () => print("Ganti Foto"),
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
              "Ketuk untuk ubah foto",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _buildInputLabel("Username"),
            const SizedBox(height: 8),
            _buildTextField(hint: "Username saat ini", initialValue: "GeoValid User"),
            const SizedBox(height: 20),
            _buildInputLabel("Email"),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Email saat ini",
              initialValue: "user@geovalid.com",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildInputLabel("Password Baru (Opsional)"),
            const SizedBox(height: 8),
            _buildPasswordField(
              hint: "********",
              isVisible: _isPasswordVisible,
              onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            const SizedBox(height: 20),
            _buildInputLabel("Ulangi Password Baru"),
            const SizedBox(height: 8),
            _buildPasswordField(
              hint: "********",
              isVisible: _isConfirmPasswordVisible,
              onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil berhasil diperbarui!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD46E46),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
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

  Widget _buildTextField({required String hint, String? initialValue, TextInputType? keyboardType}) => TextFormField(
    initialValue: initialValue,
    keyboardType: keyboardType,
    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _earthyColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD46E46), width: 2)),
    ),
  );

  Widget _buildPasswordField({required String hint, required bool isVisible, required VoidCallback onToggle}) => TextFormField(
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
