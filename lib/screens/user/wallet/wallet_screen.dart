import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/data/models/wallet_transaction_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/screens/user/wallet/top_up_screen.dart';
import 'package:badminton_ai/screens/user/wallet/withdrawal_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));

    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví điện tử KLOO'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Thẻ ví
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư khả dụng',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  format.format(user.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.add_circle_outline,
                      label: 'Nạp tiền',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TopUpScreen()));
                      },
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Rút tiền',
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawalScreen()));
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                }
                final transactions = snapshot.data ?? [];
                
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(t.status).withValues(alpha: 0.1),
                        child: Icon(_getTypeIcon(t.type), color: _getStatusColor(t.status)),
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
                          color: (t.type == 'WITHDRAW' || t.type == 'PAYMENT') ? Colors.red : Colors.green,
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

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'TOPUP': return Icons.arrow_downward;
      case 'WITHDRAW': return Icons.arrow_upward;
      case 'REVENUE': return Icons.account_balance;
      case 'PAYMENT': return Icons.payment;
      case 'REFUND': return Icons.refresh;
      default: return Icons.receipt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }
}
