import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:badminton_ai/config/api_keys.dart';

/// Service để lấy thông tin chi tiết về sân thể thao từ Google Maps
class CourtInfoService {
  static const String _apiKey = ApiKeys.googleMapsApiKey;

  /// Lấy URL hình ảnh của sân từ Google Maps Static API
  ///
  /// [location] - Tọa độ của sân
  /// [width] - Chiều rộng hình ảnh (mặc định 400)
  /// [height] - Chiều cao hình ảnh (mặc định 300)
  /// [zoom] - Mức độ zoom (mặc định 16)
  static String getCourtImageUrl(
    LatLng location, {
    int width = 400,
    int height = 300,
    int zoom = 16,
  }) {
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=${location.latitude},${location.longitude}'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&maptype=roadmap'
        '&markers=color:red%7C${location.latitude},${location.longitude}'
        '&key=$_apiKey';
  }

  /// Lấy URL hình ảnh Street View của sân (nếu có)
  ///
  /// [location] - Tọa độ của sân
  /// [width] - Chiều rộng hình ảnh (mặc định 400)
  /// [height] - Chiều cao hình ảnh (mặc định 300)
  /// [fov] - Góc nhìn (field of view, mặc định 90)
  static String getStreetViewImageUrl(
    LatLng location, {
    int width = 400,
    int height = 300,
    int fov = 90,
  }) {
    return 'https://maps.googleapis.com/maps/api/streetview?'
        'size=${width}x$height'
        '&location=${location.latitude},${location.longitude}'
        '&fov=$fov'
        '&key=$_apiKey';
  }

  /// Tạo URL để mở Google Maps với chỉ đường đến sân
  ///
  /// [destination] - Tọa độ đích (sân thể thao)
  /// [destinationName] - Tên địa điểm đích (tùy chọn)
  /// [origin] - Tọa độ xuất phát (tùy chọn, nếu null sẽ dùng vị trí hiện tại)
  static String getDirectionsUrl(
    LatLng destination, {
    String? destinationName,
    LatLng? origin,
  }) {
    final dest = destinationName != null
        ? Uri.encodeComponent(destinationName)
        : '${destination.latitude},${destination.longitude}';

    if (origin != null) {
      // Chỉ đường từ vị trí cụ thể
      return 'https://www.google.com/maps/dir/?api=1'
          '&origin=${origin.latitude},${origin.longitude}'
          '&destination=$dest'
          '&travelmode=driving';
    } else {
      // Chỉ đường từ vị trí hiện tại
      return 'https://www.google.com/maps/dir/?api=1'
          '&destination=$dest'
          '&travelmode=driving';
    }
  }

  /// Tạo URL để mở Google Maps app với chỉ đường
  /// Sử dụng cho mobile app (sẽ mở Google Maps app nếu có)
  static String getDirectionsAppUrl(
    LatLng destination, {
    String? destinationName,
    LatLng? origin,
  }) {
    final dest = destinationName != null
        ? Uri.encodeComponent(destinationName)
        : '${destination.latitude},${destination.longitude}';

    if (origin != null) {
      return 'https://www.google.com/maps/dir/'
          '${origin.latitude},${origin.longitude}/'
          '$dest';
    } else {
      return 'https://www.google.com/maps/dir/?api=1'
          '&destination=$dest';
    }
  }
}
