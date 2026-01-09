// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Import Core Services
import 'core/services/supabase_service.dart';
import 'core/services/session_service.dart';
import 'core/routing/app_router.dart';
import 'core/constants/app_theme.dart';

// Import ViewModel Settings
import 'features/settings/viewmodel/settings_viewmodel.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService().initialize();
  await SessionService.load();

  runApp(const ProviderScope(child: GeoValidApp()));
}

class GeoValidApp extends ConsumerWidget {
  const GeoValidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'GeoValid',
      debugShowCheckedModeBanner: false,

      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],

      routerConfig: AppRouter.router,
    );
  }
}