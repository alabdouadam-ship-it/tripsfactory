import 'package:flutter/material.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class ProhibitedItemsDialog extends StatelessWidget {
  const ProhibitedItemsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final items = [
      {'icon': Icons.local_pharmacy, 'label': localizations.prohibitedDrugs},
      {'icon': Icons.liquor, 'label': localizations.prohibitedAlcohol},
      {'icon': Icons.warning, 'label': localizations.prohibitedWeapons},
      {
        'icon': Icons.local_fire_department,
        'label': localizations.prohibitedFlammables,
      },
      {'icon': Icons.money, 'label': localizations.prohibitedCurrency},
    ];

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(localizations.prohibitedItemsTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.prohibitedItemsDisclaimer),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: Colors.redAccent,
                    ),
                    title: Text(item['label'] as String),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.close),
        ),
      ],
    );
  }
}
