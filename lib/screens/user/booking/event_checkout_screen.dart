import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/viewmodels/checkout_viewmodel.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventCheckoutScreen extends StatelessWidget {
  final EventModel event;
  final int quantity;
  final int totalPrice;
  final String customerName;
  final String customerPhone;

  const EventCheckoutScreen({
    super.key,
    required this.event,
    required this.quantity,
    required this.totalPrice,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final balance = auth.userModel?.balance ?? 0;
    final int amountToPayWithSepay = balance >= totalPrice ? 0 : totalPrice - balance;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = CheckoutViewModel();
        vm.setCustomerName(customerName);
        vm.setCustomerPhone(customerPhone);
        // Ngưởi dùng dùng tiền trong ví, nếu thiểu thì QR sePay hiện khoản thiếu.
        vm.initializePayment(amountToPayWithSepay, event.id);
        return vm;
      },
      child: EventCheckoutScreenView(
        event: event,
        quantity: quantity,
        totalPrice: totalPrice,
      ),
    );
  }
}
class EventCheckoutScreenView extends StatefulWidget {
  final EventModel event;
  final int quantity;
  final int totalPrice;

  const EventCheckoutScreenView({
    super.key,
    required this.event,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<EventCheckoutScreenView> createState() => _EventCheckoutScreenViewState();
}

class _EventCheckoutScreenViewState extends State<EventCheckoutScreenView> {
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận thành công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã đặt ${widget.quantity} vé tham gia sự kiện:\n"${widget.event.title}"',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hoàn tất'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirmPayment() async {
    final vm = context.read<CheckoutViewModel>();
    final auth = context.read<AppAuthProvider>();
    final balance = auth.userModel?.balance ?? 0;
    final int amountDeductedFromWallet = balance >= widget.totalPrice ? widget.totalPrice : balance;
    final repo = context.read<SupabaseRepository>();

    if (vm.finalAmount == 0) {
      // Thanh toán hoàn toàn bằng ví
      await vm.processZeroPayment();
      try {
        await repo.joinEvent(widget.event.id, auth.userId!, amountDeductedFromWallet.toDouble());
        if (mounted) _showSuccessDialog();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
      return;
    }

    // Nếu còn thiếu tiền, tiến hành tạo QR
    // Bắt đầu tạo pending state
    vm.setBookingCreated(true);
    // Bắt đầu đếm ngược
    vm.startCountdown(() => _onPaymentExpired(vm.transactionId));
    // Sau khi tạo đơn, hiển thị QR và lắng nghe SePay
    _listenForPayment();
  }

  void _onPaymentExpired(String transactionId) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Hết thời gian thanh toán. Chỗ của bạn đã bị hủy.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _listenForPayment() async {
    final vm = context.read<CheckoutViewModel>();
    
    final success = await vm.startListeningForPayment();

    if (success) {
      final auth = context.read<AppAuthProvider>();
      final balance = auth.userModel?.balance ?? 0;
      final int amountDeductedFromWallet = balance >= widget.totalPrice ? widget.totalPrice : balance;
      final repo = context.read<SupabaseRepository>();

      try {
        await repo.joinEvent(widget.event.id, auth.userId!, amountDeductedFromWallet.toDouble());
        if (mounted) _showSuccessDialog();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật CSDL: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    } else {
      if (mounted && vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CheckoutViewModel>();
    final bgColor = const Color(0xFF0e7a46);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Thanh toán Sự kiện',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin thanh toán',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildRow('Tên sự kiện:', widget.event.title),
                  const SizedBox(height: 8),
                  _buildRow('Thời gian:', '${widget.event.startTime} - ${widget.event.endTime} | ${DateFormat('dd/MM/yyyy').format(widget.event.dateTime)}'),
                  const SizedBox(height: 8),
                  _buildRow('Số lượng vé:', '${widget.quantity} vé'),
                  const SizedBox(height: 8),
                  _buildRow('Tổng tiền:', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.totalPrice), isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (vm.isBookingCreated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, color: AppColors.primaryDark),
                        SizedBox(width: 8),
                        Text(
                          'QUÉT MÃ VIETQR',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          vm.qrUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Đang chờ hệ thống xác nhận thanh toán...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textBlack, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Consumer<CheckoutViewModel>(
                      builder: (_, vm, __) {
                        final isLow = vm.remainingSeconds <= 60;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: isLow ? Colors.red : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Giao dịch tự hủy sau ${vm.remainingLabel}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isLow ? Colors.red : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(strokeWidth: 2),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: bgColor,
        padding: const EdgeInsets.all(16),
        child: vm.isBookingCreated
            ? const SizedBox.shrink()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: vm.isLoading ? null : _onConfirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1C40F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tạo QR Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isTotal ? AppColors.brandOrange : AppColors.textBlack,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
