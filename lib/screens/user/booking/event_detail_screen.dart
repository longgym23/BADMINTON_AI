import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/data/models/court_location_model.dart';
import 'package:badminton_ai/data/models/event_model.dart';
import 'package:badminton_ai/screens/user/booking/event_checkout_screen.dart';
import 'package:badminton_ai/utils/notification_utils.dart';
import 'package:badminton_ai/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final CourtLocationModel court;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.court,
  });

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
    if (!widget.event.isBookable) return;
    setState(() {
      final available = widget.event.availableParticipants;
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
    final available = widget.event.availableParticipants;
    final canBook = widget.event.isBookable;
    final totalPrice = quantity * widget.event.price;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'screens.d'.tr());

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('screens.scheduleAnEvent'.tr(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Block 1: Thông tin sân
            _buildBlock(
              title: 'screens.yardInformation'.tr(),
              icon: Icons.map,
              children: [
                _buildRichText('screens.stadiumName'.tr(), widget.court.name),
                SizedBox(height: 8),
                _buildRichText('screens.address'.tr(), widget.court.address),
              ],
            ),
            SizedBox(height: 16),

            // Block 2: Thông tin sự kiện
            _buildBlock(
              title: 'screens.eventInformation'.tr(),
              icon: Icons.event_note,
              children: [
                if (!canBook) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.event.isEnded
                          ? 'screens.theEventHasEndedNoMoreT'.tr()
                          : 'screens.theEventIsSoldOut'.tr(),
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
                _buildRichText('screens.eventCode'.tr(), widget.event.eventCode),
                SizedBox(height: 8),
                _buildRichText('screens.eventName2'.tr(), widget.event.title),
                SizedBox(height: 8),
                Text('screens.pitchTime'.tr(),
                  style: TextStyle(color: AppColors.textBlack),
                ),
                SizedBox(height: 4),
                Text(
                  '  - ${widget.event.courtArea}: ${widget.event.startTime} - ${widget.event.endTime}',
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildRichText(
                  'screens.day'.tr(),
                  DateFormat('dd/MM/yyyy').format(widget.event.dateTime),
                ),
                SizedBox(height: 8),
                _buildRichText(
                  'screens.ticketPrice'.tr(),
                  '${(widget.event.price / 1000).toStringAsFixed(0)}k/Người',
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('screens.level'.tr(),
                      style: TextStyle(color: AppColors.textBlack),
                    ),
                    Container(
                      padding: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            child: Icon(
                              Icons.sports_tennis,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            widget.event.sportType,
                            style: TextStyle(
                              color: AppColors.textBlack,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.event.level,
                              style: TextStyle(
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
                SizedBox(height: 8),
                _buildRichText('screens.numberOfRemainingTickets'.tr(), '$available'),
              ],
            ),
            SizedBox(height: 16),

            // Block 3: Ghi chú
            _buildBlock(
              title: null,
              icon: null,
              children: [
                Text('screens.note1'.tr(),
                  style: TextStyle(color: AppColors.textBlack, fontSize: 15),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Block 4: Số lượng vé muốn đặt & Tổng tiền
            _buildBlock(
              title: null,
              icon: null,
              children: [
                Text('screens.numberOfTicketsYouWantTo'.tr(),
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
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
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '$quantity',
                            style: TextStyle(
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
                            child: Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Total Price
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'screens.totalAmount2'.tr(),
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: formatter.format(totalPrice),
                            style: TextStyle(
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
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => NotificationUtils.showComingSoon(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('screens.addServices'.tr()),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Block 5: Contact info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('screens.customerName'.tr(),
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'screens.enterAName'.tr(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () => _nameController.clear(),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text('screens.phoneNumber'.tr(),
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'screens.enterPhoneNumber'.tr(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, color: Colors.grey),
                      onPressed: () => _phoneController.clear(),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 100), // Spacing for bottom button
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.all(16),
        color: bgColor,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed:
                canBook &&
                    quantity > 0 &&
                    _nameController.text.isNotEmpty &&
                    _phoneController.text.isNotEmpty
                ? () {
                    if (!widget.event.isBookable) {
                      AppToast.show(
                        context,
                        'screens.theEventHasExpiredOrIsSo'.tr(),
                        type: ToastType.error,
                      );
                      return;
                    }
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
            child: Text('screens.rEGISTERNOW'.tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock({
    String? title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && icon != null) ...[
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(height: 1, color: AppColors.borderColor),
            SizedBox(height: 12),
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
          TextSpan(
            text: label,
            style: TextStyle(color: AppColors.textGrey),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppColors.textBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
