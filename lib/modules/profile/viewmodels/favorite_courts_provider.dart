import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/modules/profile/repositories/favorite_repository.dart';
import 'package:flutter/material.dart';

/// ViewModel for favorite courts. Talks directly to [IFavoriteRepository].
class FavoriteCourtsProvider extends ChangeNotifier {
  FavoriteCourtsProvider({required IFavoriteRepository favoriteRepository})
    : _favoriteRepository = favoriteRepository;

  final IFavoriteRepository _favoriteRepository;

  String? _userId;
  List<CourtLocationModel> _favorites = [];

  List<CourtLocationModel> get favorites => List.unmodifiable(_favorites);

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (_userId != null) {
        _loadFavorites();
      } else {
        _favorites = [];
        notifyListeners();
      }
    }
  }

  bool isFavorite(String courtId) => _favorites.any((c) => c.id == courtId);

  Future<void> toggleFavorite(CourtLocationModel court) async {
    final current = await _favoriteRepository.loadFavorites(_userId);
    final isFav = current.any((c) => c.id == court.id);
    final updated = isFav
        ? current.where((c) => c.id != court.id).toList()
        : [...current, court];
    await _favoriteRepository.saveFavorites(_userId, updated);
    _favorites = updated;
    notifyListeners();
  }

  Future<void> removeFavorite(String courtId) async {
    final current = await _favoriteRepository.loadFavorites(_userId);
    final updated = current.where((c) => c.id != courtId).toList();
    await _favoriteRepository.saveFavorites(_userId, updated);
    _favorites = updated;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    _favorites = await _favoriteRepository.loadFavorites(_userId);
    notifyListeners();
  }
}
