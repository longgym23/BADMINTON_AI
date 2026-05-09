import 'package:easy_localization/easy_localization.dart';

class WalletTransactionModel {
  final String id;
  final String userId;
  final int amount;
  final String type; // TOPUP, WITHDRAW, REVENUE, PAYMENT, REFUND
  final String status; // PENDING, SUCCESS, REJECTED
  final String? bankInfo;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    this.bankInfo,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromSupabase(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toInt(),
      type: json['type'],
      status: json['status'],
      bankInfo: json['bank_info'],
      referenceId: json['reference_id'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      if (bankInfo != null) 'bank_info': bankInfo,
      if (referenceId != null) 'reference_id': referenceId,
      if (description != null) 'description': description,
    };
  }

  // Tiện ích hiển thị
  String get formattedAmount {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    // Nếu là WITHDRAW hoặc PAYMENT thì hiển thị dấu trừ
    if (type == 'WITHDRAW' || type == 'PAYMENT') {
      return '-${format.format(amount)}';
    }
    return '+${format.format(amount)}';
  }

  String get typeLabel {
    switch (type) {
      case 'TOPUP':
        return 'Nạp tiền';
      case 'WITHDRAW':
        return 'Rút tiền';
      case 'REVENUE':
        return 'Doanh thu';
      case 'PAYMENT':
        return 'Thanh toán đặt sân';
      case 'REFUND':
        return 'Hoàn tiền hủy sân';
      default:
        return 'Giao dịch';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Đang xử lý';
      case 'SUCCESS':
        return 'Thành công';
      case 'REJECTED':
        return 'Bị từ chối';
      default:
        return 'Không rõ';
    }
  }
}
