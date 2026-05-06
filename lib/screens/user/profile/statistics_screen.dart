import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/viewmodels/statistics_viewmodel.dart';
import 'package:badminton_ai/screens/user/profile/components/statistics_filter_row.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/viewmodels/mixins/filterable_viewmodel_mixin.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    if (userId == null) {
      return Scaffold(
        appBar: CustomGradientAppBar(title: Text('profile_screen.statistics'.tr())),
        body: Center(child: Text('common.pleaseLogin'.tr())),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => StatisticsViewModel(
        repo: context.read<SupabaseRepository>(),
        userId: userId,
      ),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    
    final vm = context.watch<StatisticsViewModel>();
    final currencyFmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Scaffold(
      appBar: _buildAppBar(),
      body: vm.isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : vm.error != null
              ? Center(child: Text('${'common.error'.tr()}: ${vm.error}'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Row (Total Spend & Bookings)
                      _SummaryRow(
                        totalSpend: vm.totalSpend,
                        count: vm.courtsBooked,
                        currencyFmt: currencyFmt,
                      ),
                      SizedBox(height: 24),
                      
                      // Filter Section
                      _FilterHeader(vm: vm),
                      SizedBox(height: 24),

                      // Chart Section
                      _ChartSection(
                        distribution: vm.getSportTypeDistribution(),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomGradientAppBar(
      title: Text('profile_screen.statistics'.tr(),
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
        color: AppColors.surface,
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
          Text(value, style: TextStyle(color: AppColors.textBlack, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Filter Header ───────────────────────────────────────────────────────────

class _FilterHeader extends StatelessWidget {
  final StatisticsViewModel vm;
const _FilterHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  vm.filterMode == FilterMode.all ? 'booking_history_screen.sectionAll'.tr() : 'profile_screen.statisticalFilter'.tr(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (vm.filterMode != FilterMode.all) ...[
                SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onTap: vm.setFilterAll,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              vm.filterLabel(context),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(color: AppColors.primary, fontSize: 12),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.close, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 8),
        StatisticsFilterRow(vm: vm),
      ],
    );
  }
}

// ─── Chart Section ───────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final Map<String, int> distribution;
const _ChartSection({required this.distribution});

  Color _getColorForSport(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'badminton':
        return AppColors.brandOrange; // Cam
      case 'football':
        return Colors.amber; // Vàng
      case 'pickleball':
        return Colors.green; // Xanh
      default:
        return Colors.lightBlue; // Mặc định
    }
  }

  String _getNameForSport(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'badminton':
        return 'checkout_screen.badminton'.tr();
      case 'football':
        return 'profile_screen.football'.tr();
      case 'pickleball':
        return 'profile_screen.pickleball'.tr();
      default:
        // if the type in the DB is unrecognized or "unknown", fallback to "Other"
        return sportType == 'unknown' ? 'profile_screen.otherSports'.tr() : sportType; 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'common.noData'.tr(),
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    int total = distribution.values.fold(0, (sum, val) => sum + val);

    final List<PieChartSectionData> pieSections = distribution.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _getColorForSport(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile_screen.pieChartTitle'.tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: pieSections,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Legends
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: distribution.keys.map((key) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForSport(key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getNameForSport(key),
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
