// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:network_image_mock/network_image_mock.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // Import Localization
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:geo_valid_app/l10n/app_localizations.dart';
//
// // Import Mocks
// import 'unit_test.mocks.dart';
//
// // Import Providers
// import 'package:geo_valid_app/features/auth/viewmodel/auth_viewmodel.dart';
// import 'package:geo_valid_app/features/chatbot/viewmodel/chat_viewmodel.dart';
// import 'package:geo_valid_app/features/detection/viewmodel/detection_viewmodel.dart';
// import 'package:geo_valid_app/features/profile/viewmodel/profile_viewmodel.dart';
//
// // Import Halaman
// import 'package:geo_valid_app/features/auth/view/login_page.dart';
// import 'package:geo_valid_app/features/chatbot/view/chat_page.dart';
// import 'package:geo_valid_app/features/detection/view/detection_page.dart';
// import 'package:geo_valid_app/features/profile/view/feedback_page.dart';
// import 'package:geo_valid_app/features/profile/view/edit_profile_page.dart';
//
// void main() {
//   final mockAuthRepo = MockAuthRepository();
//   final mockChatRepo = MockChatRepository();
//   final mockDetectionRepo = MockDetectionRepository();
//   final mockProfileRepo = MockProfileRepository();
//
//   setUpAll(() {
//     SharedPreferences.setMockInitialValues({});
//   });
//
//   Widget createWidgetUnderTest(Widget child) {
//     return ProviderScope(
//       overrides: [
//         authRepositoryProvider.overrideWithValue(mockAuthRepo),
//         chatRepositoryProvider.overrideWithValue(mockChatRepo),
//         detectionRepositoryProvider.overrideWithValue(mockDetectionRepo),
//         profileRepositoryProvider.overrideWithValue(mockProfileRepo),
//         currentUserProvider.overrideWith((ref) => Future.value(null)),
//       ],
//       child: MaterialApp(
//         localizationsDelegates: AppLocalizations.localizationsDelegates,
//         supportedLocales: AppLocalizations.supportedLocales,
//         locale: const Locale('id'),
//         home: child,
//       ),
//     );
//   }
//
//   group('Widget Testing - Komponen UI', () {
//     // 1. LOGIN PAGE
//     testWidgets('Login Page memiliki Field Email, Password dan Tombol Login', (WidgetTester tester) async {
//       await mockNetworkImagesFor(() async {
//         await tester.pumpWidget(createWidgetUnderTest(const LoginPage()));
//       });
//       await tester.pumpAndSettle();
//
//       expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
//       expect(find.byType(ElevatedButton), findsOneWidget);
//     });
//
//     // 2. CHAT PAGE
//     testWidgets('Chat Page memiliki ListView pesan dan Input field', (WidgetTester tester) async {
//       await mockNetworkImagesFor(() async {
//         await tester.pumpWidget(createWidgetUnderTest(const ChatPage()));
//       });
//       await tester.pumpAndSettle();
//
//       expect(find.byType(ListView), findsOneWidget);
//       expect(find.byType(TextField), findsOneWidget);
//       expect(find.byIcon(Icons.send_rounded), findsOneWidget);
//     });
//
//     // 3. DETECTION PAGE
//     testWidgets('Detection Page memiliki tombol navigasi ambil gambar', (WidgetTester tester) async {
//       await mockNetworkImagesFor(() async {
//         await tester.pumpWidget(createWidgetUnderTest(const DetectionPage()));
//       });
//
//       // [FIX] Gunakan pump() biasa, jangan pumpAndSettle().
//       // pumpAndSettle akan error karena ada CircularProgressIndicator (loading kamera) yang animasinya infinite.
//       await tester.pump(const Duration(milliseconds: 500));
//
//       expect(find.byType(Scaffold), findsOneWidget);
//
//       // [FIX] Sesuaikan icon dengan yang ada di detection_page.dart (Icons.camera & Icons.image)
//       // Tombol controls tetap muncul walaupun kamera loading (di dalam Stack)
//       final cameraBtn = find.byIcon(Icons.camera);
//       final galleryBtn = find.byIcon(Icons.image);
//
//       expect(cameraBtn, findsOneWidget);
//       expect(galleryBtn, findsOneWidget);
//     });
//
//     // 4. FEEDBACK PAGE
//     testWidgets('Feedback Page memiliki field input multiline dan tombol kirim', (WidgetTester tester) async {
//       await mockNetworkImagesFor(() async {
//         await tester.pumpWidget(createWidgetUnderTest(const FeedbackPage()));
//       });
//       await tester.pumpAndSettle();
//
//       // [FIX] FeedbackPage menggunakan TextField, BUKAN TextFormField
//       final feedbackField = find.byType(TextField);
//       final sendButton = find.byType(ElevatedButton);
//
//       expect(feedbackField, findsOneWidget);
//       expect(sendButton, findsOneWidget);
//     });
//
//     // 5. EDIT PROFILE
//     testWidgets('Edit Profile Page memiliki form input', (WidgetTester tester) async {
//       await mockNetworkImagesFor(() async {
//         await tester.pumpWidget(createWidgetUnderTest(const EditProfilePage()));
//       });
//       await tester.pumpAndSettle();
//
//       expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
//     });
//   });
// }