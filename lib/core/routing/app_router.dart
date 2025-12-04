import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import semua halaman
import '../../features/auth/view/splash_page.dart';
import '../../features/auth/view/launch_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/register_page.dart';
import '../../features/home/view/home_page.dart';
import '../../features/home/view/main_navigation.dart';
import '../../features/detection/view/detection_page.dart';
import '../../features/maps/view/maps_page.dart';
// import '../../features/chatbot/view/chatbot_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/profile/view/edit_profile_page.dart';
import '../../features/profile/view/about_page.dart';
import '../../features/detection/view/detection_result_page.dart';
import '../../features/detection/view/location_picker_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final path = state.uri.toString();
      final isAuthPage = path == '/splash' ||
          path == '/launch' ||
          path == '/login' ||
          path == '/register';

      // 1. Jika User SUDAH Login, tapi ada di halaman Auth -> Lempar ke Home
      if (isLoggedIn && isAuthPage) {
        return '/home';
      }

      // 2. Jika User BELUM Login, tapi mau masuk halaman dalam -> Lempar ke Launch
      if (!isLoggedIn && !isAuthPage) {
        return '/launch';
      }

      return null;
    },

    routes: [
      GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashPage()
      ),
      GoRoute(
          path: '/launch',
          builder: (_, __) => const LaunchPage()
      ),
      GoRoute(
          path: '/login',
          builder: (_, __) => const LoginPage()
      ),
      GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterPage()
      ),

      // --- MAIN ROUTES ---
      GoRoute(
          path: '/home',
          builder: (context, state) => const MainNavigation()
      ),

      // --- FEATURE ROUTES ---
      GoRoute(
          path: '/detection',
          builder: (_, __) => const DetectionPage()
      ),
      GoRoute(
          path: '/location-picker',
          builder: (_, __) => const LocationPickerPage()
      ),

      // 🔥 PERBAIKAN DI SINI: Tidak perlu passing parameter lagi
      GoRoute(
        path: '/result',
        builder: (context, state) {
          return const DetectionResultPage();
        },
      ),

      GoRoute(
          path: '/maps',
          builder: (_, __) => const MapsPage()
      ),
      // GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotPage()),

      // --- PROFILE ROUTES ---
      GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfilePage()
      ),
      GoRoute(
          path: '/edit-profile',
          builder: (_, __) => const EditProfilePage()
      ),
      GoRoute(
          path: '/about',
          builder: (_, __) => const AboutPage()
      ),
    ],
  );
}