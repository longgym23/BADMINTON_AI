import 'package:flutter/material.dart';
import 'package:badminton_ai/core/data/models/wallet_transaction_model.dart';
import '../repositories/wallet_repository.dart';
import 'package:badminton_ai/core/utils/app_logger.dart';

/// Presentation-facing ViewModel for the Wallet module — calls the
/// repository directly.
class WalletViewModel extends ChangeNotifier {
  final String userId;
  final IWalletRepository _walletRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  WalletViewModel({required this.userId, required IWalletRepository walletRepository})
      : _walletRepository = walletRepository;

  // Gửi yêu cầu rút tiền
  Future<bool> requestWithdrawal(int amount, String bankInfo) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _walletRepository.requestWithdrawal(
        userId: userId,
        amount: amount,
        bankInfo: bankInfo,
      );
      _setLoading(false);
      return true;
    } catch (e, st) {
      AppLogger.e('WalletVM', 'Error requesting withdrawal', e, st);
      _errorMessage = 'Lỗi yêu cầu rút tiền: $e';
      _setLoading(false);
      return false;
    }
  }

  // Gửi yêu cầu nạp tiền (trả về giao dịch PENDING để lấy ID làm mã nạp)
  Future<WalletTransactionModel?> requestTopUp(int amount) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final transaction = await _walletRepository.createPendingTopUp(
        userId: userId,
        amount: amount,
      );
      _setLoading(false);
      return transaction;
    } catch (e, st) {
      AppLogger.e('WalletVM', 'Error requesting top-up', e, st);
      _errorMessage = 'Lỗi tạo yêu cầu nạp tiền: $e';
      _setLoading(false);
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
