import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SePayService {
  final String bankBin = '970422';
  final String accountNo = '0344136328';
  final String accountName = 'BADMINTON';

  /// Tạo link ảnh QR VietQR cho giao dịch
  String generateVietQRUrl({
    required int amount,
    required String bookingReference,
    String prefix = 'DATSAN',
  }) {
    final addInfo = '$prefix $bookingReference';
    return 'https://img.vietqr.io/image/$bankBin-$accountNo-compact2.png'
        '?amount=$amount'
        '&addInfo=${Uri.encodeComponent(addInfo)}'
        '&accountName=${Uri.encodeComponent(accountName)}';
  }

  /// Lắng nghe trạng thái thanh toán bằng polling định kỳ.
  /// Kiểm tra DB mỗi [intervalSeconds] giây trong tối đa [timeoutSeconds] giây.
  /// Trả về true khi booking chuyển sang PAID, false nếu hết timeout.
  Future<bool> listenPaymentSuccess(
    String transactionId, {
    int intervalSeconds = 3,
    int timeoutSeconds = 5 * 60,
  }) async {
    final supabase = Supabase.instance.client;
    final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));

    while (DateTime.now().isBefore(deadline)) {
      try {
        final session = supabase.auth.currentSession;
        if (session != null && session.isExpired) {
          debugPrint('JWT Session expired during polling, refreshing...');
          await supabase.auth.refreshSession();
        }
      } catch (e) {
        debugPrint('Error refreshing session in polling: $e');
      }

      try {
        final rows = await supabase
            .from('bookings')
            .select('status')
            .eq('transaction_id', transactionId);

        if (rows.isNotEmpty) {
          final isPaid = rows.any((b) => b['status'] == 'PAID');
          if (isPaid) return true;
        }
      } catch (e) {
        debugPrint('Polling payment error: $e');
      }

      await Future.delayed(Duration(seconds: intervalSeconds));
    }

    return false; // Hết timeout
  }
}
