import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/core/data/models/wallet_transaction_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/modules/wallet/views/pages/recharge_screen.dart';
import 'package:badminton_ai/modules/wallet/views/pages/withdrawal_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: CustomGradientAppBar(title: Text('Ví điện tử KLOO')),
      body: Column(
        children: [
          // Thẻ ví
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư khả dụng',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<int>(
                  stream: SupabaseRepository().getUserBalanceStream(user.id),
                  initialData: user.balance,
                  builder: (context, snapshot) {
                    final currentBalance = snapshot.data ?? user.balance;

                    // Cập nhật ngầm lại userModel trong AppAuthProvider để đồng bộ các nơi khác
                    if (snapshot.hasData && currentBalance != user.balance) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        authProvider.updateUserModel(
                          user.copyWith(balance: currentBalance),
                        );
                      });
                    }

                    // Format số dư và tách 'đ' ra để style riêng nếu muốn, nhưng tạm dùng NumberFormat
                    return Text(
                      format.format(currentBalance),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade200, thickness: 1, height: 1),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFigmaActionButton(
                      context,
                      icon: Icons.add,
                      label: 'Nạp tiền',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RechargeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFigmaActionButton(
                      context,
                      icon: Icons.credit_card_outlined,
                      label: 'Rút tiền',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WithdrawalScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tiêu đề lịch sử
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lịch sử giao dịch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // Danh sách lịch sử
          Expanded(
            child: StreamBuilder<List<WalletTransactionModel>>(
              stream: SupabaseRepository().getWalletTransactionsStream(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                  );
                }
                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có giao dịch nào',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(
                        height: 80,
                      ), // Đẩy nhẹ lên trên một chút giống figma
                    ],
                  );
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(
                          t.status,
                        ).withValues(alpha: 0.1),
                        child: Icon(
                          _getTypeIcon(t.type),
                          color: _getStatusColor(t.status),
                        ),
                      ),
                      title: Text(t.description ?? t.typeLabel),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt)} - ${t.statusLabel}',
                        style: TextStyle(color: _getStatusColor(t.status)),
                      ),
                      trailing: Text(
                        t.formattedAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (t.type == 'WITHDRAW' || t.type == 'PAYMENT')
                              ? Colors.red
                              : Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Icon(icon, color: const Color(0xFF374151), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'TOPUP':
        return Icons.arrow_downward;
      case 'WITHDRAW':
        return Icons.arrow_upward;
      case 'REVENUE':
        return Icons.account_balance;
      case 'PAYMENT':
        return Icons.payment;
      case 'REFUND':
        return Icons.refresh;
      default:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
