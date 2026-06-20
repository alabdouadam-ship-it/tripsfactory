import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/features/profile/data/profile_model.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/core/providers/app_mode_provider.dart';
import '../test_helpers/rebuild_counter.dart';
import '../test_helpers/perf_budgets_loader.dart';

/// HomeScreen rebuild budget: minor profile field update should not rebuild entire tree.
/// We test a widget that uses the same .select() pattern as HomeScreen (travelerStatus, isClientMode).
void main() {
  testWidgets('home-style consumer stays under rebuild budget on profile update', (tester) async {
    final budgets = loadPerfBudgets();
    final maxRebuilds = getInt(budgets['flutter'] as Map<String, dynamic>, 'max_rebuilds_per_minor_update', 8);

    int rebuildCount = 0;
    final profileState = StateProvider<Profile?>((ref) => const Profile(id: 'u1', fullName: 'Test', travelerStatus: 'approved'));
    final override = currentUserProfileProvider.overrideWith((ref) async => ref.watch(profileState));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [override],
        child: MaterialApp(
          home: RebuildCounter(
            onBuild: () => rebuildCount++,
            child: Consumer(
              builder: (context, ref, _) {
                ref.watch(isClientModeProvider);
                ref.watch(currentUserProfileProvider.select((p) => p.value?.travelerStatus));
                return const Scaffold(body: Text('Home'));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final afterBuild = rebuildCount;
    final container = ProviderScope.containerOf(tester.element(find.byType(Consumer)));
    container.read(profileState.notifier).state = const Profile(id: 'u1', fullName: 'Test', travelerStatus: 'approved');
    await tester.pump();

    expect(rebuildCount - afterBuild, lessThanOrEqualTo(maxRebuilds), reason: 'Minor or no-op profile update should not exceed rebuild budget');
  });
}
