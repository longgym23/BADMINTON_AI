import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/auth_provider.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

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
  CourtLocationModel? _selectedCourt;
  int? _selectedCourtNumber;
  DateTime _selectedEventDate = DateTime.now().add(const Duration(days: 1));

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
        AppToast.show(
          context,
          'Vui lòng chọn Cơ sở sân!',
          type: ToastType.error,
        );
        return;
      }
      if (_selectedCourtNumber == null) {
        AppToast.show(
          context,
          'Vui lòng chọn sân tổ chức sự kiện!',
          type: ToastType.error,
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
        dateTime: DateTime(
          _selectedEventDate.year,
          _selectedEventDate.month,
          _selectedEventDate.day,
        ),
        startTime: _startTimeCtrl.text,
        endTime: _endTimeCtrl.text,
        courtArea: 'Sân $_selectedCourtNumber',
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
        AppToast.show(
          context,
          'Thêm sự kiện thành công!',
          type: ToastType.success,
        );
        Navigator.pop(context);
      } catch (e) {
        if (!context.mounted) return;
        AppToast.show(context, 'Lỗi khi thêm: $e', type: ToastType.error);
      }
    }
  }

  void _showTimePickerIOS(TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Xong',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      controller.text =
                          '${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate.isBefore(firstDay)
          ? firstDay
          : _selectedEventDate,
      firstDate: firstDay,
      lastDate: firstDay.add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() {
      _selectedEventDate = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(title: const Text('Thêm sự kiện mới')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const Text(
                        'Không có dữ liệu sân. Vui lòng thêm sân trước.',
                      );
                    }
                    final courts = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Chọn cơ sở sân (Venue)',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCourtId,
                      isExpanded: true,
                      items: courts.map((court) {
                        return DropdownMenuItem(
                          value: court.id,
                          child: Text(
                            court.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final selected = courts.firstWhere((c) => c.id == val);
                        setState(() {
                          _selectedCourtId = val;
                          _selectedCourt = selected;
                          _selectedCourtNumber = selected.totalCourts > 0
                              ? 1
                              : null;
                        });
                      },
                      validator: (v) => v == null ? 'Vui lòng chọn sân' : null,
                    );
                  },
                ),
                if (_selectedCourt != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Chọn sân tổ chức (Sân con)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCourtNumber,
                    isExpanded: true,
                    items: List.generate(_selectedCourt!.totalCourts, (index) {
                      final number = index + 1;
                      return DropdownMenuItem(
                        value: number,
                        child: Text('Sân $number'),
                      );
                    }),
                    onChanged: (val) =>
                        setState(() => _selectedCourtNumber = val),
                    validator: (v) =>
                        v == null ? 'Vui lòng chọn sân tổ chức' : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _eventCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mã sự kiện (vd: #1234)',
                  ),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tên sự kiện'),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickEventDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày diễn ra',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedEventDate),
                        ),
                        const Icon(Icons.calendar_month),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeCtrl,
                        readOnly: true,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng chọn giờ'
                            : null,
                        onTap: () => _showTimePickerIOS(_startTimeCtrl),
                        decoration: const InputDecoration(
                          labelText: 'Giờ bắt đầu (vd: 14:00)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeCtrl,
                        readOnly: true,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng chọn giờ'
                            : null,
                        onTap: () => _showTimePickerIOS(_endTimeCtrl),
                        decoration: const InputDecoration(
                          labelText: 'Giờ k.thúc (vd: 18:00)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sportTypeCtrl.text.isEmpty
                      ? 'Cầu lông'
                      : _sportTypeCtrl.text,
                  decoration: const InputDecoration(labelText: 'Môn thể thao'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Cầu lông',
                      child: Text('Cầu lông'),
                    ),
                    DropdownMenuItem(
                      value: 'Pickleball',
                      child: Text('Pickleball'),
                    ),
                    DropdownMenuItem(value: 'Bóng đá', child: Text('Bóng đá')),
                    DropdownMenuItem(value: 'Tennis', child: Text('Tennis')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sportTypeCtrl.text = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _levelCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Trình độ (vd: 2.0 -> 3.0)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá vé (đ)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxParticipantsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số chỗ tối đa',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả thêm / Ghi chú',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(),
                    child: const Text(
                      'LƯU SỰ KIỆN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
