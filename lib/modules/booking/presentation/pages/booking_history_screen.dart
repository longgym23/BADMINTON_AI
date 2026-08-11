import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/data/models/booking_model.dart';
import 'package:badminton_ai/core/data/repositories/supabase_repository.dart';

import 'package:badminton_ai/modules/auth/viewmodels/auth_provider.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/components/booking_history/booking_card.dart';
import 'package:badminton_ai/modules/booking/presentation/pages/components/booking_history/filter_section.dart';
import 'package:badminton_ai/core/design_system/patterns/filterable_viewmodel_mixin.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/booking/presentation/viewmodels/booking_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';

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
    
    final vm = context.watch<BookingHistoryViewModel>();
    final repo = context.watch<SupabaseRepository>();
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    return Scaffold(
      appBar: _buildAppBar(),
      body: userId == null
          ? Center(child: Text('common.pleaseLogin'.tr()))
          : StreamBuilder<List<BookingModel>>(
              stream: repo.getUserBookingHistoryStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: VColors.brandPrimary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${'common.error'.tr()}: ${snapshot.error}'));
                }

                final bookings = snapshot.data ?? [];
                final groups = vm.groupBookings(bookings);
                final filtered = vm.applyFilter(groups);
                final totalSpend = vm.calculateTotalSpend(filtered);
                final currencyFmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(totalSpend: totalSpend, count: filtered.length, currencyFmt: currencyFmt),
                      SizedBox(height: 16),
                      _FilterHeader(vm: vm),
                      SizedBox(height: 12),
                      if (filtered.isEmpty)
                        _EmptyState(message: bookings.isEmpty ? 'booking_history_screen.noBookings'.tr() : 'booking_history_screen.noBookingsInRange'.tr())
                      else
                        ...filtered.map((g) => BookingCard(group: g, repo: repo)),
                      SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomGradientAppBar(
      title: Text('booking_history_screen.title'.tr(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
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
const _SummaryRow({
    required this.totalSpend,
    required this.count,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(title: 'booking_history_screen.totalSpend'.tr(), value: currencyFmt.format(totalSpend))),
        SizedBox(width: 16),
        Expanded(child: _SummaryCard(title: 'booking_history_screen.courtsBooked'.tr(), value: '$count ${'booking_history_screen.times'.tr()}')),
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
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: VColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text(value, style: TextStyle(color: VColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Filter Header (section label + active filter chip + filter button) ──────

class _FilterHeader extends StatelessWidget {
  final BookingHistoryViewModel vm;
const _FilterHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          vm.filterMode == FilterMode.all ? 'booking_history_screen.sectionAll'.tr() : 'booking_history_screen.filterResults'.tr(),
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        FilterRow(vm: vm),
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
        padding: EdgeInsets.only(top: 48),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

