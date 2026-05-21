import 'dart:async';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/screens/user/map/map_tab.dart' show SportType;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final ValueNotifier<double> sheetExtentNotifier = ValueNotifier<double>(0.55);

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

  // ─── Semantic keyword → sportType mapping (giống home_filter_bloc) ──────────
  static const _sportKeywordMap = <String, String>{
    'cầu lông': 'badminton',
    'cau long': 'badminton',
    'caulong': 'badminton',
    'badminton': 'badminton',
    'pickleball': 'pickleball',
    'pickle ball': 'pickleball',
    'bóng đá': 'football',
    'bong da': 'football',
    'bongda': 'football',
    'football': 'football',
    'soccer': 'football',
    'bóng rổ': 'basketball',
    'bong ro': 'basketball',
    'basketball': 'basketball',
    'bóng chuyền': 'volleyball',
    'bong chuyen': 'volleyball',
    'volleyball': 'volleyball',
    'tennis': 'tennis',
    'bơi': 'swimming',
    'boi': 'swimming',
    'swimming': 'swimming',
  };

  // --- Computed Properties ---
  List<CourtLocationModel> get filteredCourts {
    final courts = List<CourtLocationModel>.from(_allCourts);

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      final mappedSport = _sportKeywordMap[q];

      return courts.where((court) {
        final nameMatch = court.name.toLowerCase().contains(q);
        final addressMatch = court.address.toLowerCase().contains(q);
        final courtSport = court.sportType?.toLowerCase() ?? '';

        // Nếu query khớp từ khóa môn thể thao → match theo sportType
        if (mappedSport != null) {
          return courtSport == mappedSport;
        }

        // Ngược lại → match theo tên, địa chỉ, hoặc sportType chứa query
        return nameMatch || addressMatch || courtSport.contains(q);
      }).toList();
    } else {
      // Không có query → lọc theo sport chip đang chọn
      return courts.where((court) {
        final st = court.sportType?.trim().toLowerCase() ?? '';
        final nameLower = court.name.toLowerCase();

        switch (selectedSport) {
          case SportType.badminton:
            return st == 'badminton' ||
                nameLower.contains('badminton') ||
                // Fallback: sân không có sportType và không phải môn khác
                (st.isEmpty &&
                    !nameLower.contains('pickle') &&
                    !nameLower.contains('football') &&
                    !nameLower.contains('tennis'));
          case SportType.pickleball:
            return st == 'pickleball' || nameLower.contains('pickle');
          case SportType.football:
            return st == 'football' ||
                st == 'soccer' ||
                nameLower.contains('football') ||
                nameLower.contains('soccer');
          case SportType.tennis:
            return st == 'tennis' || nameLower.contains('tennis');
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
    sheetExtentNotifier.value = 0.55;
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
    sheetExtentNotifier.value = 0.55;
    notifyListeners();
  }

  // Removed setHideFabs and setSheetExtentSilent as they are handled by ValueNotifier and UI now
}
