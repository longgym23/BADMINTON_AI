import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_event.dart';
import 'package:badminton_ai/data/models/filter_criteria.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeFilterModal extends StatefulWidget {
  final FilterCriteria initialCriteria;

  const HomeFilterModal({super.key, required this.initialCriteria});

  @override
  State<HomeFilterModal> createState() => _HomeFilterModalState();
}

class _HomeFilterModalState extends State<HomeFilterModal> {
  late String? _selectedSport;
  late double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.initialCriteria.sportType;
    _maxPrice = widget.initialCriteria.maxPrice;
  }

  void _applyFilter() {
    // Bắn event áp dụng bộ lọc lên Bloc
    context.read<HomeFilterBloc>().add(
      FilterCriteriaApplied(sportType: _selectedSport, maxPrice: _maxPrice),
    );
    Navigator.pop(context);
  }

  void _clearFilter() {
    setState(() {
      _selectedSport = null;
      _maxPrice = null;
    });
    // Bắn event Reset về Bloc
    context.read<HomeFilterBloc>().add(FilterCriteriaReset());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc tìm kiếm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sport Type
          const Text('Loại Sân', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('Cầu lông', 'badminton'),
              _buildChoiceChip('Pickleball', 'pickleball'),
              _buildChoiceChip('Bóng đá', 'football'),
            ],
          ),
          const SizedBox(height: 20),

          // Price Range (Simplified)
          const Text(
            'Khoảng giá (Giờ)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _maxPrice ?? 500000,
            min: 50000,
            max: 500000,
            divisions: 9,
            activeColor: AppColors.primary,
            label: '${(_maxPrice ?? 500000).toInt() ~/ 1000}k',
            onChanged: (value) {
              setState(() {
                _maxPrice = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0đ', style: TextStyle(color: Colors.grey)),
              Text(
                _maxPrice != null
                    ? 'Dưới ${(_maxPrice!).toInt() ~/ 1000}k'
                    : 'Tất cả giá',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _clearFilter,
                  child: const Text('Xóa bộ lọc'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _applyFilter,
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedSport == value,
      selectedColor: AppColors.primary.withOpacity(0.2),
      onSelected: (bool selected) {
        setState(() {
          _selectedSport = selected ? value : null;
        });
      },
    );
  }
}
