import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_event.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onQrScan;
  final VoidCallback onFilterTap;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onQrScan,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) {
                // Bắn event SearchQueryChanged lên Bloc
                context.read<HomeFilterBloc>().add(SearchQueryChanged(value));
              },
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sân, địa điểm...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.grey),
            onPressed: onQrScan,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFilterTap,
            child: const Image(
              image: AssetImage('assets/images/setting.png'),
              width: 24,
              height: 24,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
