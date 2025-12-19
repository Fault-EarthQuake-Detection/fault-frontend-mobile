// lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/view/splash_page.dart';
import '../../features/auth/view/launch_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/register_page.dart';
import '../../features/home/view/main_navigation.dart';
import '../../features/detection/view/detection_page.dart';
import '../../features/detection/view/detection_result_page.dart';
import '../../features/detection/view/location_picker_page.dart';
import '../../features/maps/view/maps_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/profile/view/edit_profile_page.dart';
import '../../features/profile/view/about_page.dart';
import '../services/session_service.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      final isLoggedIn = SessionService.hasCachedToken();
      final path = state.uri.toString();

      final inAuthFlow = path == '/splash' || path == '/launch' || path == '/login' || path == '/register';

      if (isLoggedIn && inAuthFlow) return '/home';
      if (!isLoggedIn && !inAuthFlow) return '/launch';
      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/launch', builder: (_, __) => const LaunchPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      GoRoute(path: '/home', builder: (_, __) => const MainNavigation()),

      GoRoute(path: '/detection', builder: (_, __) => const DetectionPage()),
      GoRoute(path: '/location-picker', builder: (_, __) => const LocationPickerPage()),
      GoRoute(path: '/detection-result', builder: (_, __) => const DetectionResultPage()),

      // GoRoute(path: '/maps', builder: (_, __) => const MapsPage()),

      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfilePage()),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
    ],
  );
}
