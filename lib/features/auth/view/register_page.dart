import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../viewmodel/auth_viewmodel.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authState = ref.watch(authViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listener State
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        // [FIX] Kalau Register sukses, arahkan ke LOGIN, bukan Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.'), backgroundColor: Colors.green),
        );
        context.go('/login');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: size.height * 0.12,
                    child: Image.asset('assets/Logo.png', fit: BoxFit.contain),
                  ),
                  Text(
                    "GeoValid",
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInputLabel(l10n.username, isDark),
                  const SizedBox(height: 6),
                  _buildTextField(hint: l10n.username, controller: _usernameController, l10n: l10n, isDark: isDark),

                  const SizedBox(height: 12),

                  _buildInputLabel(l10n.email, isDark),
                  const SizedBox(height: 6),
                  _buildTextField(hint: l10n.email, controller: _emailController, isEmail: true, l10n: l10n, isDark: isDark),

                  const SizedBox(height: 12),

                  _buildInputLabel(l10n.password, isDark),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                      hint: "********",
                      controller: _passwordController,
                      isVisible: _isPasswordVisible,
                      onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      isMainPassword: true, // Enable validasi ketat
                      l10n: l10n,
                      isDark: isDark
                  ),

                  const SizedBox(height: 12),

                  _buildInputLabel(l10n.confirmPassword, isDark),
                  const SizedBox(height: 6),
                  _buildPasswordField(
                      hint: "********",
                      controller: _confirmPasswordController,
                      isVisible: _isConfirmPasswordVisible,
                      onToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      validationCompare: _passwordController,
                      l10n: l10n,
                      isDark: isDark
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                        if (_formKey.currentState!.validate()) {
                          ref.read(authViewModelProvider.notifier).register(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                            _usernameController.text.trim(),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(l10n.register, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(l10n.orLoginWith, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: authState.isLoading ? null : () => ref.read(authViewModelProvider.notifier).loginWithGoogle(),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                      ),
                      child: Image.asset('assets/google.png', height: 24),
                    ),
                  ),

                  const SizedBox(height: 24),

                  RichText(
                    text: TextSpan(
                      text: "${l10n.haveAccount} ",
                      style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                      children: [
                        TextSpan(
                          text: l10n.login,
                          style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600),
                          recognizer: TapGestureRecognizer()..onTap = () => context.go('/login'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF5D534A)
          ),
          children: [
            TextSpan(text: " *", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool isEmail = false,
    required AppLocalizations l10n,
    required bool isDark
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFF8D8D8D))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.fieldRequired;
        if (isEmail) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) return l10n.invalidEmail;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required String hint, required TextEditingController controller,
    required bool isVisible, required VoidCallback onToggle,
    bool isMainPassword = false, TextEditingController? validationCompare,
    required AppLocalizations l10n,
    required bool isDark
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey), onPressed: onToggle),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFF8D8D8D))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.fieldRequired;

        // [FIX] Validasi Sesuai Zod Backend (Huruf Besar, Angka, Simbol)
        if (isMainPassword) {
          if (value.length < 8) return "Password minimal 8 karakter";
          if (!value.contains(RegExp(r'[A-Z]'))) return "Harus ada huruf besar";
          if (!value.contains(RegExp(r'[0-9]'))) return "Harus ada angka";
          if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return "Harus ada simbol unik";
        }

        if (validationCompare != null && value != validationCompare.text) return l10n.passwordMismatch;
        return null;
      },
    );
  }
}