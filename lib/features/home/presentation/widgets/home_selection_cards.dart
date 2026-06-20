import 'package:flutter/material.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'home_selection_card.dart';

/// The internal/external transport selection cards shown on the
/// sender home screen when no transport type is selected yet.
class HomeSelectionCards extends StatelessWidget {
  final VoidCallback onInternalTapped;
  final VoidCallback onExternalTapped;

  const HomeSelectionCards({
    super.key,
    required this.onInternalTapped,
    required this.onExternalTapped,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: HomeSelectionCard(
                  title: localizations.internalShipping,
                  icon: Icons.location_on,
                  color: Colors.blueAccent,
                  onTap: onInternalTapped,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: HomeSelectionCard(
                  title: localizations.externalShipping,
                  icon: Icons.public,
                  color: Colors.orangeAccent,
                  onTap: onExternalTapped,
                  delay: const Duration(milliseconds: 100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
