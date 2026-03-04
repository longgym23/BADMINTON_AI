
class CourtLocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final int totalCourts;
  final String? sportType; // Loại sân: 'badminton', 'pickleball', 'football'
  final String? imageUrl;
  final double rating;
  final int totalReviews;

  CourtLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.totalCourts,
    this.sportType,
    this.imageUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
  });


  // Chuyển từ Supabase (Map snake_case) sang Model
  factory CourtLocationModel.fromSupabase(Map<String, dynamic> data) {
    return CourtLocationModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: (data['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      totalCourts: (data['total_courts'] as num?)?.toInt() ?? 0,
      sportType: data['sport_type'] as String?,
      imageUrl: data['image_url'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (data['total_reviews'] as num?)?.toInt() ?? 0,
    );
  }

  // Chuyển sang Map để insert vào Supabase
  Map<String, dynamic> toSupabase() {
    return {
      // 'id': id, // Thường để Supabase tự sinh ID gen_random_uuid()
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'total_courts': totalCourts,
      if (sportType != null) 'sport_type': sportType,
      if (imageUrl != null) 'image_url': imageUrl,
      'rating': rating,
      'total_reviews': totalReviews,
    };
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
      if (imageUrl != null) 'imageUrl': imageUrl,
      'rating': rating,
      'totalReviews': totalReviews,
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
