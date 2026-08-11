import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../widgets/court_card_item.dart';

/// Modularized Court Selection Page (<80 lines) built on V-Design-System.
class CourtSelectionPage extends StatefulWidget {
  const CourtSelectionPage({super.key});

  @override
  State<CourtSelectionPage> createState() => _CourtSelectionPageState();
}

class _CourtSelectionPageState extends State<CourtSelectionPage> {
  final List<Map<String, dynamic>> _courts = [
    {'id': 'c1', 'name': 'Sân Cầu Lông Số 1', 'price': 80000.0, 'available': true},
    {'id': 'c2', 'name': 'Sân Cầu Lông Số 2', 'price': 80000.0, 'available': true},
    {'id': 'c3', 'name': 'Sân VIP Số 3', 'price': 120000.0, 'available': false},
    {'id': 'c4', 'name': 'Sân Cầu Lông Số 4', 'price': 80000.0, 'available': true},
  ];

  @override
  Widget build(BuildContext context) {
    return VPage(
      title: 'Chọn Sân Cầu Lông',
      body: ListView.separated(
        itemCount: _courts.length,
        separatorBuilder: (_, __) => const SizedBox(height: VSpacing.md),
        itemBuilder: (context, index) {
          final court = _courts[index];
          return CourtCardItem(
            courtName: court['name'],
            pricePerHour: court['price'],
            isAvailable: court['available'],
            onSelect: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã chọn ${court['name']}')),
              );
            },
          );
        },
      ),
    );
  }
}
