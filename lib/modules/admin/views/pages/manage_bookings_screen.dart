import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/data/models/booking_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/admin/repositories/admin_repository.dart';

import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/admin/viewmodels/manage_bookings_viewmodel.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:badminton_ai/core/design_system/components/ui/time_filter_widget.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/design_system/components/ui/app_toast.dart';
import 'package:badminton_ai/core/utils/dialog_utils.dart';

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageBookingsViewModel(),
      child: const _ManageBookingsView(),
    );
  }
}

class _ManageBookingsView extends StatefulWidget {
  const _ManageBookingsView();

  @override
  _ManageBookingsViewState createState() => _ManageBookingsViewState();
}

class _ManageBookingsViewState extends State<_ManageBookingsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadUserNames());
  }

  Future<void> _loadUserNames() async {
    try {
      final repo = context.read<SupabaseRepository>();
      final users = await repo.getUsers();
      if (mounted) {
        setState(() {
          _userNames = {
            for (var u in users) u.id: u.displayName ?? (u.email != null ? u.email!.split('@')[0] : 'Khách')
          };
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách người dùng: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _confirmDelete(
    BuildContext context,
    String? bookingId,
  ) {
    if (bookingId == null) return;

    DialogUtils.showConfirmDialog(
      context,
      title: 'screens.cancelBooking'.tr(),
      content: 'screens.adminOwnerAreYouSureYou'.tr(),
      confirmText: 'common.confirm'.tr(),
      cancelText: 'common.no'.tr(),
      isDestructive: true,
      onConfirm: () async {
        try {
          await context.read<IAdminRepository>().cancelBooking(bookingId);
          if (!context.mounted) return;
          AppToast.show(
            context,
            'screens.theFieldHasBeenSuccessfull'.tr(),
            type: ToastType.success,
          );
          setState(() {});
        } catch (e) {
          if (!context.mounted) return;
          AppToast.show(context, "Hủy sân thất bại: $e", type: ToastType.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SupabaseRepository>();
    final vm = context.watch<ManageBookingsViewModel>();
    final auth = context.read<AppAuthProvider>();
    final isOwner = auth.userRole == 'court_owner';
    final ownerId = isOwner ? auth.userModel?.id : null;

    final currencyFormatter = NumberFormat.simpleCurrency(
      locale: 'vi_VN',
      decimalDigits: 0,
    );

    final isAllowed =
        auth.userRole == 'admin' || auth.userRole == 'court_owner';

    if (!isAllowed) {
      return Scaffold(
        body: Center(child: Text('screens.youDoNotHavePermissionTo'.tr())),
      );
    }

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(
          isOwner
              ? 'screens.manageMyCalendar'.tr()
              : 'screens.manageAllBookings'.tr(),
        ),
      ),
      body: Column(
        children: [
          // Filter Header Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Quick Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo mã booking',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'screens.timeFilter'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    TimeFilterWidget(viewModel: vm),
                  ],
                ),
              ],
            ),
          ),

          // Total Revenue / Stats Row (Optional but nice)
          const SizedBox(height: 12),

          // List results
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              // Using the new more flexible stream
              stream: repo.getBookingsStream(ownerId: ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }

                final allBookings = snapshot.data ?? [];
                
                // Quick search filtering
                final searched = allBookings.where((b) {
                  if (_searchQuery.isEmpty) return true;
                  final query = _searchQuery.toLowerCase();
                  final cachedName = _userNames[b.userId]?.toLowerCase() ?? '';
                  return b.id!.toLowerCase().contains(query) ||
                         cachedName.contains(query);
                }).toList();

                final filtered = vm.applyFilter(searched);
                final sorted = vm.sortBookings(filtered);

                if (sorted.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'screens.thereAreNoBookingsNforThe'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length + 1, // +1 for summary card
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _RevenueSummary(
                        total: vm.calculateTotalRevenue(sorted),
                        count: sorted.length,
                        fmt: currencyFormatter,
                      );
                    }

                    final booking = sorted[index - 1];
                    return _AdminBookingCard(
                      booking: booking,
                      userName: _userNames[booking.userId] ?? 'Khách hàng',
                      fmt: currencyFormatter,
                      onDelete: () => _confirmDelete(context, booking.id),
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
}

class _RevenueSummary extends StatelessWidget {
  final int total;
  final int count;
  final NumberFormat fmt;

  const _RevenueSummary({
    required this.total,
    required this.count,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VColors.brandPrimaryDark, VColors.brandPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: VColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'screens.totalRevenue'.tr(),
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                fmt.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'screens.bookingNumber'.tr(),
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String userName;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _AdminBookingCard({
    required this.booking,
    required this.userName,
    required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = booking.status == 'PAID'
        ? Colors.green
        : (booking.status == 'cancelled' ? Colors.red : VColors.brandPrimary);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Left decor line
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ID: ${booking.id!.length > 8 ? booking.id!.substring(0, 8).toUpperCase() : booking.id!.toUpperCase()}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          userName.isNotEmpty ? userName : 'Khách hàng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(booking.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${booking.courtName} - Sân #${booking.courtNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: VColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.timeSlot}:00 - ${booking.timeSlot + 1}:00',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Spacer(),
                      Text(
                        fmt.format(booking.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: VColors.brandPrimaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
