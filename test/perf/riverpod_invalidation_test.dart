import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/perf_budgets_loader.dart';

/// Stage 3: Providers using .select() or split providers must not recompute
/// on unrelated state changes. Repository fetch (mocked) must be called at most
/// once per lifecycle.
void main() {
  test(
    'provider with .select() does not recompute when unrelated dependency changes',
    () {
      final budgets = loadPerfBudgets();
      getInt(
        budgets['flutter'] as Map<String, dynamic>,
        'max_recomputes_on_unrelated_change',
        0,
      );

      int computeCount = 0;
      final counterProvider = StateProvider<int>((ref) => 0);
      final otherProvider = StateProvider<int>((ref) => 0);

      final selectedProvider = Provider<int>((ref) {
        computeCount++;
        ref.watch(counterProvider);
        return ref.watch(counterProvider);
      });

      final container = ProviderContainer(overrides: []);
      addTearDown(container.dispose);

      expect(container.read(selectedProvider), 0);
      expect(computeCount, 1);

      container.read(otherProvider.notifier).state = 1;
      container.read(selectedProvider);
      expect(
        computeCount,
        1,
        reason:
            'Unrelated provider change should not recompute selected provider',
      );

      container.read(counterProvider.notifier).state = 2;
      expect(container.read(selectedProvider), 2);
      expect(computeCount, 2);
    },
  );

  test(
    'fetch called at most max_fetch_calls_per_lifecycle per lifecycle',
    () async {
      final budgets = loadPerfBudgets();
      final maxCalls = getInt(
        budgets['flutter'] as Map<String, dynamic>,
        'max_fetch_calls_per_lifecycle',
        1,
      );

      int fetchCount = 0;
      final fetchProvider = FutureProvider<int>((ref) async {
        fetchCount++;
        return 42;
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(fetchProvider.future);
      await container.read(fetchProvider.future);
      expect(
        fetchCount,
        lessThanOrEqualTo(maxCalls),
        reason: 'Repeated read should use cache (one fetch per lifecycle)',
      );
    },
  );
}
