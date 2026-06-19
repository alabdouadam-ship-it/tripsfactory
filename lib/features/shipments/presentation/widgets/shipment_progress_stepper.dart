import 'package:flutter/material.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class ShipmentProgressStepper extends StatelessWidget {
  final Shipment shipment;

  const ShipmentProgressStepper({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // 1. Accepted/Approved
    final isAccepted = shipment.isAccepted;

    // 2. Goods Handed over / Received by driver
    final isHandedOver = shipment.isHandedOver;

    // 3. Paid
    final isPaid = shipment.isPaid;

    // 4. Delivered
    final isDelivered = shipment.isDelivered;

    return Padding(
      key: const Key('shipment_progress'),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStep(
            context,
            localizations.statusAccepted,
            isAccepted,
            isFirst: true,
            isLast: false,
            isNextStep: false,
          ),
          _buildStep(
            context,
            localizations.handshakeGoodsReceived,
            isHandedOver,
            isFirst: false,
            isLast: false,
            isNextStep: isAccepted && !isHandedOver,
          ),
          _buildStep(
            context,
            localizations.paid,
            isPaid,
            isFirst: false,
            isLast: false,
            isNextStep: isHandedOver && !isPaid,
          ),
          _buildStep(
            context,
            localizations.statusDelivered,
            isDelivered,
            isFirst: false,
            isLast: true,
            isNextStep: isPaid && !isDelivered,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String label,
    bool isCompleted, {
    required bool isFirst,
    required bool isLast,
    required bool isNextStep,
  }) {
    final color = isCompleted
        ? Colors.green
        : (isNextStep ? Colors.orange : Colors.grey[300]!);
    final circleColor = isCompleted
        ? Colors.green
        : (isNextStep
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.grey[300]!);

    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  color: isFirst
                      ? Colors.transparent
                      : (isCompleted || isNextStep ? color : Colors.grey[300]),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: isNextStep
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : (isNextStep
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange,
                                ),
                              ),
                            )
                          : null),
              ),
              Expanded(
                child: Container(
                  height: 3,
                  color: isLast
                      ? Colors.transparent
                      : (isCompleted ? color : Colors.grey[300]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCompleted || isNextStep
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isCompleted
                  ? Colors.green
                  : (isNextStep ? Colors.orange[800] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
