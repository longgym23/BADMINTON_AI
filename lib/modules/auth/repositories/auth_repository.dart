import 'package:badminton_ai/core/data/models/user_model.dart';
import 'package:badminton_ai/core/errors/failure.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data access port for authentication & profile access.
abstract class IAuthRepository {
  /// Emits current auth user id, or null when signed out.
  Stream<String?> watchAuthUserId();

  Future<UserModel?> getUserById(String userId);

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<bool> signInWithGoogle();

  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<UserModel?> updateUserProfile(
    String userId, {
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    DateTime? dob,
    String? gender,
  });

  Future<bool> updatePassword(String newPassword);

  Future<void> updateLastActiveStatus(String userId, String status);
}

class AuthRepository implements IAuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Stream<String?> watchAuthUserId() {
    return _client.auth.onAuthStateChange.map(
      (event) => event.session?.user.id,
    );
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromSupabase(data);
    } catch (e) {
      debugPrint('Error getUserById: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return getUserById(response.user!.id);
      }
      return null;
    } on AuthException catch (e) {
      throw AuthenticationFailure(message: e.message, errorCode: e.code);
    } catch (e) {
      debugPrint('Error signIn: $e');
      rethrow;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.kloo://login-callback/',
      );
    } catch (e) {
      debugPrint('Error signInWithGoogle: $e');
      return false;
    }
  }

  @override
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user != null) {
        return UserModel(
          id: response.user!.id,
          email: email,
          displayName: displayName,
          role: 'user',
        );
      }
      return null;
    } on AuthException catch (e) {
      throw AuthenticationFailure(message: e.message, errorCode: e.code);
    } catch (e) {
      debugPrint('Error register: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<UserModel?> updateUserProfile(
    String userId, {
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    DateTime? dob,
    String? gender,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.id != userId) return null;

      final updateData = <String, dynamic>{};
      if (displayName != null) {
        await _client.auth.updateUser(
          UserAttributes(data: {'display_name': displayName}),
        );
        updateData['display_name'] = displayName;
      }
      if (phoneNumber != null) {
        updateData['phone_number'] = phoneNumber;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl.isEmpty ? null : avatarUrl;
      }
      if (dob != null) {
        updateData['date_of_birth'] = dob.toIso8601String().split('T')[0];
      }
      if (gender != null) {
        updateData['gender'] = gender;
      }

      if (updateData.isNotEmpty) {
        await _client.from('profiles').update(updateData).eq('id', userId);
      }

      return getUserById(userId);
    } catch (e) {
      debugPrint('Error updateUserProfile: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      debugPrint('Error updatePassword: $e');
      return false;
    }
  }

  @override
  Future<void> updateLastActiveStatus(String userId, String status) async {
    try {
      await _client.from('profiles').update({
        'status': status,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updateLastActiveStatus: $e');
    }
  }
}
