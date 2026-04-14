class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String role;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime? lastActiveAt;
  final int balance;
  final String status; // 'online', 'offline', 'away'

  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.role = 'user',
    this.photoUrl,
    this.fcmToken,
    this.lastActiveAt,
    this.balance = 0,
    this.status = 'offline',
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? role,
    String? photoUrl,
    String? fcmToken,
    DateTime? lastActiveAt,
    int? balance,
    String? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      balance: balance ?? this.balance,
      status: status ?? this.status,
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
      lastActiveAt: data['last_active_at'] != null 
          ? DateTime.parse(data['last_active_at']) 
          : null,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'role': role,
      // status & last_active_at được quản lý riêng bởi presence system
      // không ghi đè ở đây để tránh lỗi nếu cột chưa tồn tại trên DB
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (photoUrl != null) 'avatar_url': photoUrl,
      'balance': balance,
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
