import 'dart:convert';

import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data access port for the user's favorite-courts list.
abstract class IFavoriteRepository {
  /// Loads the persisted favorite courts for [userId] (or the anonymous
  /// bucket when `null`).
  Future<List<CourtLocationModel>> loadFavorites(String? userId);

  /// Persists the full favorite courts list for [userId].
  Future<void> saveFavorites(
    String? userId,
    List<CourtLocationModel> favorites,
  );
}

/// SharedPreferences-backed implementation of [IFavoriteRepository].
class FavoriteRepository implements IFavoriteRepository {
  const FavoriteRepository();

  String _prefKey(String? userId) =>
      userId != null ? 'favorite_courts_$userId' : 'favorite_courts_json';

  @override
  Future<List<CourtLocationModel>> loadFavorites(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey(userId));
      if (raw == null) return [];
      final List decoded = jsonDecode(raw);
      return decoded
          .map((e) => _courtFromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveFavorites(
    String? userId,
    List<CourtLocationModel> favorites,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = favorites.map(_courtToJson).toList();
    await prefs.setString(_prefKey(userId), jsonEncode(jsonList));
  }

  Map<String, dynamic> _courtToJson(CourtLocationModel c) => {
    'id': c.id,
    'name': c.name,
    'address': c.address,
    'latitude': c.latitude,
    'longitude': c.longitude,
    'pricePerHour': c.pricePerHour,
    'totalCourts': c.totalCourts,
    'sportType': c.sportType,
    'imageUrl': c.imageUrl,
    'rating': c.rating,
    'totalReviews': c.totalReviews,
  };

  CourtLocationModel _courtFromJson(Map<String, dynamic> m) =>
      CourtLocationModel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        address: m['address'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (m['longitude'] as num?)?.toDouble() ?? 0.0,
        pricePerHour: (m['pricePerHour'] as num?)?.toDouble() ?? 0.0,
        totalCourts: (m['totalCourts'] as num?)?.toInt() ?? 0,
        sportType: m['sportType'] as String?,
        imageUrl: m['imageUrl'] as String?,
        rating: (m['rating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: (m['totalReviews'] as num?)?.toInt() ?? 0,
      );
}
