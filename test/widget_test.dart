import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [WAJIB] Untuk MethodChannel
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart'; // [WAJIB] Untuk 'when'
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geo_valid_app/l10n/app_localizations.dart';

import 'unit_test.mocks.dart';

import 'package:geo_valid_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:geo_valid_app/features/chatbot/viewmodel/chat_viewmodel.dart';
import 'package:geo_valid_app/features/detection/viewmodel/detection_viewmodel.dart';
import 'package:geo_valid_app/features/profile/viewmodel/profile_viewmodel.dart';

import 'package:geo_valid_app/features/auth/view/login_page.dart';
import 'package:geo_valid_app/features/chatbot/view/chat_page.dart';
import 'package:geo_valid_app/features/detection/view/detection_page.dart';
import 'package:geo_valid_app/features/profile/view/feedback_page.dart';
import 'package:geo_valid_app/features/profile/view/edit_profile_page.dart';

import 'package:geo_valid_app/features/chatbot/data/chat_message.dart';

void main() {
  final mockAuthRepo = MockAuthRepository();
  final mockChatRepo = MockChatRepository();
  final mockDetectionRepo = MockDetectionRepository();
  final mockProfileRepo = MockProfileRepository();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    const MethodChannel('flutter.baseflow.com/permissions/methods')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'checkPermissionStatus') {
        return 1; // 1 = PermissionStatus.granted
      } else if (methodCall.method == 'requestPermissions') {
        return {1: 1};
      }
      return null;
    });

    const MethodChannel('plugins.flutter.io/camera')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'availableCameras') return [];
      if (methodCall.method == 'initialize') return null;
      return null;
    });

    when(mockChatRepo.loadLocalChat()).thenAnswer((_) async => <ChatMessage>[]);
  });

  Widget createWidgetUnderTest(Widget child) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        chatRepositoryProvider.overrideWithValue(mockChatRepo),
        detectionRepositoryProvider.overrideWithValue(mockDetectionRepo),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        currentUserProvider.overrideWith((ref) => Future.value(null)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
        home: child,
      ),
    );
  }

  group('Widget Testing - Komponen UI', () {

    testWidgets('Login Page memiliki Field Username, Password dan Tombol Login', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(const LoginPage()));
      });
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text("GeoValid"), findsOneWidget);
    });

    testWidgets('Chat Page memiliki ListView pesan dan Input field', (WidgetTester tester) async {

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(const ChatPage()));
      });

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Detection Page memiliki tombol capture walaupun kamera loading', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(const DetectionPage()));
      });

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);

      final cameraBtn = find.byIcon(Icons.camera);
      final galleryBtn = find.byIcon(Icons.image);

      expect(cameraBtn, findsOneWidget, reason: "Tombol Shutter harusnya muncul");
      expect(galleryBtn, findsOneWidget, reason: "Tombol Galeri harusnya muncul");
    });

    testWidgets('Feedback Page memiliki field input multiline dan tombol kirim', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(const FeedbackPage()));
      });
      await tester.pumpAndSettle();

      final feedbackField = find.byType(TextField);
      final sendButton = find.byType(ElevatedButton);

      expect(feedbackField, findsOneWidget);
      expect(sendButton, findsOneWidget);
      expect(find.text("Kirim"), findsOneWidget);
    });

    testWidgets('Edit Profile Page memiliki form input', (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(createWidgetUnderTest(const EditProfilePage()));
      });
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.text("Simpan Perubahan"), findsOneWidget);
    });
  });
}