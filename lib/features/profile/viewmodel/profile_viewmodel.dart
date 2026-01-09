import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../data/profile_repository.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  ProfileState({this.isLoading = false, this.error, this.isSuccess = false});
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository _repo;
  final Ref _ref;

  ProfileViewModel(this._repo, this._ref) : super(ProfileState());

  Future<void> sendFeedback(String content) async {
    state = ProfileState(isLoading: true);
    try {
      await _repo.sendFeedback(content);
      state = ProfileState(isSuccess: true);
    } catch (e) {
      state = ProfileState(error: e.toString());
    }
  }

  Future<void> updateProfile({
    required String username,
    File? imageFile,
    String? currentUserId,
  }) async {
    state = ProfileState(isLoading: true);
    try {
      String? avatarUrl;

      if (imageFile != null && currentUserId != null) {
        avatarUrl = await _repo.uploadAvatar(imageFile, currentUserId);
      }

      await _repo.updateProfile(username: username, avatarUrl: avatarUrl);

      _ref.refresh(currentUserProvider);

      state = ProfileState(isSuccess: true);
    } catch (e) {
      state = ProfileState(error: e.toString());
    }
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    state = ProfileState(isLoading: true);
    try {
      await _repo.changePassword(oldPassword: oldPassword, newPassword: newPassword);
      state = ProfileState(isSuccess: true);
    } catch (e) {
      state = ProfileState(error: e.toString());
    }
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final repo = ref.read(profileRepositoryProvider);
  return ProfileViewModel(repo, ref);
});