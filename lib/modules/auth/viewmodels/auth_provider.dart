import 'dart:async';
import 'dart:io';

import 'package:badminton_ai/core/errors/failure.dart';
import 'package:badminton_ai/core/data/models/user_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import '../repositories/auth_repository.dart';
import 'package:badminton_ai/core/services/presence_service.dart';
import 'package:badminton_ai/core/services/push_notification_service.dart';
import 'package:flutter/material.dart';

enum AuthState { unknown, loading, authenticated, unauthenticated }

/// Presentation session controller for Auth — calls [IAuthRepository]
/// directly.
class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  StreamSubscription<String?>? _authStateSubscription;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  bool _isSigningIn = false;
  bool get isSigningIn => _isSigningIn;

  AuthState _authState = AuthState.unknown;
  AuthState get authState => _authState;

  String? _currentUserId;
  String? get userId => _currentUserId;
  String get userName => _userModel?.displayName ?? 'User';
  String get userRole => _userModel?.role ?? 'user';

  void updateUserModel(UserModel updatedUser) {
    _userModel = updatedUser;
    notifyListeners();
  }

  Future<void> reloadUserModel() async {
    if (_currentUserId != null) {
      final model = await _authRepository.getUserById(_currentUserId!);
      if (model != null) {
        _userModel = model;
        notifyListeners();
      }
    }
  }

  void checkAuthState() {
    _authState = AuthState.loading;
    notifyListeners();

    _authStateSubscription = _authRepository.watchAuthUserId().listen((
      String? userId,
    ) async {
      if (userId == null) {
        _currentUserId = null;
        _userModel = null;
        _authState = AuthState.unauthenticated;
      } else {
        _currentUserId = userId;
        final model = await _authRepository.getUserById(userId);
        if (model != null) {
          _userModel = model;
        }
        _authState = AuthState.authenticated;
        PresenceService().start(userId);
        PushNotificationService().listenToRealtimeNotifications(userId);
        PushNotificationService().initialize();
      }
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    _isSigningIn = true;
    notifyListeners();
    try {
      final model = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (model != null) {
        _userModel = model;
        _currentUserId = model.id;
        _authState = AuthState.authenticated;
        _isSigningIn = false;
        notifyListeners();
        return null;
      }
      _isSigningIn = false;
      notifyListeners();
      return 'Đăng nhập thất bại';
    } on AuthenticationFailure catch (e) {
      _isSigningIn = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isSigningIn = false;
      notifyListeners();
      return 'Đã xảy ra lỗi không xác định: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    _isSigningIn = true;
    notifyListeners();
    try {
      final success = await _authRepository.signInWithGoogle();
      _isSigningIn = false;
      notifyListeners();
      return success;
    } catch (_) {
      _isSigningIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _authState = AuthState.loading;
    notifyListeners();
    try {
      final model = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (model != null) {
        _userModel = model;
        _currentUserId = model.id;
        _authState = AuthState.authenticated;
        notifyListeners();
        return true;
      }
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await PresenceService().stop();
    await _authRepository.signOut();
  }

  Future<bool> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    DateTime? dob,
    String? gender,
  }) async {
    if (_currentUserId == null) return false;
    final trimmedName = displayName?.trim();
    final trimmedPhone = phoneNumber?.trim();
    final trimmedGender = gender?.trim();

    if ((trimmedName == null || trimmedName.isEmpty) &&
        trimmedPhone == null &&
        dob == null &&
        (trimmedGender == null || trimmedGender.isEmpty)) {
      return false;
    }

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final model = await _authRepository.updateUserProfile(
        _currentUserId!,
        displayName: trimmedName,
        phoneNumber: trimmedPhone,
        dob: dob,
        gender: trimmedGender,
      );
      if (model != null) {
        _userModel = model;
        _isUpdatingProfile = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // flag toggled below
    }

    _isUpdatingProfile = false;
    notifyListeners();
    return false;
  }

  Future<bool> updatePassword(String newPassword) async {
    return _authRepository.updatePassword(newPassword);
  }

  Future<bool> updateUserAvatar(File image) async {
    if (_currentUserId == null) return false;

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final supabaseRepo = SupabaseRepository();
      final String publicUrl = await supabaseRepo.uploadImage(
        image.path,
        'avatars',
      );

      final model = await _authRepository.updateUserProfile(
        _currentUserId!,
        avatarUrl: publicUrl,
      );

      if (model != null) {
        _userModel = model;
        _isUpdatingProfile = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updateUserAvatar: $e');
    }

    _isUpdatingProfile = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteUserAvatar() async {
    if (_currentUserId == null) return false;

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final model = await _authRepository.updateUserProfile(
        _currentUserId!,
        avatarUrl: '',
      );

      if (model != null) {
        _userModel = model;
        _isUpdatingProfile = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleteUserAvatar: $e');
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
