import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DialogUtils {
  static Future<void> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) async {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(cancelText),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          // Bỏ qua title khi rỗng để tránh padding thừa phía trên
          title: title.isNotEmpty ? Text(title) : null,
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Material(color: Colors.transparent, child: content),
          ),
          actions: actions ?? [],
        );
      },
    );
  }

  static Future<void> showAlertDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Đóng',
    VoidCallback? onConfirm,
  }) async {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
