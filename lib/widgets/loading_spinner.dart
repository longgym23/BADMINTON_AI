import 'package:flutter/material.dart';


class LoadingSpinner extends StatelessWidget {
  final String message;
  const LoadingSpinner({Key? key, this.message = 'Đang tải...'}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // SỬA LỖI: Bỏ Container với constraints.expand()
    // Chỉ cần một Container màu mờ để che phủ
    return Container(
      // Màu nền đen mờ
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: 120, // Kích thước của hộp loading
          height: 120,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.9), // Nền xanh đậm
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.secondary), // Vòng quay màu vàng
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang tải...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none, // Bỏ gạch chân
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

