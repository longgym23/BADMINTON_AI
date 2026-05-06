import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';

import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/providers/booking_provider.dart';
import 'package:badminton_ai/providers/notification_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/screens/user/booking/court_selection_screen.dart';
import 'package:badminton_ai/viewmodels/checkout_viewmodel.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class CheckoutScreen extends StatelessWidget {
  final CourtLocationModel selectedCourt;
  final DateTime selectedDate;
  final List<SelectedSlot> selectedSlots;
  final double totalHours;
  final int totalPrice;
  final String? reservedTransactionId;
  final DateTime? reservedExpiresAt;

  const CheckoutScreen({
    super.key,
    required this.selectedCourt,
    required this.selectedDate,
    required this.selectedSlots,
    required this.totalHours,
    required this.totalPrice,
    this.reservedTransactionId,
    this.reservedExpiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = CheckoutViewModel();
        // Prefill user data if available
        final user = context.read<AppAuthProvider>().userModel;
        int walletBal = 0;
        if (user != null) {
          vm.setCustomerName(user.displayName ?? '');
          vm.setCustomerPhone(user.phoneNumber ?? '');
          walletBal = user.balance;
        }
        vm.initializePayment(
          totalPrice,
          selectedCourt.id,
          walletBalance: walletBal,
          transactionId: reservedTransactionId,
        );

        // If slots already reserved from previous screen (UX-first flow),
        // mark booking created so user can proceed to payment immediately.
        if (reservedTransactionId != null) {
          vm.setBookingCreated(true);
        }
        return vm;
      },
      child: CheckoutScreenView(
        selectedCourt: selectedCourt,
        selectedDate: selectedDate,
        selectedSlots: selectedSlots,
        totalHours: totalHours,
        totalPrice: totalPrice,
        reservedExpiresAt: reservedExpiresAt,
      ),
    );
  }
}

class CheckoutScreenView extends StatefulWidget {
  final CourtLocationModel selectedCourt;
  final DateTime selectedDate;
  final List<SelectedSlot> selectedSlots;
  final double totalHours;
  final int totalPrice;
  final DateTime? reservedExpiresAt;

  const CheckoutScreenView({
    super.key,
    required this.selectedCourt,
    required this.selectedDate,
    required this.selectedSlots,
    required this.totalHours,
    required this.totalPrice,
    this.reservedExpiresAt,
  });

  @override
  State<CheckoutScreenView> createState() => _CheckoutScreenViewState();
}

class _CheckoutScreenViewState extends State<CheckoutScreenView> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<CheckoutViewModel>();
    _nameController = TextEditingController(text: vm.customerName);
    _phoneController = TextEditingController(text: vm.customerPhone);
    _noteController = TextEditingController();

    // Nếu slot đã được reserve từ màn grid, chỉ khởi động đồng hồ đếm ngược.
    // QR sẽ chỉ hiện sau khi user kiểm tra thông tin và bấm Xác nhận.
    if (widget.reservedExpiresAt != null) {
      final remaining = widget.reservedExpiresAt!
          .difference(DateTime.now())
          .inSeconds;
      if (remaining > 0) {
        vm.startCountdown(() {
          final authProvider = context.read<AppAuthProvider>();
          final userId = authProvider.userModel?.id;
          _onPaymentExpired(vm.transactionId, vm.appliedBalance, userId);
        });
        // Không gọi _listenForPayment() ở đây — chờ user bấm Xác nhận
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await context.read<SupabaseRepository>().releaseBookingTransaction(
            vm.transactionId,
          );
          if (mounted) {
            AppToast.show(
              context,
              'checkout_screen.slotExpired'.tr(),
              type: ToastType.error,
            );
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatTime(double t) {
    final h = t.floor();
    final m = ((t - h) * 60).round();
    return '${h.toString()}:${m.toString().padLeft(2, '0')}';
  }

  String _displayTotalHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  Future<bool> _createPendingBookings() async {
    final provider = context.read<BookingProvider>();
    final vm = context.read<CheckoutViewModel>();
    int success = 0;

    // Group selected slots by court number
    Map<int, List<int>> slotsByCourt = {};
    for (var slot in widget.selectedSlots) {
      slotsByCourt
          .putIfAbsent(slot.courtNumber, () => [])
          .add(slot.timeSlot.toInt());
    }

    for (var entry in slotsByCourt.entries) {
      int courtNum = entry.key;
      List<int> slots = entry.value;

      for (int slot in slots) {
        final bookingId = await provider.createBooking(
          courtId: widget.selectedCourt.id,
          courtName: widget.selectedCourt.name,
          courtNumber: courtNum,
          date: widget.selectedDate,
          timeSlot: slot,
          price: widget.selectedCourt.pricePerHour.round(),
          status: 'PENDING_PAYMENT',
          transactionId: vm.transactionId,
        );
        if (bookingId != null) success++;
      }
    }
    return success > 0;
  }

  Future<void> _sendSuccessNotifications() async {
    final notificationProvider = context.read<NotificationProvider>();
    final authProvider = context.read<AppAuthProvider>();
    final userId = authProvider.userModel?.id;
    if (userId == null) return;

    Map<int, List<int>> slotsByCourt = {};
    for (var slot in widget.selectedSlots) {
      slotsByCourt
          .putIfAbsent(slot.courtNumber, () => [])
          .add(slot.timeSlot.toInt());
    }

    for (var entry in slotsByCourt.entries) {
      int courtNum = entry.key;
      List<int> slots = entry.value;
      slots.sort();

      if (slots.isNotEmpty) {
        int startSlot = slots[0];
        int endSlot = startSlot + 1;
        int currentPrice = widget.selectedCourt.pricePerHour.round();

        for (int i = 1; i < slots.length; i++) {
          if (slots[i] == endSlot) {
            endSlot++;
            currentPrice += widget.selectedCourt.pricePerHour.round();
          } else {
            try {
              await notificationProvider.createBookingSuccessNotification(
                userId: userId,
                courtId: widget.selectedCourt.id,
                bookingId: 'group_$startSlot',
                courtName: widget.selectedCourt.name,
                courtAddress: widget.selectedCourt.address,
                courtNumber: courtNum,
                bookingDate: widget.selectedDate,
                timeSlot: startSlot,
                price: currentPrice,
                durationHours: endSlot - startSlot,
              );
            } catch (e) {
              print("Lỗi tạo thông báo: $e");
            }
            startSlot = slots[i];
            endSlot = startSlot + 1;
            currentPrice = widget.selectedCourt.pricePerHour.round();
          }
        }
        try {
          await notificationProvider.createBookingSuccessNotification(
            userId: userId,
            courtId: widget.selectedCourt.id,
            bookingId: 'group_$startSlot',
            courtName: widget.selectedCourt.name,
            courtAddress: widget.selectedCourt.address,
            courtNumber: courtNum,
            bookingDate: widget.selectedDate,
            timeSlot: startSlot,
            price: currentPrice,
            durationHours: endSlot - startSlot,
          );
        } catch (e) {
          print("Lỗi tạo thông báo: $e");
        }
      }
    }
  }

  Future<void> _finishRegularBookingSuccess() async {
    if (!mounted) return;
    
    AppToast.show(context, 'checkout_screen.paymentSuccess'.tr(), type: ToastType.success);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _onConfirmPayment() async {
    final vm = context.read<CheckoutViewModel>();

    if (vm.customerName.isEmpty || vm.customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('checkout_screen.fillNameAndPhone'.tr())),
      );
      return;
    }

    if (!vm.isBookingCreated) {
      // TH1: Chưa reserve slot — tạo pending bookings trước
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(width: 20),
              Expanded(child: Text('checkout_screen.creatingOrder'.tr())),
            ],
          ),
        ),
      );

      final isCreated = await _createPendingBookings();
      if (mounted) Navigator.pop(context);

      if (!isCreated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('checkout_screen.orderError'.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      vm.setBookingCreated(true);
    }

    // Xử lý trừ ví (cả 2 flow)
    final authProvider = context.read<AppAuthProvider>();
    final userId = authProvider.userModel?.id;
    final repo = context.read<SupabaseRepository>();

    if (vm.appliedBalance > 0 && userId != null) {
      await repo.deductBalance(userId, vm.appliedBalance);
      if (authProvider.userModel != null) {
        authProvider.updateUserModel(
          authProvider.userModel!.copyWith(
            balance: authProvider.userModel!.balance - vm.appliedBalance,
          ),
        );
      }
    }

    // Hiển QR và bắt đầu nghe thanh toán
    if (vm.finalAmount > 0) {
      vm.setQrVisible(true); // Hiện QR, ẩn button
      if (!vm.isExpired) {
        // Chỉ start countdown nếu chưa chạy (flow không pre-reserved)
        if (widget.reservedExpiresAt == null) {
          vm.startCountdown(
            () =>
                _onPaymentExpired(vm.transactionId, vm.appliedBalance, userId),
          );
        }
      }
      _listenForPayment();
    } else {
      _processZeroPayment(vm.transactionId);
    }
  }

  void _processZeroPayment(String transactionId) async {
    final vm = context.read<CheckoutViewModel>();
    final repo = context.read<SupabaseRepository>();

    // Đánh dấu Paid trong db
    await repo.markBookingsAsPaid(transactionId);

    final success = await vm.processZeroPayment();

    if (success && mounted) {
      await _sendSuccessNotifications();
      await _finishRegularBookingSuccess();
    }
  }

  /// Gọi khi hết 5 phút chưa thanh toán: xóa booking PENDING rồi về Home
  Future<void> _onPaymentExpired(
    String transactionId,
    int refundedBalance,
    String? userId,
  ) async {
    try {
      final repo = context.read<SupabaseRepository>();
      await repo.releaseBookingTransaction(transactionId);

      // Hoàn lại tiền ví nếu đã trừ
      if (refundedBalance > 0 && userId != null) {
        await repo.addBalance(userId, refundedBalance);
        final authProvider = context.read<AppAuthProvider>();
        if (authProvider.userModel != null) {
          authProvider.updateUserModel(
            authProvider.userModel!.copyWith(
              balance: authProvider.userModel!.balance + refundedBalance,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi xóa booking hết hạn: $e');
    }

    if (mounted) {
      AppToast.show(
        context,
        'checkout_screen.paymentExpired'.tr(),
        type: ToastType.error,
      );
      // Về màn trước (court selection) rồi về Home
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  void _listenForPayment() async {
    final vm = context.read<CheckoutViewModel>();

    // Bắt đầu chờ Webhook cập nhật Database thành PAID qua Supabase Realtime
    final success = await vm.startListeningForPayment();

    if (success) {
      await _sendSuccessNotifications();
      await _finishRegularBookingSuccess();
    } else {
      // Nghe thất bại hoặc Timeout
      if (mounted && vm.errorMessage != null) {
        AppToast.show(context, vm.errorMessage!, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final vm = context.watch<CheckoutViewModel>();

    // Sort slots for display
    final sortedSlots = List<SelectedSlot>.from(widget.selectedSlots)
      ..sort((a, b) {
        if (a.courtNumber != b.courtNumber)
          return a.courtNumber.compareTo(b.courtNumber);
        return a.timeSlot.compareTo(b.timeSlot);
      });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          context.read<SupabaseRepository>().releaseBookingTransaction(
            vm.transactionId,
          );
        }
      },
      child: Scaffold(
        appBar: CustomGradientAppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'checkout_screen.title'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
          elevation: 0,
        ),
        // Button hiện khi chưa bấm Xác nhận, ẩn sau khi QR xuất hiện
        bottomSheet: vm.isQrVisible
            ? null
            : Container(
                color: AppColors.surface,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: vm.isLoading ? null : _onConfirmPayment,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'checkout_screen.createPayment'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'checkout_screen.courtInfo'.tr(),
                icon: Icons.map_outlined,
                children: [
                  _buildInfoRow('checkout_screen.clubName'.tr(), widget.selectedCourt.name),
                  SizedBox(height: 8),
                  _buildInfoRow('checkout_screen.address'.tr(), widget.selectedCourt.address),
                ],
              ),
              SizedBox(height: 16),

              _buildSectionCard(
                title: 'checkout_screen.bookingInfo'.tr(),
                icon: Icons.calendar_month_outlined,
                children: [
                  _buildInfoRow(
                    'checkout_screen.date'.tr(),
                    DateFormat('dd/MM/yyyy').format(widget.selectedDate),
                  ),
                  SizedBox(height: 8),
                  ...sortedSlots.map(
                    (slot) => Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "- ${'booking_history_screen.court'.tr()} ${slot.courtNumber}: ${_formatTime(slot.timeSlot)} - ${_formatTime(slot.timeSlot + 1)} | ${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(widget.selectedCourt.pricePerHour)}",
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow('checkout_screen.sport'.tr(), 'checkout_screen.badminton'.tr()),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    'court_selection_screen.totalHours'.tr(),
                    _displayTotalHours(widget.totalHours),
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    'court_selection_screen.totalPrice'.tr(),
                    NumberFormat.simpleCurrency(
                      locale: 'vi_VN',
                      decimalDigits: 0,
                    ).format(widget.totalPrice),
                    isTotal: true,
                  ),
                  if (vm.appliedBalance > 0) ...[
                    SizedBox(height: 8),
                    _buildInfoRow(
                      'checkout_screen.deductWallet'.tr(),
                      '- ${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(vm.appliedBalance)}',
                      color: Colors.green,
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(
                      'checkout_screen.amountToPay'.tr(),
                      NumberFormat.simpleCurrency(
                        locale: 'vi_VN',
                        decimalDigits: 0,
                      ).format(vm.finalAmount),
                      isTotal: true,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
              SizedBox(height: 24),

              Text(
                'checkout_screen.customerName'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 4),
              TextField(
                controller: _nameController,
                onChanged: vm.setCustomerName,
                decoration: _inputDecoration(
                  'checkout_screen.customerNameHint'.tr(),
                  Icons.person_outline,
                ),
              ),
              SizedBox(height: 16),

              Text(
                'checkout_screen.customerPhone'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 4),
              TextField(
                controller: _phoneController,
                onChanged: vm.setCustomerPhone,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  'checkout_screen.customerPhoneHint'.tr(),
                  Icons.phone_outlined,
                ),
              ),
              SizedBox(height: 16),

              Text(
                'checkout_screen.noteForOwner'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              SizedBox(height: 4),
              TextField(
                controller: _noteController,
                onChanged: vm.setNote,
                maxLines: 2,
                decoration: _inputDecoration('checkout_screen.noteHint'.tr(), null),
              ),
              SizedBox(height: 24),

              // QR thanh toán (chỉ hiển thị khi user đã bấm Xác nhận)
              if (vm.isQrVisible)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            color: AppColors.primaryDark,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'checkout_screen.scanVietQR'.tr(),
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            vm.qrUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),
                                    Text(
                                      'checkout_screen.qrLoadError'.tr(),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'checkout_screen.waitingPayment'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Đồng hồ đếm ngược (không có loading spinner)
                      Consumer<CheckoutViewModel>(
                        builder: (_, vm, __) {
                          final isLow = vm.remainingSeconds <= 60;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: isLow
                                    ? Colors.red
                                    : AppColors.primaryDark,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${'checkout_screen.expiresIn'.tr()} ${vm.remainingLabel}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isLow
                                      ? Colors.red
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: AppColors.borderColor),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color:
                  color ??
                  (isTotal ? Color(0xFFFF9800) : AppColors.textBlack),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textGrey, size: 20)
          : null,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
