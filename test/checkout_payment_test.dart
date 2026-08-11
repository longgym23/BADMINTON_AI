import 'package:badminton_ai/core/services/sepay_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SePayService VietQR URL', () {
    test('encodes amount, addInfo and account name correctly', () {
      final service = SePayService();

      final url = service.generateVietQRUrl(
        amount: 180000,
        bookingReference: 'DATSAN-ABC 123',
      );

      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'img.vietqr.io');
      expect(uri.path, '/image/970422-0344136328-compact2.png');
      expect(uri.queryParameters['amount'], '180000');
      expect(uri.queryParameters['addInfo'], 'DATSAN DATSAN-ABC 123');
      expect(uri.queryParameters['accountName'], 'BADMINTON');
    });

    test('supports custom prefix for wallet top-up references', () {
      final service = SePayService();

      final url = service.generateVietQRUrl(
        amount: 500000,
        bookingReference: 'USER123',
        prefix: 'NAPTIEN',
      );

      final uri = Uri.parse(url);
      expect(uri.queryParameters['amount'], '500000');
      expect(uri.queryParameters['addInfo'], 'NAPTIEN USER123');
    });
  });
}
