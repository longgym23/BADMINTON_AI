import 'package:badminton_ai/core/data/models/wallet_transaction_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';

/// Data access port for wallet balance & transaction operations.
abstract class IWalletRepository {
  /// Emits the realtime balance for [userId].
  Stream<int> watchBalance(String userId);

  /// Emits the realtime transaction history for [userId].
  Stream<List<WalletTransactionModel>> watchTransactions(String userId);

  /// (Admin) Emits pending withdrawal requests across all users.
  Stream<List<WalletTransactionModel>> watchPendingWithdrawals();

  /// User creates a WITHDRAW request (balance is deducted by a DB trigger).
  Future<void> requestWithdrawal({
    required String userId,
    required int amount,
    required String bankInfo,
  });

  /// User creates a pending TOPUP request awaiting SePay webhook approval.
  Future<WalletTransactionModel> createPendingTopUp({
    required String userId,
    required int amount,
  });

  /// (Admin) Approves/rejects a pending transaction.
  Future<void> updateTransactionStatus(String transactionId, String status);

  Future<void> deductBalance(String userId, int amount);

  Future<void> addBalance(String userId, int amount);
}

class WalletRepository implements IWalletRepository {
  WalletRepository({SupabaseRepository? repository})
      : _repository = repository ?? SupabaseRepository();

  final SupabaseRepository _repository;

  @override
  Stream<int> watchBalance(String userId) {
    return _repository.getUserBalanceStream(userId);
  }

  @override
  Stream<List<WalletTransactionModel>> watchTransactions(String userId) {
    return _repository.getWalletTransactionsStream(userId);
  }

  @override
  Stream<List<WalletTransactionModel>> watchPendingWithdrawals() {
    return _repository
        .getPendingWithdrawalsStream()
        .map((rows) => rows.map(WalletTransactionModel.fromSupabase).toList());
  }

  @override
  Future<void> requestWithdrawal({
    required String userId,
    required int amount,
    required String bankInfo,
  }) {
    return _repository.requestWithdrawal(
      userId: userId,
      amount: amount,
      bankInfo: bankInfo,
    );
  }

  @override
  Future<WalletTransactionModel> createPendingTopUp({
    required String userId,
    required int amount,
  }) {
    return _repository.createPendingTopUp(userId: userId, amount: amount);
  }

  @override
  Future<void> updateTransactionStatus(String transactionId, String status) {
    return _repository.updateWalletTransactionStatus(transactionId, status);
  }

  @override
  Future<void> deductBalance(String userId, int amount) {
    return _repository.deductBalance(userId, amount);
  }

  @override
  Future<void> addBalance(String userId, int amount) {
    return _repository.addBalance(userId, amount);
  }
}
