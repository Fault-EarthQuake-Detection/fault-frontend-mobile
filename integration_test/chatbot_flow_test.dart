import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Untuk cek bubble chat
import 'package:geo_valid_app/main.dart' as app;

void mockPermissionHandler() {
  const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'checkPermissionStatus') return 1;
      if (methodCall.method == 'requestPermissions') {
        final List<dynamic> permissions = methodCall.arguments;
        final Map<int, int> result = {};
        for (var permission in permissions) result[permission] = 1;
        return result;
      }
      return null;
    },
  );
}

Future<void> delay([int seconds = 2]) async {
  await Future.delayed(Duration(seconds: seconds));
}

// Fungsi tunggu widget (agar tidak error jika loading lama)
Future<void> waitFor(WidgetTester tester, Finder finder, {int timeoutSec = 20}) async {
  int retries = 0;
  while (retries < timeoutSec) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(seconds: 1));
    retries++;
  }
  throw Exception("Timeout menunggu widget: $finder");
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  mockPermissionHandler();

  testWidgets('Chatbot Flow: Login -> RAG -> Gen -> Reset',
          (WidgetTester tester) async {

        // --- AKUN EXISTING ---
        const usernameExisting = "plugin";
        const passwordExisting = "plugin123";

        print("=== START TEST 2: CHATBOT ===");
        print("Login sebagai: $usernameExisting");

        app.main();
        await tester.pumpAndSettle();
        print("Menunggu Splash...");
        await delay(6);

        // =======================================================================
        // STEP 1: LOGIN (BYPASS REGISTER)
        // =======================================================================

        // Cek posisi: Launch Page atau Login Page
        // Jika ada tombol Daftar & Masuk (Launch Page) -> Klik Masuk
        final btnMasuk = find.widgetWithText(ElevatedButton, "Masuk");
        if (find.widgetWithText(ElevatedButton, "Daftar").evaluate().isNotEmpty) {
          print("Posisi Launch Page. Masuk ke Login Page...");
          await tester.tap(btnMasuk);
          await tester.pumpAndSettle();
          await delay(2);
        }

        // Pastikan di Login Page
        await waitFor(tester, find.text("Masuk"));
        print("Mengisi Login Form...");

        final formLogin = find.byType(TextFormField);
        await tester.enterText(formLogin.at(0), usernameExisting);
        await delay(1);
        await tester.enterText(formLogin.at(1), passwordExisting);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        await tester.tap(btnMasuk); // Tombol Masuk
        print("Login process...");
        await delay(8); // Tunggu API Login & Home Load
        await tester.pumpAndSettle();

        // =======================================================================
        // STEP 2: MASUK CHATBOT
        // =======================================================================
        print("Step 2: Masuk ke Fitur Chatbot");
        // Cari FAB Chatbot di Home
        await waitFor(tester, find.byType(FloatingActionButton));
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await delay(2);

        // Validasi Default Model = RAG
        expect(find.text("GeoValid RAG"), findsOneWidget);

        // =======================================================================
        // STEP 3: TANYA MODEL RAG
        // =======================================================================
        print("Step 3: Tanya 'kamu siapa?' (RAG)");
        final inputField = find.byType(TextField);
        final sendIcon = find.byIcon(Icons.send_rounded);

        await tester.enterText(inputField, "kamu siapa?");
        await tester.tap(sendIcon);
        await tester.pump(); // Update UI bubble user

        print("Menunggu jawaban RAG...");
        await delay(6);
        await tester.pumpAndSettle();

        // Cek apakah ada balasan (MarkdownBody)
        expect(find.byType(MarkdownBody), findsWidgets);
        print("Bot RAG Menjawab.");

        // =======================================================================
        // STEP 4: SWITCH MODEL -> GENERATIVE
        // =======================================================================
        print("Step 4: Switch ke Generative");
        await tester.tap(find.text("GeoValid RAG")); // Klik AppBar
        await tester.pumpAndSettle();

        await tester.tap(find.text("GeoValid Generative")); // Pilih Gen
        await tester.pumpAndSettle();

        expect(find.text("GeoValid Gen"), findsOneWidget); // Validasi Title

        // =======================================================================
        // STEP 5: TANYA MODEL GEN
        // =======================================================================
        print("Step 5: Tanya 'jelaskan apa itu sesar?' (Generative)");
        await tester.enterText(inputField, "jelaskan apa itu sesar?");
        await tester.tap(sendIcon);

        print("Menunggu jawaban Generative (agak lama)...");
        await delay(10); // Gen AI biasanya lebih lambat
        await tester.pumpAndSettle();

        expect(find.byType(MarkdownBody), findsWidgets);
        print("Bot Generative Menjawab.");

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton)); // Masuk Chat lagi
        await tester.pumpAndSettle();
        expect(find.text("jelaskan apa itu sesar?"), findsOneWidget);


        // =======================================================================
        // STEP 6: RESET CHAT & PERSISTENCE
        // =======================================================================
        print("Step 6: Hapus Percakapan & Cek Persistence");

        // Hapus
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, "Ya, Mulai Baru"));
        await tester.pumpAndSettle();

        // Verifikasi bubble chat "sesar" hilang
        expect(find.text("jelaskan apa itu sesar?"), findsNothing);
        print("Chat Reset.");

        // Keluar ke Home -> Masuk Lagi
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton)); // Masuk Chat lagi
        await tester.pumpAndSettle();

        // Verifikasi tetap bersih
        expect(find.text("jelaskan apa itu sesar?"), findsNothing);
        // Verifikasi pesan welcome ada
        expect(find.textContaining("Percakapan baru"), findsOneWidget);

        print("=== TEST 2 CHATBOT SELESAI & SUKSES ===");
      });
}