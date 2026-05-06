import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/notification_model.dart';
import 'package:badminton_ai/data/models/user_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/data/models/review_model.dart';
import 'package:badminton_ai/utils/app_logger.dart';

class SupabaseRepository {
  final SupabaseClient _client;

  SupabaseRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  // --- Court Location Functions (Admin & User) ---

  // Lấy stream các sân (Realtime)
  // Lấy stream các sân (Realtime)
  Stream<List<CourtLocationModel>> getCourtLocationsStream({String? ownerId}) {
    if (ownerId != null) {
      return _client
          .from('courts')
          .stream(primaryKey: ['id'])
          .eq('owner_id', ownerId)
          .map(
            (data) =>
                data.map((e) => CourtLocationModel.fromSupabase(e)).toList(),
          );
    }
    return _client
        .from('courts')
        .stream(primaryKey: ['id'])
        .map<List<CourtLocationModel>>(
          (data) =>
              data.map((e) => CourtLocationModel.fromSupabase(e)).toList(),
        );
  }

  // Fetch sân 1 lần (dùng làm fallback khi Realtime Stream bị lỗi / timeout)
  Future<List<CourtLocationModel>> getAllCourtsFallback({
    String? ownerId,
  }) async {
    try {
      dynamic query = _client.from('courts').select();
      if (ownerId != null) query = query.eq('owner_id', ownerId);
      final data = await query;
      return List<CourtLocationModel>.from(
        data.map((e) => CourtLocationModel.fromSupabase(e)),
      );
    } catch (e, st) {
      AppLogger.e('Repository', 'getAllCourtsFallback error', e, st);
      return [];
    }
  }

  // Thêm sân mới
  Future<void> addCourtLocation(CourtLocationModel court) async {
    await _client.from('courts').insert(court.toSupabase());
  }

  // Cập nhật sân
  Future<void> updateCourtLocation(CourtLocationModel court) async {
    await _client.from('courts').update(court.toSupabase()).eq('id', court.id);
  }

  // Xóa sân
  Future<void> deleteCourtLocation(String courtId) async {
    await _client.from('courts').delete().eq('id', courtId);
  }

  // Lấy thông tin sân theo ID
  Future<CourtLocationModel?> getCourtLocationById(String courtId) async {
    try {
      final data = await _client
          .from('courts')
          .select()
          .eq('id', courtId)
          .single();
      return CourtLocationModel.fromSupabase(data);
    } catch (e, st) {
      AppLogger.e('Repository', 'getCourtLocationById error', e, st);
      return null;
    }
  }

  // --- Booking Functions (User & Admin) ---

  // Lấy stream các booking của 1 Sân Lớn trong 1 Ngày
  Stream<List<BookingModel>> getBookingsStreamForDay(
    String courtId,
    DateTime date,
  ) {
    // Supabase lưu date dạng chuỗi YYYY-MM-DD
    String dateStr = date.toIso8601String().split('T')[0];

    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('court_id', courtId)
        .map<List<BookingModel>>(
          (data) => data
              .where(
                (e) =>
                    e['booking_date'] == dateStr &&
                    // Chỉ loại bỏ cancelled. PENDING_PAYMENT sẽ chiếm chỗ tạm thời để tránh đặt trùng,
                    // nhưng cần bỏ qua các pending đã hết hạn (timeout client-side nếu DB chưa có expires_at).
                    e['status'] != 'cancelled' &&
                    (() {
                      final status = e['status'];
                      if (status != 'PENDING_PAYMENT') return true;

                      // Ưu tiên dùng expires_at nếu DB có.
                      final expiresAtRaw = e['expires_at'];
                      if (expiresAtRaw != null) {
                        final expiresAt = DateTime.tryParse(
                          expiresAtRaw.toString(),
                        );
                        if (expiresAt == null) return true;
                        return DateTime.now().isBefore(expiresAt);
                      }

                      // Fallback: dùng created_at + 5 phút.
                      final createdAtRaw = e['created_at'];
                      final createdAt = createdAtRaw != null
                          ? DateTime.tryParse(createdAtRaw.toString())
                          : null;
                      if (createdAt == null) return true;
                      return DateTime.now().difference(createdAt) <
                          const Duration(minutes: 5);
                    })(),
              )
              .map((e) => BookingModel.fromSupabase(e))
              .toList(),
        );
  }

  // Tạo booking mới - bookingId tự sinh
  Future<String> createBooking(BookingModel booking) async {
    final response = await _client
        .from('bookings')
        .insert(booking.toSupabase())
        .select()
        .single();
    return response['id'];
  }

  // Xóa tất cả booking PENDING_PAYMENT của một giao dịch (khi hết giờ thanh toán)
  Future<void> deletePendingBookingsByTransactionId(
    String transactionId,
  ) async {
    await _client
        .from('bookings')
        .delete()
        .eq('transaction_id', transactionId)
        .eq('status', 'PENDING_PAYMENT');
  }

  // Lấy stream các booking của user (Realtime — giới hạn 50 mục gần nhất)
  Stream<List<BookingModel>> getUserBookingHistoryStream(String userId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('booking_date', ascending: false)
        .limit(50) // Pagination: chỉ lấy 50 gần nhất qua stream
        .map((data) => data.map((e) => BookingModel.fromSupabase(e)).toList());
  }

  // Pagination: Lấy thêm booking cũ hơn (dùng khi user kéo "Load more")
  Future<List<BookingModel>> getMoreBookingHistory({
    required String userId,
    required int offset,
    int limit = 20,
  }) async {
    try {
      final data = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('booking_date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return data.map<BookingModel>((e) => BookingModel.fromSupabase(e)).toList();
    } catch (e, st) {
      AppLogger.e('Repository', 'getMoreBookingHistory error', e, st);
      return [];
    }
  }

  // Lấy danh sách booking trong 1 khoảng thời gian (dùng cho thống kê biểu đồ)
  Future<List<BookingModel>> getBookingsForDateRange(
    DateTime start,
    DateTime end, {
    String? ownerId,
    String? courtId,
  }) async {
    final startStr = start.toIso8601String().split('T')[0];
    final endStr   = end.toIso8601String().split('T')[0];
    try {
      var query = _client
          .from('bookings')
          .select()
          .gte('booking_date', startStr)
          .lte('booking_date', endStr);
      if (courtId != null) {
        query = query.eq('court_id', courtId);
      } else if (ownerId != null) {
        final userCourtsResp = await _client
            .from('courts')
            .select('id')
            .eq('owner_id', ownerId);
        final courtIds = (userCourtsResp as List).map((c) => c['id'] as String).toList();
        if (courtIds.isEmpty) return [];
        query = query.inFilter('court_id', courtIds);
      }
      final data = await query;
      return data.map((e) => BookingModel.fromSupabase(e)).toList();
    } catch (e, st) {
      AppLogger.e('Repository', 'getBookingsForDateRange error', e, st);
      return [];
    }
  }

  // Lấy danh sách Sân cho Dropdown (Chủ sân chỉ thấy sân của họ, Admin thấy all)
  Future<List<Map<String, dynamic>>> getSimpleCourtsList({
    String? ownerId,
  }) async {
    try {
      var query = _client.from('courts').select('id, name');
      if (ownerId != null) {
        query = query.eq('owner_id', ownerId);
      }
      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Lỗi lấy danh sách field courts: $e");
      return [];
    }
  }

  // Lấy TẤT CẢ booking trong ngày (cho Admin / Chủ sân)
  Stream<List<BookingModel>> getAllBookingsForDay(
    DateTime date, {
    String? ownerId,
  }) async* {
    String dateStr = date.toIso8601String().split('T')[0];

    if (ownerId != null) {
      final userCourtsResp = await _client
          .from('courts')
          .select('id')
          .eq('owner_id', ownerId);
      final List<String> courtIds = (userCourtsResp as List)
          .map((c) => c['id'] as String)
          .toList();

      if (courtIds.isEmpty) {
        yield [];
        return;
      }

      yield* _client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('booking_date', dateStr)
          .map<List<BookingModel>>(
            (data) => data
                .map((e) => BookingModel.fromSupabase(e))
                .where((b) => courtIds.contains(b.courtId))
                .toList(),
          );
    } else {
      yield* _client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('booking_date', dateStr)
          .map<List<BookingModel>>(
            (data) => data.map((e) => BookingModel.fromSupabase(e)).toList(),
          );
    }
  }

  // Lấy stream bookings trong 1 khoảng thời gian (cho Admin / Chủ sân / Thống kê)
  Stream<List<BookingModel>> getBookingsStream({
    DateTime? start,
    DateTime? end,
    String? ownerId,
    String? courtId,
  }) async* {
    dynamic query = _client.from('bookings').stream(primaryKey: ['id']);

    if (start != null) {
      query = query.gte('booking_date', start.toIso8601String().split('T')[0]);
    }
    if (end != null) {
      query = query.lte('booking_date', end.toIso8601String().split('T')[0]);
    }

    if (ownerId != null) {
      // Vì Supabase stream filter .eq() hạn chế, ta sẽ filter thủ công hoặc dùng rpc nếu phức tạp.
      // Ở đây ta lấy danh sách sân của chủ sân trước.
      final userCourtsResp = await _client
          .from('courts')
          .select('id')
          .eq('owner_id', ownerId);
      final List<String> courtIds = (userCourtsResp as List)
          .map((c) => c['id'] as String)
          .toList();

      if (courtIds.isEmpty) {
        yield [];
        return;
      }

      yield* (query as Stream<List<Map<String, dynamic>>>)
          .map<List<BookingModel>>(
            (data) => data
                .map((e) => BookingModel.fromSupabase(e))
                .where((b) => courtIds.contains(b.courtId))
                .toList(),
          );
    } else if (courtId != null) {
      yield* (query as SupabaseStreamFilterBuilder)
          .eq('court_id', courtId)
          .map<List<BookingModel>>(
            (data) => data.map((e) => BookingModel.fromSupabase(e)).toList(),
          );
    } else {
      yield* (query as Stream<List<Map<String, dynamic>>>)
          .map<List<BookingModel>>(
            (data) => data.map((e) => BookingModel.fromSupabase(e)).toList(),
          );
    }
  }

  // Xóa/Hủy booking
  Future<void> deleteBooking(String bookingId) async {
    await _client.from('bookings').delete().eq('id', bookingId);
  }

  // Hủy booking (Admin/Owner)
  Future<void> cancelBooking(String bookingId) async {
    await _client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }

  // Hủy booking và hoàn tiền vào Balance
  Future<void> cancelBookingWithRefund(BookingModel booking) async {
    try {
      final now = DateTime.now();
      final bookingDateTime = DateTime(
        booking.date.year,
        booking.date.month,
        booking.date.day,
        booking.timeSlot, // Giờ đặt sân
      );

      final diffHours = bookingDateTime.difference(now).inHours;
      final diffMinutes = bookingDateTime.difference(now).inMinutes;

      // >= 2h trước giờ chơi → hoàn 100%
      // 0 < x < 2h (chưa tới giờ) → hoàn 50%
      // Đã tới hoặc quá giờ (diffMinutes <= 0) → không hoàn
      int refundAmount = 0;
      if (diffHours >= 2) {
        refundAmount = booking.price; // 100%
      } else if (diffMinutes > 0) {
        refundAmount = (booking.price * 0.5).toInt(); // 50%
      }

      // 1. Cập nhật trạng thái booking -> cancelled
      final updateRes = await _client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', booking.id!)
          .select();
      if (updateRes.isEmpty) {
        throw Exception(
          "Không thể cập nhật trạng thái hủy (Có thể do sai ID hoặc Quyền)",
        );
      }

      // 2. Cập nhật số dư ví nếu có hoàn tiền
      if (refundAmount > 0) {
        await addBalance(booking.userId, refundAmount);
        debugPrint('[Refund] Hoàn $refundAmount₫ → userId=${booking.userId}');
      }
    } catch (e) {
      debugPrint('Lỗi cancelBookingWithRefund: $e');
      rethrow;
    }
  }

  // --- Notification Functions ---

  // Tạo notification mới
  Future<void> createNotification(NotificationModel notification) async {
    await _client.from('notifications').insert(notification.toSupabase());
  }

  // Lấy danh sách ID của admin và chủ sân
  Future<List<String>> getAdminsAndCourtOwner(String courtId) async {
    Set<String> userIdsToNotify = {};
    try {
      final courtData = await _client
          .from('courts')
          .select('owner_id')
          .eq('id', courtId)
          .maybeSingle();
      if (courtData != null && courtData['owner_id'] != null) {
        userIdsToNotify.add(courtData['owner_id']);
      }
    } catch (e) {
      // Ignored
    }
    try {
      final admins = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'admin');
      for (var admin in admins) {
        userIdsToNotify.add(admin['id']);
      }
    } catch (e) {
      // Ignored
    }
    return userIdsToNotify.toList();
  }

  // Lấy stream các notifications của user
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map<List<NotificationModel>>(
          (data) => data.map((e) => NotificationModel.fromSupabase(e)).toList(),
        );
  }

  // Đánh dấu notification là đã đọc
  Future<void> markNotificationAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // Đánh dấu tất cả notifications là đã đọc
  Future<void> markAllNotificationsAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  // Xóa notification
  Future<void> deleteNotification(String notificationId) async {
    await _client.from('notifications').delete().eq('id', notificationId);
  }

  // --- Event Management Functions ---

  // --- Event Management Functions ---

  Stream<List<EventModel>> getEventsStream({String? ownerId, String? courtId}) {
    dynamic query = _client.from('events').stream(primaryKey: ['id']);
    if (ownerId != null) {
      query = query.eq('owner_id', ownerId);
    }
    if (courtId != null) {
      query = query.eq('court_id', courtId);
    }
    return (query as Stream<List<Map<String, dynamic>>>).map<List<EventModel>>(
      (data) => data.map((e) => EventModel.fromSupabase(e)).toList(),
    );
  }

  Future<void> createEvent(EventModel event, String ownerId) async {
    var data = event.toSupabase();
    data['owner_id'] = ownerId;
    data.remove('id'); // Tự tạo ID tại DB hoặc truyền uuid
    await _client.from('events').insert(data);
  }

  Future<void> updateEvent(EventModel event) async {
    await _client.from('events').update(event.toSupabase()).eq('id', event.id);
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<void> createEventPaymentPlaceholder({
    required EventModel event,
    required String userId,
    required String transactionId,
    required int totalPrice,
    int holdMinutes = 5,
  }) async {
    final existing = await _client
        .from('bookings')
        .select('id')
        .eq('transaction_id', transactionId)
        .maybeSingle();
    if (existing != null) return;

    final startTimeStr = event.startTime.toString();
    final matchStart = RegExp(r'\d+').firstMatch(startTimeStr);
    final startTimeNum = matchStart != null
        ? int.parse(matchStart.group(0)!)
        : 0;

    final courtAreaStr = event.courtArea.toString();
    final matchArea = RegExp(r'\d+').firstMatch(courtAreaStr);
    final courtAreaNum = matchArea != null ? int.parse(matchArea.group(0)!) : 0;

    await _client.from('bookings').insert({
      'user_id': userId,
      'court_id': event.courtId,
      'court_name': 'Sự kiện',
      'court_number': courtAreaNum,
      'booking_date': event.dateTime.toIso8601String().split('T')[0],
      'time_slot': startTimeNum,
      'price': totalPrice,
      'status': 'PENDING_PAYMENT',
      'transaction_id': transactionId,
      'expires_at': DateTime.now()
          .add(Duration(minutes: holdMinutes))
          .toIso8601String(),
    });
  }

  Future<void> joinEvent(
    String eventId,
    String userId,
    double priceDeduction, {
    int quantity = 1,
    String? paymentTransactionId,
  }) async {
    final safeQuantity = quantity < 1 ? 1 : quantity;

    // Tạm thời gọi tuần tự do Flutter chưa gọi RPC dễ dàng nếu không viết thủ tục.
    final ev = await _client
        .from('events')
        .select(
          'current_participants, max_participants, court_id, court_area, date_time, start_time, price',
        )
        .eq('id', eventId)
        .single();

    final cur = (ev['current_participants'] as num?)?.toInt() ?? 0;
    final maxP = (ev['max_participants'] as num?)?.toInt() ?? 0;
    final remaining = maxP - cur;
    if (remaining <= 0) {
      throw Exception("Sự kiện đã đầy, không thể tham gia!");
    }
    if (safeQuantity > remaining) {
      throw Exception("Sự kiện chỉ còn $remaining vé trống.");
    }

    if (priceDeduction > 0) {
      final profile = await _client
          .from('profiles')
          .select('balance')
          .eq('id', userId)
          .single();
      final currentBalance = (profile['balance'] as num?)?.toInt() ?? 0;
      if (currentBalance < priceDeduction.toInt()) {
        throw Exception("Số dư không đủ. Vui lòng nạp thêm!");
      }
      await _client
          .from('profiles')
          .update({'balance': currentBalance - priceDeduction.toInt()})
          .eq('id', userId);
    }

    try {
      await _client.from('event_participants').insert({
        'event_id': eventId,
        'user_id': userId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }

    await _client
        .from('events')
        .update({'current_participants': cur + safeQuantity})
        .eq('id', eventId);

    // Ghi nhận hóa đơn ảo (Virtual Booking) cho Event để đồng bộ thống kê và doanh thu
    try {
      final courtData = await _client
          .from('courts')
          .select('name')
          .eq('id', ev['court_id'])
          .single();
      String startTimeStr = ev['start_time'].toString();
      final matchStart = RegExp(r'\d+').firstMatch(startTimeStr);
      int startTimeNum = matchStart != null
          ? int.parse(matchStart.group(0)!)
          : 0;

      String courtAreaStr = ev['court_area'].toString();
      final matchArea = RegExp(r'\d+').firstMatch(courtAreaStr);
      int courtAreaNum = matchArea != null ? int.parse(matchArea.group(0)!) : 0;

      final bookingPayload = {
        'user_id': userId,
        'court_id': ev['court_id'],
        'court_name': courtData['name'] ?? 'Sự Kiện',
        'court_number': courtAreaNum,
        'booking_date': (ev['date_time'] as String).split('T')[0],
        'time_slot': startTimeNum,
        'price': (ev['price'] as num).toInt() * safeQuantity,
        'status': 'PAID',
        'expires_at': null,
      };

      if (paymentTransactionId != null &&
          paymentTransactionId.trim().isNotEmpty) {
        await _client
            .from('bookings')
            .update(bookingPayload)
            .eq('transaction_id', paymentTransactionId);
      } else {
        await _client.from('bookings').insert({
          ...bookingPayload,
          'transaction_id':
              'EVENT_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        });
      }
    } catch (e) {
      debugPrint('Lỗi tạo hóa đơn sự kiện: $e');
    }
  }

  // --- User Management Functions (Admin) ---

  // Lấy stream tất cả users (profiles)
  Stream<List<UserModel>> getAllUsersStream() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map<List<UserModel>>(
          (data) => data.map((e) => UserModel.fromSupabase(e)).toList(),
        );
  }

  // Cập nhật thông tin user (admin)
  Future<void> updateUser(UserModel user) async {
    // Chỉ gửi các cột thực sự tồn tại trong bảng profiles
    // KHÔNG gửi email (thuộc auth.users), status, last_active_at (presence)
    final payload = <String, dynamic>{
      'display_name': user.displayName,
      'phone_number': user.phoneNumber,
      'role': user.role,
      'balance': user.balance,
      if (user.fcmToken != null) 'fcm_token': user.fcmToken,
      if (user.photoUrl != null) 'avatar_url': user.photoUrl,
    };
    final response = await _client
        .from('profiles')
        .update(payload)
        .eq('id', user.id)
        .select();
    if (response.isEmpty) {
      throw Exception(
        "Cập nhật thất bại. Vui lòng kiểm tra quyền RLS trên bảng profiles.",
      );
    }
  }

  // Xóa user (admin) - Lưu ý: Xóa user trong auth khó hơn, ở đây xóa profile
  Future<void> deleteUser(String userId) async {
    // Supabase Auth Admin API cần thiết để xóa user khỏi Auth, nhưng client thường không có quyền
    // Ở đây ta xóa profile
    await _client.from('profiles').delete().eq('id', userId);
  }

  // Thay đổi role của user (admin)
  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }

  // --- Storage Functions ---

  // Upload ảnh lên Supabase Storage
  Future<String> uploadImage(String filePath, String bucket) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) throw Exception('File không tồn tại: $filePath');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      await _client.storage.from(bucket).upload(fileName, file);
      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e, st) {
      AppLogger.e('Repository', 'uploadImage error', e, st);
      rethrow;
    }
  }

  // --- Balance & Payment Helpers ---
  Future<void> deductBalance(String userId, int amount) async {
    if (amount <= 0) return;
    final r = await _client
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();
    final currentBalance = (r['balance'] as num?)?.toInt() ?? 0;
    final newBalance = (currentBalance - amount) < 0
        ? 0
        : currentBalance - amount;
    await _client
        .from('profiles')
        .update({'balance': newBalance})
        .eq('id', userId);
  }

  Future<void> addBalance(String userId, int amount) async {
    if (amount <= 0) return;
    final r = await _client
        .from('profiles')
        .select('balance')
        .eq('id', userId)
        .single();
    final newBalance = ((r['balance'] as num?)?.toInt() ?? 0) + amount;
    await _client
        .from('profiles')
        .update({'balance': newBalance})
        .eq('id', userId);
  }

  Future<void> markBookingsAsPaid(String transactionId) async {
    await _client
        .from('bookings')
        .update({'status': 'PAID'})
        .eq('transaction_id', transactionId);
  }

  // --- Atomic hold / reserve helpers (RPC) ---

  Future<Map<String, dynamic>> reserveBookingSlots({
    required String courtId,
    required String courtName,
    required DateTime bookingDate,
    required String transactionId,
    required List<Map<String, dynamic>> slots,
    int holdMinutes = 5,
  }) async {
    final resp = await _client.rpc(
      'reserve_booking_slots',
      params: {
        'p_court_id': courtId,
        'p_court_name': courtName,
        'p_booking_date': bookingDate.toIso8601String().split('T')[0],
        'p_transaction_id': transactionId,
        'p_slots': slots,
        'p_hold_minutes': holdMinutes,
      },
    );
    if (resp is Map<String, dynamic>) return resp;
    // supabase can return PostgrestMap, but dart sees it as Map<dynamic,dynamic>
    if (resp is Map) return Map<String, dynamic>.from(resp);
    throw Exception('RPC reserve_booking_slots trả về dữ liệu không hợp lệ.');
  }

  Future<int> releaseBookingTransaction(String transactionId) async {
    final resp = await _client.rpc(
      'release_booking_transaction',
      params: {'p_transaction_id': transactionId},
    );
    if (resp is int) return resp;
    if (resp is num) return resp.toInt();
    return 0;
  }

  // --- Review Functions ---

  /// Lấy danh sách đánh giá của một sân, kèm thông tin người đánh giá
  Future<List<ReviewModel>> getReviewsForCourt(String courtId) async {
    try {
      final data = await _client
          .from('reviews')
          .select('*, profiles(id, display_name, avatar_url)')
          .eq('court_id', courtId)
          .order('created_at', ascending: false)
          .limit(100);

      return data.map<ReviewModel>((row) {
        final review = ReviewModel.fromSupabase(row);
        if (row['profiles'] != null) {
          review.reviewer = UserModel.fromSupabase(row['profiles']);
        }
        return review;
      }).toList();
    } catch (e) {
      if (kDebugMode) print('getReviewsForCourt error: $e');
      return [];
    }
  }

  /// Kiểm tra xem user đã đánh giá sân chưa
  Future<bool> hasUserReviewedCourt(String courtId, String userId) async {
    try {
      final data = await _client
          .from('reviews')
          .select('id')
          .eq('court_id', courtId)
          .eq('user_id', userId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra xem user đã từng đặt sân này chưa (điều kiện được đánh giá)
  Future<bool> hasUserBookedCourt(String courtId, String userId) async {
    try {
      final data = await _client
          .from('bookings')
          .select('id')
          .eq('court_id', courtId)
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Gửi đánh giá mới (insert hoặc upsert nếu đã có)
  Future<void> submitReview(ReviewModel review) async {
    await _client
        .from('reviews')
        .upsert(review.toSupabase(), onConflict: 'court_id,user_id');
  }
}
