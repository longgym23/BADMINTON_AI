import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class AdminCreateEventScreen extends StatefulWidget {
  const AdminCreateEventScreen({super.key});

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventCodeCtrl = TextEditingController(text: '#');
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();
  final _sportTypeCtrl = TextEditingController(text: 'Cầu lông');
  final _levelCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController();
  String? _selectedCourtId;
  String? _selectedCourtName;

  late Future<List<CourtLocationModel>> _courtsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch courts once for the dropdown. Requires provider for SupabaseRepository or direct instantiaion.
    _courtsFuture = SupabaseRepository().getCourtLocationsStream().first;
  }

  @override
  void dispose() {
    _eventCodeCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _sportTypeCtrl.dispose();
    _levelCtrl.dispose();
    _priceCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCourtId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn Cơ sở sân!'), backgroundColor: Colors.red),
        );
        return;
      }

      final auth = context.read<AppAuthProvider>();
      final ownerId = auth.userId;
      if (ownerId == null) return;

      final newEvent = EventModel(
        id: '', // Sẽ để DB tạo ra UUID
        eventCode: _eventCodeCtrl.text,
        title: _titleCtrl.text,
        description: _descriptionCtrl.text,
        dateTime: DateTime.now().add(const Duration(days: 1)), // Demo next day
        startTime: _startTimeCtrl.text,
        endTime: _endTimeCtrl.text,
        courtArea: _selectedCourtName ?? 'Chưa rõ',
        sportType: _sportTypeCtrl.text,
        level: _levelCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        maxParticipants: int.tryParse(_maxParticipantsCtrl.text) ?? 10,
        currentParticipants: 0,
        courtId: _selectedCourtId!,
      );

      try {
        await context.read<SupabaseRepository>().createEvent(newEvent, ownerId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm sự kiện thành công!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Thêm sự kiện mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<CourtLocationModel>>(
                future: _courtsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 60,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Không có dữ liệu sân. Vui lòng thêm sân trước.');
                  }
                  final courts = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Chọn cơ sở sân (Venue)'),
                    value: _selectedCourtId,
                    items: courts.map((court) {
                      return DropdownMenuItem(
                        value: court.id,
                        child: Text(court.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCourtId = val;
                        _selectedCourtName = courts.firstWhere((c) => c.id == val).name;
                      });
                    },
                    validator: (v) => v == null ? 'Vui lòng chọn sân' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _eventCodeCtrl,
                decoration: const InputDecoration(labelText: 'Mã sự kiện (vd: #1234)'),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Tên sự kiện'),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _startTimeCtrl, decoration: const InputDecoration(labelText: 'Giờ bắt đầu (vd: 14h)'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _endTimeCtrl, decoration: const InputDecoration(labelText: 'Giờ kết thúc (vd: 18h)'))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sportTypeCtrl,
                decoration: const InputDecoration(labelText: 'Môn thể thao'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _levelCtrl,
                decoration: const InputDecoration(labelText: 'Trình độ (vd: 2.0 -> 3.0)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá vé (đ)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxParticipantsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số chỗ tối đa'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả thêm / Ghi chú'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                  ),
                  child: const Text('LƯU SỰ KIỆN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
