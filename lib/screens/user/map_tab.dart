import 'dart:async';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/screens/user/court_selection_screen.dart';
import 'package:badminton_ai/services/places_service.dart';
import 'package:badminton_ai/services/court_info_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Tab 2: Bản đồ
class MapTab extends StatefulWidget {
  const MapTab({super.key}); // Thêm super.key

  @override
  _MapTabState createState() => _MapTabState();
}

enum SportType { pickleball, badminton, football, tennis }

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(
    21.028511,
    105.804817,
  ); // Vị trí mặc định Hà Nội
  Set<Marker> _markers = {};
  bool _hasLoadedMarkers = false;
  bool _isLoadingLocation = true;
  SportType _selectedSport = SportType.badminton; // Mặc định chọn cầu lông
  final TextEditingController _searchController = TextEditingController();
  List<CourtLocationModel> _lastUpdatedCourts =
      []; // Lưu danh sách courts cuối cùng để tránh update không cần thiết
  bool _isLoadingPlaces = false; // Trạng thái đang tải places từ Google
  bool _searchAllVietnam = false; // Tìm kiếm toàn quốc hay chỉ gần đây

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Lấy vị trí hiện tại của người dùng
  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location service bị tắt, sử dụng vị trí mặc định (Hà Nội)');
        _useDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Permission bị từ chối, sử dụng vị trí mặc định (Hà Nội)');
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print(
          '⚠️ Permission bị từ chối vĩnh viễn, sử dụng vị trí mặc định (Hà Nội)',
        );
        _useDefaultLocation();
        return;
      }

      // Lấy vị trí hiện tại với timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout sau 10 giây
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Di chuyển camera đến vị trí hiện tại
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
          );
        }

        // KHÔNG tự động tải places từ Google - chỉ hiển thị sân từ Firestore
      }
    } catch (e) {
      print("Lỗi lấy vị trí: $e");
      // Sử dụng vị trí mặc định khi có lỗi
      _useDefaultLocation();
    }
  }

  // Sử dụng vị trí mặc định (Hà Nội) khi không lấy được vị trí
  void _useDefaultLocation() {
    if (mounted) {
      setState(() {
        // Vị trí mặc định: Hà Nội, Việt Nam
        _currentPosition = const LatLng(21.028511, 105.804817);
        _isLoadingLocation = false;
      });

      // Di chuyển camera đến vị trí mặc định
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
        );
      }

      // Hiển thị thông báo cho người dùng (chỉ hiển thị một lần)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể lấy vị trí. Đang hiển thị bản đồ Hà Nội.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Áp dụng style tối khi map được tạo
    controller.setMapStyle(_mapStyle);

    // Di chuyển camera đến vị trí hiện tại nếu đã có
    if (!_isLoadingLocation) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
      );
      // KHÔNG tự động tải places từ Google - chỉ hiển thị sân từ Firestore
    }
  }

  // Tải các địa điểm từ Google Places API
  Future<void> _loadPlacesFromGoogle() async {
    if (_isLoadingPlaces) return;

    setState(() {
      _isLoadingPlaces = true;
      _markers = {}; // Xóa markers cũ khi bắt đầu tìm kiếm mới
    });

    try {
      // Chuyển đổi SportType enum sang string
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
        // Tìm kiếm trên toàn Việt Nam
        print('🇻🇳 Đang tìm kiếm $sportTypeString trên toàn Việt Nam...');
        places = await PlacesService.searchAllVietnam(
          sportType: sportTypeString,
          maxCities: 10, // Tìm ở 10 thành phố lớn nhất
        );
      } else {
        // Tìm kiếm gần vị trí hiện tại
        print(
          '🏸 Đang tìm kiếm địa điểm: $sportTypeString gần vị trí hiện tại',
        );
        places = await PlacesService.searchBySportType(
          location: _currentPosition,
          sportType: sportTypeString,
          radius: 20000, // 20km để tìm được nhiều hơn
        );
      }

      if (mounted) {
        print('📦 Nhận được ${places.length} địa điểm từ Google Places API');

        if (places.isEmpty) {
          print('⚠️ Không tìm thấy địa điểm nào. Có thể:');
          print('   1. API Key chưa được cấu hình đúng');
          print('   2. Places API chưa được enable');
          print('   3. Không có địa điểm trong khu vực này');
          print('   4. Kiểm tra console log để xem lỗi chi tiết');

          // Hiển thị thông báo cho user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Không tìm thấy sân trong khu vực này. Thử chọn "Toàn quốc" hoặc tìm kiếm theo từ khóa.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        // Chuyển đổi PlaceResult sang CourtLocationModel
        final courts = places
            .map((place) => place.toCourtLocationModel())
            .toList();

        print('✅ Đã chuyển đổi thành ${courts.length} CourtLocationModel');

        // Cập nhật markers từ Google Places
        _updateMarkersFromPlaces(courts);

        // Nếu tìm kiếm toàn quốc, zoom out để hiển thị tất cả
        if (_searchAllVietnam && courts.isNotEmpty && _mapController != null) {
          // Zoom toàn quốc Việt Nam
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              const LatLng(16.0544, 108.2022), // Trung tâm Việt Nam
              6.0, // Zoom level để hiển thị toàn quốc
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Lỗi tải places từ Google: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Lỗi tải địa điểm';
        if (e.toString().contains('REQUEST_DENIED')) {
          errorMessage = 'API Key không hợp lệ hoặc Places API chưa được bật';
        } else if (e.toString().contains('OVER_QUERY_LIMIT')) {
          errorMessage = 'Đã vượt quá giới hạn API. Vui lòng thử lại sau.';
        } else if (e.toString().contains('ZERO_RESULTS')) {
          errorMessage =
              'Không tìm thấy sân trong khu vực này. Thử chọn "Toàn quốc".';
        } else {
          errorMessage = 'Lỗi: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
        });
      }
    }
  }

  // Tìm kiếm sân từ Firestore theo từ khóa
  void _searchCourts(String query) {
    if (query.trim().isEmpty) {
      // Nếu query rỗng, hiển thị lại tất cả sân
      setState(() {
        _lastUpdatedCourts = [];
      });
      return;
    }

    final firestoreRepo = context.read<FirestoreRepository>();
    firestoreRepo
        .getCourtLocationsStream()
        .first
        .then((allCourts) {
          final queryLower = query.toLowerCase();
          final filteredCourts = allCourts.where((court) {
            final nameMatch = court.name.toLowerCase().contains(queryLower);
            final addressMatch = court.address.toLowerCase().contains(
              queryLower,
            );
            final sportTypeMatch =
                court.sportType?.toLowerCase().contains(queryLower) ?? false;

            // Kiểm tra từ khóa phổ biến
            if (queryLower.contains('cầu lông') ||
                queryLower.contains('badminton') ||
                queryLower.contains('cau long')) {
              return (court.sportType?.toLowerCase() == 'badminton' ||
                  court.name.toLowerCase().contains('cầu lông') ||
                  court.name.toLowerCase().contains('badminton'));
            }
            if (queryLower.contains('pickleball') ||
                queryLower.contains('pickle')) {
              return (court.sportType?.toLowerCase() == 'pickleball' ||
                  court.name.toLowerCase().contains('pickleball'));
            }
            if (queryLower.contains('bóng đá') ||
                queryLower.contains('football') ||
                queryLower.contains('bong da')) {
              return (court.sportType?.toLowerCase() == 'football' ||
                  court.name.toLowerCase().contains('bóng đá') ||
                  court.name.toLowerCase().contains('football'));
            }
            if (queryLower.contains('tennis')) {
              return (court.sportType?.toLowerCase() == 'tennis' ||
                  court.name.toLowerCase().contains('tennis'));
            }

            return nameMatch || addressMatch || sportTypeMatch;
          }).toList();

          if (mounted) {
            setState(() {
              _lastUpdatedCourts = [];
            });
            _updateMarkers(filteredCourts);
          }
        })
        .catchError((e) {
          print('❌ Lỗi tìm kiếm: $e');
        });
  }

  // Cập nhật markers từ Google Places - kết hợp với sân từ Firestore
  void _updateMarkersFromPlaces(List<CourtLocationModel> googlePlacesCourts) {
    // Lấy sân từ Firestore và kết hợp với Google Places
    final firestoreRepo = context.read<FirestoreRepository>();
    firestoreRepo
        .getCourtLocationsStream()
        .first
        .then((firestoreCourts) {
          // Kết hợp cả hai nguồn dữ liệu
          final allCourts = <CourtLocationModel>[];

          // Thêm sân từ Google Places
          allCourts.addAll(googlePlacesCourts);

          // Thêm sân từ Firestore (tránh duplicate bằng placeId hoặc tọa độ)
          final existingIds = googlePlacesCourts.map((c) => c.id).toSet();
          final existingCoords = googlePlacesCourts
              .map(
                (c) =>
                    '${c.latitude.toStringAsFixed(4)}_${c.longitude.toStringAsFixed(4)}',
              )
              .toSet();

          for (final court in firestoreCourts) {
            final coordKey =
                '${court.latitude.toStringAsFixed(4)}_${court.longitude.toStringAsFixed(4)}';
            if (!existingIds.contains(court.id) &&
                !existingCoords.contains(coordKey) &&
                court.latitude != 0.0 &&
                court.longitude != 0.0) {
              allCourts.add(court);
            }
          }

          // Filter theo loại sân đã chọn
          final filteredCourts = _filterCourtsBySport(
            allCourts,
            _selectedSport,
          );

          // Cập nhật markers với tất cả sân đã filter
          _updateMarkers(filteredCourts);
        })
        .catchError((e) {
          print('Lỗi lấy sân từ Firestore: $e');
          // Nếu lỗi, chỉ hiển thị sân từ Google Places
          if (googlePlacesCourts.isEmpty) {
            if (mounted) {
              setState(() {
                _markers = {};
                _hasLoadedMarkers = true;
              });
            }
            return;
          }
          final filteredCourts = _filterCourtsBySport(
            googlePlacesCourts,
            _selectedSport,
          );
          _updateMarkers(filteredCourts);
        });
  }

  // Hàm filter courts theo loại sân
  List<CourtLocationModel> _filterCourtsBySport(
    List<CourtLocationModel> courts,
    SportType sportType,
  ) {
    if (courts.isEmpty) return [];

    // Map SportType enum sang string
    String sportTypeString;
    switch (sportType) {
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

    return courts.where((court) {
      // Ưu tiên filter theo field sportType nếu có
      if (court.sportType != null) {
        return court.sportType!.toLowerCase() == sportTypeString;
      }

      // Fallback: Tìm kiếm trong tên và địa chỉ
      final nameLower = court.name.toLowerCase();
      final addressLower = court.address.toLowerCase();

      switch (sportType) {
        case SportType.badminton:
          return nameLower.contains('cầu lông') ||
              nameLower.contains('badminton') ||
              nameLower.contains('cau long') ||
              addressLower.contains('cầu lông') ||
              addressLower.contains('badminton');
        case SportType.pickleball:
          return nameLower.contains('pickleball') ||
              nameLower.contains('pickle') ||
              addressLower.contains('pickleball');
        case SportType.football:
          return nameLower.contains('bóng đá') ||
              nameLower.contains('football') ||
              nameLower.contains('soccer') ||
              nameLower.contains('bong da') ||
              nameLower.contains('sân bóng') ||
              addressLower.contains('bóng đá') ||
              addressLower.contains('football');
        case SportType.tennis:
          return nameLower.contains('tennis') ||
              nameLower.contains('sân tennis') ||
              addressLower.contains('tennis');
      }
    }).toList();
  }

  // Hàm cập nhật markers từ danh sách sân
  void _updateMarkers(List<CourtLocationModel> courts) {
    if (courts.isEmpty) {
      if (mounted) {
        setState(() {
          _markers = {};
          _hasLoadedMarkers = true;
        });
      }
      return;
    }

    // Filter courts theo sport type đã chọn
    final filteredCourts = _filterCourtsBySport(courts, _selectedSport);

    // Debug: In ra số lượng sân được filter
    print('Tổng số sân: ${courts.length}');
    print('Số sân sau filter (${_selectedSport}): ${filteredCourts.length}');
    if (filteredCourts.isNotEmpty) {
      print(
        'Tên các sân được filter: ${filteredCourts.map((c) => c.name).join(", ")}',
      );
    }

    // Kiểm tra xem có thay đổi không để tránh update không cần thiết
    if (_lastUpdatedCourts.length == filteredCourts.length &&
        _lastUpdatedCourts.every((court) => filteredCourts.contains(court))) {
      // Không có thay đổi, không cần update
      return;
    }

    // Lưu danh sách hiện tại
    _lastUpdatedCourts = List.from(filteredCourts);

    // Nếu không có sân nào khớp filter, hiển thị tất cả sân (fallback)
    final courtsToDisplay = filteredCourts.isEmpty ? courts : filteredCourts;

    if (courtsToDisplay.isEmpty) {
      if (mounted) {
        setState(() {
          _markers = {};
          _hasLoadedMarkers = true;
        });
      }
      return;
    }

    // Sắp xếp theo khoảng cách từ vị trí hiện tại nếu có
    final sortedCourts = List<CourtLocationModel>.from(courtsToDisplay);
    if (_currentPosition.latitude != 21.028511 ||
        _currentPosition.longitude != 105.804817) {
      // Có vị trí thực, sắp xếp theo khoảng cách
      sortedCourts.sort((a, b) {
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

    // Chỉ tạo markers mới khi thực sự cần
    // Giới hạn số lượng markers để tránh quá tải buffer
    const int maxMarkers = 50; // Giới hạn tối đa 50 markers
    final courtsToShow = sortedCourts.length > maxMarkers
        ? sortedCourts.take(maxMarkers).toList()
        : sortedCourts;

    Set<Marker> markers = {};
    for (final court in courtsToShow) {
      // Kiểm tra tọa độ hợp lệ
      if (court.latitude == 0.0 && court.longitude == 0.0) {
        continue; // Bỏ qua sân không có tọa độ
      }

      // Lấy icon marker dựa trên loại sân
      final markerIcon = _getMarkerIcon(court);

      // Tạo marker với icon và info window chi tiết
      final marker = Marker(
        markerId: MarkerId(court.id),
        position: LatLng(court.latitude, court.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: court.name,
          snippet: _buildInfoWindowSnippet(court),
        ),
        onTap: () {
          _showCourtBottomSheet(court);
        },
      );
      markers.add(marker);
    }

    // Cập nhật state với danh sách markers mới
    if (mounted) {
      setState(() {
        _markers = markers;
        _hasLoadedMarkers = true;
      });

      // Tự động zoom vào các markers được filter và vị trí hiện tại
      if (markers.isNotEmpty && _mapController != null) {
        _zoomToMarkersAndLocation(markers);
      }
    }
  }

  // Lấy icon marker dựa trên loại sân
  BitmapDescriptor _getMarkerIcon(CourtLocationModel court) {
    // Xác định loại sân từ sportType hoặc tên
    String? sportType = court.sportType?.toLowerCase();
    if (sportType == null) {
      final nameLower = court.name.toLowerCase();
      if (nameLower.contains('cầu lông') ||
          nameLower.contains('badminton') ||
          nameLower.contains('cau long')) {
        sportType = 'badminton';
      } else if (nameLower.contains('pickleball') ||
          nameLower.contains('pickle')) {
        sportType = 'pickleball';
      } else if (nameLower.contains('bóng đá') ||
          nameLower.contains('football') ||
          nameLower.contains('bong da') ||
          nameLower.contains('sân bóng')) {
        sportType = 'football';
      } else if (nameLower.contains('tennis')) {
        sportType = 'tennis';
      }
    }

    // Trả về marker với màu phù hợp
    switch (sportType) {
      case 'badminton':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'pickleball':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'football':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'tennis':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  // Tạo snippet cho info window
  String _buildInfoWindowSnippet(CourtLocationModel court) {
    final parts = <String>[];

    // Thêm loại sân nếu có
    if (court.sportType != null) {
      String sportName = '';
      switch (court.sportType!.toLowerCase()) {
        case 'badminton':
          sportName = 'Cầu lông';
          break;
        case 'pickleball':
          sportName = 'Pickleball';
          break;
        case 'football':
          sportName = 'Bóng đá';
          break;
        case 'tennis':
          sportName = 'Tennis';
          break;
        default:
          sportName = court.sportType!;
      }
      parts.add('🏸 $sportName');
    }

    // Thêm địa chỉ
    if (court.address.isNotEmpty) {
      final address = court.address.length > 40
          ? '${court.address.substring(0, 40)}...'
          : court.address;
      parts.add('📍 $address');
    }

    // Thêm giá
    if (court.pricePerHour > 0) {
      final price = NumberFormat.simpleCurrency(
        locale: 'vi_VN',
        decimalDigits: 0,
      ).format(court.pricePerHour);
      parts.add('💰 $price/giờ');
    }

    return parts.join('\n');
  }

  // Hàm zoom vào markers và vị trí hiện tại
  void _zoomToMarkersAndLocation(Set<Marker> markers) {
    if (markers.isEmpty || _mapController == null) return;

    double minLat = _currentPosition.latitude;
    double maxLat = _currentPosition.latitude;
    double minLng = _currentPosition.longitude;
    double maxLng = _currentPosition.longitude;

    // Thêm vị trí hiện tại vào bounds
    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
    }

    // Tính toán bounds với padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Zoom vào bounds với padding lớn hơn để hiển thị cả vị trí hiện tại
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 150.0));
  }

  // Hiển thị bottom sheet chi tiết sân
  void _showCourtBottomSheet(CourtLocationModel court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourtBottomSheet(
        court: court,
        onBookPressed: () {
          Navigator.pop(context);
          // Navigate đến màn hình đặt sân
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourtSelectionScreen(
                selectedCourt: court,
                selectedDate: DateTime.now(),
              ),
            ),
          );
        },
      ),
    );
  }

  // Hàm quay về vị trí hiện tại
  void _goToCurrentLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy repository
    final firestoreRepo = context.watch<FirestoreRepository>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // SỬ DỤNG STREAMBUILDER ĐỂ TỰ ĐỘNG CẬP NHẬT KHI ADMIN THÊM SÂN
      body: StreamBuilder<List<CourtLocationModel>>(
        stream: firestoreRepo.getCourtLocationsStream(), // Gọi hàm Stream mới
        builder: (context, snapshot) {
          // Hiển thị loading chỉ khi chưa có marker nào và đang loading
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_hasLoadedMarkers) {
            return Center(
              child: CircularProgressIndicator(color: colors.secondary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Lỗi tải bản đồ: ${snapshot.error}",
                    style: TextStyle(color: Colors.red[300], fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          // Cập nhật markers khi có dữ liệu - luôn update để áp dụng filter mới
          if (snapshot.hasData && snapshot.data != null) {
            final courts = snapshot.data!;
            // Debounce: Chờ một chút trước khi update để tránh update quá nhiều lần
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _updateMarkers(courts);
              }
            });
          }

          // Hiển thị thông báo nếu không có sân nào (KHÔNG return sớm, để vẫn hiển thị filter buttons)
          // Chỉ đánh dấu để hiển thị overlay thông báo
          final bool showNoCourtsMessage =
              _hasLoadedMarkers && _markers.isEmpty && !_isLoadingPlaces;

          // Hiển thị loading khi đang tải places
          if (_isLoadingPlaces) {
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  mapType: MapType.normal,
                  minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                ),
                Center(
                  child: Card(
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: colors.secondary),
                          const SizedBox(height: 16),
                          Text(
                            "Đang tìm kiếm địa điểm...",
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Luôn hiển thị bản đồ
          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled:
                    false, // Tắt button mặc định, dùng custom
                mapType: MapType.normal,
                minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
                // Tối ưu để giảm buffer usage
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                // mapStyle: _mapStyle, // Style sẽ được set trong _onMapCreated
              ),

              // Thông báo không tìm thấy sân (overlay, không che filter buttons)
              if (showNoCourtsMessage)
                Positioned(
                  top: 120, // Đặt dưới filter buttons
                  left: 20,
                  right: 20,
                  child: Card(
                    color: Colors.white.withOpacity(0.95),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Không tìm thấy sân",
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Thử chọn loại sân khác hoặc tìm kiếm theo từ khóa",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // Thử lại với filter hiện tại
                                  _loadPlacesFromGoogle();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text("Thử lại"),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  // Xóa filter và hiển thị tất cả sân từ Firestore
                                  setState(() {
                                    _selectedSport = SportType.badminton;
                                    _markers = {};
                                    _hasLoadedMarkers = false;
                                    _lastUpdatedCourts = [];
                                    _isLoadingPlaces =
                                        false; // Reset loading state
                                  });
                                  // Force rebuild để StreamBuilder load lại từ Firestore
                                  // StreamBuilder sẽ tự động cập nhật khi state thay đổi
                                },
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text("Xóa filter"),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Search bar và filter buttons
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Tìm kiếm sân...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(
                                () {},
                              ); // Update UI để hiển thị/ẩn nút close
                              // Tìm kiếm real-time khi gõ
                              _searchCourts(value.trim());
                            },
                            onSubmitted: (value) {
                              // Tìm kiếm khi nhấn Enter
                              if (value.trim().isNotEmpty) {
                                _searchCourts(value.trim());
                              } else {
                                // Nếu rỗng, hiển thị lại tất cả
                                setState(() {
                                  _lastUpdatedCourts = [];
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      // Filter buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            _buildFilterButton(
                              "Sân pickleball",
                              Icons.sports_tennis,
                              SportType.pickleball,
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterButton(
                              "Sân cầu lông",
                              Icons.sports_tennis,
                              SportType.badminton,
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterButton(
                              "Sân bóng đá",
                              Icons.sports_soccer,
                              SportType.football,
                              Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterButton(
                              "Sân tennis",
                              Icons.sports_tennis,
                              SportType.tennis,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chú thích (Legend) - hiển thị các loại marker
              Positioned(
                left: 16,
                bottom: 100,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chú thích',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                        'Cầu lông',
                      ),
                      const SizedBox(height: 6),
                      _buildLegendItem(
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                        'Pickleball',
                      ),
                      const SizedBox(height: 6),
                      _buildLegendItem(
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                        'Bóng đá',
                      ),
                      const SizedBox(height: 6),
                      _buildLegendItem(
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet,
                        ),
                        'Tennis',
                      ),
                      const SizedBox(height: 6),
                      _buildLegendItem(
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                        'Khác',
                      ),
                    ],
                  ),
                ),
              ),

              // Floating action buttons
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    // Button quay về vị trí hiện tại
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _goToCurrentLocation,
                      child: Icon(Icons.my_location, color: colors.primary),
                    ),
                    const SizedBox(height: 8),
                    // Button zoom in
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: Icon(Icons.add, color: colors.primary),
                    ),
                    const SizedBox(height: 8),
                    // Button zoom out
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: Icon(Icons.remove, color: colors.primary),
                    ),
                  ],
                ),
              ),

              // Hiển thị loading khi đang lấy vị trí
              if (_isLoadingLocation)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colors.secondary),
                        const SizedBox(height: 16),
                        Text(
                          "Đang lấy vị trí...",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Widget để tạo legend item
  Widget _buildLegendItem(BitmapDescriptor icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hiển thị marker icon (sử dụng Container với màu tương ứng)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getColorFromMarker(icon),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  // Lấy màu từ marker icon
  Color _getColorFromMarker(BitmapDescriptor icon) {
    // Vì không thể lấy màu trực tiếp từ BitmapDescriptor,
    // ta sẽ map dựa trên hue
    // Đây là cách đơn giản, có thể cải thiện sau
    if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)) {
      return Colors.green;
    } else if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)) {
      return Colors.blue;
    } else if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)) {
      return Colors.orange;
    } else if (icon ==
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)) {
      return Colors.purple;
    } else {
      return Colors.red;
    }
  }

  // Widget filter button
  Widget _buildFilterButton(
    String label,
    IconData icon,
    SportType sportType,
    Color color,
  ) {
    final isSelected = _selectedSport == sportType;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSport = sportType;
            // Reset để force update markers với filter mới
            _lastUpdatedCourts = [];
            _markers = {}; // Xóa markers cũ
            _hasLoadedMarkers = false;
          });
          // Tìm kiếm từ Google Places API khi chọn filter
          _loadPlacesFromGoogle();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom sheet hiển thị chi tiết sân
class _CourtBottomSheet extends StatelessWidget {
  final CourtLocationModel court;
  final VoidCallback onBookPressed;

  const _CourtBottomSheet({required this.court, required this.onBookPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formattedPrice = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    ).format(court.pricePerHour);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hình ảnh sân từ Google Maps
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      CourtInfoService.getCourtImageUrl(
                        LatLng(court.latitude, court.longitude),
                        width: 400,
                        height: 200,
                      ),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tên sân
                  Text(
                    court.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Địa chỉ
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          court.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Thông tin giá và số sân
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.attach_money,
                          "Giá/giờ",
                          formattedPrice,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.sports_tennis,
                          "Số sân",
                          "${court.totalCourts} sân",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút chỉ đường
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Hiển thị loading
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Đang lấy vị trí hiện tại...'),
                                ],
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }

                        // Lấy vị trí hiện tại của user
                        LatLng? currentLocation;
                        try {
                          bool serviceEnabled =
                              await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) {
                            throw Exception('Dịch vụ vị trí chưa được bật');
                          }

                          LocationPermission permission =
                              await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                            if (permission == LocationPermission.denied) {
                              throw Exception(
                                'Quyền truy cập vị trí bị từ chối',
                              );
                            }
                          }

                          if (permission == LocationPermission.deniedForever) {
                            throw Exception(
                              'Quyền truy cập vị trí bị từ chối vĩnh viễn',
                            );
                          }

                          Position position =
                              await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                                timeLimit: const Duration(seconds: 10),
                              );
                          currentLocation = LatLng(
                            position.latitude,
                            position.longitude,
                          );
                        } catch (e) {
                          print('Lỗi lấy vị trí: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Không thể lấy vị trí: $e. Sử dụng chỉ đường không có điểm xuất phát.',
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }

                        // Tạo URL chỉ đường với vị trí hiện tại (nếu có)
                        final url = CourtInfoService.getDirectionsUrl(
                          LatLng(court.latitude, court.longitude),
                          destinationName: court.name,
                          origin:
                              currentLocation, // Truyền vị trí hiện tại nếu có
                        );
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể mở Google Maps'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text(
                        "Chỉ đường",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút đặt sân
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBookPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.secondary,
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Đặt sân ngay",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Thêm style tối cho bản đồ (tùy chọn nhưng sẽ hợp theme)
const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
''';
