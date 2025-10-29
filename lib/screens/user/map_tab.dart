import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// Tab 2: Bản đồ
class MapTab extends StatefulWidget {
  const MapTab({super.key}); // Thêm super.key

  @override
  _MapTabState createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition =
      const LatLng(21.028511, 105.804817); // Vị trí Hà Nội
  Set<Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Áp dụng style tối khi map được tạo
    controller.setMapStyle(_mapStyle);
  }

  // Hàm cập nhật markers từ danh sách sân
  void _updateMarkers(List<CourtLocationModel> courts) {
    Set<Marker> markers = {};
    for (final court in courts) {
      final marker = Marker(
        markerId: MarkerId(court.id),
        position: LatLng(court.latitude, court.longitude),
        infoWindow: InfoWindow(
          title: court.name,
          snippet: court.address,
        ),
        // (Tùy chọn) Thêm sự kiện on-tap
        onTap: () {
          // TODO: Hiển thị BottomSheet chi tiết sân
        },
      );
      markers.add(marker);
    }
    // Cập nhật state với danh sách markers mới
    // Thêm kiểm tra 'mounted' để tránh lỗi
    if (mounted) {
      setState(() {
        _markers = markers;
      });
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
        stream: firestoreRepo
            .getCourtLocationsStream(), // Gọi hàm Stream mới
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _markers.isEmpty) {
            // Hiển thị loading chỉ khi chưa có marker nào
            return Center(
                child: CircularProgressIndicator(color: colors.secondary));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Lỗi tải bản đồ: ${snapshot.error}",
                    style: TextStyle(color: Colors.white)));
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // Nếu có dữ liệu mới, cập nhật markers
            // Gọi sau khi build để tránh lỗi setState
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _updateMarkers(snapshot.data!);
            });
          }

          // Luôn hiển thị bản đồ
          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12.0,
            ),
            markers: _markers,
            // mapStyle: _mapStyle, // Style sẽ được set trong _onMapCreated
          );
        },
      ),
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

