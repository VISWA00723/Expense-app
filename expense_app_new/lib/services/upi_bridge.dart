import 'package:flutter/services.dart';

class UpiBridge {
  static const platform = MethodChannel("expense_app_new/upi");

  static Future<String?> makePayment(String uri) async {
    try {
      final result = await platform.invokeMethod("startUPI", {"uri": uri});
      return result;
    } catch (e) {
      return null;
    }
  }
}
