import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/chat/models/chat_message_model.dart';
import 'package:badminton_ai/core/data/models/court_location_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/court_selection_screen.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/booking_history_screen.dart';
import 'package:badminton_ai/modules/profile/views/pages/statistics_screen.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const MessageBubble({super.key, required this.message});

  Map<String, dynamic>? _action() {
    final md = message.metadata;
    if (md == null) return null;
    final a = md['action'];
    return a is Map<String, dynamic> ? a : null;
  }

  Widget _buildSafeImage(String path) {
    if (path.isEmpty) return const SizedBox.shrink();
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return _buildBrokenImagePlaceholder();
      }
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildBrokenImagePlaceholder(),
      );
    } catch (_) {
      return _buildBrokenImagePlaceholder();
    }
  }

  Widget _buildBrokenImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      width: double.infinity,
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              'screens.photoHasExpired'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = message.isUser;
    final action = !isUser ? _action() : null;
    final actionType = action?['type']?.toString();
    final actionSport = action?['sport']?.toString();

    final actionMatch = RegExp(r'\[ACTION_SEARCH:([^\]]+)\]').firstMatch(message.text);
    final String? legacySearchSportType = !isUser && actionMatch != null ? actionMatch.group(1) : null;
    final String? searchSportType = actionType == 'search_courts' ? (actionSport ?? legacySearchSportType) : legacySearchSportType;

    final viewSchedule = !isUser && (actionType == 'view_schedule' || message.text.contains('[ACTION_VIEW_SCHEDULE]'));
    final viewExpense = !isUser && (actionType == 'view_expense' || message.text.contains('[ACTION_VIEW_EXPENSE]'));
    final cancelBooking = !isUser && (actionType == 'cancel_booking' || message.text.contains('[ACTION_CANCEL_BOOKING]'));

    final cleanText = message.text
        .replaceAll(RegExp(r'\[ACTION_SEARCH:[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[ACTION_VIEW_SCHEDULE\]'), '')
        .replaceAll(RegExp(r'\[ACTION_VIEW_EXPENSE\]'), '')
        .replaceAll(RegExp(r'\[ACTION_CANCEL_BOOKING\]'), '')
        .trim();

    final nearbyCourtsData = message.metadata?['nearby_courts'];
    List<CourtLocationModel>? backendCourts;
    if (nearbyCourtsData != null && nearbyCourtsData is List) {
      backendCourts = nearbyCourtsData
          .map((e) => CourtLocationModel.fromSupabase(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    if (!isUser && message.type == 'booking_success') {
      return _buildSuccessCard(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: VColors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: VColors.surface, size: 16),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFFF8C00) : const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 100, maxWidth: 160),
                              child: _buildSafeImage(message.imagePath!),
                            ),
                          ),
                        ),
                      if (cleanText.isNotEmpty)
                        Text(
                          (!isUser && searchSportType != null) ? 'screens.belowAreTheCoursesYouCan'.tr() : cleanText,
                          style: TextStyle(color: isUser ? VColors.surface : VColors.textPrimary, fontSize: 15),
                        ),
                    ],
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 40),
            ],
          ),
          if (searchSportType != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: CourtListCarousel(sportType: searchSportType, backendCourts: backendCourts),
            ),
          if (!isUser && (viewSchedule || viewExpense || cancelBooking))
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: Row(
                children: [
                  if (viewSchedule)
                    ChatActionButton(
                      icon: Icons.calendar_today,
                      label: 'screens.viewCalendar'.tr(),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen())),
                    ),
                  if (viewExpense)
                    ChatActionButton(
                      icon: Icons.account_balance_wallet,
                      label: 'screens.seeSpending'.tr(),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen())),
                    ),
                  if (cancelBooking)
                    ChatActionButton(
                      icon: Icons.cancel,
                      label: 'screens.cancelTheField1'.tr(),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen())),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 4, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VColors.statusSuccessSubdued,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VColors.statusSuccess.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: VColors.statusSuccess, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: VColors.surface, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'screens.transactionRecorded'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: VColors.statusSuccess, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: VColors.brandPrimarySubdued, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.sports_soccer, color: VColors.brandPrimary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('screens.paymentCompleted'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('screens.theFieldWillBeReserved'.tr(), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CourtListCarousel extends StatefulWidget {
  final String sportType;
  final List<CourtLocationModel>? backendCourts;
  const CourtListCarousel({super.key, required this.sportType, this.backendCourts});

  @override
  State<CourtListCarousel> createState() => _CourtListCarouselState();
}

class _CourtListCarouselState extends State<CourtListCarousel> {
  List<CourtLocationModel> courts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.backendCourts != null) {
      courts = widget.backendCourts!;
      isLoading = false;
    } else {
      _loadCourts();
    }
  }

  Future<void> _loadCourts() async {
    try {
      final repo = SupabaseRepository();
      final all = await repo.getCourtLocationsStream().first;
      if (mounted) {
        setState(() {
          courts = all.take(5).toList();
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    if (courts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: courts.length,
        itemBuilder: (context, index) {
          final court = courts[index];
          return VCard(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(court.name, style: VTypography.headingSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(court.address, style: VTypography.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CourtSelectionScreen(selectedCourt: court, selectedDate: DateTime.now())),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: VColors.brandPrimary, padding: EdgeInsets.zero),
                      child: Text('screens.bookNow'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ChatActionButton({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: VColors.brandPrimarySubdued,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VColors.brandPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: VColors.brandPrimary),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: VColors.brandPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
