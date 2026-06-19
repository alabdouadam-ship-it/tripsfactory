import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/features/chat/data/chat_model.dart';
import 'package:tripship/features/chat/data/chat_service.dart';
import 'package:tripship/features/offers/data/offer_model.dart';
import 'package:tripship/features/offers/data/offer_service.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';

/// Realtime stream of offers for a specific shipment (sender view).
final offersForShipmentProvider = StreamProvider.autoDispose
    .family<List<Offer>, String>((ref, shipmentId) {
      return ref.watch(offerServiceProvider).watchOffersForShipment(shipmentId);
    });

/// Driver's own offers (realtime).
final myOffersStreamProvider = StreamProvider.autoDispose<List<Offer>>((ref) {
  return ref.watch(offerServiceProvider).watchMyOffers();
});

/// Selected offer ID for chat in shipment details (sender picks which offer to chat with).
final selectedOfferIdProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Offer messages stream for a specific offer.
final offerMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, offerId) {
      return ref.watch(chatServiceProvider).getOfferMessages(offerId);
    });

/// Realtime stream of a specific offer.
final offerStreamProvider = StreamProvider.autoDispose.family<Offer, String>((
  ref,
  offerId,
) {
  return ref.watch(offerServiceProvider).watchOffer(offerId);
});

/// Sender's shipments with offer counts (batch query, avoids N+1).
final myShipmentsWithOffersProvider =
    StreamProvider.autoDispose<List<ShipmentWithOfferCount>>((ref) async* {
      final shipmentService = ref.watch(shipmentServiceProvider);
      final offerService = ref.watch(offerServiceProvider);

      await for (final shipments in shipmentService.watchMyShipments()) {
        if (shipments.isEmpty) {
          yield [];
          continue;
        }

        // Single batch query instead of N separate calls
        final shipmentIds = shipments.map((s) => s.id).toList();
        Map<String, List<String>> offersByShipment;
        try {
          offersByShipment = await offerService.getOfferStatusesForShipments(
            shipmentIds,
          );
        } catch (_) {
          offersByShipment = {};
        }

        final result = <ShipmentWithOfferCount>[];
        for (final shipment in shipments) {
          final statuses = offersByShipment[shipment.id] ?? [];
          result.add(
            ShipmentWithOfferCount(
              shipment: shipment,
              totalOffers: statuses.length,
              pendingOffers: statuses.where((s) => s == 'sent').length,
              hasAccepted: statuses.any(
                (s) => s == 'accepted' || s == 'completed',
              ),
            ),
          );
        }
        yield result;
      }
    });

/// Simple data class for shipment + offer counts.
class ShipmentWithOfferCount {
  final Shipment shipment;
  final int totalOffers;
  final int pendingOffers;
  final bool hasAccepted;

  const ShipmentWithOfferCount({
    required this.shipment,
    required this.totalOffers,
    required this.pendingOffers,
    required this.hasAccepted,
  });
}
