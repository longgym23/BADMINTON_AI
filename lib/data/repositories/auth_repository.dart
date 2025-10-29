import 'package:badminton_ai/data/models/user_model.dart'; // Sử dụng path của bạn
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  })  : _firebaseAuth = firebaseAuth,
        _firebaseFirestore = firebaseFirestore;

  // Lấy stream trạng thái đăng nhập
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Lấy UserModel từ Firestore
  // SỬA LỖI 1: Xóa dấu gạch dưới `_` để biến nó thành hàm công khai
  Future<UserModel?> getUserModel(String userId) async {
    try {
      final doc =
          await _firebaseFirestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Error getUserModel: $e");
      return null;
    }
  }

  // Đăng nhập
  // SỬA LỖI 2: Tên hàm là 'signInWithEmailAndPassword'
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Lấy UserModel (đã bao gồm 'role')
        // SỬA LỖI 2: Xóa dấu gạch dưới `_` để gọi hàm công khai
        return await getUserModel(userCredential.user!.uid);
      }
      return null;
    } catch (e) {
      print("Error signIn: $e");
      rethrow;
    }
  }

  // Đăng ký
  // SỬA LỖI 3: Tên hàm là 'registerWithEmailAndPassword'
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        // Cập nhật display name trong Firebase Auth
        await userCredential.user!.updateDisplayName(displayName);

        // Tạo UserModel
        UserModel newUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: 'user', // Gán vai trò 'user' mặc định
        );

        // Tạo document trong 'users'
        await _createUserDocument(newUser);
        return newUser;
      }
      return null;
    } catch (e) {
      print("Error register: $e");
      rethrow;
    }
  }

  // Hàm private để tạo document user
  Future<void> _createUserDocument(UserModel user) async {
    try {
      await _firebaseFirestore
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      print("Error _createUserDocument: $e");
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}


