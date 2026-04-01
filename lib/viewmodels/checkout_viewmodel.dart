import 'dart:async';
import 'package:flutter/material.dart';
import 'package:badminton_ai/services/sepay_service.dart';

class CheckoutViewModel extends ChangeNotifier {
  final SePayService _sePayService = SePayService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isBookingCreated = false;
  bool get isBookingCreated => _isBookingCreated;

  void setBookingCreated(bool value) {
    _isBookingCreated = value;
    notifyListeners();
  }

  // ─── Countdown Timer (5 phút = 300 giây) ────────────────────────────────
  static const int _kTimeoutSeconds = 5 * 60;
  Timer? _countdownTimer;

  int _remainingSeconds = _kTimeoutSeconds;
  int get remainingSeconds => _remainingSeconds;

  bool _isExpired = false;
  bool get isExpired => _isExpired;

  String get remainingLabel {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Gọi hàm này ngay sau khi booking PENDING được tạo thành công
  void startCountdown(VoidCallback onExpired) {
    _remainingSeconds = _kTimeoutSeconds;
    _isExpired = false;
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _isExpired = true;
        notifyListeners();
        onExpired();
      } else {
        _remainingSeconds--;
        notifyListeners();
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
  // ─────────────────────────────────────────────────────────────────────────

  // Contact Info
  String _customerName = '';
  String get customerName => _customerName;

  String _customerPhone = '';
  String get customerPhone => _customerPhone;

  String _note = '';
  String get note => _note;

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  void setCustomerPhone(String phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  void setNote(String note) {
    _note = note;
    notifyListeners();
  }

  String _qrUrl = '';
  String get qrUrl => _qrUrl;

  late String _transactionId;
  String get transactionId => _transactionId;

  void initializePayment(int totalAmount, String courtId) {
    // Không dùng dấu _ vì ngân hàng sẽ xóa ký tự đặc biệt trong nội dung CK
    _transactionId = '${courtId.substring(0, 5)}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _qrUrl = _sePayService.generateVietQRUrl(amount: totalAmount, bookingReference: _transactionId);
  }

  Future<bool> startListeningForPayment() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isPaid = await _sePayService.listenPaymentSuccess(_transactionId);

      if (!isPaid) {
        _errorMessage = "Giao dịch chưa thành công hoặc không tìm thấy.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      cancelCountdown(); // Dừng timer khi thanh toán thành công
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
