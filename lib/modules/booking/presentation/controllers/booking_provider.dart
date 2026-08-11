import 'dart:async';
import 'package:badminton_ai/core/data/models/booking_model.dart';
import 'package:badminton_ai/core/data/models/event_model.dart';
import 'package:badminton_ai/modules/booking/application/commands/add_balance_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/cancel_booking_with_refund_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/create_booking_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/create_event_payment_placeholder_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/deduct_balance_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/join_event_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/mark_bookings_paid_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/release_booking_transaction_command.dart';
import 'package:badminton_ai/modules/booking/application/commands/reserve_booking_slots_command.dart';
import 'package:badminton_ai/modules/booking/application/mediator/booking_module_mediator.dart';
import 'package:badminton_ai/modules/booking/domain/repositories/i_booking_repository.dart';
import 'package:badminton_ai/modules/booking/infrastructure/mappers/booking_entity_mapper.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:flutter/material.dart';

/// Presentation session controller for Booking.
/// Mutations go through [IBookingModule] (CQRS); reads/stream use [IBookingRepository].
class BookingProvider with ChangeNotifier {
  BookingProvider({
    required IBookingModule bookingModule,
    required IBookingRepository bookingRepository,
    required AppAuthProvider authProvider,
    BookingEntityMapper mapper = const BookingEntityMapper(),
  })  : _bookingModule = bookingModule,
        _bookingRepository = bookingRepository,
        _authProvider = authProvider,
        _mapper = mapper;

  final IBookingModule _bookingModule;
  final IBookingRepository _bookingRepository;
  final AppAuthProvider _authProvider;
  final BookingEntityMapper _mapper;

  // Stream để lắng nghe các sân con đã bị đặt
  StreamSubscription? _bookingSubscription;
  final StreamController<List<BookingModel>> _bookingsStreamController =
      StreamController<List<BookingModel>>.broadcast();

  Stream<List<BookingModel>> get bookingsStream =>
      _bookingsStreamController.stream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Hàm này lắng nghe qua IBookingRepository và đẩy dữ liệu vào StreamController
  void fetchBookingsForDay(String courtId, DateTime date) {
    // Hủy stream cũ (nếu có) trước khi lắng nghe stream mới
    _bookingSubscription?.cancel();

    // Phát ngay danh sách rỗng để StreamBuilder thoát khỏi trạng thái 'waiting'
    // tránh loading vô tận khi chuyển ngày hoặc mở màn hình lần đầu
    if (!_bookingsStreamController.isClosed) {
      _bookingsStreamController.add([]);
    }

    _bookingSubscription = _bookingRepository
        .watchBookingsForDay(courtId, date)
        .listen(
          (bookings) {
            if (!_bookingsStreamController.isClosed) {
              _bookingsStreamController.add(
                bookings.map(_mapper.toModel).toList(),
              );
            }
          },
          onError: (error) {
            if (!_bookingsStreamController.isClosed) {
              // Khi lỗi, phát danh sách rỗng thay vì addError để UI không crash
              _bookingsStreamController.add([]);
            }
          },
        );
  }

  // Hàm để đóng stream khi không cần thiết (tránh rò rỉ bộ nhớ)
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
    String status = 'confirmed',
    String? transactionId,
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

      final bookingId = await _bookingModule
          .executeCommand<CreateBookingCommand, String>(
        CreateBookingCommand(
          userId: user.id,
          userName: user.displayName ?? user.email ?? 'Không tên',
          courtId: courtId,
          courtName: courtName,
          courtNumber: courtNumber,
          date: date,
          timeSlot: timeSlot,
          price: price,
          status: status,
          transactionId: transactionId,
        ),
      );

      _isLoading = false;
      notifyListeners();
      return bookingId;
    } catch (e) {
      _errorMessage = "Đặt sân thất bại: $e";
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Giữ chỗ (hold) một hoặc nhiều slot qua RPC nguyên tử.
  Future<Map<String, dynamic>> reserveBookingSlots({
    required String courtId,
    required String courtName,
    required DateTime bookingDate,
    required String transactionId,
    required List<Map<String, dynamic>> slots,
    int holdMinutes = 5,
  }) {
    return _bookingModule
        .executeCommand<ReserveBookingSlotsCommand, Map<String, dynamic>>(
      ReserveBookingSlotsCommand(
        courtId: courtId,
        courtName: courtName,
        bookingDate: bookingDate,
        transactionId: transactionId,
        slots: slots,
        holdMinutes: holdMinutes,
      ),
    );
  }

  /// Giải phóng giao dịch đã giữ chỗ (hết hạn hoặc hủy giữa chừng).
  Future<int> releaseBookingTransaction(String transactionId) {
    return _bookingModule
        .executeCommand<ReleaseBookingTransactionCommand, int>(
      ReleaseBookingTransactionCommand(transactionId: transactionId),
    );
  }

  /// Đánh dấu tất cả booking của một giao dịch là đã thanh toán.
  Future<void> markBookingsAsPaid(String transactionId) {
    return _bookingModule.executeCommand<MarkBookingsPaidCommand, void>(
      MarkBookingsPaidCommand(transactionId: transactionId),
    );
  }

  Future<void> deductBalance(String userId, int amount) {
    return _bookingModule.executeCommand<DeductBalanceCommand, void>(
      DeductBalanceCommand(userId: userId, amount: amount),
    );
  }

  Future<void> addBalance(String userId, int amount) {
    return _bookingModule.executeCommand<AddBalanceCommand, void>(
      AddBalanceCommand(userId: userId, amount: amount),
    );
  }

  /// Hủy booking và hoàn tiền vào ví (logic hoàn tiền chạy ở DB trigger).
  Future<void> cancelBookingWithRefund(BookingModel booking) {
    return _bookingModule
        .executeCommand<CancelBookingWithRefundCommand, void>(
      CancelBookingWithRefundCommand(booking: _mapper.toEntity(booking)),
    );
  }

  Future<void> createEventPaymentPlaceholder({
    required EventModel event,
    required String userId,
    required String transactionId,
    required int totalPrice,
    int holdMinutes = 5,
  }) {
    return _bookingModule
        .executeCommand<CreateEventPaymentPlaceholderCommand, void>(
      CreateEventPaymentPlaceholderCommand(
        event: event,
        userId: userId,
        transactionId: transactionId,
        totalPrice: totalPrice,
        holdMinutes: holdMinutes,
      ),
    );
  }

  Future<void> joinEvent(
    String eventId,
    String userId,
    double priceDeduction, {
    int quantity = 1,
    String? paymentTransactionId,
  }) {
    return _bookingModule.executeCommand<JoinEventCommand, void>(
      JoinEventCommand(
        eventId: eventId,
        userId: userId,
        priceDeduction: priceDeduction,
        quantity: quantity,
        paymentTransactionId: paymentTransactionId,
      ),
    );
  }
}
