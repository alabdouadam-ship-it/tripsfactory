import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';

void main() {
  group('Shipment.fromJson', () {
    test('parses minimal valid json', () {
      final json = _minimalShipmentJson();
      final s = Shipment.fromJson(json);
      expect(s.id, 's1');
      expect(s.senderId, 'u1');
      expect(s.weightKg, 10.5);
      expect(s.transportType, 'internal');
      expect(s.status, ShipmentStatus.pending);
    });

    test('parses all shipment statuses', () {
      final statuses = <String, ShipmentStatus>{
        'pending': ShipmentStatus.pending,
        'in_communication': ShipmentStatus.inCommunication,
        'accepted': ShipmentStatus.accepted,
        'picked_up': ShipmentStatus.pickedUp,
        'delivered': ShipmentStatus.delivered,
        'cancelled': ShipmentStatus.cancelled,
      };
      for (final entry in statuses.entries) {
        final s = Shipment.fromJson(_minimalShipmentJson(status: entry.key));
        expect(s.status, entry.value, reason: 'status ${entry.key}');
      }
    });

    test('parses in_communication status', () {
      final s = Shipment.fromJson(_minimalShipmentJson(status: 'in_communication'));
      expect(s.status, ShipmentStatus.inCommunication);
    });

    test('parses optional fields', () {
      final json = _minimalShipmentJson()
        ..addAll({
          'description': 'Test shipment',
          'weight_kg': 25.5,
          'pickup_latitude': 33.5,
          'pickup_longitude': 36.3,
        });
      final s = Shipment.fromJson(json);
      expect(s.description, 'Test shipment');
      expect(s.weightKg, 25.5);
      expect(s.pickupLat, 33.5);
      expect(s.pickupLng, 36.3);
    });
  });

  group('Shipment.toJson', () {
    test('round-trip preserves core fields', () {
      final json = _minimalShipmentJson(status: 'accepted');
      final s = Shipment.fromJson(json);
      final out = s.toJson();
      expect(out['id'], 's1');
      expect(out['status'], 'accepted');
      expect(out['weight_kg'], 10.5);
      expect(out['transport_type'], 'internal');
    });
  });
}

Map<String, dynamic> _minimalShipmentJson({String status = 'pending'}) => {
      'id': 's1',
      'sender_id': 'u1',
      'pickup_location_id': 'loc1',
      'dropoff_location_id': 'loc2',
      'weight_kg': 10.5,
      'transport_type': 'internal',
      'pickup_date': '2025-01-01T00:00:00Z',
      'status': status,
      'created_at': '2025-01-01T00:00:00Z',
    };
