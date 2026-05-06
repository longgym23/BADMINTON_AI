import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_event.dart';
import 'package:badminton_ai/data/models/filter_criteria.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/custom_date_range_picker_dialog.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:flutter/cupertino.dart';
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
  late String _scheduleType;
  DateTimeRange? _dateRange;
  TimeOfDay? _timeStart;
  TimeOfDay? _timeEnd;
  String? _eventTimeFilter;
  late double _maxPrice;

  // ─── Instance getters thay vì static const ──────────────────────────────
  // Dùng getter để .tr() được gọi mỗi lần render → đúng ngôn ngữ hiện tại
  List<Map<String, dynamic>> get _sports => [
    {'label': 'Pickleball',                  'value': 'pickleball', 'icon': 'pickleball', 'color': Colors.orange},
    {'label': 'screens.badminton'.tr(),       'value': 'badminton',  'icon': 'caulong',    'color': Colors.blue},
    {'label': 'screens.football'.tr(),        'value': 'football',   'icon': 'soccer',     'color': Colors.green},
    {'label': 'Tennis',                       'value': 'tennis',     'icon': 'tennis',     'color': Colors.yellow[700]!},
  ];

  List<Map<String, String>> get _eventFilters => [
    {'label': 'screens.today'.tr(),           'value': 'today'},
    {'label': 'screens.tomorrow'.tr(),        'value': 'tomorrow'},
    {'label': 'screens.theLast3Days'.tr(),    'value': '3days'},
    {'label': 'screens.theLast1Week'.tr(),    'value': '1week'},
    {'label': 'screens.theLast2Weeks'.tr(),   'value': '2weeks'},
  ];

  List<String> get _keywords => [
    'screens.badmintonNearMe'.tr(),
    'screens.pickleballNearMe'.tr(),
    'screens.eventsNearMe'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.initialCriteria.sportType;
    _scheduleType = widget.initialCriteria.scheduleType ?? 'empty';
    _dateRange = widget.initialCriteria.dateRange;
    _timeStart = widget.initialCriteria.timeStart;
    _timeEnd = widget.initialCriteria.timeEnd;
    _eventTimeFilter = widget.initialCriteria.eventTimeFilter;
    _maxPrice = widget.initialCriteria.maxPrice ?? 500000.0;
  }

  void _applyFilter() {
    context.read<HomeFilterBloc>().add(FilterCriteriaApplied(
      sportType: _selectedSport,
      scheduleType: _scheduleType,
      dateRange: _dateRange,
      timeStart: _timeStart,
      timeEnd: _timeEnd,
      eventTimeFilter: _eventTimeFilter,
      maxPrice: _maxPrice,
    ));
    Navigator.pop(context);
  }

  void _clearFilter() {
    setState(() {
      _selectedSport = null;
      _scheduleType = 'empty';
      _dateRange = null;
      _timeStart = null;
      _timeEnd = null;
      _eventTimeFilter = null;
      _maxPrice = 500000.0;
    });
    context.read<HomeFilterBloc>().add(FilterCriteriaReset());
  }

  void _applyKeyword(String keyword) {
    setState(() {
      // So sánh với bản dịch hiện tại — luôn đúng dù đang dùng ngôn ngữ nào
      if (keyword == 'screens.badmintonNearMe'.tr()) {
        _selectedSport = 'badminton';
        _scheduleType  = 'empty';
      } else if (keyword == 'screens.pickleballNearMe'.tr()) {
        _selectedSport = 'pickleball';
        _scheduleType  = 'empty';
      } else if (keyword == 'screens.eventsNearMe'.tr()) {
        _scheduleType  = 'event';
        _selectedSport = null;
      }
      _maxPrice = 500000;
    });
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSportSection(),
                  const SizedBox(height: 24),
                  _buildScheduleTypeSection(),
                  const SizedBox(height: 16),
                  if (_scheduleType == 'empty') _buildEmptyCourtFilters()
                  else if (_scheduleType == 'event') _buildEventFilters(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  _buildKeywordSection(),
                ],
              ),
            ),
          ),
        ),
        _buildApplyButton(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomGradientAppBar(
      title: const Text('Tìm kiếm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
          onPressed: _clearFilter,
          tooltip: 'Làm mới bộ lọc',
        ),
      ],
    );
  }

  Widget _buildSportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Môn thể thao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedSport = null),
              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
              label: const Text('Tất cả', style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _sports.map((sport) => _buildSportChip(sport)).toList(),
        ),
      ],
    );
  }

  Widget _buildSportChip(Map<String, dynamic> sport) {
    final label = sport['label'] as String;
    final value = sport['value'] as String;
    final color = sport['color'] as Color;
    final iconKey = sport['icon'] as String;
    final isSelected = _selectedSport == value;

    Widget icon;
    switch (iconKey) {
      case 'pickleball':
        icon = Image(image: AssetImage('assets/images/pickleball.png'), color: Colors.grey);
        break;
      case 'caulong':
        icon = Image(image: AssetImage('assets/images/caulong.png'), color: Colors.grey);
        break;
      case 'soccer':
        icon = const Icon(Icons.sports_soccer, color: Colors.green);
        break;
      case 'tennis':
        icon = Icon(Icons.sports_tennis, color: Colors.yellow[700]!);
        break;
      default:
        icon = const Icon(Icons.sports);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedSport = isSelected ? null : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: _buildColoredIcon(icon, isSelected, color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredIcon(Widget icon, bool isSelected, Color color) {
    if (icon is Icon) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(isSelected ? color : Colors.grey, BlendMode.srcIn),
        child: icon,
      );
    } else if (icon is Image) {
      return Image(
        image: icon.image,
        color: isSelected ? color : Colors.grey,
        colorBlendMode: isSelected ? BlendMode.srcIn : BlendMode.dstIn,
      );
    }
    return icon;
  }

  Widget _buildScheduleTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Loại lịch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildScheduleBtn('Sân trống', 'empty')),
            const SizedBox(width: 8),
            Expanded(child: _buildScheduleBtn('Sự kiện', 'event')),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleBtn(String label, String value) {
    final isSelected = _scheduleType == value;
    return GestureDetector(
      onTap: () => setState(() => _scheduleType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBg : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCourtFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateField(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeField('Từ giờ', _timeStart, true)),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeField('Đến giờ', _timeEnd, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ngày đặt', style: TextStyle(fontSize: 13, color: Colors.black)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateRange == null
                        ? 'Chọn khoảng ngày'
                        : '${DateFormat('dd/MM', 'vi_VN').format(_dateRange!.start)} - ${DateFormat('dd/MM', 'vi_VN').format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TimeOfDay? time, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickCupertinoTime(isStart: isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text(time?.format(context) ?? '--:--', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _eventTimeFilter ?? '3days',
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          items: _eventFilters.map((f) => DropdownMenuItem(
            value: f['value'],
            child: Center(
              child: Text(f['label']!, style: const TextStyle(color: AppColors.primary, fontSize: 15)),
            ),
          )).toList(),
          onChanged: (val) => setState(() => _eventTimeFilter = val),
          isExpanded: true,
          dropdownColor: Colors.grey[50],
          style: const TextStyle(color: AppColors.primary),
          alignment: Alignment.center,
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Giá tiền (giờ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _maxPrice >= 500000 ? 'Tất cả giá' : 'Dưới ${NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(_maxPrice)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 10,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
          ),
          child: Slider(
            value: _maxPrice,
            min: 50000,
            max: 500000,
            divisions: 45,
            onChanged: (val) => setState(() => _maxPrice = val),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('50k', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            Text('500k', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildKeywordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Từ khoá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _keywords.map((kw) => ActionChip(
            label: Text(kw),
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.transparent),
            ),
            onPressed: () => _applyKeyword(kw),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: ElevatedButton(
        onPressed: _applyFilter,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Tìm kiếm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final result = await showCustomDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
    );

    if (result != null) {
      setState(() => _dateRange = result);
    }
  }

  Future<void> _pickCupertinoTime({required bool isStart}) async {
    TimeOfDay initialTime = (isStart ? _timeStart : _timeEnd) ?? const TimeOfDay(hour: 8, minute: 0);
    DateTime initialDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, initialTime.hour, initialTime.minute);

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) => Container(
        height: 250,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Hủy', style: TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Xong', style: TextStyle(color: AppColors.primary)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialDateTime,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    if (isStart) {
                      _timeStart = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                    } else {
                      _timeEnd = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }
}
