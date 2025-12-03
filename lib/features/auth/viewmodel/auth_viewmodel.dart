import 'dart:io'; // Tambahan untuk File
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.login(email: email, password: password);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> register(String email, String password, String username) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.register(email: email, password: password, username: username);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthState(isLoading: true);
    try {
      await _repository.googleSignIn();
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }

  Future<void> updateProfile({
    String? fullName,
    File? imageFile,
    String? password,
  }) async {
    state = AuthState(isLoading: true);
    try {
      String? avatarUrl;
      final user = _repository.currentUser;

      if (user == null) throw "User tidak ditemukan";

      if (imageFile != null) {
        avatarUrl = await _repository.uploadAvatar(imageFile, user.id);
      }

      await _repository.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        password: password,
      );

      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthViewModel(repo);
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});