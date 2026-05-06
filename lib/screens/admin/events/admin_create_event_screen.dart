import 'package:easy_localization/easy_localization.dart';
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
  final _sportTypeCtrl = TextEditingController(text: 'screens.badminton'.tr());
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
          'screens.pleaseSelectYardFacility'.tr(),
          type: ToastType.error,
        );
        return;
      }
      if (_selectedCourtNumber == null) {
        AppToast.show(
          context,
          'screens.pleaseSelectTheEventVenue'.tr(),
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
          'screens.moreSuccessfulEvents'.tr(),
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
      appBar: CustomGradientAppBar(title: Text('screens.addNewEvent'.tr())),
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
                      return Text('screens.noYardDataAvailablePlease'.tr());
                    }
                    final courts = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'screens.chooseAYardFacilityVenue'.tr(),
                        border: const OutlineInputBorder(),
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
                      validator: (v) =>
                          v == null ? 'screens.pleaseSelectACourse'.tr() : null,
                    );
                  },
                ),
                if (_selectedCourt != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'screens.selectTheVenueSubCourse'.tr(),
                      border: const OutlineInputBorder(),
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
                        v == null ? 'screens.pleaseSelectTheVenue'.tr() : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _eventCodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'screens.eventCodeEG1234'.tr(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'screens.pleaseEnter'.tr() : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'screens.eventName'.tr(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'screens.pleaseEnter'.tr() : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickEventDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'screens.eventDate'.tr(),
                      border: const OutlineInputBorder(),
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
                            ? 'screens.pleaseSelectATime'.tr()
                            : null,
                        onTap: () => _showTimePickerIOS(_startTimeCtrl),
                        decoration: InputDecoration(
                          labelText: 'screens.startTimeEg1400'.tr(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeCtrl,
                        readOnly: true,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'screens.pleaseSelectATime'.tr()
                            : null,
                        onTap: () => _showTimePickerIOS(_endTimeCtrl),
                        decoration: InputDecoration(
                          labelText: 'screens.endTimeEg1800'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sportTypeCtrl.text.isEmpty
                      ? 'screens.badminton'.tr()
                      : _sportTypeCtrl.text,
                  decoration: InputDecoration(labelText: 'screens.sports'.tr()),
                  items: [
                    DropdownMenuItem(
                      value: 'screens.badminton'.tr(),
                      child: Text('screens.badminton'.tr()),
                    ),
                    const DropdownMenuItem(
                      value: 'Pickleball',
                      child: Text('Pickleball'),
                    ),
                    DropdownMenuItem(
                      value: 'screens.football'.tr(),
                      child: Text('screens.football'.tr()),
                    ),
                    const DropdownMenuItem(
                      value: 'Tennis',
                      child: Text('Tennis'),
                    ),
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
                  decoration: InputDecoration(
                    labelText: 'screens.levelEg2030'.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'screens.ticketPriceD'.tr(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxParticipantsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'screens.maximumNumberOfSeats'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'screens.additionalDescriptionNotes'.tr(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveEvent,
                    style: ElevatedButton.styleFrom(),
                    child: Text(
                      'screens.sAVEEVENT'.tr(),
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
