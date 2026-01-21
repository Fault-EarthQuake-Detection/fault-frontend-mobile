// import 'dart:io'; // Wajib untuk File
// import 'package:flutter_test/flutter_test.dart';
// import 'package:geo_valid_app/features/home/data/home_repository.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// // Import Repository
// import 'package:geo_valid_app/features/auth/data/auth_repository.dart';
// import 'package:geo_valid_app/features/chatbot/data/chat_repository.dart';
// import 'package:geo_valid_app/features/detection/data/detection_repository.dart';
// import 'package:geo_valid_app/features/profile/data/profile_repository.dart';
//
// // Import ViewModel
// import 'package:geo_valid_app/features/auth/viewmodel/auth_viewmodel.dart';
// import 'package:geo_valid_app/features/chatbot/viewmodel/chat_viewmodel.dart';
// import 'package:geo_valid_app/features/detection/viewmodel/detection_viewmodel.dart';
// import 'package:geo_valid_app/features/profile/viewmodel/profile_viewmodel.dart';
//
// // Generate Mocks
// @GenerateMocks([
//   AuthRepository,
//   ChatRepository,
//   DetectionRepository,
//   ProfileRepository,
//   HomeRepository
// ])
// import 'unit_test.mocks.dart';
//
// // Mock Ref Riverpod
// class MockRef extends Mock implements Ref {}
//
// void main() {
//   late MockAuthRepository mockAuthRepo;
//   late MockChatRepository mockChatRepo;
//   late MockDetectionRepository mockDetectionRepo;
//   late MockProfileRepository mockProfileRepo;
//   late MockRef mockRef;
//
//   setUp(() {
//     mockAuthRepo = MockAuthRepository();
//     mockChatRepo = MockChatRepository();
//     mockDetectionRepo = MockDetectionRepository();
//     mockProfileRepo = MockProfileRepository();
//     mockRef = MockRef();
//   });
//
//   group('Unit Testing - Fitur Utama', () {
//     // 1. AUTH: Login Success
//     test('AuthViewModel - Login Berhasil mengubah state menjadi Success', () async {
//       final viewModel = AuthViewModel(mockAuthRepo, mockRef);
//
//       when(mockAuthRepo.login(username: 'user@test.com', password: 'password'))
//           .thenAnswer((_) async => {});
//
//       await viewModel.login('user@test.com', 'password');
//
//       expect(viewModel.state.isLoading, false);
//       expect(viewModel.state.isSuccess, true);
//     });
//
//     // 2. DETECTION: Process Success (REVISED & FIXED TYPE CAST ERROR)
//     test('DetectionViewModel - Proses Deteksi Berhasil', () async {
//       final viewModel = DetectionViewModel(mockDetectionRepo);
//       final dummyFile = File('dummy.jpg');
//
//       // 1. Mock Upload Image
//       when(mockDetectionRepo.uploadImageToStorage(any, any))
//           .thenAnswer((_) async => 'https://dummy-url.com/image.jpg');
//
//       // 2. Mock Analyze Image (AI)
//       // [FIX] Tambahkan <String, dynamic> pada map bersarang agar casting berhasil
//       when(mockDetectionRepo.analyzeImage(any))
//           .thenAnswer((_) async => <String, dynamic>{
//         'fault_analysis': <String, dynamic>{ // <--- EKSPLISIT TIPE DATA
//           'status_level': 'BAHAYA',
//           'deskripsi_singkat': 'Sesar Lembang',
//           'penjelasan_lengkap': 'Terdeteksi retakan signifikan.'
//         },
//         'images_base64': <String, dynamic>{} // <--- EKSPLISIT TIPE DATA
//       });
//
//       // 3. Mock Check Location
//       when(mockDetectionRepo.checkLocationRisk(any, any))
//           .thenAnswer((_) async => <String, dynamic>{
//         'status': 'WASPADA',
//         'nama_patahan': 'Sesar Lembang',
//         'jarak_km': 5.0
//       });
//
//       // 4. Mock Save Result
//       when(mockDetectionRepo.saveDetectionResult(
//         latitude: anyNamed('latitude'),
//         longitude: anyNamed('longitude'),
//         originalImageUrl: anyNamed('originalImageUrl'),
//         overlayImageUrl: anyNamed('overlayImageUrl'),
//         maskImageUrl: anyNamed('maskImageUrl'),
//         detectionResult: anyNamed('detectionResult'),
//         statusLevel: anyNamed('statusLevel'),
//         descriptionMap: anyNamed('descriptionMap'),
//         address: anyNamed('address'),
//       )).thenAnswer((_) async => null);
//
//       // Act
//       await viewModel.processDetection(
//         imageFile: dummyFile,
//         latitude: -6.9,
//         longitude: 107.6,
//       );
//
//       // DEBUGGING
//       if (viewModel.state.error != null) {
//         print("TEST ERROR: ${viewModel.state.error}");
//       }
//
//       // Assert
//       expect(viewModel.state.isLoading, false);
//       expect(viewModel.state.error, isNull);
//       expect(viewModel.state.result, isNotNull);
//       expect(viewModel.state.result!['faultType'], 'Sesar Lembang');
//     });
//
//     // 3. CHATBOT: Send Message
//     test('ChatViewModel - Kirim Pesan & Terima Balasan', () async {
//       final viewModel = ChatViewModel(mockChatRepo);
//
//       when(mockChatRepo.sendMessage('Halo', any))
//           .thenAnswer((_) async => 'Halo juga!');
//
//       await viewModel.sendMessage('Halo');
//
//       expect(viewModel.state.messages.last.text, 'Halo juga!');
//       expect(viewModel.state.messages.last.isUser, false);
//     });
//
//     // 4. FEEDBACK: Send Feedback
//     test('ProfileViewModel - Kirim Feedback Berhasil', () async {
//       final viewModel = ProfileViewModel(mockProfileRepo, mockRef);
//
//       when(mockProfileRepo.sendFeedback('Aplikasi bagus'))
//           .thenAnswer((_) async => {});
//
//       await viewModel.sendFeedback('Aplikasi bagus');
//
//       expect(viewModel.state.isSuccess, true);
//     });
//
//     // 5. CHANGE PASSWORD: Success
//     test('ProfileViewModel - Ganti Password Berhasil', () async {
//       final viewModel = ProfileViewModel(mockProfileRepo, mockRef);
//
//       when(mockProfileRepo.changePassword(
//           oldPassword: 'oldPass',
//           newPassword: 'newPass'
//       )).thenAnswer((_) async => {});
//
//       await viewModel.changePassword(
//           oldPassword: 'oldPass',
//           newPassword: 'newPass'
//       );
//
//       expect(viewModel.state.isSuccess, true);
//     });
//   });
// }