import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// Returns a user-friendly error message. Avoids leaking technical details.
/// When [context] or [localizations] is provided, uses localization for known error keys.
String getUserFriendlyMessage(
  Object error, [
  String fallback = 'An unexpected error occurred',
  BuildContext? context,
  AppLocalizations? localizations,
]) {
  final loc =
      localizations ?? (context != null ? AppLocalizations.of(context) : null);

  if (error is TripShipException) {
    if (loc != null && error.messageKey != null) {
      try {
        final msg = _resolveErrorKey(error.messageKey!, loc);
        if (msg != null) return msg;
      } catch (_) {
        // Fallback to userMessage if resolution fails
      }
    }
    return error.userMessage;
  }

  // Handle Exception with known codes (e.g. from services or Supabase)
  if (error is Exception) {
    final msg = error.toString();
    if (loc != null) {
      if (msg.contains('ACCOUNT_SUSPENDED')) return loc.accountSuspended;
      if (msg.contains('CREDENTIALS_EXPIRED')) return loc.credentialsExpired;
      if (msg.contains('CANNOT_CANCEL_ACTIVE_BOOKINGS') ||
          msg.contains('Cannot cancel trip')) {
        return loc.cannotCancelTripActiveBookings;
      }
      if (msg.contains('FETCH_TRIPS_ERROR')) {
        return loc.errorFetchingTrips;
      }
      if (msg.contains('Invalid login credentials')) {
        return loc.invalidCredentialsMessage;
      }
      if (msg.contains('Email not confirmed')) return loc.emailNotConfirmed;
      if (msg.contains('User already registered')) {
        return loc.emailAlreadyRegistered;
      }
      if (_isNetworkError(msg)) return loc.networkError;
    }
  }

  if (error is AuthException) {
    if (loc != null) {
      if (error.message.contains('Invalid login credentials')) {
        return loc.invalidCredentialsMessage;
      }
      if (error.message.contains('Email not confirmed')) {
        return loc.emailNotConfirmed;
      }
      if (error.message.contains('User already registered')) {
        return loc.emailAlreadyRegistered;
      }
      return error.message;
    }
    return error.message;
  }

  return fallback;
}

bool _isNetworkError(String msg) {
  final lower = msg.toLowerCase();
  return lower.contains('socketexception') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('timeout') ||
      lower.contains('connection timed out') ||
      lower.contains('network is unreachable') ||
      lower.contains('failed host lookup') ||
      lower.contains('no internet');
}

String? _resolveErrorKey(String key, AppLocalizations loc) {
  switch (key) {
    case 'request_already_sent':
      return loc.requestAlreadySent;
    case 'booking_request_exists':
      return loc.bookingRequestExists;
    case 'cannot_cancel_goods_handed_over':
      return loc.cannotCancelGoodsHandedOver;
    case 'cannot_cancel_payment_confirmed':
      return loc.cannotCancelPaymentConfirmed;
    case 'cannot_cancel_trip_active_bookings':
      return loc.cannotCancelTripActiveBookings;
    case 'invalid_otp':
    case 'invalid_code':
      return loc.invalidCode;
    case 'active_engagement_exists':
      return loc.cannotBlockActiveEngagement;
    default:
      return null;
  }
}
