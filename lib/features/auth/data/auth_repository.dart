import 'dart:io'; // Tambahan untuk File
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _supabase = SupabaseService().client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> register({required String email, required String password, required String username}) async {
    await _supabase.auth.signUp(email: email, password: password, data: {'username': username});
  }

  Future<void> login({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> googleSignIn() async {
    const webClientId = '204345218481-307nql93btdhpslm76jt8u6uumm2ti98.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;

    if (googleAuth == null) {
      throw 'Login Google dibatalkan.';
    }

    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'Tidak ditemukan ID Token Google.';
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final fileExt = file.path.split('.').last;
    final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _supabase.storage.from('avatar-profile').upload(
      fileName,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    final imageUrl = _supabase.storage.from('avatar-profile').getPublicUrl(fileName);
    return imageUrl;
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl, String? password}) async {
    final updates = UserAttributes(
      data: {
        if (fullName != null) 'full_name': fullName,
        if (fullName != null) 'name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (avatarUrl != null) 'picture': avatarUrl,
      },
      password: (password != null && password.isNotEmpty) ? password : null,
    );

    await _supabase.auth.updateUser(updates);
  }
}