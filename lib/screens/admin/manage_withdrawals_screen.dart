import 'package:badminton_ai/utils/snackbar_utils.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';

class ManageWithdrawalsScreen extends StatefulWidget {
  const ManageWithdrawalsScreen({Key? key}) : super(key: key);

  @override
  State<ManageWithdrawalsScreen> createState() =>
      _ManageWithdrawalsScreenState();
}

class _ManageWithdrawalsScreenState extends State<ManageWithdrawalsScreen> {
  final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  Future<void> _updateStatus(String txId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('wallet_transactions')
          .update({'status': newStatus})
          .eq('id', txId);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Đã duyệt yêu cầu rút tiền');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showConfirmDialog(Map<String, dynamic> tx, String status) {
    DialogUtils.showConfirmDialog(
      context,
      title: status == 'SUCCESS' ? 'Xác nhận duyệt?' : 'Từ chối yêu cầu?',
      content: status == 'SUCCESS'
          ? 'Bạn đã chuyển khoản thành công cho user này?\nSố tiền: ${formatCurrency.format(tx['amount'])}'
          : 'Bạn muốn từ chối yêu cầu này? Số tiền sẽ được hoàn lại vào ví của user.',
      confirmText: 'Đồng ý',
      cancelText: 'Hủy',
      isDestructive: status != 'SUCCESS',
      onConfirm: () => _updateStatus(tx['id'], status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(title: Text('Quản lý rút tiền')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseRepository().getPendingWithdrawalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallet, size: 50, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có yêu cầu rút tiền nào cần xử lý',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final tx = list[index];
              final date =
                  DateTime.tryParse(tx['created_at'])?.toLocal() ??
                  DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CHỜ XỬ LÝ',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Số tiền: ',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            formatCurrency.format(tx['amount']),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin ngân hàng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tx['bank_info'] ?? 'Không có thông tin',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  _showConfirmDialog(tx, 'REJECTED'),
                              child: const Text(
                                'Từ chối',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF4CAF50,
                                ), // Xanh lá cây
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () =>
                                  _showConfirmDialog(tx, 'SUCCESS'),
                              child: const Text(
                                'Đã chuyển khoản',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
