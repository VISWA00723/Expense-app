import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/services/session_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

// Check if user has a saved session
final hasSessionProvider = FutureProvider<bool>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.hasSession();
});

// Get saved user ID from session
final savedUserIdProvider = Provider<int?>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getUserId();
});

// Get saved user email from session
final savedUserEmailProvider = Provider<String?>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getUserEmail();
});

// Get saved user name from session
final savedUserNameProvider = Provider<String?>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getUserName();
});
