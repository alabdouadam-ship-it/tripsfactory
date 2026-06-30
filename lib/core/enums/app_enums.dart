import 'package:json_annotation/json_annotation.dart';
import 'package:tripsfactory/core/utils/logger.dart';

enum TripStatus {
  @JsonValue('available')
  available, // Trip created and visible in public listings
  @JsonValue('in_communication')
  inCommunication, // At least one user has sent a message
  @JsonValue('pending_confirmation')
  pendingConfirmation, // At least one booking request pending
  @JsonValue('booked')
  booked, // At least one booking accepted
  @JsonValue('in_transit')
  inTransit, // Goods are being transported
  @JsonValue('full')
  full, // Driver marked as full OR first delivery confirmed
  @JsonValue('cancelled')
  cancelled, // Driver cancelled
  @JsonValue('completed')
  completed; // All bookings completed

  String toStringValue() {
    switch (this) {
      case available:
        return 'available';
      case inCommunication:
        return 'in_communication';
      case pendingConfirmation:
        return 'pending_confirmation';
      case booked:
        return 'booked';
      case inTransit:
        return 'in_transit';
      case full:
        return 'full';
      case cancelled:
        return 'cancelled';
      case completed:
        return 'completed';
    }
  }

  static TripStatus fromString(String? value) {
    if (value == null) return TripStatus.available;
    if (value == 'in_communication') return TripStatus.inCommunication;
    if (value == 'pending_confirmation') return TripStatus.pendingConfirmation;
    if (value == 'in_transit') return TripStatus.inTransit;
    // Handle legacy values
    if (value == 'scheduled') return TripStatus.available;
    if (value == 'active') return TripStatus.inTransit;
    return TripStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () {
        StructuredLogger.warning(
          'TripStatus',
          'Unknown status "$value", defaulting to available',
        );
        return TripStatus.available;
      },
    );
  }
}

enum BookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('delivered')
  delivered,
  @JsonValue('in_communication')
  inCommunication,
  @JsonValue('frozen')
  frozen,
  @JsonValue('disputed')
  disputed;

  String toStringValue() {
    switch (this) {
      case pending:
        return 'pending';
      case accepted:
        return 'accepted';
      case rejected:
        return 'rejected';
      case completed:
        return 'completed';
      case cancelled:
        return 'cancelled';
      case inTransit:
        return 'in_transit';
      case delivered:
        return 'delivered';
      case inCommunication:
        return 'in_communication';
      case frozen:
        return 'frozen';
      case disputed:
        return 'disputed';
    }
  }

  static BookingStatus fromString(String? value) {
    if (value == null) return BookingStatus.pending;
    if (value == 'in_transit') return BookingStatus.inTransit;
    if (value == 'in_communication') return BookingStatus.inCommunication;
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () {
        StructuredLogger.warning(
          'BookingStatus',
          'Unknown status "$value", defaulting to pending',
        );
        return BookingStatus.pending;
      },
    );
  }

  /// Valid state transitions for the booking lifecycle.
  /// Returns true if transitioning from this status to [target] is allowed.
  bool canTransitionTo(BookingStatus target) {
    switch (this) {
      case inCommunication:
        return target == pending || target == cancelled;
      case pending:
        return target == accepted || target == rejected || target == cancelled;
      case accepted:
        return target == inTransit || target == cancelled;
      case inTransit:
        return target == delivered || target == completed;
      case delivered:
        return target == completed;
      case completed:
      case cancelled:
      case rejected:
      case frozen:
      case disputed:
        return false; // Terminal / admin-managed states (no client transition)
    }
  }
}

enum TravelerType {
  @JsonValue('with_vehicle')
  withVehicle,
  @JsonValue('no_vehicle')
  noVehicle;

  String toStringValue() {
    switch (this) {
      case withVehicle:
        return 'with_vehicle';
      case noVehicle:
        return 'no_vehicle';
    }
  }

  static TravelerType fromString(String? value) {
    if (value == null) return TravelerType.noVehicle;
    if (value == 'with_vehicle') return TravelerType.withVehicle;
    if (value == 'no_vehicle') return TravelerType.noVehicle;
    return TravelerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TravelerType.noVehicle,
    );
  }
}

enum IdentityType {
  @JsonValue('id_card')
  idCard,
  @JsonValue('passport')
  passport,
  @JsonValue('iqama')
  iqama;

  String toStringValue() {
    switch (this) {
      case idCard:
        return 'id_card';
      case passport:
        return 'passport';
      case iqama:
        return 'iqama';
    }
  }

  static IdentityType fromString(String? value) {
    if (value == null) return IdentityType.idCard;
    if (value == 'id_card') return IdentityType.idCard;
    return IdentityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IdentityType.idCard,
    );
  }
}

enum VehicleType {
  @JsonValue('tractor_trailer')
  tractorTrailer,
  @JsonValue('large_car')
  largeCar,
  @JsonValue('medium_car')
  mediumCar,
  @JsonValue('small_car')
  smallCar,
  @JsonValue('refrigerated')
  refrigerated,
  @JsonValue('none')
  none;

  String toStringValue() {
    switch (this) {
      case tractorTrailer:
        return 'tractor_trailer';
      case largeCar:
        return 'large_car';
      case mediumCar:
        return 'medium_car';
      case smallCar:
        return 'small_car';
      case refrigerated:
        return 'refrigerated';
      case none:
        return 'none';
    }
  }

  static VehicleType fromString(String? value) {
    if (value == null) return VehicleType.none;
    return VehicleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VehicleType.none,
    );
  }
}

enum TransportType { none, internal, external }
