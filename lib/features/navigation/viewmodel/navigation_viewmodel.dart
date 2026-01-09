import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

// [1] Provider untuk Index Tab (Global State agar bisa diakses dari page lain)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// [2] ViewModel untuk Logic inisialisasi (Permissions)
class MainNavigationViewModel extends StateNotifier<void> {
  MainNavigationViewModel() : super(null);

  Future<void> requestInitialPermissions() async {
    // Request permission secara batch
    await [
      Permission.camera,
      Permission.location,
      Permission.photos,
      // Tambahkan storage jika perlu untuk Android lama
      Permission.storage,
    ].request();
  }
}

final mainNavigationViewModelProvider = StateNotifierProvider<MainNavigationViewModel, void>((ref) {
  return MainNavigationViewModel();
});