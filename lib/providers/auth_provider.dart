import 'dart:async';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';

enum AuthState { unknown, loading, authenticated, unauthenticated }

class AppAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  AuthState _authState = AuthState.unknown;
  AuthState get authState => _authState;

  String? get userId => _currentUser?.id;
  String get userName => _userModel?.displayName ?? "User";
  String get userRole => _userModel?.role ?? 'user';

  User? _currentUser;

  AppAuthProvider({required AuthRepository authRepository})
    : _authRepository = authRepository;

  void updateUserModel(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }

  Future<void> reloadUserModel() async {
    if (_currentUser != null) {
      _userModel = await _authRepository.getUserModel(_currentUser!.id);
      notifyListeners();
    }
  }

  // Kiểm tra trạng thái đăng nhập
  void checkAuthState() {
    _authState = AuthState.loading;
    notifyListeners();

    _authStateSubscription = _authRepository.authStateChanges.listen((
      User? user,
    ) async {
      if (user == null) {
        _currentUser = null;
        _userModel = null;
        _authState = AuthState.unauthenticated;
      } else {
        _currentUser = user;
        // Lấy thông tin user (vai trò) từ Table profiles
        _userModel = await _authRepository.getUserModel(user.id);
        _authState = AuthState.authenticated;
      }
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    _authState = AuthState.loading;
    notifyListeners();
    try {
      final userModel = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );

      if (userModel != null) {
        _userModel = userModel;
        _authState = AuthState.authenticated;
        notifyListeners();
        return null; // Success
      }
      return 'Đăng nhập thất bại';
    } on AuthException catch (e) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      // Trả về message từ Supabase (đã được localize hoặc raw message)
      return e.message;
    } catch (e) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    _authState = AuthState.loading;
    notifyListeners();
    try {
      // Gọi repository
      final success = await _authRepository.signInWithGoogle();
      if (!success) {
        _authState = AuthState.unauthenticated;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _authState = AuthState.loading;
    notifyListeners();
    try {
      final userModel = await _authRepository.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );

      if (userModel != null) {
        _userModel = userModel;
        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<bool> updateUserProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;
    final trimmedName = displayName?.trim();
    final trimmedPhone = phoneNumber?.trim();

    if ((trimmedName == null || trimmedName.isEmpty) &&
        (trimmedPhone == null)) {
      return false;
    }

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        _currentUser!.id,
        displayName: trimmedName,
        phoneNumber: trimmedPhone,
      );
      if (updatedUser != null) {
        _userModel = updatedUser;
        _isUpdatingProfile = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // ignore error, will toggle flag below
    }

    _isUpdatingProfile = false;
    notifyListeners();
    return false;
  }

  Future<bool> updatePassword(String newPassword) async {
    return await _authRepository.updatePassword(newPassword);
  }

  Future<bool> updateUserAvatar(File image) async {
    if (_currentUser == null) return false;

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final supabaseRepo = SupabaseRepository();
      final String publicUrl = await supabaseRepo.uploadImage(
        image.path,
        'avatars',
      );

      final updatedUser = await _authRepository.updateUserProfile(
        _currentUser!.id,
        avatarUrl: publicUrl,
      );

      if (updatedUser != null) {
        _userModel = updatedUser;
        _isUpdatingProfile = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Error updateUserAvatar: $e");
    }

    _isUpdatingProfile = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteUserAvatar() async {
    if (_currentUser == null) return false;

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final updatedUser = await _authRepository.updateUserProfile(
        _currentUser!.id,
        avatarUrl: '', // Send empty string to signify deletion in repository
      );

      if (updatedUser != null) {
        _userModel = updatedUser;
        _isUpdatingProfile = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
       print("Error deleteUserAvatar: $e");
    }

    _isUpdatingProfile = false;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
