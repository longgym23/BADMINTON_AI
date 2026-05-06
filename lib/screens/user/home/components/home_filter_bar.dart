import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeFilterBar extends StatelessWidget {
  const HomeFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe tiêu chí lọc hiện tại từ Bloc
    final currentSport = context.select(
      (HomeFilterBloc bloc) => bloc.state.filterCriteria.sportType,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(context, 'screens.badminton'.tr(), 'badminton', currentSport),
          SizedBox(width: 8),
          _buildFilterChip(context, 'Pickleball', 'pickleball', currentSport),
          SizedBox(width: 8),
          _buildFilterChip(context, 'screens.football'.tr(), 'football', currentSport),
          SizedBox(width: 8),
          _buildFilterChip(context, 'Tennis', 'tennis', currentSport),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    String? currentSport,
  ) {
    final isSelected = currentSport == value;
    return GestureDetector(
      onTap: () {
        // Bắn Event thay đổi hoặc huỷ lọc sport
        context.read<HomeFilterBloc>().add(
          SportFilterToggled(isSelected ? null : value),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.grey[500]!) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
