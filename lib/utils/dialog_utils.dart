import 'package:flutter/material.dart';

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
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(cancelText, style: const TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child: Text(
                confirmText,
                style: TextStyle(color: isDestructive ? Colors.red : Colors.blue),
              ),
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
    List<TextButton>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Material(
              color: Colors.transparent,
              child: content,
            ),
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
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (onConfirm != null) onConfirm();
              },
              child: Text(confirmText, style: const TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
