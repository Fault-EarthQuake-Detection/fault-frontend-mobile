import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geo_valid_app/features/auth/data/auth_repository.dart';
import 'package:geo_valid_app/features/chatbot/data/chat_repository.dart';
import 'package:geo_valid_app/features/detection/data/detection_repository.dart';
import 'package:geo_valid_app/features/profile/data/profile_repository.dart';
import 'package:geo_valid_app/features/home/data/home_repository.dart';

import 'package:geo_valid_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:geo_valid_app/features/chatbot/viewmodel/chat_viewmodel.dart';
import 'package:geo_valid_app/features/detection/viewmodel/detection_viewmodel.dart';
import 'package:geo_valid_app/features/profile/viewmodel/profile_viewmodel.dart';

import 'package:geo_valid_app/features/chatbot/data/chat_message.dart';

@GenerateMocks([
  AuthRepository,
  ChatRepository,
  DetectionRepository,
  ProfileRepository,
  HomeRepository
])
import 'unit_test.mocks.dart';

class MockRef extends Mock implements Ref {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockChatRepository mockChatRepo;
  late MockDetectionRepository mockDetectionRepo;
  late MockProfileRepository mockProfileRepo;
  late MockRef mockRef;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockChatRepo = MockChatRepository();
    mockDetectionRepo = MockDetectionRepository();
    mockProfileRepo = MockProfileRepository();
    mockRef = MockRef();
  });

  group('Unit Testing - Fitur Utama', () {

    test('AuthViewModel - Login Berhasil', () async {
      when(mockAuthRepo.login(username: 'user@test.com', password: 'password'))
          .thenAnswer((_) async => Future.value());

      final viewModel = AuthViewModel(mockAuthRepo, mockRef);
      await viewModel.login('user@test.com', 'password');

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.isSuccess, true);
    });

    test('DetectionViewModel - Analisis & Simpan Berhasil', () async {
      final viewModel = DetectionViewModel(mockDetectionRepo);
      final dummyFile = File('dummy.jpg');

      when(mockDetectionRepo.uploadImageToStorage(any, any))
          .thenAnswer((_) async => 'https://url.com/original.jpg');

      when(mockDetectionRepo.analyzeImage(any))
          .thenAnswer((_) async => <String, dynamic>{
        'fault_analysis': <String, dynamic>{
          'status_level': 'BAHAYA',
          'deskripsi_singkat': 'Sesar Lembang',
          'penjelasan_lengkap': 'Deskripsi deteksi.'
        },
        'images_base64': <String, dynamic>{
          'overlay': 'base64Overlay',
          'mask': 'base64Mask'
        }
      });

      when(mockDetectionRepo.checkLocationRisk(any, any))
          .thenAnswer((_) async => <String, dynamic>{
        'status': 'WASPADA',
        'nama_patahan': 'Lembang',
        'jarak_km': 5.0
      });

      when(mockDetectionRepo.uploadBase64ToStorage(any, any))
          .thenAnswer((_) async => 'https://url.com/generated.jpg');

      when(mockDetectionRepo.saveDetectionResult(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        originalImageUrl: anyNamed('originalImageUrl'),
        overlayImageUrl: anyNamed('overlayImageUrl'),
        maskImageUrl: anyNamed('maskImageUrl'),
        detectionResult: anyNamed('detectionResult'),
        statusLevel: anyNamed('statusLevel'),
        descriptionMap: anyNamed('descriptionMap'),
        address: anyNamed('address'),
      )).thenAnswer((_) async => Future.value());

      await viewModel.analyzeOnly(
        imageFile: dummyFile,
        latitude: -6.9,
        longitude: 107.6,
      );

      expect(viewModel.state.isLoading, false);
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.result, isNotNull);
      expect(viewModel.state.result!['faultType'], 'Sesar Lembang');

      await viewModel.saveResultToDatabase();

      expect(viewModel.state.isSaving, false);
      expect(viewModel.state.isSavedSuccess, true);

      verify(mockDetectionRepo.saveDetectionResult(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        originalImageUrl: anyNamed('originalImageUrl'),
        overlayImageUrl: anyNamed('overlayImageUrl'),
        maskImageUrl: anyNamed('maskImageUrl'),
        detectionResult: anyNamed('detectionResult'),
        statusLevel: anyNamed('statusLevel'),
        descriptionMap: anyNamed('descriptionMap'),
        address: anyNamed('address'),
      )).called(1);
    });

    test('ChatViewModel - Kirim Pesan', () async {
      when(mockChatRepo.loadLocalChat())
          .thenAnswer((_) async => <ChatMessage>[]);

      when(mockChatRepo.saveLocalChat(any))
          .thenAnswer((_) async => Future.value());

      when(mockChatRepo.sendMessage(any, any))
          .thenAnswer((_) async => 'Halo juga!');

      final viewModel = ChatViewModel(mockChatRepo);
      await viewModel.sendMessage('Halo');

      expect(viewModel.state.messages.isNotEmpty, true);
      expect(viewModel.state.messages.last.text, 'Halo juga!');
    });

    test('ProfileViewModel - Kirim Feedback', () async {
      final viewModel = ProfileViewModel(mockProfileRepo, mockRef);

      when(mockProfileRepo.sendFeedback(any))
          .thenAnswer((_) async => Future.value());

      await viewModel.sendFeedback('Aplikasi bagus');

      expect(viewModel.state.isSuccess, true);
    });

    test('ProfileViewModel - Ganti Password', () async {
      final viewModel = ProfileViewModel(mockProfileRepo, mockRef);

      when(mockProfileRepo.changePassword(
          oldPassword: anyNamed('oldPassword'),
          newPassword: anyNamed('newPassword')
      )).thenAnswer((_) async => Future.value());

      await viewModel.changePassword(
          oldPassword: 'oldPass',
          newPassword: 'newPass'
      );

      expect(viewModel.state.isSuccess, true);
    });
  });
}