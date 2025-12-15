// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Supabase first (for storage / optional supabase flows)
  await SupabaseService().initialize();

  // Load cached token for sync routing
  await SessionService.load();

  runApp(const ProviderScope(child: GeoValidApp()));
}

class GeoValidApp extends StatelessWidget {
  const GeoValidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GeoValid',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
