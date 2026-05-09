import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/viewmodels/wallet_viewmodel.dart';
import 'package:badminton_ai/services/sepay_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _qrUrl;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _generateQr(BuildContext context, WalletViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountStr) ?? 0;

    // Tạo giao dịch PENDING trên DB
    final transaction = await viewModel.requestTopUp(amount);
    if (transaction != null) {
      // Dùng ID của transaction làm mã tham chiếu để webhook biết cộng tiền cho ai
      // Nhưng theo format trước đó, ta có thể dùng luôn USER_ID cho đơn giản nếu ko cần strict tracing
      // Ở đây ta dùng format "NAPTIEN [USER_ID]" để webhook dễ parse
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.id ?? '';
      
      // Lấy 8 ký tự đầu của User ID cho mã ngắn gọn
      final shortUserId = userId.length > 8 ? userId.substring(0, 8).toUpperCase() : userId.toUpperCase();
      
      final qrUrl = SePayService().generateVietQRUrl(
        amount: amount,
        bookingReference: shortUserId,
        prefix: 'NAPTIEN',
      );

      setState(() {
        _qrUrl = qrUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppAuthProvider>(context).userModel;
    if (user == null) return const Scaffold();

    return ChangeNotifierProvider(
      create: (_) => WalletViewModel(userId: user.id),
      child: Consumer<WalletViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('Nạp tiền vào ví')),
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
                          const Text('Nhập số tiền cần nạp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền';
                              final num = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                              if (num == null || num < 20000) return 'Số tiền nạp tối thiểu là 20.000đ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: viewModel.isLoading ? null : () => _generateQr(context, viewModel),
                              child: viewModel.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('TẠO MÃ QR NẠP TIỀN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Quét mã QR để thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Image.network(_qrUrl!, height: 300, fit: BoxFit.contain),
                          const SizedBox(height: 20),
                          const Text(
                            'Tiền sẽ tự động được cộng vào ví của bạn trong vòng 1-3 phút sau khi chuyển khoản thành công.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Trở về Ví của tôi'),
                            ),
                          )
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
