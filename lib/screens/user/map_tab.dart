import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/screens/user/court_selection_screen.dart';
import 'package:badminton_ai/services/places_service.dart';
import 'package:badminton_ai/services/court_info_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// Tab 2: Bản đồ
class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  _MapTabState createState() => _MapTabState();
}

enum SportType { pickleball, badminton, football, tennis }

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(
    21.028511,
    105.804817,
  ); // Mặc định Hà Nội
  Set<Marker> _markers = {};
  bool _isLoadingLocation = true;
  SportType _selectedSport = SportType.badminton;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingPlaces = false;
  bool _searchAllVietnam = false;

  // Data management
  StreamSubscription<List<CourtLocationModel>>? _courtsSubscription;
  List<CourtLocationModel> _firestoreCourts = [];
  List<CourtLocationModel> _googlePlacesCourts = [];

  // Custom Markers
  final Map<String, BitmapDescriptor> _customIcons = {};
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCustomMarkers();
    _setupFirestoreSubscription();
  }

  Future<void> _loadCustomMarkers() async {
    try {
      _customIcons['badminton'] = await _createCustomMarkerBitmap(
        Icons.sports_tennis,
        Colors.green,
      );
      _customIcons['pickleball'] = await _createCustomMarkerBitmap(
        Icons.sports_tennis,
        Colors.blue,
      ); // Pickleball icon proxy
      _customIcons['football'] = await _createCustomMarkerBitmap(
        Icons.sports_soccer,
        Colors.orange,
      );
      _customIcons['tennis'] = await _createCustomMarkerBitmap(
        Icons.sports_tennis,
        Colors.purple,
      );

      if (mounted) {
        setState(() {
          _iconsLoaded = true;
        });
        _updateAllMarkers();
      }
    } catch (e) {
      debugPrint('Error creating custom markers: $e');
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    IconData iconData,
    Color color,
  ) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = const Size(120, 120); // Slightly larger for better visibility
    final radius = size.width / 2;

    final paint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Draw shadow
    canvas.drawCircle(Offset(radius, radius + 5), radius - 5, shadowPaint);
    // Draw circle background
    canvas.drawCircle(Offset(radius, radius), radius - 10, paint);
    // Draw white border
    canvas.drawCircle(Offset(radius, radius), radius - 10, borderPaint);

    // Draw Icon
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 60,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage, // Important for Cupertino/Material icons
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final image = await pictureRecorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _setupFirestoreSubscription() {
    final firestoreRepo = context.read<FirestoreRepository>();
    _courtsSubscription = firestoreRepo.getCourtLocationsStream().listen(
      (courts) {
        if (mounted) {
          setState(() {
            _firestoreCourts = courts;
          });
          _updateAllMarkers();
        }
      },
      onError: (e) {
        debugPrint('Lỗi tải sân từ Firestore: $e');
      },
    );
  }

  @override
  void dispose() {
    _courtsSubscription?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
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

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = const LatLng(21.028511, 105.804817);
        _isLoadingLocation = false;
      });
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_isLoadingLocation) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
      );
    }
  }

  // Unified update method
  void _updateAllMarkers() {
    // 1. Merge lists
    final allCourts = <CourtLocationModel>[];
    allCourts.addAll(_googlePlacesCourts);

    // Dedup Firestore courts against Google Places courts
    final existingIds = _googlePlacesCourts.map((c) => c.id).toSet();
    final existingCoords = _googlePlacesCourts
        .map(
          (c) =>
              '${c.latitude.toStringAsFixed(4)}_${c.longitude.toStringAsFixed(4)}',
        )
        .toSet();

    for (final court in _firestoreCourts) {
      final coordKey =
          '${court.latitude.toStringAsFixed(4)}_${court.longitude.toStringAsFixed(4)}';
      if (!existingIds.contains(court.id) &&
          !existingCoords.contains(coordKey) &&
          court.latitude != 0.0 &&
          court.longitude != 0.0) {
        allCourts.add(court);
      }
    }

    // 2. Filter
    List<CourtLocationModel> filteredCourts;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      filteredCourts = allCourts.where((court) {
        final nameMatch = court.name.toLowerCase().contains(queryLower);
        final addressMatch = court.address.toLowerCase().contains(queryLower);
        final sportTypeMatch =
            court.sportType?.toLowerCase().contains(queryLower) ?? false;

        // Check filtering keywords
        if (queryLower.contains('cầu lông') ||
            queryLower.contains('badminton')) {
          return (court.sportType?.toLowerCase() == 'badminton' ||
              court.name.toLowerCase().contains('cầu lông') ||
              court.name.toLowerCase().contains('badminton'));
        }
        // Add other checks if needed...
        return nameMatch || addressMatch || sportTypeMatch;
      }).toList();
    } else {
      filteredCourts = _filterCourtsBySport(allCourts, _selectedSport);
    }

    // 3. Create Markers
    Set<Marker> newMarkers = {};
    const int maxMarkers = 50;

    // Sort by distance if location available
    if (_currentPosition.latitude != 21.028511) {
      filteredCourts.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          a.latitude,
          a.longitude,
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          b.latitude,
          b.longitude,
        );
        return distA.compareTo(distB);
      });
    }

    final courtsToShow = filteredCourts.take(maxMarkers).toList();

    for (final court in courtsToShow) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(court.id),
          position: LatLng(court.latitude, court.longitude),
          icon: _getMarkerIcon(court),
          infoWindow: InfoWindow(
            title: court.name,
            snippet: _buildInfoWindowSnippet(court),
          ),
          onTap: () => _showCourtBottomSheet(court),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  Future<void> _loadPlacesFromGoogle() async {
    if (_isLoadingPlaces) return;

    setState(() {
      _isLoadingPlaces = true;
      _googlePlacesCourts = [];
    });

    try {
      String sportTypeString;
      switch (_selectedSport) {
        case SportType.badminton:
          sportTypeString = 'badminton';
          break;
        case SportType.pickleball:
          sportTypeString = 'pickleball';
          break;
        case SportType.football:
          sportTypeString = 'football';
          break;
        case SportType.tennis:
          sportTypeString = 'tennis';
          break;
      }

      List<PlaceResult> places;
      if (_searchAllVietnam) {
        places = await PlacesService.searchAllVietnam(
          sportType: sportTypeString,
          maxCities: 10,
        );
      } else {
        places = await PlacesService.searchBySportType(
          location: _currentPosition,
          sportType: sportTypeString,
          radius: 20000,
        );
      }

      if (mounted) {
        final courts = places
            .map(
              (place) => place.toCourtLocationModel(
                overrideSportType: sportTypeString,
              ),
            )
            .toList();

        setState(() {
          _googlePlacesCourts = courts;
        });
        _updateAllMarkers();

        if (_searchAllVietnam && courts.isNotEmpty && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(const LatLng(16.0544, 108.2022), 6.0),
          );
        } else if (courts.isNotEmpty &&
            _mapController != null &&
            !_searchAllVietnam) {
          // Zoom to show new markers
          // Logic similar to _zoomToMarkersAndLocation but without recreating markers logic here
          // Just let user scroll or reuse existing logic if needed
        }
      }
    } catch (e) {
      debugPrint('Error loading places: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải địa điểm: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  List<CourtLocationModel> _filterCourtsBySport(
    List<CourtLocationModel> courts,
    SportType sportType,
  ) {
    if (courts.isEmpty) return [];
    String sportTypeString = sportType
        .name; // simple enum to string (badminton, pickleball etc matches)

    return courts.where((court) {
      if (court.sportType != null) {
        return court.sportType!.toLowerCase() == sportTypeString;
      }
      final nameLower = court.name.toLowerCase();
      final addressLower = court.address.toLowerCase();

      switch (sportType) {
        case SportType.badminton:
          return nameLower.contains('cầu lông') ||
              nameLower.contains('badminton');
        case SportType.pickleball:
          return nameLower.contains('pickleball') ||
              nameLower.contains('pickle');
        case SportType.football:
          return nameLower.contains('bóng đá') ||
              nameLower.contains('football') ||
              nameLower.contains('soccer');
        case SportType.tennis:
          return nameLower.contains('tennis');
      }
      return false;
    }).toList();
  }

  // --- Helper methods (kept mostly same but concise) ---

  BitmapDescriptor _getMarkerIcon(CourtLocationModel court) {
    if (!_iconsLoaded) return BitmapDescriptor.defaultMarker;

    String? sportType = court.sportType?.toLowerCase();

    // Fallback based on name if sportType is missing (legacy data)
    if (sportType == null) {
      final nameLower = court.name.toLowerCase();
      if (nameLower.contains('pickle'))
        sportType = 'pickleball';
      else if (nameLower.contains('bóng đá') || nameLower.contains('football'))
        sportType = 'football';
      else if (nameLower.contains('tennis'))
        sportType = 'tennis';
      else
        sportType = 'badminton';
    }

    if (sportType == 'pickleball')
      return _customIcons['pickleball'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    if (sportType == 'football')
      return _customIcons['football'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    if (sportType == 'tennis')
      return _customIcons['tennis'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

    return _customIcons['badminton'] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  String _buildInfoWindowSnippet(CourtLocationModel court) {
    // Simplified snippet builder
    return court.address;
  }

  void _zoomToMarkersAndLocation(Set<Marker> markers) {
    if (markers.isEmpty || _mapController == null) return;
    // ... (bounds calculation logic) ...
    double minLat = _currentPosition.latitude;
    double maxLat = _currentPosition.latitude;
    double minLng = _currentPosition.longitude;
    double maxLng = _currentPosition.longitude;

    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  void _showCourtBottomSheet(CourtLocationModel court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourtBottomSheet(
        court: court,
        onBookPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourtSelectionScreen(
                selectedCourt: court,
                selectedDate: DateTime.now(),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          if (_isLoadingPlaces)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // Search & Filter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm sân...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _updateAllMarkers();
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onSubmitted: (_) => _updateAllMarkers(),
                        onChanged: (val) {
                          if (val.isEmpty) _updateAllMarkers();
                        },
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    // Filter chips
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Cầu lông',
                          SportType.badminton,
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Pickleball',
                          SportType.pickleball,
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Bóng đá',
                          SportType.football,
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Tennis',
                          SportType.tennis,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'loc',
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zin',
                  onPressed: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zout',
                  onPressed: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SportType type, Color color) {
    final isSelected = _selectedSport == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSport = type;
            _markers =
                {}; // Clear old markers to show loading effect or just refresh
          });
          _loadPlacesFromGoogle(); // Reload logic
          _updateAllMarkers(); // Re-apply filters
        }
      },
      avatar: Icon(
        Icons.sports_tennis,
        size: 16,
        color: isSelected ? color : Colors.grey,
      ),
    );
  }
}

// Bottom sheet (kept concise)
class _CourtBottomSheet extends StatelessWidget {
  final CourtLocationModel court;
  final VoidCallback onBookPressed;
  const _CourtBottomSheet({required this.court, required this.onBookPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(court.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(court.address),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBookPressed,
              child: const Text('Đặt sân'),
            ),
          ),
        ],
      ),
    );
  }
}
