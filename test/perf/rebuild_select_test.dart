import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import '../test_helpers/perf_budgets_loader.dart';

/// Tests that widgets using .select() on currentUserProfileProvider
/// do not rebuild when an unrelated profile field changes (Stage 3 optimization).
void main() {
  late Profile profileA;
  late Profile profileSameStatusNewName;
  late Profile profileNewStatus;

  setUpAll(() {
    profileA = const Profile(
      id: 'u1',
      fullName: 'User One',
      travelerStatus: 'pending',
    );
    profileSameStatusNewName = const Profile(
      id: 'u1',
      fullName: 'User One Updated Name',
      travelerStatus: 'pending',
    );
    profileNewStatus = const Profile(
      id: 'u1',
      fullName: 'User One',
      travelerStatus: 'approved',
    );
  });

  testWidgets(
    'widget watching travelerStatus via .select() rebuilds only when travelerStatus changes',
    (tester) async {
      final budgets = loadPerfBudgets();
      final maxRecomputes = getInt(
        budgets['flutter'] as Map<String, dynamic>,
        'max_recomputes_on_unrelated_change',
        0,
      );

      int rebuildCount = 0;
      final profileState = StateProvider<Profile?>((ref) => profileA);
      final override = currentUserProfileProvider.overrideWith(
        (ref) async => ref.watch(profileState),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [override],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      // Count rebuilds of this Consumer (select listener), not the parent
                      // wrapper — wrapping with RebuildCounter misses child rebuilds.
                      rebuildCount++;
                      final status = ref.watch(
                        currentUserProfileProvider.select(
                          (p) => p.value?.travelerStatus ?? 'none',
                        ),
                      );
                      return Text('Status: $status');
                    },
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () =>
                                ref.read(profileState.notifier).state =
                                    profileSameStatusNewName,
                            child: const Text('Unrelated'),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.read(profileState.notifier).state =
                                    profileNewStatus,
                            child: const Text('Related'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final afterFirstBuild = rebuildCount;

      await tester.tap(find.text('Unrelated'));
      await tester.pump();

      final afterUnrelatedChange = rebuildCount;
      expect(
        afterUnrelatedChange - afterFirstBuild,
        lessThanOrEqualTo(maxRecomputes),
        reason:
            'Unrelated profile change (fullName) should not trigger rebuild when using .select(travelerStatus)',
      );

      await tester.tap(find.text('Related'));
      // FutureProvider needs a microtask to resolve even if state is sync
      await tester.runAsync(() => Future.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(
        rebuildCount,
        greaterThan(afterUnrelatedChange),
        reason: 'Changing travelerStatus should trigger rebuild',
      );
    },
  );
}
