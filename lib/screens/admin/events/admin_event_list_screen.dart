import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/screens/admin/events/admin_create_event_screen.dart';
import 'package:badminton_ai/viewmodels/admin_events_viewmodel.dart';
import 'package:badminton_ai/widgets/time_filter_widget.dart';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';

class AdminEventListScreen extends StatelessWidget {
  const AdminEventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminEventsViewModel(),
      child: const _AdminEventListView(),
    );
  }
}

class _AdminEventListView extends StatefulWidget {
  const _AdminEventListView();

  @override
  State<_AdminEventListView> createState() => _AdminEventListViewState();
}

class _AdminEventListViewState extends State<_AdminEventListView> {
  void _confirmDelete(BuildContext context, EventModel event) {
    DialogUtils.showConfirmDialog(
      context,
      title: 'Xác nhận xoá',
      content: 'Bạn có chắc chắn muốn xoá sự kiện "${event.title}"?',
      confirmText: 'Xóa',
      isDestructive: true,
      onConfirm: () async {
        try {
          await context.read<SupabaseRepository>().deleteEvent(event.id);
          if (!context.mounted) return;
          AppToast.show(context, 'Đã xóa sự kiện!', type: ToastType.success);
          setState(() {});
        } catch (e) {
          if (!context.mounted) return;
          AppToast.show(context, 'Lỗi: $e', type: ToastType.error);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final isCourtOwner = auth.userRole == 'court_owner';
    final ownerId = isCourtOwner ? auth.userId : null;
    final vm = context.watch<AdminEventsViewModel>();
    final fmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);
    final l = AppLocalizations.of(context);

    if (auth.userRole != 'admin' && auth.userRole != 'court_owner') {
      return const Scaffold(body: Center(child: Text('Bạn không có quyền truy cập trang này.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomGradientAppBar(title: const Text('Quản lý sự kiện')),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TimeFilterWidget(
                  viewModel: vm,
                  l: l,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: context.read<SupabaseRepository>().getEventsStream(ownerId: ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu.'));
                
                final allEvents = snapshot.data ?? [];
                final filtered = vm.filterEvents(allEvents);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Không tìm thấy sự kiện nào.', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    return _EventCard(
                      event: event,
                      fmt: fmt,
                      onDelete: () => _confirmDelete(context, event),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (isCourtOwner) {
            final repo = context.read<SupabaseRepository>();
            final courts = await repo.getCourtLocationsStream(ownerId: ownerId).first;
            if (courts.isEmpty) {
              if (context.mounted) {
                AppToast.show(context, 'Bạn cần thêm sân trước khi tạo sự kiện!', type: ToastType.error);
              }
              return;
            }
          }
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreateEventScreen()));
          setState(() {}); // Refresh data after creating a new event
        },
        backgroundColor: AppColors.brandOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sự kiện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _EventCard({required this.event, required this.fmt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isFull = event.currentParticipants >= event.maxParticipants;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Badge
              Container(
                width: 60,
                height: 70,
                decoration: BoxDecoration(color: AppColors.brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('dd').format(event.dateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.brandOrangeDark)),
                    Text(DateFormat('MMM').format(event.dateTime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brandOrangeDark, height: 0.8)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(event.eventCode, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.courtArea, style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('👥 ${event.currentParticipants}/${event.maxParticipants}', style: TextStyle(color: isFull ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(fmt.format(event.price), style: const TextStyle(color: AppColors.brandOrangeDark, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete Button
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

