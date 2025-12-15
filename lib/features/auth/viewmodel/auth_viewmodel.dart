// lib/features/auth/viewmodel/auth_viewmodel.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/session_service.dart';
import '../data/auth_repository.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(AuthState());

  Future<void> login(String username, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.login(username: username, password: password);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> register(String email, String password, String username) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.register(email: email, password: password, username: username);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthState(isLoading: true);
    try {
      await _repository.googleSignIn();
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }

  Future<void> updateProfile({
    String? username,
    File? imageFile,
  }) async {
    state = AuthState(isLoading: true);
    try {
      String? avatarUrl;
      final user = await SessionService.getUser();

      if (user == null) throw "User tidak ditemukan";
      final userId = user['id'] as String;

      if (imageFile != null) {
        avatarUrl = await _repository.uploadAvatar(imageFile, userId);
      }

      await _repository.updateProfile(username: username, avatarUrl: avatarUrl);

      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.changePassword(oldPassword: oldPassword, newPassword: newPassword);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  String _toMessage(Object? e) {
    if (e == null) return 'Terjadi kesalahan';
    if (e is String) return e;
    return e.toString();
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthViewModel(repo);
});

// currentUserProvider reads from SessionService
final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await SessionService.getUser();
});
