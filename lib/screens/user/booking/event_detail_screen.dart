import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/screens/user/booking/event_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final CourtLocationModel court;

  const EventDetailScreen({super.key, required this.event, required this.court});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int quantity = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final Color bgColor = AppColors.background;
  final Color blockColor = Colors.white;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      final available = widget.event.maxParticipants - widget.event.currentParticipants;
      if (quantity < available) {
        quantity++;
      }
    });
  }

  void _decrement() {
    if (quantity > 0) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.event.maxParticipants - widget.event.currentParticipants;
    final totalPrice = quantity * widget.event.price;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text(
          'Đặt lịch sự kiện',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Block 1: Thông tin sân
            _buildBlock(
              title: "Thông tin sân",
              icon: Icons.map,
              children: [
                _buildRichText('Tên sân: ', widget.court.name),
                const SizedBox(height: 8),
                _buildRichText('Địa chỉ: ', widget.court.address),
              ],
            ),
            const SizedBox(height: 16),

            // Block 2: Thông tin sự kiện
            _buildBlock(
              title: "Thông tin sự kiện",
              icon: Icons.event_note,
              children: [
                _buildRichText('Mã sự kiện: ', widget.event.eventCode),
                const SizedBox(height: 8),
                _buildRichText('Tên sự kiện: ', widget.event.title),
                const SizedBox(height: 8),
                const Text('Sân & Thời gian:', style: TextStyle(color: AppColors.textBlack)),
                const SizedBox(height: 4),
                Text(
                  '  - ${widget.event.courtArea}: ${widget.event.startTime} - ${widget.event.endTime}',
                  style: const TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRichText(
                  'Ngày: ',
                  DateFormat('dd/MM/yyyy').format(widget.event.dateTime),
                ),
                const SizedBox(height: 8),
                _buildRichText('Giá vé: ', '${(widget.event.price / 1000).toStringAsFixed(0)}k/Người'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Trình độ: ', style: TextStyle(color: AppColors.textBlack)),
                    Container(
                      padding: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            child: Icon(Icons.sports_tennis, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.event.sportType,
                            style: const TextStyle(color: AppColors.textBlack, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.event.level,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRichText('Số lượng vé còn lại: ', '$available'),
              ],
            ),
            const SizedBox(height: 16),

            // Block 3: Ghi chú
            _buildBlock(
              title: null,
              icon: null,
              children: [
                const Text(
                  'Ghi chú:',
                  style: TextStyle(color: AppColors.textBlack, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Block 4: Số lượng vé muốn đặt & Tổng tiền
            _buildBlock(
              title: null,
              icon: null,
              children: [
                const Text(
                  'Số lượng vé muốn đặt',
                  style: TextStyle(color: AppColors.textBlack, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Counter
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _decrement,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove, color: Colors.white),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _increment,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Total Price
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Tổng tiền: ',
                            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                          ),
                          TextSpan(
                            text: formatter.format(totalPrice),
                            style: const TextStyle(
                              color: AppColors.brandOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Thêm dịch vụ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Block 5: Contact info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tên khách hàng',
                  style: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () => _nameController.clear(),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Số điện thoại:',
                  style: TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Nhập số điện thoại',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () => _phoneController.clear(),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Spacing for bottom button
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        color: bgColor,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: quantity > 0 && _nameController.text.isNotEmpty && _phoneController.text.isNotEmpty
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventCheckoutScreen(
                          event: widget.event,
                          quantity: quantity,
                          totalPrice: totalPrice.toInt(),
                          customerName: _nameController.text,
                          customerPhone: _phoneController.text,
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text(
              'ĐĂNG KÝ NGAY',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock({String? title, IconData? icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && icon != null) ...[
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderColor),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildRichText(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: label, style: const TextStyle(color: AppColors.textGrey)),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.textBlack, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
