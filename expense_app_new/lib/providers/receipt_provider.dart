import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to securely pass receipt text between screens without using navigation arguments.
/// This ensures the data is not persisted in the navigation history.
final receiptTextProvider = StateProvider<String?>((ref) => null);
