import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smsServiceProvider = Provider((ref) => SmsService());

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<void> initialize() async {
    // Just request permissions here
    await Permission.sms.request();
  }

  // Method to read past SMS
  Future<List<SmsMessage>> getBankSms() async {
    var permission = await Permission.sms.status;
    if (permission.isDenied) {
      await Permission.sms.request();
    }

    if (await Permission.sms.isGranted) {
      List<SmsMessage> messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 50, // Limit to recent 50 messages
      );

      // Filter for bank-like messages
      return messages.where((msg) {
        final body = (msg.body ?? '').toLowerCase();
        return body.contains('debited') || 
               body.contains('spent') || 
               body.contains('txn') ||
               body.contains('acct');
      }).toList();
    }
    return [];
  }
}
