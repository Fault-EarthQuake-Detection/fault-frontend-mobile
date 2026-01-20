import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_valid_app/features/home/viewmodel/home_viewmodel.dart';
import '../../../core/services/session_service.dart';
import '../../navigation/viewmodel/navigation_viewmodel.dart';
import '../../sidebar/viewmodel/history_viewmodel.dart';
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
  final Ref _ref;

  AuthViewModel(this._repository, this._ref) : super(AuthState());

  Future<void> login(String username, String password) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.login(username: username, password: password);
      _ref.invalidate(currentUserProvider);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> register(String email, String password, String username) async {
    state = AuthState(isLoading: true);
    try {
      await _repository.register(email: email, password: password, username: username);
      // Sukses Register
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthState(isLoading: true);
    try {
      await _repository.googleSignIn();
      _ref.invalidate(currentUserProvider);
      state = AuthState(isSuccess: true, isLoading: false);
    } catch (e) {
      state = AuthState(error: _toMessage(e), isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(bottomNavIndexProvider);
    state = AuthState();
  }

  String _toMessage(Object? e) {
    if (e == null) return 'Terjadi kesalahan';
    if (e is String) return e;
    return e.toString(); // Menghilangkan "Exception:" prefix jika ada
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthViewModel(repo, ref);
});

final currentUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await SessionService.getUser();
});