import 'dart:async';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/screens/user/map/map_tab.dart' show SportType;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class MapViewModel extends ChangeNotifier {
  final SupabaseRepository _repository;
  StreamSubscription<List<CourtLocationModel>>? _courtsSubscription;

  // Data
  List<CourtLocationModel> _allCourts = [];
  List<CourtLocationModel> searchHistory = [];
  
  // State
  LatLng currentPosition = const LatLng(21.028511, 105.804817);
  bool isLoadingLocation = true;
  SportType selectedSport = SportType.badminton;
  String searchQuery = '';
  
  // UI State - specific to animations
  CourtLocationModel? selectedCourt;
  bool showNearbyList = false;
  bool hideFabs = false;
  double sheetExtent = 0.55;

  MapViewModel(this._repository) {
    _getCurrentLocation();
    _setupCourtsSubscription();
  }

  @override
  void dispose() {
    _courtsSubscription?.cancel();
    super.dispose();
  }

  // --- Data Initialization ---
  void _setupCourtsSubscription() {
    _courtsSubscription = _repository.getCourtLocationsStream().listen(
      (courts) {
        _allCourts = courts;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Lỗi tải sân từ Supabase: $e');
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      currentPosition = LatLng(position.latitude, position.longitude);
      isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    currentPosition = const LatLng(21.028511, 105.804817);
    isLoadingLocation = false;
    notifyListeners();
  }
  
  Future<void> requestLocationUpdate() async {
    isLoadingLocation = true;
    notifyListeners();
    await _getCurrentLocation();
  }

  // --- Computed Properties ---
  List<CourtLocationModel> get filteredCourts {
    final courts = List<CourtLocationModel>.from(_allCourts);
    
    if (searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      return courts.where((court) {
        final nameMatch = court.name.toLowerCase().contains(queryLower);
        final addressMatch = court.address.toLowerCase().contains(queryLower);
        final sportTypeMatch =
            court.sportType?.toLowerCase().contains(queryLower) ?? false;

        if (queryLower.contains('screens.badminton1'.tr()) || queryLower.contains('badminton')) {
          return (court.sportType?.toLowerCase() == 'badminton' ||
              court.name.toLowerCase().contains('screens.badminton1'.tr()) ||
              court.name.toLowerCase().contains('badminton'));
        }
        return nameMatch || addressMatch || sportTypeMatch;
      }).toList();
    } else {
      return courts.where((court) {
        final st = court.sportType?.trim().toLowerCase() ?? '';
        final nameLower = court.name.toLowerCase();
        
        switch (selectedSport) {
          case SportType.badminton:
            return st.contains('badminton') || st.contains('screens.badminton1'.tr()) || nameLower.contains('screens.badminton1'.tr()) || nameLower.contains('badminton') || (st.isEmpty && !nameLower.contains('pickle') && !nameLower.contains('screens.football1'.tr()) && !nameLower.contains('tennis'));
          case SportType.pickleball:
            return st.contains('pickle') || nameLower.contains('pickle');
          case SportType.football:
            return st.contains('football') || st.contains('screens.football1'.tr()) || st.contains('soccer') || nameLower.contains('screens.football1'.tr()) || nameLower.contains('football');
          case SportType.tennis:
            return st.contains('tennis') || nameLower.contains('tennis');
        }
      }).toList();
    }
  }

  List<CourtLocationModel> get searchResults {
    if (searchQuery.trim().isEmpty) return searchHistory;
    return filteredCourts;
  }

  List<CourtLocationModel> get courtsSortedByDistance {
    final list = List<CourtLocationModel>.from(_allCourts);
    if (currentPosition.latitude != 21.028511) {
      list.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          currentPosition.latitude, currentPosition.longitude, a.latitude, a.longitude);
        final distB = Geolocator.distanceBetween(
          currentPosition.latitude, currentPosition.longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
    }
    return list;
  }

  // --- UI Interactions ---
  void selectSport(SportType type) {
    selectedSport = type;
    selectedCourt = null; // Hide card when changing filter
    showNearbyList = false;
    notifyListeners();
  }

  void setSearchQuery(String val) {
    searchQuery = val;
    notifyListeners();
  }

  void selectCourt(CourtLocationModel court) {
    searchHistory.removeWhere((c) => c.id == court.id);
    searchHistory.insert(0, court);
    if (searchHistory.length > 5) searchHistory.removeLast();

    showNearbyList = false;
    selectedCourt = court;
    hideFabs = false;
    sheetExtent = 0.55;
    notifyListeners();
  }

  void toggleNearbyList() {
    showNearbyList = !showNearbyList;
    if (showNearbyList) selectedCourt = null; 
    notifyListeners();
  }

  void closeBottomCard() {
    selectedCourt = null;
    showNearbyList = false;
    hideFabs = false;
    sheetExtent = 0.55;
    notifyListeners();
  }

  void setHideFabs(bool val) {
    if (hideFabs != val) {
      hideFabs = val;
      notifyListeners();
    }
  }

  void setSheetExtent(double extent) {
    if ((sheetExtent - extent).abs() > 0.005) {
      sheetExtent = extent;
      notifyListeners();
    }
  }
}
