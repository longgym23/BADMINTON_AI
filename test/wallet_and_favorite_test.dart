import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/wallet_transaction_model.dart';
import 'package:badminton_ai/providers/favorite_courts_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAsyncLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WalletTransactionModel', () {
    WalletTransactionModel tx(String type, {String status = 'SUCCESS'}) {
      return WalletTransactionModel.fromSupabase({
        'id': 'wallet-tx-$type',
        'user_id': 'user-001',
        'amount': 150000,
        'type': type,
        'status': status,
        'bank_info': 'VCB - 123456 - NGUYEN VAN A',
        'reference_id': 'ref-001',
        'description': 'Test transaction',
        'created_at': '2026-05-13T08:30:00.000Z',
      });
    }

    test('parses TOPUP, WITHDRAW, PAYMENT and REFUND transaction types', () {
      expect(tx('TOPUP').type, 'TOPUP');
      expect(tx('WITHDRAW').type, 'WITHDRAW');
      expect(tx('PAYMENT').type, 'PAYMENT');
      expect(tx('REFUND').type, 'REFUND');
    });

    test('formattedAmount uses plus sign for incoming money', () {
      expect(tx('TOPUP').formattedAmount, startsWith('+'));
      expect(tx('REVENUE').formattedAmount, startsWith('+'));
      expect(tx('REFUND').formattedAmount, startsWith('+'));
    });

    test('formattedAmount uses minus sign for outgoing money', () {
      expect(tx('WITHDRAW').formattedAmount, startsWith('-'));
      expect(tx('PAYMENT').formattedAmount, startsWith('-'));
    });

    test('labels transaction type and status for wallet UI', () {
      expect(tx('TOPUP').typeLabel, 'Nạp tiền');
      expect(tx('WITHDRAW').typeLabel, 'Rút tiền');
      expect(tx('PAYMENT').typeLabel, 'Thanh toán đặt sân');
      expect(tx('REFUND').typeLabel, 'Hoàn tiền hủy sân');
      expect(tx('TOPUP', status: 'PENDING').statusLabel, 'Đang xử lý');
      expect(tx('TOPUP', status: 'REJECTED').statusLabel, 'Bị từ chối');
    });

    test('toSupabase keeps ledger fields used by database triggers', () {
      final map = tx('PAYMENT').toSupabase();

      expect(map['id'], 'wallet-tx-PAYMENT');
      expect(map['user_id'], 'user-001');
      expect(map['amount'], 150000);
      expect(map['type'], 'PAYMENT');
      expect(map['status'], 'SUCCESS');
      expect(map['reference_id'], 'ref-001');
    });
  });

  group('FavoriteCourtsProvider', () {
    final court = CourtLocationModel(
      id: 'court-fav-001',
      name: 'KLOO Badminton Center',
      address: '123 Nguyen Van Linh',
      latitude: 10.7333,
      longitude: 106.7000,
      pricePerHour: 120000,
      totalCourts: 6,
      sportType: 'badminton',
      imageUrl: 'https://example.com/court.jpg',
      rating: 4.8,
      totalReviews: 32,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds and removes a favorite court', () async {
      final provider = FavoriteCourtsProvider();
      await _pumpAsyncLoad();

      expect(provider.favorites, isEmpty);
      expect(provider.isFavorite(court.id), isFalse);

      await provider.toggleFavorite(court);

      expect(provider.favorites, hasLength(1));
      expect(provider.isFavorite(court.id), isTrue);

      await provider.toggleFavorite(court);

      expect(provider.favorites, isEmpty);
      expect(provider.isFavorite(court.id), isFalse);
    });

    test('removeFavorite deletes only the requested court id', () async {
      final anotherCourt = CourtLocationModel(
        id: 'court-fav-002',
        name: 'Second Court',
        address: '456 Tran Phu',
        latitude: 10.8,
        longitude: 106.8,
        pricePerHour: 90000,
        totalCourts: 4,
      );
      final provider = FavoriteCourtsProvider();
      await _pumpAsyncLoad();

      await provider.toggleFavorite(court);
      await provider.toggleFavorite(anotherCourt);
      await provider.removeFavorite(court.id);

      expect(provider.isFavorite(court.id), isFalse);
      expect(provider.isFavorite(anotherCourt.id), isTrue);
      expect(provider.favorites, hasLength(1));
    });

    test('persists favorite courts through SharedPreferences', () async {
      final provider = FavoriteCourtsProvider();
      await _pumpAsyncLoad();

      await provider.toggleFavorite(court);

      final reloaded = FavoriteCourtsProvider();
      await _pumpAsyncLoad();

      expect(reloaded.favorites, hasLength(1));
      expect(reloaded.favorites.first.id, court.id);
      expect(reloaded.favorites.first.name, court.name);
      expect(reloaded.favorites.first.pricePerHour, court.pricePerHour);
      expect(reloaded.favorites.first.sportType, court.sportType);
    });
  });
}
