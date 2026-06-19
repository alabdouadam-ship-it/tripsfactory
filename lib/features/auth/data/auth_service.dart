import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/features/profile/data/profile_service.dart';
import 'package:tripship/core/config/app_constants.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client.auth);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProfileProvider = FutureProvider<Profile?>((ref) async {
  // Only rebuild this provider when the user ID changes.
  // This prevents unnecessary DB fetches when Supabase fires token refreshes.
  final userId = ref.watch(
    authStateProvider.select((state) => state.value?.session?.user.id),
  );
  if (userId == null) return null;

  // We use profileServiceProvider to fetch the profile
  final profileService = ref.read(profileServiceProvider);
  return await profileService.getProfile(userId);
});

class AuthService {
  final GoTrueClient _auth;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;

  // Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      // Tell Supabase to redirect the email-confirmation link back into the
      // mobile app via our custom scheme instead of the project's web Site URL.
      emailRedirectTo: AppConstants.authCallbackLogin,
    );
  }

  // Sign In with Email and Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  // Check if user exists via RPC
  Future<bool> checkUserExists(String email) async {
    try {
      final response = await Supabase.instance.client.rpc(
        AppConstants.rpcCheckUserExists,
        params: {'email_input': email},
      );
      return response as bool;
    } on PostgrestException catch (e) {
      // Only suppress if the RPC function doesn't exist (42883 = undefined function)
      if (e.code == '42883') return false;
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.resetPasswordForEmail(
      email,
      redirectTo: AppConstants.authCallbackReset,
    );
  }

  // Sign In with Google
  Future<void> signInWithGoogle() async {
    // Requires flutter/foundation.dart for kIsWeb if we were to support web
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConstants.authCallbackLogin,
    );
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Sign In with Phone (OTP)
  Future<void> signInWithOtp(String phone, {Map<String, dynamic>? data}) async {
    await _auth.signInWithOtp(phone: phone, shouldCreateUser: true, data: data);
  }

  // Verify OTP
  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }
}
