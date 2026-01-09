import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
// Import Auto-generated Localization
import '../../../l10n/app_localizations.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Akses string dari .arb via context
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle), // Menggunakan string dari .arb
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              // Gunakan warna dari AppColors/Theme context
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                // --- Dark Mode Switch ---
                SwitchListTile(
                  value: isDark,
                  activeColor: AppColors.primary,
                  title: Text(
                    l10n.themeTitle,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.themeSubtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dark_mode, color: Colors.purple),
                  ),
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme(val);
                  },
                ),

                Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                // --- Language Dropdown ---
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.language, color: Colors.blue),
                  ),
                  title: Text(
                    l10n.langTitle,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.langSubtitle,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: locale.languageCode,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      // dropdownColor handled by Theme
                      style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500
                      ),
                      items: const [
                        DropdownMenuItem(value: 'id', child: Text("🇮🇩 ID")),
                        DropdownMenuItem(value: 'en', child: Text("🇺🇸 EN")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(localeProvider.notifier).changeLocale(val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}