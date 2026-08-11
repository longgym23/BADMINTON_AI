import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';

/// Data access port for Admin-side operations.
abstract class IAdminRepository {
  /// Cancels a booking on behalf of an admin/court-owner (no refund logic).
  Future<void> cancelBooking(String bookingId);

  /// Approves (`SUCCESS`) or rejects (`REJECTED`) a pending withdrawal
  /// request.
  Future<void> updateWithdrawalStatus(String transactionId, String status);
}

/// Wraps the shared [SupabaseRepository] for Admin-specific operations.
class AdminRepository implements IAdminRepository {
  AdminRepository({required SupabaseRepository repository})
    : _repository = repository;

  final SupabaseRepository _repository;

  @override
  Future<void> cancelBooking(String bookingId) {
    return _repository.cancelBooking(bookingId);
  }

  @override
  Future<void> updateWithdrawalStatus(String transactionId, String status) {
    return _repository.updateWalletTransactionStatus(transactionId, status);
  }
}
