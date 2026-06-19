import 'package:flutter/material.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/enums/app_enums.dart';
import '../controllers/trip_details_controller.dart';

class TripManagementButtons extends StatelessWidget {
  final Trip trip;
  final TripDetailsController controller;
  final bool isLoading;
  final bool cannotCancel;
  final AppLocalizations localizations;

  const TripManagementButtons({
    super.key,
    required this.trip,
    required this.controller,
    required this.isLoading,
    required this.cannotCancel,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    if (trip.status == TripStatus.cancelled ||
        trip.status == TripStatus.completed) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (trip.status != TripStatus.full) ...[
          const SizedBox(height: 16),
          _buildButton(
            onPressed: isLoading
                ? null
                : () => _confirmAction(
                    context,
                    localizations.tripIsFull,
                    localizations.markTripFullConfirmMessage,
                    controller.markTripAsFull,
                  ),
            icon: Icons.check_circle_outline,
            label: localizations.markTripAsFull,
            borderColor: Colors.orange,
            color: Colors.orange,
          ),
        ],
        if (trip.status != TripStatus.full && !cannotCancel) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: isLoading
                ? null
                : () => _confirmAction(
                    context,
                    localizations.cancelTripTitle,
                    localizations.cancelTripConfirmMessage,
                    controller.cancelTrip,
                    isRed: true,
                  ),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: Text(
              localizations.cancelTrip,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    Color? color,
    Color? borderColor,
    bool isElevated = false,
  }) {
    final style = isElevated
        ? ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          )
        : OutlinedButton.styleFrom(
            side: borderColor != null ? BorderSide(color: borderColor) : null,
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 12),
          );

    return SizedBox(
      width: double.infinity,
      child: isElevated
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: style,
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: style,
            ),
    );
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    Future<void> Function() action, {
    bool isGreen = false,
    bool isRed = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isGreen
                  ? Colors.green
                  : (isRed ? Colors.red : Colors.blue),
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.confirm),
          ),
        ],
      ),
    );
    if (confirm == true) action();
  }
}
