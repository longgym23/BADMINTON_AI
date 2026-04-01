import 'package:badminton_ai/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({
    SupabaseClient? client,
    // Giữ lại tham số cũ để tránh lỗi trong main.dart nếu chưa sửa xong
    dynamic firebaseAuth,
    dynamic firebaseFirestore,
  }) : _client = client ?? Supabase.instance.client;

  // Lấy stream trạng thái đăng nhập
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  // Lấy UserModel từ Table profiles
  Future<UserModel?> getUserModel(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromSupabase(data);
    } catch (e) {
      print("Error getUserModel: $e");
      return null;
    }
  }

  Future<UserModel?> updateUserProfile(
    String userId, {
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.id != userId) return null;

      final updateData = <String, dynamic>{};
      if (displayName != null) {
        // Cập nhật metadata trong Auth
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

      if (updateData.isNotEmpty) {
        await _client.from('profiles').update(updateData).eq('id', userId);
      }

      return await getUserModel(userId);
    } catch (e) {
      print("Error updateUserProfile: $e");
      rethrow;
    }
  }

  // Đăng nhập
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return await getUserModel(response.user!.id);
      }
      return null;
    } catch (e) {
      print("Error signIn: $e");
      rethrow;
    }
  }

  // Đăng nhập Bằng Google
  Future<bool> signInWithGoogle() async {
    try {
      // Gọi OAuth mặc định của Supabase
      // Trên Web/Android nó sẽ mở Popup/Browser để chọn tài khoản Google
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.kloo://login-callback/',
      );
      return success;
    } catch (e) {
      print("Error signInWithGoogle: $e");
      return false;
    }
  }

  // Đăng ký
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
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
    } catch (e) {
      print("Error register: $e");
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
