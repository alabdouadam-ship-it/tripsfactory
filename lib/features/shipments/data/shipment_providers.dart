import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';

/// Realtime stream of a specific shipment.
final shipmentStreamProvider = StreamProvider.autoDispose
    .family<Shipment, String>((ref, shipmentId) {
      return ref.watch(shipmentServiceProvider).watchShipment(shipmentId);
    });
