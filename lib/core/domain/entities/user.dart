import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final UserRole role;
  final String? photoUrl;
  final String? fcmToken;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.role = UserRole.user,
    this.photoUrl,
    this.fcmToken,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    UserRole? role,
    String? photoUrl,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, phoneNumber, role, photoUrl, fcmToken];
}

enum UserRole {
  user,
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.user:
        return 'user';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}