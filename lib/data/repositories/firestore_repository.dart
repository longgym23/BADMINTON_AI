
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  final FirebaseFirestore _firebaseFirestore;

  // SỬA LỖI 1 & 2: Định nghĩa tên collection ở đây
  final String _courtCollection = 'court_locations';
  final String _bookingCollection = 'bookings';

  FirestoreRepository({required FirebaseFirestore firebaseFirestore})
      : _firebaseFirestore = firebaseFirestore;
  // --- Court Location Functions (Admin) ---

  // Lấy stream các sân
  Stream<List<CourtLocationModel>> getCourtLocationsStream() {
    return _firebaseFirestore
        .collection(_courtCollection) // Dùng biến
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CourtLocationModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      print("Lỗi getCourtLocationsStream: $error");
      return <CourtLocationModel>[];
    });
  }

  // Thêm sân mới
  Future<void> addCourtLocation(CourtLocationModel court) async {
    await _firebaseFirestore
        .collection(_courtCollection) // Dùng biến
        .add(court.toFirestore());
  }

  // Cập nhật sân
  Future<void> updateCourtLocation(CourtLocationModel court) async {
    await _firebaseFirestore
        .collection(_courtCollection) // Dùng biến
        .doc(court.id)
        .update(court.toFirestore());
  }

  // Xóa sân
  Future<void> deleteCourtLocation(String courtId) async {
    await _firebaseFirestore
        .collection(_courtCollection) // Dùng biến
        .doc(courtId)
        .delete();
  }

  // --- Booking Functions (User & Admin) ---

  // Lấy stream các booking của 1 Sân Lớn trong 1 Ngày
  Stream<List<BookingModel>> getBookingsStreamForDay(
      String courtId, DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    return _firebaseFirestore
        .collection(_bookingCollection) // Dùng biến
        .where('courtId', isEqualTo: courtId)
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      print("Lỗi getBookingsStreamForDay: $error");
      return <BookingModel>[];
    });
  }

  // Tạo booking mới
  Future<void> createBooking(BookingModel booking) async {
    DateTime normalizedDate =
        DateTime(booking.date.year, booking.date.month, booking.date.day);

    BookingModel bookingToSave = booking.copyWith(date: normalizedDate);

    await _firebaseFirestore
        .collection(_bookingCollection) // Dùng biến
        .add(bookingToSave.toFirestore());
  }

  // SỬA LỖI 3: Giữ lại MỘT phiên bản của hàm này
  // Lấy lịch sử đặt sân của user
  Stream<List<BookingModel>> getUserBookingHistoryStream(String userId) {
    return _firebaseFirestore
        .collection(_bookingCollection) // Dùng biến
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
      // Sắp xếp thủ công để không cần tạo index trên Firestore
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }).handleError((error) {
      print("Lỗi getUserBookingHistoryStream: $error");
      return <BookingModel>[];
    });
  }

  // Lấy TẤT CẢ booking trong ngày (cho Admin)
  Stream<List<BookingModel>> getAllBookingsForDay(DateTime date) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return _firebaseFirestore
        .collection(_bookingCollection) // Dùng biến
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      print("Lỗi getAllBookingsForDay: $error");
      return <BookingModel>[];
    });
  }

  // SỬA LỖI 4: Giữ lại MỘT phiên bản của hàm này
  // Xóa/Hủy booking
  Future<void> deleteBooking(String bookingId) async {
    await _firebaseFirestore
        .collection(_bookingCollection) // Dùng biến
        .doc(bookingId)
        .delete();
  }
}

