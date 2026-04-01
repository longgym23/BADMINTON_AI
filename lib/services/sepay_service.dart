import 'package:supabase_flutter/supabase_flutter.dart';

class SePayService {
  // Config: Thực tế bạn có thể chuyển vào file .env hoặc constants
  final String bankBin = '970422'; // Mã BIN ngân hàng (vd: Vietcombank)
  final String accountNo = '0344136328';
  final String accountName = 'BADMINTON';

  /// Tạo link mã ảnh VietQR cho giao dịch
  String generateVietQRUrl({
    required int amount,
    required String bookingReference,
  }) {
    // Generate nội dung chuyển khoản an toàn (mã nhận diện duy nhất)
    final addInfo = 'DATSAN $bookingReference';
    
    // Sử dụng api img.vietqr.io để parse link (hoặc API của sePay)
    return 'https://img.vietqr.io/image/$bankBin-$accountNo-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(addInfo)}&accountName=${Uri.encodeComponent(accountName)}';
  }

  /// Lắng nghe trạng thái cập nhật thanh toán từ Supabase Webhook
  Future<bool> listenPaymentSuccess(String transactionId) async {
    final supabase = Supabase.instance.client;
    
    // Mở stream nghe tự động từ bảng bookings với cùng transactionId
    final stream = supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('transaction_id', transactionId);
        
    await for (final List<Map<String, dynamic>> data in stream) {
      if (data.isNotEmpty) {
        // Nếu bất kỳ bản ghi nào trong mảng chuyển thành PAID, ta xác nhận thành công
        final isPaid = data.any((b) => b['status'] == 'PAID');
        if (isPaid) {
          return true;
        }
      }
    }
    return false;
  }
}
