import 'package:go_router/go_router.dart';

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
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/launch', builder: (_, __) => const LaunchPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/home', builder: (context, state) => const MainNavigation()),
      GoRoute(path: '/detection', builder: (_, __) => const DetectionPage()),
      GoRoute(path: '/maps', builder: (_, __) => const MapsPage()),
      // GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfilePage()),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(path: '/result', builder: (_, __) => const DetectionResultPage()),
      GoRoute(path: '/location-picker', builder: (_, __) => const LocationPickerPage()),

    ],
  );
}
