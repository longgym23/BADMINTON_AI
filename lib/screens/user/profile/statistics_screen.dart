import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:badminton_ai/l10n/generated/app_localizations.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/viewmodels/statistics_viewmodel.dart';
import 'package:badminton_ai/screens/user/profile/components/statistics_filter_row.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AppAuthProvider>().userModel?.id;

    if (userId == null) {
      return Scaffold(
        appBar: CustomGradientAppBar(title: Text(AppLocalizations.of(context).statistics)),
        body: Center(child: Text(AppLocalizations.of(context).pleaseLogin)),
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
    final l = AppLocalizations.of(context);
    final vm = context.watch<StatisticsViewModel>();
    final currencyFmt = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return Scaffold(
      appBar: _buildAppBar(l),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : vm.error != null
              ? Center(child: Text('${l.error}: ${vm.error}'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Row (Total Spend & Bookings)
                      _SummaryRow(
                        totalSpend: vm.totalSpend,
                        count: vm.courtsBooked,
                        currencyFmt: currencyFmt,
                        l: l,
                      ),
                      const SizedBox(height: 24),
                      
                      // Filter Section
                      _FilterHeader(vm: vm, l: l),
                      const SizedBox(height: 24),

                      // Chart Section
                      _ChartSection(
                        distribution: vm.getSportTypeDistribution(),
                        l: l,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l) {
    return CustomGradientAppBar(
      title: Text(l.statistics,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      centerTitle: true,
      elevation: 0,
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

// ─── Filter Header ───────────────────────────────────────────────────────────

class _FilterHeader extends StatelessWidget {
  final StatisticsViewModel vm;
  final AppLocalizations l;

  const _FilterHeader({required this.vm, required this.l});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          vm.filterMode == FilterMode.all ? l.sectionAll : l.statisticalFilter,
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
                  Text(vm.filterLabel(context, l.viewAll, l.filterByDateRange, l.filterByMonth, l.filterByYear), 
                        style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
        const Spacer(),
        StatisticsFilterRow(vm: vm, l: l),
      ],
    );
  }
}

// ─── Chart Section ───────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final Map<String, int> distribution;
  final AppLocalizations l;

  const _ChartSection({required this.distribution, required this.l});

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

  String _getNameForSport(String sportType, AppLocalizations l) {
    switch (sportType.toLowerCase()) {
      case 'badminton':
        return l.badminton;
      case 'football':
        return l.football;
      case 'pickleball':
        return l.pickleball;
      default:
        // if the type in the DB is unrecognized or "unknown", fallback to "Other"
        return sportType == 'unknown' ? l.otherSports : sportType; 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            l.noData,
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
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pieChartTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textBlack),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
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
                  const SizedBox(width: 8),
                  Text(
                    _getNameForSport(key, l),
                    style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.w500),
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
