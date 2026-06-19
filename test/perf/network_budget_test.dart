import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/perf_budgets_loader.dart';

/// Stage 3: List screens must not trigger excessive network requests;
/// response row count and payload size are bounded by budget.
void main() {
  test('max_requests_per_list_load is bounded', () {
    final budgets = loadPerfBudgets();
    final maxRequests = getInt(budgets['flutter'] as Map<String, dynamic>, 'max_requests_per_list_load', 2);
    expect(maxRequests, greaterThanOrEqualTo(1));
    expect(maxRequests, lessThanOrEqualTo(5));
  });

  test('max_response_payload_kb is set', () {
    final budgets = loadPerfBudgets();
    final maxKb = getInt(budgets['flutter'] as Map<String, dynamic>, 'max_response_payload_kb', 100);
    expect(maxKb, greaterThan(0));
  });

  test('default_page_size matches trip and shipment search (20)', () {
    final budgets = loadPerfBudgets();
    final pageSize = getInt(budgets['flutter'] as Map<String, dynamic>, 'default_page_size', 20);
    expect(pageSize, 20);
  });
}
