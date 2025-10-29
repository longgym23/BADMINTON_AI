import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // <-- LỖI LÀ DO THIẾU DÒNG NÀY
  final String? email;
  final String? displayName;
  final String role; 

  UserModel({
    required this.id, // <-- VÀ DÒNG NÀY
    this.email,
    this.displayName,
    this.role = 'user', 
  });

  // Chuyển từ Firestore document sang UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id, // <-- VÀ DÒNG NÀY
      email: data['email'],
      displayName: data['displayName'],
      role: data['role'] ?? 'user',
    );
  }

  // Chuyển từ UserModel sang Map để ghi vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }
}

