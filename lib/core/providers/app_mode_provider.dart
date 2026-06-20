import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';

/// Notifier that manages app mode (Client/Traveler) and resets on logout
class AppModeNotifier extends StateNotifier<bool> {
  final Ref _ref;
  
  AppModeNotifier(this._ref) : super(true) {
    // Listen to auth state changes and reset to client mode on logout
    _ref.listen(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.value?.session != null;
      final isLoggedIn = next.value?.session != null;
      
      // If user just logged out, reset to client mode
      if (wasLoggedIn && !isLoggedIn) {
        state = true;
      }
    });
  }
  
  void setMode(bool isClientMode) {
    state = isClientMode;
  }
}

// True = Client Mode (Sender), False = Driver Mode
final isClientModeProvider = StateNotifierProvider<AppModeNotifier, bool>((ref) {
  return AppModeNotifier(ref);
});
