class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String role;
  final String? photoUrl;
  final String? fcmToken;

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.role = 'user',
    this.photoUrl,
    this.fcmToken,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? role,
    String? photoUrl,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'],
      email: data['email'],
      displayName: data['display_name'],
      phoneNumber: data['phone_number'],
      role: data['role'] ?? 'user',
      photoUrl: data['avatar_url'],
      fcmToken: data['fcm_token'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'role': role,
      'fcm_token': fcmToken,
      'avatar_url': photoUrl,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role,
      'photoUrl': photoUrl,
    };
  }
}
