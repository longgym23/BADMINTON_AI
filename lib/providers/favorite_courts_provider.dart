import 'dart:convert';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteCourtsProvider extends ChangeNotifier {
  static const _prefKey = 'favorite_courts_json';
  List<CourtLocationModel> _favorites = [];

  List<CourtLocationModel> get favorites => List.unmodifiable(_favorites);

  FavoriteCourtsProvider() {
    _loadFromPrefs();
  }

  bool isFavorite(String courtId) =>
      _favorites.any((c) => c.id == courtId);

  Future<void> toggleFavorite(CourtLocationModel court) async {
    if (isFavorite(court.id)) {
      _favorites.removeWhere((c) => c.id == court.id);
    } else {
      _favorites.add(court);
    }
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> removeFavorite(String courtId) async {
    _favorites.removeWhere((c) => c.id == courtId);
    notifyListeners();
    await _saveToPrefs();
  }

  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _favorites.map((c) => _courtToJson(c)).toList();
    await prefs.setString(_prefKey, jsonEncode(jsonList));
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        _favorites = decoded
            .map((e) => _courtFromJson(Map<String, dynamic>.from(e)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Mini serialization (not hitting Supabase to keep it fast) ────────────────

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
