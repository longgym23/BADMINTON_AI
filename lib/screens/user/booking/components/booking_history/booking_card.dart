import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:badminton_ai/services/court_info_service.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/viewmodels/booking_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';

/// Card hiển thị thông tin 1 booking (nhóm slot liên tiếp).
class BookingCard extends StatelessWidget {
  final BookingGroup group;
  final SupabaseRepository repo;
  final AppLocalizations l;

  const BookingCard({super.key, required this.group, required this.repo, required this.l});

  Future<void> _launchMaps(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.gettingLocation), duration: const Duration(seconds: 1)),
    );
    try {
      final court = await repo.getCourtLocationById(group.base.courtId);
      if (court == null || (court.latitude == 0 && court.longitude == 0)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.locationNotFound)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
    }
  }

  (String, Color, Color, IconData) _resolveStatus(bool isCancelled, bool isCompleted) {
    if (isCancelled) return (l.statusCancelled, AppColors.textGrey, AppColors.borderColor, Icons.cancel);
    if (isCompleted) return (l.statusCompleted, AppColors.success, AppColors.successBg, Icons.check_circle);
    return (l.statusUpcoming, AppColors.primary, AppColors.primaryBg, Icons.calendar_today);
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
    int expectedRefund = 0;
    String refundMsg = "";
    
    if (diffHours >= 24) {
      expectedRefund = group.price;
      refundMsg = "Bạn huỷ trước 24h, hệ thống sẽ hoàn 100% (${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(expectedRefund)}) vào Số Dư Ví trên App.";
    } else if (diffHours >= 12) {
      expectedRefund = (group.price * 0.5).toInt();
      refundMsg = "Bạn huỷ trước dưới 24h và trên 12h, bạn chỉ được hoàn 50% (${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(expectedRefund)}) vào Số Dư Ví.";
    } else {
      expectedRefund = 0;
      refundMsg = "Bạn huỷ sân quá sát giờ chơi (< 12h), bạn sẽ không được hoàn cọc theo quy định.";
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận Huỷ sân"),
        content: Text("Bạn có chắc chắn muốn huỷ lịch đặt sân này?\n\n$refundMsg"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Không", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text("Xác nhận Huỷ"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Hiển thị dialog đang tải
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        for (var item in group.items) {
          await repo.cancelBookingWithRefund(item);
        }
        if (context.mounted) {
          await context.read<AppAuthProvider>().reloadUserModel();
          Navigator.pop(context); // Tắt loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã huỷ sân thành công. Số dư ví đã được cập nhật!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Tắt loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi huỷ sân: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = group.base;
    final now = DateTime.now();
    final bookingTime = DateTime(booking.date.year, booking.date.month, booking.date.day, group.startSlot);

    final isCancelled = booking.status == 'cancelled';
    final isCompleted = !isCancelled && bookingTime.isBefore(now);

    final (statusText, statusColor, statusBgColor, statusIcon) = _resolveStatus(isCancelled, isCompleted);
    final currencyFmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 14),

                // ── Court icon + Details ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CourtIcon(courtNumber: booking.courtNumber, label: l.court),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.courtName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textBlack,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            text: DateFormat('dd/MM/yyyy').format(booking.date),
                          ),
                          const SizedBox(height: 3),
                          _InfoRow(
                            icon: Icons.access_time,
                            text:
                                '${group.startSlot}:00 - ${group.endSlot}:00 (${group.endSlot - group.startSlot}${l.hours})',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (!isCancelled && !isCompleted)
                  TextButton.icon(
                    onPressed: () => _onCancelBooking(context),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                    label: const Text('Huỷ sân', style: TextStyle(color: AppColors.error, fontSize: 14)),
                  )
                else if (isCancelled)
                  TextButton.icon(
                    onPressed: null, // Disabled
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.grey),
                    label: const Text('Đã huỷ sân', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                const Spacer(),
                if (!isCancelled)
                  OutlinedButton.icon(
                    onPressed: () => _launchMaps(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.directions, size: 15, color: AppColors.primary),
                    label: Text(l.getDirections,
                        style: const TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.w500, fontSize: 13)),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.rebookComingSoon)),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 15, color: AppColors.primary),
                    label: Text(l.rebook, style: const TextStyle(color: AppColors.primary)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CourtIcon extends StatelessWidget {
  final int courtNumber;
  final String label;

  const _CourtIcon({required this.courtNumber, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_tennis, color: AppColors.primary, size: 18),
          const SizedBox(height: 2),
          Text(
            '$label $courtNumber',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 9),
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
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}
