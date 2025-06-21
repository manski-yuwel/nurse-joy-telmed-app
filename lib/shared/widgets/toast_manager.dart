import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';

class ToastManager {
  /// Shows a toast using Fluttertoast (global native toast)
  static void showToast({
    required String title,
    required String type,
    required Map<String, dynamic> body,
    VoidCallback? onTap, // Not usable with fluttertoast
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast? toastLength = Toast.LENGTH_SHORT,
  }) {
    Fluttertoast.cancel(); // Cancel any existing toast

    Fluttertoast.showToast(
      msg: title,
      toastLength: toastLength,
    );

    // Optionally log or trigger additional callbacks here
    // You cannot directly attach an onTap to fluttertoast
    debugPrint("Toast shown: $title");
  }

  /// Determine toast color based on type
  static Color _getBackgroundColor(String type) {
    switch (type) {
      case 'error':
        return Colors.red.shade700;
      case 'success':
        return Colors.green.shade700;
      case 'warning':
        return Colors.orange.shade800;
      case 'info':
      case 'appointment':
      case 'message':
      default:
        return Colors.blueGrey.shade900;
    }
  }
}
