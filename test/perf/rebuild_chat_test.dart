import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/rebuild_counter.dart';
import '../test_helpers/perf_budgets_loader.dart';

/// ChatScreen: one incoming message should only rebuild message list area, not full scaffold.
/// We test that a list + composer pattern stays under budget when list length changes.
void main() {
  testWidgets('chat-style list update stays under rebuild budget', (tester) async {
    final budgets = loadPerfBudgets();
    final maxRebuilds = getInt(budgets['flutter'] as Map<String, dynamic>, 'max_rebuilds_chat_new_message', 5);

    int rebuildCount = 0;
    final messageCount = StateProvider<int>((ref) => 0);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RebuildCounter(
              onBuild: () => rebuildCount++,
              child: Consumer(
                builder: (context, ref, _) {
                  final n = ref.watch(messageCount);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Messages: $n'),
                      ...List.generate(n, (i) => ListTile(title: Text('Msg $i'))),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final afterFirst = rebuildCount;
    final container = ProviderScope.containerOf(tester.element(find.byType(Consumer)));
    container.read(messageCount.notifier).state = 1;
    await tester.pump();

    expect(rebuildCount - afterFirst, lessThanOrEqualTo(maxRebuilds), reason: 'One new message should not exceed chat rebuild budget');
  });
}
