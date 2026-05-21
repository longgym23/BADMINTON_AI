import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';

import 'package:badminton_ai/services/court_info_service.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/viewmodels/booking_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:badminton_ai/utils/dialog_utils.dart';
import 'package:flutter/cupertino.dart';

/// Card hiển thị thông tin 1 booking (nhóm slot liên tiếp).
class BookingCard extends StatelessWidget {
  final BookingGroup group;
  final SupabaseRepository repo;
const BookingCard({super.key, required this.group, required this.repo});

  Future<void> _launchMaps(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('booking_history_screen.gettingLocation'.tr()), duration: const Duration(seconds: 1)),
    );
    try {
      final court = await repo.getCourtLocationById(group.base.courtId);
      if (court == null || (court.latitude == 0 && court.longitude == 0)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('booking_history_screen.locationNotFound'.tr())),
          );
        }
        return;
      }
      final url = CourtInfoService.getDirectionsUrl(
        LatLng(court.latitude, court.longitude),
        destinationName: court.name,
      );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: $e')));
      }
    }
  }

  (String, Color, Color, IconData) _resolveStatus(String status, bool isCompleted) {
    if (status == 'cancelled') return ('booking_history_screen.statusCancelled'.tr(), AppColors.textGrey, AppColors.borderColor, Icons.cancel);
    if (status == 'PENDING_PAYMENT') return ('booking_history_screen.statusPending'.tr(), Colors.orange, const Color(0xFFFFF3E0), Icons.hourglass_empty);
    if (isCompleted) return ('booking_history_screen.statusCompleted'.tr(), AppColors.success, AppColors.successBg, Icons.check_circle);
    return ('booking_history_screen.statusUpcoming'.tr(), AppColors.primary, AppColors.primaryBg, Icons.calendar_today);
  }

  Future<void> _onCancelBooking(BuildContext context) async {
    final now = DateTime.now();
    final bookingTime = DateTime(
      group.base.date.year,
      group.base.date.month,
      group.base.date.day,
      group.startSlot,
    );

    final diffHours = bookingTime.difference(now).inHours;
    final diffMinutes = bookingTime.difference(now).inMinutes;

    // Ngưỡng hoàn tiền 3 mức
    int expectedRefund = 0;
    String refundMsg = "";

    final bool isPaid = group.base.status == 'PAID';

    if (!isPaid) {
      expectedRefund = 0;
      refundMsg = "Lịch đặt này chưa thanh toán, hệ thống sẽ hủy chỗ và không hoàn lại tiền.";
    } else {
      if (diffHours >= 2) {
        expectedRefund = group.price;
        refundMsg = "Bạn hủy trước 2 giờ, hệ thống sẽ hoàn 100% (${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(expectedRefund)}) vào Số Dư Ví.";
      } else if (diffMinutes > 0) {
        expectedRefund = (group.price * 0.5).toInt();
        refundMsg = "Bạn hủy trong vòng 2 giờ (chưa tới giờ chơi), sẽ được hoàn 50% (${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(expectedRefund)}) vào Số Dư Ví.";
      } else {
        expectedRefund = 0;
        refundMsg = 'screens.ifThePlayingTimeHasReache'.tr();
      }
    }

    DialogUtils.showConfirmDialog(
      context,
      title: 'screens.confirmationOfCancellation'.tr(),
      content: "Bạn có chắc chắn muốn hủy lịch đặt sân này?\n\n$refundMsg",
      confirmText: 'screens.confirmCancellation'.tr(),
      cancelText: 'screens.areNot'.tr(),
      isDestructive: true,
      onConfirm: () async {
        // Hiển thị dialog đang tải
        DialogUtils.showCustomDialog(
          context,
          title: '',
          content: const Center(child: CupertinoActivityIndicator()),
        );

        try {
          for (var item in group.items) {
            await repo.cancelBookingWithRefund(item);
          }
          if (context.mounted) {
            await context.read<AppAuthProvider>().reloadUserModel();
            Navigator.pop(context); // Tắt loading
            AppToast.show(context, 'screens.theFieldHasBeenCanceledSu'.tr(), type: ToastType.success);
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Tắt loading
            AppToast.show(context, 'Lỗi khi huỷ sân: $e', type: ToastType.error);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = group.base;
    final now = DateTime.now();
    final bookingTime = DateTime(booking.date.year, booking.date.month, booking.date.day, group.startSlot);

    final isCancelled = booking.status == 'cancelled';
    final isCompleted = !isCancelled && bookingTime.isBefore(now);
    final isEvent = booking.transactionId?.startsWith('EVENT_') ?? false;

    final (statusText, statusColor, statusBgColor, statusIcon) = _resolveStatus(booking.status, isCompleted);
    final currencyFmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status + Price ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatusBadge(
                      text: statusText,
                      icon: statusIcon,
                      color: statusColor,
                      bgColor: statusBgColor,
                    ),
                    Text(
                      currencyFmt.format(group.price),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),

                // ── Court icon + Details ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CourtIcon(
                      courtNumber: booking.courtNumber, 
                      label: isEvent ? 'Sự Kiện' : 'booking_history_screen.court'.tr(),
                      isEvent: isEvent,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.courtName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textBlack,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            text: DateFormat('dd/MM/yyyy').format(booking.date),
                          ),
                          SizedBox(height: 3),
                          _InfoRow(
                            icon: Icons.access_time,
                            text: isEvent
                                ? 'Bắt đầu: ${group.startSlot}:00 (Mở cửa từ giờ này)'
                                : '${group.startSlot}:00 - ${group.endSlot}:00 (${group.endSlot - group.startSlot}${'booking_history_screen.hours'.tr()})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[100]),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (!isCancelled && !isCompleted)
                  TextButton.icon(
                    onPressed: () => _onCancelBooking(context),
                    icon: Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                    label: Text('screens.cancelTheField'.tr(), style: TextStyle(color: AppColors.error, fontSize: 14)),
                  )
                else if (isCancelled)
                  TextButton.icon(
                    onPressed: null, // Disabled
                    icon: Icon(Icons.cancel_outlined, size: 16, color: Colors.grey),
                    label: Text('screens.canceledCourse'.tr(), style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                const Spacer(),
                if (!isCancelled)
                  OutlinedButton.icon(
                    onPressed: () => _launchMaps(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: Icon(Icons.directions, size: 15, color: AppColors.primary),
                    label: Text('booking_history_screen.getDirections'.tr(),
                        style: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.w500, fontSize: 13)),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      AppToast.show(context, 'booking_history_screen.rebookComingSoon'.tr(), type: ToastType.success);
                    },
                    icon: Icon(Icons.refresh, size: 15, color: AppColors.primary),
                    label: Text('booking_history_screen.rebook'.tr(), style: TextStyle(color: AppColors.primary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Private helpers ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatusBadge({required this.text, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CourtIcon extends StatelessWidget {
  final int courtNumber;
  final String label;
  final bool isEvent;

  const _CourtIcon({required this.courtNumber, required this.label, this.isEvent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: isEvent ? AppColors.successBg : AppColors.primaryBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isEvent ? Icons.event_available : Icons.sports_tennis, color: isEvent ? AppColors.success : AppColors.primary, size: 18),
          SizedBox(height: 2),
          Text(
            isEvent ? label : '$label $courtNumber',
            style: TextStyle(color: isEvent ? AppColors.success : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        SizedBox(width: 5),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}

