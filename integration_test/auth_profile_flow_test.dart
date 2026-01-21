import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geo_valid_app/main.dart' as app;

// --- MOCK PERMISSION ---
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  mockPermissionHandler();

  testWidgets('Auth Flow: Validasi Form -> Register -> Login -> Edit -> Logout -> Cek Duplikat',
          (WidgetTester tester) async {

        // --- DATA DUMMY ---
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomNum = Random().nextInt(1000);

        final usernameBaru = "UserTes_$randomNum";
        final emailBaru = "tes.$timestamp@geovalid.com";
        final passwordValid = "Password@123";
        final usernameEdit = "User_Updated_$randomNum";

        print("=== START TEST 1: AUTH & PROFILE ===");
        print("Email Target: $emailBaru");

        app.main();
        await tester.pumpAndSettle();
        await delay(6); // Tunggu Splash

        // =======================================================================
        // STEP 1: MASUK KE REGISTER PAGE
        // =======================================================================
        print("Step 1: Masuk ke Register Page");
        final buttonsLaunch = find.byType(ElevatedButton);
        expect(buttonsLaunch, findsAtLeastNWidgets(2));
        await tester.tap(buttonsLaunch.at(1)); // Tombol Daftar
        await tester.pumpAndSettle();
        await delay(2);

        // =======================================================================
        // STEP 2: NEGATIVE TEST (VALIDASI FORM SALAH)
        // =======================================================================
        print("Step 2: Negative Test - Input Salah");

        final formRegister = find.byType(TextFormField);

        await tester.enterText(formRegister.at(0), "User");
        await tester.enterText(formRegister.at(1), "ini_bukan_email");
        await tester.enterText(formRegister.at(2), "123");
        await tester.enterText(formRegister.at(3), "123");

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pumpAndSettle();

        expect(find.text("Daftar"), findsOneWidget);
        print("Sukses: Validasi form berjalan.");
        await delay(2);

        // =======================================================================
        // STEP 3: REGISTER SUKSES (DATA BENAR)
        // =======================================================================
        print("Step 3: Register dengan Data Benar");

        await tester.enterText(formRegister.at(0), usernameBaru);
        await tester.enterText(formRegister.at(1), emailBaru);
        await tester.enterText(formRegister.at(2), passwordValid);
        await tester.enterText(formRegister.at(3), passwordValid);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        // [FIX] Pastikan tombol terlihat (kadang tertutup keyboard di layar kecil)
        final btnRegister = find.byType(ElevatedButton).first;
        await tester.ensureVisible(btnRegister);
        await tester.tap(btnRegister);

        await delay(8); // Tunggu API Register
        await tester.pumpAndSettle();

        expect(find.text('Masuk'), findsOneWidget);
        print("Register Berhasil -> Pindah ke Login Page.");

        // =======================================================================
        // STEP 4: LOGIN PAGE
        // =======================================================================
        print("Step 4: Login dengan Akun Baru");
        final formLogin = find.byType(TextFormField);

        await tester.enterText(formLogin.at(0), usernameBaru);
        await delay(1);
        await tester.enterText(formLogin.at(1), passwordValid);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        await tester.tap(find.byType(ElevatedButton).first);

        await delay(10); // Tunggu Login
        await tester.pumpAndSettle();

        // =======================================================================
        // STEP 5: EDIT PROFILE
        // =======================================================================
        print("Step 5: Edit Profile (Ganti Username)");
        await tester.tap(find.byIcon(Icons.person).last);
        await tester.pumpAndSettle();
        await delay(2);

        // [FIX] Scroll ke tombol edit jika perlu
        final editMenu = find.byIcon(Icons.edit);
        await tester.scrollUntilVisible(editMenu, 500, scrollable: find.byType(Scrollable).first);
        await tester.tap(editMenu);

        await tester.pumpAndSettle();
        await delay(2);

        // Ganti Nama
        final formEdit = find.byType(TextFormField);
        await tester.tap(formEdit.at(0));
        await tester.enterText(formEdit.at(0), '');
        await tester.enterText(formEdit.at(0), usernameEdit);

        // [CRITICAL FIX] Tutup keyboard & pastikan tombol terlihat
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(2);

        final btnSimpan = find.byType(ElevatedButton).first;
        // Scroll sampai tombol Simpan benar-benar terlihat agar tidak miss-click
        await tester.scrollUntilVisible(btnSimpan, 500, scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle(); // Tunggu scroll selesai
        await tester.tap(btnSimpan);

        await delay(6); // Tunggu API Update
        await tester.pumpAndSettle();

        // Verifikasi: Kita harus sudah BALIK ke Profile Page
        // Indikatornya: Ada tombol/icon "Edit" lagi (karena di edit page tidak ada icon edit menu)
        expect(find.byIcon(Icons.edit), findsOneWidget);
        // Dan teks nama baru ada
        expect(find.text(usernameEdit), findsOneWidget);
        print("Username berhasil diubah & Kembali ke Profile Page.");

        // =======================================================================
        // STEP 6: LOGOUT
        // =======================================================================
        print("Step 6: Logout");

        final logoutIcon = find.byIcon(Icons.logout);
        // [FIX] Scroll dulu ke bawah karena Logout ada di paling bawah
        await tester.scrollUntilVisible(logoutIcon, 500, scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();

        await tester.tap(logoutIcon);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, "Ya, Keluar"));
        await delay(4);
        await tester.pumpAndSettle();

        expect(find.text('Masuk'), findsOneWidget);

        // =======================================================================
        // STEP 7: NEGATIVE TEST (REGISTER DUPLIKAT)
        // =======================================================================
        print("Step 7: Tes Register Ulang (Harus Gagal)");

        final richTextFinder = find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            final text = widget.text.toPlainText();
            return text.contains("Daftar") || text.contains("Register");
          }
          return false;
        });

        if (richTextFinder.evaluate().isNotEmpty) {
          final bottomRight = tester.getBottomRight(richTextFinder.last);
          await tester.tapAt(bottomRight - const Offset(10, 5));
        } else {
          await tester.tap(find.text("Daftar"));
        }
        await tester.pumpAndSettle();
        await delay(2);

        final formRegDup = find.byType(TextFormField);
        await tester.enterText(formRegDup.at(0), "User_Iseng");
        await tester.enterText(formRegDup.at(1), emailBaru); // Email DUPLIKAT
        await tester.enterText(formRegDup.at(2), passwordValid);
        await tester.enterText(formRegDup.at(3), passwordValid);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        // [FIX] Ensure visible again
        final btnRegDup = find.byType(ElevatedButton).first;
        await tester.ensureVisible(btnRegDup);
        await tester.tap(btnRegDup);

        await delay(5);
        await tester.pumpAndSettle();

        final snackBar = find.byType(SnackBar);
        if (snackBar.evaluate().isNotEmpty) {
          print("OK: SnackBar Error muncul.");
        }

        expect(find.text("Daftar"), findsAtLeastNWidgets(1));
        expect(find.text("Masuk"), findsNothing);

        print("=== TEST 1 SELESAI: Validasi, Flow, & Error Handling Aman ===");
      });
}