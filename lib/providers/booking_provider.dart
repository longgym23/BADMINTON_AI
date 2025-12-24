import 'dart:async';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/firestore_repository.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:flutter/material.dart';

class BookingProvider with ChangeNotifier {
  final FirestoreRepository _firestoreRepository;
  final AppAuthProvider _authProvider;

  // Stream để lắng nghe các sân con đã bị đặt
  // SỬA: Dùng StreamController để quản lý stream tốt hơn
  StreamSubscription? _bookingSubscription;
  final StreamController<List<BookingModel>> _bookingsStreamController =
      StreamController<List<BookingModel>>.broadcast();
      
  Stream<List<BookingModel>> get bookingsStream => _bookingsStreamController.stream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BookingProvider({
    required FirestoreRepository firestoreRepository,
    required AppAuthProvider authProvider,
  })  : _firestoreRepository = firestoreRepository,
        _authProvider = authProvider;

  // SỬA: Hàm này giờ sẽ lắng nghe và đẩy dữ liệu vào StreamController
  void fetchBookingsForDay(String courtId, DateTime date) {
    // Hủy stream cũ (nếu có) trước khi lắng nghe stream mới
    _bookingSubscription?.cancel();
    
    _bookingSubscription = _firestoreRepository
        .getBookingsStreamForDay(courtId, date)
        .listen((bookings) {
          if (!_bookingsStreamController.isClosed) {
            _bookingsStreamController.add(bookings);
          }
        }, onError: (error) {
           if (!_bookingsStreamController.isClosed) {
             _bookingsStreamController.addError(error);
           }
        });
  }

  // THÊM: Hàm để đóng stream khi không cần thiết (tránh rò rỉ bộ nhớ)
  void disposeStream() {
    _bookingSubscription?.cancel();
    // Đóng StreamController
    // _bookingsStreamController.close(); // Gây lỗi nếu quay lại
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    _bookingsStreamController.close(); // Đóng hẳn khi Provider bị hủy
    super.dispose();
  }

  // Hàm tạo booking mới - trả về bookingId nếu thành công, null nếu thất bại
  Future<String?> createBooking({
    required String courtId,
    required String courtName,
    required int courtNumber,
    required DateTime date,
    required int timeSlot,
    required int price,
  }) async {
    if (_authProvider.userModel == null) {
      _errorMessage = "Bạn phải đăng nhập để đặt sân.";
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _authProvider.userModel!;
      
      BookingModel newBooking = BookingModel(
        userId: user.id,
        userName: user.displayName ?? user.email ?? 'Không tên',
        courtId: courtId,
        courtName: courtName,
        courtNumber: courtNumber,
        date: date,
        timeSlot: timeSlot,
        price: price,
        status: 'confirmed', // Thêm status
      );

      final bookingId = await _firestoreRepository.createBooking(newBooking);
      
      _isLoading = false;
      notifyListeners();
      return bookingId;
    } catch (e) {
      print("Lỗi createBooking: $e");
      _errorMessage = "Đặt sân thất bại: $e";
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}

