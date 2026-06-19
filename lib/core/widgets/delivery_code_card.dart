import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches the delivery OTP from the sender-only `delivery_codes` table.
/// Returns null when no code exists or the caller is not the sender (RLS).
final deliveryCodeProvider = FutureProvider.autoDispose
    .family<String?, ({String? shipmentId, String? bookingId})>((ref, args) async {
  final query = Supabase.instance.client.from('delivery_codes').select('code');
  final row = args.shipmentId != null
      ? await query.eq('shipment_id', args.shipmentId!).maybeSingle()
      : await query.eq('booking_id', args.bookingId!).maybeSingle();
  return row?['code'] as String?;
});

/// Amber OTP card shown to the sender. Renders nothing while loading or when
/// the code is unavailable.
class DeliveryCodeCard extends ConsumerWidget {
  const DeliveryCodeCard({
    super.key,
    this.shipmentId,
    this.bookingId,
    required this.title,
    required this.hint,
    required this.copiedLabel,
    this.padding = EdgeInsets.zero,
  }) : assert((shipmentId == null) != (bookingId == null),
            'Provide exactly one of shipmentId or bookingId');

  final String? shipmentId;
  final String? bookingId;
  final String title;
  final String hint;
  final String copiedLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(
      deliveryCodeProvider((shipmentId: shipmentId, bookingId: bookingId)),
    );
    final code = codeAsync.valueOrNull;
    if (code == null || code.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          border: Border.all(color: Colors.amber, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$copiedLabel: $code'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 18, color: Colors.amber),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
