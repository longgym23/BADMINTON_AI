import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';

class PlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Cache để giảm số requests (tiết kiệm free credit)
  static final Map<String, List<PlaceResult>> _cache = {};
  static const Duration _cacheDuration = Duration(hours: 24);
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Kiểm tra API Key có được cấu hình chưa
  static bool get isApiKeyConfigured =>
      _apiKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE' && _apiKey.isNotEmpty;

  // Tìm kiếm các địa điểm gần vị trí
  static Future<List<PlaceResult>> searchNearby({
    required LatLng location,
    required String query, // Ví dụ: "badminton court", "sân cầu lông"
    int radius = 5000, // Bán kính tìm kiếm (mét)
    String? language, // 'vi' cho tiếng Việt
    bool useCache = true, // Sử dụng cache để tiết kiệm requests
  }) async {
    // Kiểm tra API Key
    if (!isApiKeyConfigured) {
      print('⚠️ LỖI: Google Places API Key chưa được cấu hình!');
      print(
        'Vui lòng thay thế YOUR_GOOGLE_PLACES_API_KEY_HERE trong lib/services/places_service.dart',
      );
      print('Xem hướng dẫn trong file GOOGLE_PLACES_API_SETUP.md');
      return [];
    }

    // Kiểm tra cache để tiết kiệm requests (free credit)
    if (useCache) {
      final cacheKey =
          '${location.latitude.toStringAsFixed(2)}_${location.longitude.toStringAsFixed(2)}_$query';
      if (_cache.containsKey(cacheKey)) {
        final timestamp = _cacheTimestamps[cacheKey];
        if (timestamp != null &&
            DateTime.now().difference(timestamp) < _cacheDuration) {
          print('💾 Sử dụng cache (tiết kiệm free credit)');
          return _cache[cacheKey]!;
        }
      }
    }

    try {
      // Sử dụng Text Search API để tìm kiếm theo từ khóa
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$_baseUrl/textsearch/json?query=$encodedQuery&location=${location.latitude},${location.longitude}&radius=$radius&key=$_apiKey${language != null ? '&language=$language' : ''}',
      );

      print(
        '🔍 Đang tìm kiếm: "$query" tại vị trí (${location.latitude}, ${location.longitude})',
      );
      print(
        '📡 URL (ẩn API key): ${url.toString().replaceAll(_apiKey, 'API_KEY_HIDDEN')}',
      );

      final response = await http.get(url);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String;
        print('📋 API Response status: $status');

        if (status == 'OK') {
          final results = data['results'] as List? ?? [];
          final places = results
              .map((json) => PlaceResult.fromJson(json))
              .toList();
          print('✅ Tìm thấy ${places.length} địa điểm cho query "$query"');

          if (places.isNotEmpty) {
            print('📍 Địa điểm đầu tiên: ${places.first.name}');
            print('📍 Địa chỉ: ${places.first.address ?? "N/A"}');
          }

          // Lưu vào cache để tiết kiệm requests
          if (useCache) {
            final cacheKey =
                '${location.latitude.toStringAsFixed(2)}_${location.longitude.toStringAsFixed(2)}_$query';
            _cache[cacheKey] = places;
            _cacheTimestamps[cacheKey] = DateTime.now();
          }

          return places;
        } else if (status == 'ZERO_RESULTS') {
          print('ℹ️ Không tìm thấy địa điểm nào cho query "$query"');
          print('   Vị trí: (${location.latitude}, ${location.longitude})');
          print('   Bán kính: ${radius}m');
          return [];
        } else {
          final errorMsg = data['error_message'] ?? 'Unknown error';
          print('❌ Places API Error: $status - $errorMsg');
          print('📄 Full response: ${json.encode(data)}');
          print('🔍 Query: "$query"');
          print('📍 Location: (${location.latitude}, ${location.longitude})');
          print('📏 Radius: ${radius}m');

          // Hiển thị lỗi cụ thể
          if (data['status'] == 'REQUEST_DENIED') {
            print('⚠️ API Key không hợp lệ hoặc Places API chưa được enable!');
            print('Vui lòng kiểm tra:');
            print(
              '1. API Key đã đúng chưa? (Hiện tại: ${_apiKey.substring(0, 10)}...)',
            );
            print(
              '2. Places API đã được enable trong Google Cloud Console chưa?',
            );
            print('3. API Key có restrictions không?');
            print('4. Billing đã được enable chưa?');
          } else if (data['status'] == 'OVER_QUERY_LIMIT') {
            print(
              '⚠️ Đã vượt quá quota! Kiểm tra billing và quota trong Cloud Console',
            );
          } else if (data['status'] == 'INVALID_REQUEST') {
            print('⚠️ Request không hợp lệ. Kiểm tra lại query và parameters');
          }

          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        final bodyPreview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        print('Response body: $bodyPreview');
        return [];
      }
    } catch (e) {
      print('❌ Error searching places: $e');
      return [];
    }
  }

  // Tìm kiếm theo thành phố/tỉnh ở Việt Nam
  static Future<List<PlaceResult>> searchByCity({
    required String cityName, // Ví dụ: "Hà Nội", "Hồ Chí Minh", "Đà Nẵng"
    required String
    sportType, // 'badminton', 'pickleball', 'football', 'tennis'
    String? language, // 'vi' cho tiếng Việt
    bool useCache = true,
  }) async {
    // Tọa độ các thành phố lớn ở Việt Nam
    final Map<String, LatLng> vietnamCities = {
      'Hà Nội': const LatLng(21.0285, 105.8542),
      'Hồ Chí Minh': const LatLng(10.8231, 106.6297),
      'Đà Nẵng': const LatLng(16.0544, 108.2022),
      'Hải Phòng': const LatLng(20.8449, 106.6881),
      'Cần Thơ': const LatLng(10.0452, 105.7469),
      'An Giang': const LatLng(10.5216, 105.1259),
      'Bà Rịa - Vũng Tàu': const LatLng(10.3460, 107.0843),
      'Bắc Giang': const LatLng(21.2734, 106.1946),
      'Bắc Kạn': const LatLng(22.1470, 105.8342),
      'Bạc Liêu': const LatLng(9.2942, 105.7278),
      'Bắc Ninh': const LatLng(21.1861, 106.0763),
      'Bến Tre': const LatLng(10.2415, 106.3755),
      'Bình Định': const LatLng(13.8800, 109.1170),
      'Bình Dương': const LatLng(11.3254, 106.4774),
      'Bình Phước': const LatLng(11.7512, 106.7235),
      'Bình Thuận': const LatLng(10.9289, 108.1021),
      'Cà Mau': const LatLng(9.1769, 105.1527),
      'Cao Bằng': const LatLng(22.6657, 106.2577),
      'Đắk Lắk': const LatLng(12.6662, 108.0505),
      'Đắk Nông': const LatLng(12.0046, 107.6877),
      'Điện Biên': const LatLng(21.3833, 103.0167),
      'Đồng Nai': const LatLng(10.9574, 106.8429),
      'Đồng Tháp': const LatLng(10.4930, 105.7469),
      'Gia Lai': const LatLng(13.9833, 108.0000),
      'Hà Giang': const LatLng(22.8333, 104.9833),
      'Hà Nam': const LatLng(20.5411, 105.9220),
      'Hà Tĩnh': const LatLng(18.3333, 105.9000),
      'Hải Dương': const LatLng(20.9373, 106.3146),
      'Hậu Giang': const LatLng(9.7844, 105.4700),
      'Hòa Bình': const LatLng(20.8133, 105.3383),
      'Hưng Yên': const LatLng(20.6464, 106.0511),
      'Khánh Hòa': const LatLng(12.2388, 109.1967),
      'Kiên Giang': const LatLng(9.9580, 105.1234),
      'Kon Tum': const LatLng(14.3545, 108.0076),
      'Lai Châu': const LatLng(22.3964, 103.4582),
      'Lâm Đồng': const LatLng(11.9404, 108.4583),
      'Lạng Sơn': const LatLng(21.8536, 106.7613),
      'Lào Cai': const LatLng(22.4856, 103.9700),
      'Long An': const LatLng(10.6086, 106.6714),
      'Nam Định': const LatLng(20.4201, 106.1789),
      'Nghệ An': const LatLng(18.6796, 105.6813),
      'Ninh Bình': const LatLng(20.2539, 105.9750),
      'Ninh Thuận': const LatLng(11.5643, 108.9886),
      'Phú Thọ': const LatLng(21.3081, 105.3139),
      'Phú Yên': const LatLng(13.0889, 109.2950),
      'Quảng Bình': const LatLng(17.4687, 106.6227),
      'Quảng Nam': const LatLng(15.8801, 108.3380),
      'Quảng Ngãi': const LatLng(15.1167, 108.8000),
      'Quảng Ninh': const LatLng(21.0064, 107.2925),
      'Quảng Trị': const LatLng(16.7500, 107.2000),
      'Sóc Trăng': const LatLng(9.6025, 105.9739),
      'Sơn La': const LatLng(21.3257, 103.9180),
      'Tây Ninh': const LatLng(11.3131, 106.0963),
      'Thái Bình': const LatLng(20.4461, 106.3368),
      'Thái Nguyên': const LatLng(21.5942, 105.8482),
      'Thanh Hóa': const LatLng(19.8067, 105.7853),
      'Thừa Thiên Huế': const LatLng(16.4637, 107.5909),
      'Tiền Giang': const LatLng(10.3600, 106.3600),
      'Trà Vinh': const LatLng(9.9347, 106.3453),
      'Tuyên Quang': const LatLng(21.8180, 105.2119),
      'Vĩnh Long': const LatLng(10.2531, 105.9722),
      'Vĩnh Phúc': const LatLng(21.3081, 105.5959),
      'Yên Bái': const LatLng(21.7051, 104.9113),
    };

    // Tìm tọa độ thành phố
    final cityLocation = vietnamCities[cityName];
    if (cityLocation == null) {
      print('⚠️ Không tìm thấy thành phố: $cityName');
      return [];
    }

    // Sử dụng hàm searchBySportType với tọa độ thành phố và radius lớn
    return await searchBySportType(
      location: cityLocation,
      sportType: sportType,
      radius: 50000, // 50km để bao phủ toàn thành phố
    );
  }

  // Tìm kiếm trên toàn Việt Nam (các thành phố lớn)
  static Future<List<PlaceResult>> searchAllVietnam({
    required String
    sportType, // 'badminton', 'pickleball', 'football', 'tennis'
    int maxCities = 10, // Giới hạn số thành phố để tránh quá nhiều requests
    bool useCache = true,
  }) async {
    // Danh sách các thành phố lớn nhất Việt Nam
    final List<String> majorCities = [
      'Hà Nội',
      'Hồ Chí Minh',
      'Đà Nẵng',
      'Hải Phòng',
      'Cần Thơ',
      'An Giang',
      'Bình Dương',
      'Đồng Nai',
      'Khánh Hòa',
      'Quảng Ninh',
      'Long An',
      'Bà Rịa - Vũng Tàu',
      'Đắk Lắk',
      'Cà Mau',
      'Bình Thuận',
    ];

    // Giới hạn số thành phố
    final citiesToSearch = majorCities.take(maxCities).toList();

    print(
      '🇻🇳 Đang tìm kiếm ${sportType} trên ${citiesToSearch.length} thành phố lớn ở Việt Nam...',
    );

    List<PlaceResult> allResults = [];
    Set<String> seenPlaceIds = {}; // Tránh duplicate

    // Tìm kiếm từng thành phố
    for (int i = 0; i < citiesToSearch.length; i++) {
      final city = citiesToSearch[i];
      print(
        '📍 Đang tìm kiếm tại $city (${i + 1}/${citiesToSearch.length})...',
      );

      try {
        final results = await searchByCity(
          cityName: city,
          sportType: sportType,
          language: 'vi',
          useCache: useCache,
        );

        // Thêm vào danh sách nếu chưa có
        for (final result in results) {
          if (!seenPlaceIds.contains(result.placeId)) {
            allResults.add(result);
            seenPlaceIds.add(result.placeId);
          }
        }

        print('✅ Tìm thấy ${results.length} địa điểm tại $city');
      } catch (e) {
        print('❌ Lỗi khi tìm kiếm tại $city: $e');
      }

      // Nghỉ một chút giữa các requests để tránh rate limit
      if (i < citiesToSearch.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    print(
      '🎉 Tổng cộng tìm thấy ${allResults.length} địa điểm trên toàn Việt Nam',
    );
    return allResults;
  }

  // Tìm kiếm theo loại sân
  static Future<List<PlaceResult>> searchBySportType({
    required LatLng location,
    required String
    sportType, // 'badminton', 'pickleball', 'football', 'tennis'
    int radius = 20000, // Tăng lên 20km để tìm được nhiều hơn
  }) async {
    // Sử dụng nhiều từ khóa để tìm kiếm tốt hơn
    List<String> queries = [];

    switch (sportType) {
      case 'badminton':
        queries = [
          'sân cầu lông',
          'cầu lông',
          'badminton court',
          'badminton',
          'sân cầu lông Hà Nội',
          'câu lạc bộ cầu lông',
          'nhà thi đấu cầu lông',
        ];
        break;
      case 'pickleball':
        queries = [
          'pickleball court',
          'sân pickleball',
          'pickleball',
          'sân pickleball Việt Nam',
        ];
        break;
      case 'football':
        queries = [
          'sân bóng đá',
          'bóng đá',
          'football field',
          'soccer field',
          'sân cỏ nhân tạo',
          'sân bóng mini',
        ];
        break;
      case 'tennis':
        queries = ['sân tennis', 'tennis court', 'tennis', 'sân quần vợt'];
        break;
      default:
        queries = ['sân cầu lông', 'badminton court', 'cầu lông', 'badminton'];
    }

    // Tìm kiếm với tất cả các từ khóa và gộp kết quả
    List<PlaceResult> allResults = [];
    Set<String> seenPlaceIds = {}; // Tránh duplicate

    for (final query in queries) {
      final results = await searchNearby(
        location: location,
        query: query,
        radius: radius,
        language: 'vi',
        useCache: true,
      );

      // Thêm vào danh sách nếu chưa có
      for (final result in results) {
        if (!seenPlaceIds.contains(result.placeId)) {
          allResults.add(result);
          seenPlaceIds.add(result.placeId);
        }
      }

      // Nghỉ một chút giữa các requests để tránh rate limit
      await Future.delayed(const Duration(milliseconds: 200));
    }

    print('📊 Tổng cộng tìm thấy ${allResults.length} địa điểm (${sportType})');
    return allResults;
  }
}

// Model cho kết quả từ Places API
class PlaceResult {
  final String placeId;
  final String name;
  final String? address;
  final LatLng location;
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final String? website;

  PlaceResult({
    required this.placeId,
    required this.name,
    this.address,
    required this.location,
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.website,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;

    return PlaceResult(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: json['formatted_address'] as String?,
      location: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      userRatingsTotal: json['user_ratings_total'] as int?,
    );
  }

  // Chuyển đổi sang CourtLocationModel để tương thích với code hiện tại
  CourtLocationModel toCourtLocationModel({String? overrideSportType}) {
    return CourtLocationModel(
      id: placeId,
      name: name,
      address: address ?? 'Không có địa chỉ',
      latitude: location.latitude,
      longitude: location.longitude,
      pricePerHour: 0.0, // Places API không có giá
      totalCourts: 1, // Mặc định 1 sân
      sportType: overrideSportType ?? _getSportTypeFromName(name),
    );
  }

  String? _getSportTypeFromName(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('badminton') ||
        nameLower.contains('cầu lông') ||
        nameLower.contains('cau long')) {
      return 'badminton';
    } else if (nameLower.contains('pickleball') ||
        nameLower.contains('pickle')) {
      return 'pickleball';
    } else if (nameLower.contains('football') ||
        nameLower.contains('bóng đá') ||
        nameLower.contains('bong da')) {
      return 'football';
    }
    return null;
  }
}
