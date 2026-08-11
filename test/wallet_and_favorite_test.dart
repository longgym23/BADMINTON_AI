import 'package:badminton_ai/core/data/models/wallet_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletTransactionModel', () {
    test('WalletTransactionModel initializes correctly', () {
      final now = DateTime.now();
      final tx = WalletTransactionModel(
        id: 'tx-01',
        userId: 'user-01',
        amount: 50000,
        type: 'TOPUP',
        status: 'PENDING',
        createdAt: now,
      );

      expect(tx.id, 'tx-01');
      expect(tx.userId, 'user-01');
      expect(tx.amount, 50000);
      expect(tx.type, 'TOPUP');
      expect(tx.status, 'PENDING');
      expect(tx.createdAt, now);
    });
  });
}
