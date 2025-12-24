import 'package:cloud_firestore/cloud_firestore.dart';

class CourtLocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final int totalCourts;
  final String? sportType; // Loại sân: 'badminton', 'pickleball', 'football'

  CourtLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.totalCourts,
    this.sportType,
  });

  // Chuyển từ Firestore Document sang Model
  factory CourtLocationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourtLocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      totalCourts: (data['totalCourts'] as num?)?.toInt() ?? 0,
      sportType: data['sportType'] as String?,
    );
  }

  // Chuyển từ Model sang Object để ghi lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerHour': pricePerHour,
      'totalCourts': totalCourts,
      if (sportType != null) 'sportType': sportType,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourtLocationModel && other.id == id;
  }

  // Ghi đè hàm hashCode
  // Đi kèm với (==)
  @override
  int get hashCode => id.hashCode;
}
