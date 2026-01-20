import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Penting untuk MethodChannel
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geo_valid_app/main.dart' as app;

// --- FUNGSI MOCK PERMISSION ---
// Fungsi ini akan mencegat request permission dan otomatis bilang "GRANTED"
void mockPermissionHandler() {
  const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
        (MethodCall methodCall) async {
      // Return value 1 artinya PermissionStatus.granted

      if (methodCall.method == 'checkPermissionStatus') {
        return 1; // Granted
      }
      else if (methodCall.method == 'requestPermissions') {
        // Apapun permission yang diminta, kita jawab Granted semua
        final List<dynamic> permissions = methodCall.arguments;
        final Map<int, int> result = {};
        for (var permission in permissions) {
          result[permission] = 1; // 1 = Granted
        }
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

  // [PENTING] Panggil Mock Permission sebelum test jalan
  mockPermissionHandler();

  testWidgets('Full Flow: Daftar -> Login -> Edit Profil -> Keluar',
          (WidgetTester tester) async {

        // --- 0. DATA TESTER ---
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomNum = Random().nextInt(1000);

        final usernameBaru = "UserTes_$randomNum";
        final emailBaru = "tes.$timestamp@geovalid.com";
        final passwordValid = "Password@123";
        final usernameEdit = "User_Updated_$randomNum";

        print("=== MULAI TESTING ===");
        print("Akun Test: $emailBaru");

        // 1. JALANKAN APLIKASI
        await delay(3);

        app.main();
        await tester.pumpAndSettle();

        print("Menunggu Splash Screen selesai...");
        await delay(6);

        // =======================================================================
        // STEP 1: LAUNCH PAGE
        // =======================================================================
        print("Step 1: Di Launch Page -> Tekan tombol 'Daftar'");

        final buttonsLaunch = find.byType(ElevatedButton);
        // Safety check: Kalau tombol tidak ketemu, mungkin permission belum ke-load atau nyangkut
        // Tapi dengan Mock Permission, harusnya lancar.
        expect(buttonsLaunch, findsAtLeastNWidgets(2));

        await tester.tap(buttonsLaunch.at(1));
        await tester.pumpAndSettle();
        await delay(2);

        // =======================================================================
        // STEP 2: REGISTER PAGE
        // =======================================================================
        print("Step 2: Mengisi Form Pendaftaran");

        final formRegister = find.byType(TextFormField);

        await tester.enterText(formRegister.at(0), usernameBaru);
        await delay(1);
        await tester.enterText(formRegister.at(1), emailBaru);
        await delay(1);
        await tester.enterText(formRegister.at(2), passwordValid);
        await delay(1);
        await tester.enterText(formRegister.at(3), passwordValid);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        print("Step 2b: Tekan Tombol Daftar");
        final btnDaftar = find.byType(ElevatedButton).first;
        await tester.ensureVisible(btnDaftar);
        await tester.tap(btnDaftar);

        await delay(8);
        await tester.pumpAndSettle();

        // =======================================================================
        // STEP 3: LOGIN PAGE
        // =======================================================================
        print("Step 3: Login dengan akun yang baru dibuat");

        expect(find.text('Masuk'), findsAtLeastNWidgets(1));

        final formLogin = find.byType(TextFormField);

        await tester.enterText(formLogin.at(0), usernameBaru);
        await delay(1);
        await tester.enterText(formLogin.at(1), passwordValid);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(1);

        print("Step 3b: Tekan Tombol Masuk");
        await tester.tap(find.byType(ElevatedButton).first);

        // Saat tombol masuk ditekan, aplikasi akan ke Home dan memanggil Permission Handler.
        // Karena sudah kita Mock di atas, tidak akan ada popup dan tidak ada crash.
        await delay(10);
        await tester.pumpAndSettle();

        // =======================================================================
        // STEP 4: MASUK KE PROFIL
        // =======================================================================
        print("Step 4: Navigasi ke Halaman Profil");

        final navProfil = find.byIcon(Icons.person).last;
        await tester.tap(navProfil);

        await tester.pumpAndSettle();
        await delay(2);

        // =======================================================================
        // STEP 5: EDIT PROFIL
        // =======================================================================
        print("Step 5: Klik Menu 'Edit Profil'");

        final menuEdit = find.byIcon(Icons.edit);
        await tester.scrollUntilVisible(menuEdit, 500, scrollable: find.byType(Scrollable).first);
        await tester.tap(menuEdit);

        await tester.pumpAndSettle();
        await delay(2);

        print("Step 6: Mengganti Username");
        final formEdit = find.byType(TextFormField);

        await tester.tap(formEdit.at(0));
        await tester.enterText(formEdit.at(0), '');
        await tester.enterText(formEdit.at(0), usernameEdit);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await delay(2);

        print("Step 6b: Simpan Perubahan");
        final btnSimpan = find.byType(ElevatedButton).first;
        await tester.ensureVisible(btnSimpan);
        await tester.tap(btnSimpan);

        await delay(6);
        await tester.pumpAndSettle();

        expect(find.text(usernameEdit), findsOneWidget);
        print("Verifikasi OK: Nama berubah jadi $usernameEdit");

        // =======================================================================
        // STEP 7: LOGOUT
        // =======================================================================
        print("Step 7: Keluar Aplikasi");

        final menuLogout = find.byIcon(Icons.logout);
        await tester.scrollUntilVisible(menuLogout, 500, scrollable: find.byType(Scrollable).first);
        await tester.tap(menuLogout);

        await tester.pumpAndSettle();
        await delay(2);

        print("Step 7b: Konfirmasi Dialog");
        final btnYaKeluar = find.widgetWithText(ElevatedButton, "Ya, Keluar");
        await tester.tap(btnYaKeluar);

        await delay(4);
        await tester.pumpAndSettle();

        expect(find.text('Masuk'), findsAtLeastNWidgets(1));

        print("=== TESTING SELESAI & SUKSES ===");
      });
}