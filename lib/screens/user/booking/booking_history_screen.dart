import 'package:badminton_ai/data/models/booking_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/screens/user/booking/components/booking_history/booking_card.dart';
import 'package:badminton_ai/screens/user/booking/components/booking_history/filter_section.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/viewmodels/booking_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─── Screen Entry Point ──────────────────────────────────────────────────────

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingHistoryViewModel(),
      child: const _BookingHistoryView(),
    );
  }
}

// ─── View ─────────────────────────────────────────────────────────────────────

class _BookingHistoryView extends StatelessWidget {
  const _BookingHistoryView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final vm = context.watch<BookingHistoryViewModel>();
    final repo = context.watch<SupabaseRepository>();
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(l),
      body: userId == null
          ? Center(child: Text(l.pleaseLogin))
          : StreamBuilder<List<BookingModel>>(
              stream: repo.getUserBookingHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${l.error}: ${snapshot.error}'));
                }

                final bookings = snapshot.data ?? [];
                final groups = vm.groupBookings(bookings);
                final filtered = vm.applyFilter(groups);
                final totalSpend = vm.calculateTotalSpend(filtered);
                final currencyFmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(totalSpend: totalSpend, count: filtered.length, currencyFmt: currencyFmt, l: l),
                      const SizedBox(height: 16),
                      _FilterHeader(vm: vm, l: l),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        _EmptyState(message: bookings.isEmpty ? l.noBookings : l.noBookingsInRange)
                      else
                        ...filtered.map((g) => BookingCard(group: g, repo: repo, l: l)),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }

  AppBar _buildAppBar(AppLocalizations l) {
    return AppBar(
      title: Text(l.bookingHistory,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brandOrangeDark, AppColors.brandOrangeLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// ─── Summary Row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final int totalSpend;
  final int count;
  final NumberFormat currencyFmt;
  final AppLocalizations l;

  const _SummaryRow({
    required this.totalSpend,
    required this.count,
    required this.currencyFmt,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(title: l.totalSpend, value: currencyFmt.format(totalSpend))),
        const SizedBox(width: 16),
        Expanded(child: _SummaryCard(title: l.courtsBooked, value: '$count ${l.times}')),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Filter Header (section label + active filter chip + filter button) ──────

class _FilterHeader extends StatelessWidget {
  final BookingHistoryViewModel vm;
  final AppLocalizations l;

  const _FilterHeader({required this.vm, required this.l});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          vm.filterMode == FilterMode.all ? l.sectionAll : l.filterResults,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        if (vm.filterMode != FilterMode.all) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: vm.setFilterAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vm.filterLabel(context), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
        const Spacer(),
        FilterRow(vm: vm, l: l),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
