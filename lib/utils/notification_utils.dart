import 'package:flutter/material.dart';
import 'dart:async';

class NotificationUtils {
  static OverlayEntry? _overlayEntry;

  /// Hiển thị thông báo "Tính năng sắp ra mắt" trượt từ phải sang trên AppBar
  static void showComingSoon(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _ComingSoonToast(
        onDismissed: () {
          if (_overlayEntry != null) {
            _overlayEntry?.remove();
            _overlayEntry = null;
          }
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }
}

class _ComingSoonToast extends StatefulWidget {
  final VoidCallback onDismissed;

  const _ComingSoonToast({required this.onDismissed});

  @override
  State<_ComingSoonToast> createState() => _ComingSoonToastState();
}

class _ComingSoonToastState extends State<_ComingSoonToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Bắt đầu từ bên phải màn hình
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    // Tự động dismiss sau 2.5 giây
    _timer = Timer(const Duration(milliseconds: 2500), _dismiss);
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismissed();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Để nằm trên AppBar và dưới Status Bar một chút
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
    top: topPadding + 10,
    left: 16,
    right: 16,
    child: Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Align(
          alignment: Alignment.centerRight,   // hoặc Alignment.center
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,  // 85% chiều rộng màn hình
            child: _buildToastContent(),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildToastContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Màu xanh nhạt (light green) như mẫu
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.black87,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Thông báo',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tính năng sắp ra mắt',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _timer?.cancel();
              _dismiss();
            },
            child: const Icon(
              Icons.close,
              color: Colors.black54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
