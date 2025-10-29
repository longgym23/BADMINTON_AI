import 'dart:async';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum AuthState { unknown, loading, authenticated, unauthenticated }

class AppAuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  AuthState _authState = AuthState.unknown;
  AuthState get authState => _authState;

  String? get userId => _firebaseUser?.uid;
  String get userName => _userModel?.displayName ?? "User";
  String get userRole => _userModel?.role ?? 'user'; // Sửa 'member' thành 'user'

  User? _firebaseUser;

  AppAuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Kiểm tra trạng thái đăng nhập
  void checkAuthState() {
    _authState = AuthState.loading;
    notifyListeners();

    _authStateSubscription =
        _authRepository.authStateChanges.listen((User? user) async {
      if (user == null) {
        _firebaseUser = null;
        _userModel = null;
        _authState = AuthState.unauthenticated;
      } else {
        _firebaseUser = user;
        // Lấy thông tin user (vai trò) từ Firestore
        // SỬA LỖI 1:
        _userModel = await _authRepository.getUserModel(user.uid);
        _authState = AuthState.authenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _authState = AuthState.loading;
    notifyListeners();
    try {
      // SỬA LỖI 2:
      final userModel = await _authRepository.signInWithEmailAndPassword(email, password);
      
      // Nếu đăng nhập thành công, listener trong checkAuthState
      // sẽ tự động chạy và cập nhật _userModel.
      // Tuy nhiên, chúng ta có thể cập nhật ngay lập tức ở đây.
      if (userModel != null) {
         _userModel = userModel;
         _authState = AuthState.authenticated;
         notifyListeners();
         return true;
      }
      return false; // Trường hợp hiếm
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
      // SỬA LỖI 3:
      final userModel = await _authRepository.registerWithEmailAndPassword(email, password, displayName);
      
      // Tương tự như signIn, listener sẽ tự động cập nhật
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
    // Listener sẽ tự động chuyển _authState = AuthState.unauthenticated
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

