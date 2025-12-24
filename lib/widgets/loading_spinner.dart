import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final String message;
  const LoadingSpinner({Key? key, this.message = 'Đang tải...'})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // SỬA LỖI: Sử dụng Scaffold để tránh overflow và đảm bảo layout đúng
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.65),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 200, // Giới hạn chiều rộng tối đa
            minWidth: 120, // Chiều rộng tối thiểu
          ),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.9), // Nền xanh đậm
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0, // Giảm padding để tránh overflow
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // Quan trọng: giữ kích thước tối thiểu
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.secondary,
                  ), // Màu vàng
                ),
              ),
              const SizedBox(height: 10), // Giảm khoảng cách
              Flexible(
                child: Text(
                  message, // Sử dụng message parameter
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13, // Giảm font size một chút
                    decoration: TextDecoration.none, // Bỏ gạch chân
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
