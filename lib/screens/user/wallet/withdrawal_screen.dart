import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/viewmodels/wallet_viewmodel.dart';
import 'package:intl/intl.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _bankInfoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _bankInfoController.dispose();
    super.dispose();
  }

  void _submitWithdrawal(
    BuildContext context,
    WalletViewModel viewModel,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountStr) ?? 0;

    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    final currentBalance = user?.balance ?? 0;

    if (amount > currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư không đủ để rút số tiền này')),
      );
      return;
    }

    final success = await viewModel.requestWithdrawal(
      amount,
      _bankInfoController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu rút tiền thành công. Vui lòng chờ admin xử lý.',
          ),
        ),
      );
      // Update local balance immediately for better UX
      if (user != null) {
        authProvider.updateUserModel(
          user.copyWith(balance: currentBalance - amount),
        );
      }
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Có lỗi xảy ra')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.userModel;
    if (user == null) return const Scaffold();

    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return ChangeNotifierProvider(
      create: (_) => WalletViewModel(userId: user.id),
      child: Consumer<WalletViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: CustomGradientAppBar(title: Text('Rút tiền')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Số dư khả dụng:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            format.format(user.balance),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Số tiền cần rút',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'VD: 100000',
                        border: OutlineInputBorder(),
                        suffixText: 'VNĐ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập số tiền';
                        final num = int.tryParse(
                          value.replaceAll(RegExp(r'[^0-9]'), ''),
                        );
                        if (num == null || num < 50000)
                          return 'Số tiền rút tối thiểu là 50.000đ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Thông tin nhận tiền (Ngân hàng - STK - Tên)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bankInfoController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'VD: Vietcombank - 0123456789 - NGUYEN VAN A',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập thông tin ngân hàng';
                        if (value.length < 10) return 'Thông tin quá ngắn';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _submitWithdrawal(context, viewModel),
                        child: viewModel.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'GỬI YÊU CẦU RÚT TIỀN',
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
            ),
          );
        },
      ),
    );
  }
}
