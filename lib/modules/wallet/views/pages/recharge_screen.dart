import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/wallet/repositories/wallet_repository.dart';
import 'package:badminton_ai/modules/wallet/viewmodels/wallet_viewmodel.dart';
import 'package:badminton_ai/core/services/sepay_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _qrUrl;
  RealtimeChannel? _subscription;

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _amountController.dispose();
    super.dispose();
  }

  void _generateQr(BuildContext context, WalletViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountStr) ?? 0;

    // Lấy ID user hiện tại để gắn vào nội dung chuyển khoản
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final userId = authProvider.userModel?.id ?? '';

    // Lấy 8 ký tự đầu của User ID cho mã ngắn gọn
    final shortUserId = userId.length > 8
        ? userId.substring(0, 8).toUpperCase()
        : userId.toUpperCase();

    final qrUrl = SePayService().generateVietQRUrl(
      amount: amount,
      bookingReference: shortUserId,
      prefix: 'NAPTIEN',
    );

    setState(() {
      _qrUrl = qrUrl;
    });

    // Lắng nghe realtime từ Supabase để tự động đóng màn hình khi nạp thành công
    _subscription?.unsubscribe(); // Hủy cái cũ nếu có
    _subscription = Supabase.instance.client
        .channel('public:wallet_transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wallet_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newTx = payload.newRecord;
            if (newTx['type'] == 'TOPUP' && newTx['status'] == 'SUCCESS') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nạp thành công $amountStrđ vào ví!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context); // Quay lại WalletScreen
              }
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppAuthProvider>(context).userModel;
    if (user == null) return const Scaffold();

    return ChangeNotifierProvider(
      create: (context) => WalletViewModel(
        userId: user.id,
        walletRepository: context.read<IWalletRepository>(),
      ),
      child: Consumer<WalletViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: CustomGradientAppBar(title: Text('Nạp tiền vào ví')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_qrUrl == null) ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nhập số tiền cần nạp',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'VD: 50000',
                              border: OutlineInputBorder(),
                              suffixText: 'VNĐ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số tiền';
                              }
                              final num = int.tryParse(
                                value.replaceAll(RegExp(r'[^0-9]'), ''),
                              );
                              if (num == null || num < 20000) {
                                return 'Số tiền nạp tối thiểu là 20.000đ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VColors.brandPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => _generateQr(context, viewModel),
                              child: viewModel.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'TẠO MÃ QR NẠP TIỀN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Hiển thị QR Code
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Quét mã QR để thanh toán',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Image.network(
                            _qrUrl!,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Tiền sẽ tự động được cộng vào ví của bạn trong vòng 1-3 phút sau khi chuyển khoản thành công.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: VColors.brandPrimary,
                              ),
                              child: const Text('Trở về Ví của tôi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
