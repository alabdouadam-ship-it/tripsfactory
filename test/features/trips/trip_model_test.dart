import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/enums/app_enums.dart';
import 'package:tripsfactory/features/trips/data/trip_model.dart';

void main() {
  group('Trip.fromJson', () {
    test('parses minimal valid json', () {
      final json = {
        'id': 't1',
        'traveler_id': 'd1',
        'origin_location_id': 'loc1',
        'dest_location_id': 'loc2',
        'departure_time': '2025-01-15T10:00:00Z',
        'trip_type': 'scheduled',
        'status': 'available',
        'created_at': '2025-01-01T00:00:00Z',
      };
      final t = Trip.fromJson(json);
      expect(t.id, 't1');
      expect(t.driverId, 'd1');
      expect(t.originLocationId, 'loc1');
      expect(t.destLocationId, 'loc2');
      expect(t.tripType, 'scheduled');
      expect(t.status, TripStatus.available);
      expect(t.maxWeightKg, isNull);
    });

    test('parses all trip statuses', () {
      final statuses = <String, TripStatus>{
        'available': TripStatus.available,
        'in_communication': TripStatus.inCommunication,
        'pending_confirmation': TripStatus.pendingConfirmation,
        'booked': TripStatus.booked,
        'in_transit': TripStatus.inTransit,
        'full': TripStatus.full,
        'cancelled': TripStatus.cancelled,
        'completed': TripStatus.completed,
      };
      for (final entry in statuses.entries) {
        final t = Trip.fromJson(_minimalTripJson(status: entry.key));
        expect(t.status, entry.value, reason: 'status ${entry.key}');
      }
    });

    test('parses legacy status values', () {
      expect(Trip.fromJson(_minimalTripJson(status: 'scheduled')).status, TripStatus.available);
      expect(Trip.fromJson(_minimalTripJson(status: 'active')).status, TripStatus.inTransit);
    });

    test('parses optional fields', () {
      final json = {
        ..._minimalTripJson(),
        'max_weight_kg': 100.5,
        'suggested_flat_price': 50.0,
        'notes': 'Test notes',
      };
      final t = Trip.fromJson(json);
      expect(t.maxWeightKg, 100.5);
      expect(t.suggestedFlatPrice, 50.0);
      expect(t.notes, 'Test notes');
    });
  });

  group('Trip.toJson', () {
    test('round-trip preserves status', () {
      final json = _minimalTripJson(status: 'booked');
      final t = Trip.fromJson(json);
      final out = t.toJson();
      expect(out['status'], 'booked');
      expect(Trip.fromJson(Map<String, dynamic>.from(out)).status, TripStatus.booked);
    });
  });
}

Map<String, dynamic> _minimalTripJson({String status = 'available'}) => {
      'id': 't1',
      'traveler_id': 'd1',
      'origin_location_id': 'loc1',
      'dest_location_id': 'loc2',
      'departure_time': '2025-01-15T10:00:00Z',
      'trip_type': 'scheduled',
      'status': status,
      'created_at': '2025-01-01T00:00:00Z',
    };
