import 'package:badminton_ai/services/sepay_service.dart';
import 'package:badminton_ai/viewmodels/checkout_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Checkout payment workflow', () {
    test('wallet covers full amount without generating VietQR', () {
      final vm = CheckoutViewModel();

      vm.initializePayment(
        240000,
        'court_abc_001',
        walletBalance: 300000,
        transactionId: 'TXN_FULL_WALLET',
      );

      expect(vm.appliedBalance, 240000);
      expect(vm.finalAmount, 0);
      expect(vm.transactionId, 'TXN_FULL_WALLET');
      expect(vm.qrUrl, isEmpty);

      vm.dispose();
    });

    test('partial wallet payment generates VietQR for remaining amount', () {
      final vm = CheckoutViewModel();

      vm.initializePayment(
        300000,
        'court_abc_001',
        walletBalance: 125000,
        transactionId: 'TXN_PARTIAL',
      );

      expect(vm.appliedBalance, 125000);
      expect(vm.finalAmount, 175000);
      expect(vm.transactionId, 'TXN_PARTIAL');

      final uri = Uri.parse(vm.qrUrl);
      expect(uri.host, 'img.vietqr.io');
      expect(uri.queryParameters['amount'], '175000');
      expect(uri.queryParameters['addInfo'], 'DATSAN TXN_PARTIAL');
      expect(uri.queryParameters['accountName'], 'BADMINTON');

      vm.dispose();
    });

    test('reserved transaction id is preserved for webhook matching', () {
      final vm = CheckoutViewModel();

      vm.initializePayment(
        100000,
        'court_abc_001',
        walletBalance: 0,
        transactionId: 'COURT_RESERVE_20260513',
      );

      expect(vm.transactionId, 'COURT_RESERVE_20260513');
      expect(vm.qrUrl, contains('COURT_RESERVE_20260513'));

      vm.dispose();
    });
  });

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
