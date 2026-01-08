import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/models/user_model.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreRepository {
  final FirebaseFirestore _firebaseFirestore;

  // SỬA LỖI 1 & 2: Định nghĩa tên collection ở đây
  final String _courtCollection = 'court_locations';
  final String _bookingCollection = 'bookings';
  final String _notificationCollection = 'notifications';
  final String _usersCollection = 'users';

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
        })
        .handleError((error) {
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

  // Lấy thông tin sân theo ID
  Future<CourtLocationModel?> getCourtLocationById(String courtId) async {
    try {
      final doc = await _firebaseFirestore
          .collection(_courtCollection)
          .doc(courtId)
          .get();
      if (doc.exists) {
        return CourtLocationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Lỗi getCourtLocationById: $e");
      return null;
    }
  }

  // --- Booking Functions (User & Admin) ---

  // Lấy stream các booking của 1 Sân Lớn trong 1 Ngày
  Stream<List<BookingModel>> getBookingsStreamForDay(
    String courtId,
    DateTime date,
  ) {
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
        })
        .handleError((error) {
          print("Lỗi getBookingsStreamForDay: $error");
          return <BookingModel>[];
        });
  }

  // Tạo booking mới - trả về bookingId
  Future<String> createBooking(BookingModel booking) async {
    DateTime normalizedDate = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
    );

    BookingModel bookingToSave = booking.copyWith(date: normalizedDate);

    final docRef = await _firebaseFirestore
        .collection(_bookingCollection) // Dùng biến
        .add(bookingToSave.toFirestore());

    return docRef.id;
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
        })
        .handleError((error) {
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
        })
        .handleError((error) {
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

  // --- Notification Functions ---

  // Tạo notification mới
  Future<void> createNotification(NotificationModel notification) async {
    await _firebaseFirestore
        .collection(_notificationCollection)
        .add(notification.toFirestore());
  }

  // Lấy stream các notifications của user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firebaseFirestore
        .collection(_notificationCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          // Sort trong code thay vì dùng orderBy để tránh cần index
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        })
        .handleError((error) {
          print("Lỗi getUserNotificationsStream: $error");
          return <NotificationModel>[];
        });
  }

  // Đánh dấu notification là đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firebaseFirestore
        .collection(_notificationCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Đánh dấu tất cả notifications là đã đọc
  Future<void> markAllNotificationsAsRead(String userId) async {
    final snapshot = await _firebaseFirestore
        .collection(_notificationCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firebaseFirestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Xóa notification
  Future<void> deleteNotification(String notificationId) async {
    await _firebaseFirestore
        .collection(_notificationCollection)
        .doc(notificationId)
        .delete();
  }

  // --- User Management Functions (Admin) ---

  // Lấy stream tất cả users
  Stream<List<UserModel>> getAllUsersStream() {
    return _firebaseFirestore
        .collection(_usersCollection)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          print("Lỗi getAllUsersStream: $error");
          return <UserModel>[];
        });
  }

  // Cập nhật thông tin user (admin)
  Future<void> updateUser(UserModel user) async {
    await _firebaseFirestore
        .collection(_usersCollection)
        .doc(user.id)
        .update(user.toFirestore());
  }

  // Xóa user (admin)
  Future<void> deleteUser(String userId) async {
    await _firebaseFirestore.collection(_usersCollection).doc(userId).delete();
  }

  // Thay đổi role của user (admin)
  Future<void> updateUserRole(String userId, String role) async {
    await _firebaseFirestore.collection(_usersCollection).doc(userId).update({
      'role': role,
    });
  }

  // --- Storage Functions ---

  // Upload ảnh lên Firebase Storage
  Future<String> uploadImage(String filePath, String folder) async {
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File không tồn tại tại đường dẫn: $filePath');
      }

      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      Reference ref = FirebaseStorage.instance.ref().child('$folder/$fileName');

      // Thêm metadata để server biết loại file (giảm thiểu lỗi upload session)
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg', // Giả định là jpeg/png từ ImagePicker
        customMetadata: {'picked-file-path': filePath},
      );

      UploadTask uploadTask = ref.putFile(file, metadata);

      // Lắng nghe tiến trình (nếu cần debug)
      // uploadTask.snapshotEvents.listen((event) {
      //   print('Upload progress: ${(event.bytesTransferred / event.totalBytes) * 100}%');
      // });

      TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception(
          'Upload không thành công. Trạng thái: ${snapshot.state}',
        );
      }
    } catch (e) {
      print("Lỗi uploadImage chi tiết: $e");
      throw e; // Ném lỗi ra để UI bắt được
    }
  }
}
