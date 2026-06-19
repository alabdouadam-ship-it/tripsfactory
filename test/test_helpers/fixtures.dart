import 'package:tripship/features/bookings/data/booking_model.dart';
import 'package:tripship/features/chat/data/chat_model.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/core/enums/app_enums.dart';

import 'booking_fixture.dart';

// ─── Profile fixtures (trust-critical) ─────────────────────────────────────

class ProfileFixture {
  static Profile verifiedTravelerValidLicense() {
    return Profile(
      id: 'profile-verified-1',
      fullName: 'Verified Driver',
      travelerStatus: 'approved',
      identityDocUrl: 'https://example.com/id.jpg',
      licenseExpiresAt: DateTime(2026, 12, 31),
      travelerRatingAvg: 4.8,
      travelerRatingCount: 42,
      isDriver: true,
    );
  }

  static Profile verifiedTravelerExpiredLicense() {
    return Profile(
      id: 'profile-expired-1',
      fullName: 'Expired License Driver',
      travelerStatus: 'approved',
      identityDocUrl: 'https://example.com/id.jpg',
      licenseExpiresAt: DateTime(2020, 1, 1),
      travelerRatingAvg: 4.5,
      travelerRatingCount: 10,
      isDriver: true,
    );
  }

  static Profile unverifiedTraveler() {
    return Profile(
      id: 'profile-unverified-1',
      fullName: 'Unverified Driver',
      travelerStatus: 'none',
      identityDocUrl: null,
      licenseExpiresAt: null,
      isDriver: false,
    );
  }

  static Profile requesterHighRating() {
    return Profile(
      id: 'profile-requester-1',
      fullName: 'Trusted Requester',
      travelerStatus: 'none',
      clientRatingAvg: 4.9,
      clientRatingCount: 100,
    );
  }
}

// ─── Trip fixtures ─────────────────────────────────────────────────────────

Trip tripFixtureWithDriver(Profile? driver) {
  return Trip(
    id: 'trip-trust-1',
    driverId: driver?.id ?? 'driver-1',
    originLocationId: 'o1',
    destLocationId: 'd1',
    departureTime: DateTime(2025, 2, 1, 10, 0),
    status: TripStatus.booked,
    createdAt: DateTime(2025, 1, 1),
    driver: driver,
  );
}

// ─── Booking fixtures (re-export + trust-specific) ──────────────────────────

Booking rejectedBooking() {
  return BookingFixture.pending().copyWith(status: BookingStatus.rejected);
}

Booking cancelledBooking() {
  return BookingFixture.pending().copyWith(status: BookingStatus.cancelled);
}

// ─── Message fixtures ─────────────────────────────────────────────────────

class MessageFixture {
  static ChatMessage normalMessage({
    String id = 'msg-1',
    String content = 'Hello',
    bool isMe = false,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id,
      bookingId: 'b1',
      senderId: isMe ? 'me' : 'other',
      content: content,
      createdAt: createdAt ?? DateTime(2025, 1, 15, 12, 0),
      type: 'text',
      isMe: isMe,
      isRead: false,
    );
  }

  static ChatMessage systemMessage({
    String id = 'msg-sys-1',
    String content = 'Booking was accepted.',
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id,
      bookingId: 'b1',
      senderId: 'system',
      content: content,
      createdAt: createdAt ?? DateTime(2025, 1, 15, 11, 0),
      type: 'system',
      isMe: false,
      isRead: true,
    );
  }
}
