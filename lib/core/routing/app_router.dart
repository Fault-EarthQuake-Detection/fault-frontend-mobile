// lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/view/splash_page.dart';
import '../../features/auth/view/launch_page.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/register_page.dart';

import '../../features/home/data/feed_item.dart';
import '../../features/home/view/bmkg_detail_page.dart';

import '../../features/detection/view/detection_page.dart';
import '../../features/detection/view/detection_result_page.dart';
import '../../features/detection/view/location_picker_page.dart';

import '../../features/maps/view/maps_page.dart';

import '../../features/navigation/view/main_navigation.dart';
import '../../features/profile/view/feedback_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/profile/view/edit_profile_page.dart';
import '../../features/profile/view/about_page.dart';

import '../../features/settings/view/settings_page.dart';

// [TAMBAHAN] Import Chatbot
import '../../features/chatbot/view/chat_page.dart';

import '../services/session_service.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      final isLoggedIn = SessionService.hasCachedToken();
      final path = state.uri.toString();

      if (path == '/splash') {
        return null;
      }

      final isAuthPage = path == '/launch' || path == '/login' || path == '/register';

      if (isLoggedIn && isAuthPage) {
        return '/home';
      }

      if (!isLoggedIn && !isAuthPage) {
        return '/launch';
      }

      return null;
    },

    routes: [
      // --- AUTH ROUTES ---
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/launch', builder: (_, __) => const LaunchPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      // --- MAIN ROUTES ---
      GoRoute(path: '/home', builder: (_, __) => const MainNavigation()),

      // --- CHATBOT ROUTE ---
      GoRoute(path: '/chatbot', builder: (_, __) => const ChatPage()),

      // --- DETECTION ROUTES ---
      GoRoute(path: '/detection', builder: (_, __) => const DetectionPage()),
      GoRoute(path: '/location-picker', builder: (_, __) => const LocationPickerPage()),
      GoRoute(
        path: '/detection-result',
        builder: (context, state) {
          final historyData = state.extra as Map<String, dynamic>?;
          return DetectionResultPage(historyData: historyData);
        },
      ),

      // --- HOME FEED ROUTES ---
      GoRoute(
        path: '/bmkg-detail',
        builder: (context, state) {
          final item = state.extra as FeedItem;
          return BMKGDetailPage(item: item);
        },
      ),

      // --- MAPS ---
      GoRoute(path: '/maps', builder: (_, __) => const MapsPage()),

      // --- PROFILE & SETTINGS ROUTES ---
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfilePage()),
      GoRoute(path: '/feedback', builder: (_, __) => const FeedbackPage()),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
}