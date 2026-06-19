import 'package:flutter/material.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class ShipmentOtpDialog extends StatefulWidget {
  const ShipmentOtpDialog({super.key});

  @override
  State<ShipmentOtpDialog> createState() => _ShipmentOtpDialogState();
}

class _ShipmentOtpDialogState extends State<ShipmentOtpDialog> {
  final _codeController = TextEditingController();
  bool _showCodeInput = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      scrollable: true,
      title: Text(localizations.markAsDelivered),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showCodeInput) ...[
            Text(
              localizations.deliveryCodeOptional,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showCodeInput = true;
                  });
                },
                icon: const Icon(Icons.lock_outline, color: Colors.blue),
                label: Text(localizations.confirmWithCode),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, 'no_code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
                child: Text(localizations.markDeliveredWithoutCode),
              ),
            ),
          ] else ...[
            Text(localizations.enterDeliveryCode),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: localizations.shipmentDeliveryCode,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsAlignment: _showCodeInput
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      actions: [
        if (_showCodeInput) ...[
          TextButton(
            onPressed: () {
              setState(() {
                _showCodeInput = false;
                _codeController.clear();
              });
            },
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              if (code.isNotEmpty) {
                FocusScope.of(context).unfocus();
                Navigator.pop(context, code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.confirm),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations.cancel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }
}
