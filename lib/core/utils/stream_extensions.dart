import 'dart:async';

/// Extensions on [Stream] for TripShip-specific performance patterns.
extension TripShipStreamExtensions<T> on Stream<T> {
  /// Throttles the stream so that after emitting an item, subsequent items
  /// within [duration] are dropped. The first event always passes through.
  ///
  /// Use this on Supabase realtime `.stream()` chains to prevent
  /// rapid-fire re-fetches when multiple rows change in quick succession.
  Stream<T> throttle(Duration duration) {
    Timer? timer;
    bool canEmit = true;

    final controller = StreamController<T>.broadcast();

    final subscription = listen(
      (data) {
        if (canEmit) {
          controller.add(data);
          canEmit = false;
          timer = Timer(duration, () {
            canEmit = true;
          });
        }
      },
      onError: controller.addError,
      onDone: () {
        timer?.cancel();
        controller.close();
      },
    );

    controller.onCancel = () {
      timer?.cancel();
      subscription.cancel();
    };

    return controller.stream;
  }
}

///Extension for `Stream<List<Map<String, dynamic>>>` — the type emitted by
/// Supabase `.stream()`.
extension SupabaseStreamExtensions on Stream<List<Map<String, dynamic>>> {
  /// Suppresses duplicate Supabase stream events where the underlying row data
  /// has not actually changed.
  ///
  /// Supabase `.stream()` re-emits the current snapshot on every subscription
  /// open and after unrelated table events. This causes unnecessary downstream
  /// `asyncMap(_ => fullFetch())` calls even when nothing changed.
  ///
  /// Fingerprinting strategy: join each row's `id` and `updated_at`
  /// (falling back to `created_at`) into a compact string. If the fingerprint
  /// matches the previous emission the event is dropped entirely, preventing
  /// any downstream network round-trip.
  Stream<List<Map<String, dynamic>>> distinctUntilDataChanged() {
    String? lastFingerprint;

    return where((rows) {
      // Build a lightweight fingerprint: "id1:ts1,id2:ts2,..."
      // Sorting by id ensures order-independent comparison.
      final sorted = [...rows]
        ..sort(
          (a, b) =>
              (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? ''),
        );
      final fingerprint = sorted
          .map((r) {
            final id = r['id']?.toString() ?? '';
            final ts = (r['updated_at'] ?? r['created_at'])?.toString() ?? '';
            final status = r['status']?.toString() ?? '';
            return '$id:$ts:$status';
          })
          .join(',');

      if (fingerprint == lastFingerprint) {
        return false; // suppress — data unchanged
      }
      lastFingerprint = fingerprint;
      return true;
    });
  }
}
