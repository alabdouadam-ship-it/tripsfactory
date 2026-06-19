import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/perf_budgets_loader.dart';

/// Stage 3: List fetches must use limit/offset (pagination); no full-table fetch.
/// Budget default_page_size must match code (trip_service searchTrips limit=20, shipment getRecentShipments limit=20).
void main() {
  test('default page size is within budget', () {
    final budgets = loadPerfBudgets();
    final defaultPageSize = getInt(budgets['flutter'] as Map<String, dynamic>, 'default_page_size', 20);
    final maxPageSize = getInt(budgets['flutter'] as Map<String, dynamic>, 'max_page_size', 50);
    expect(defaultPageSize, lessThanOrEqualTo(maxPageSize));
    expect(defaultPageSize, greaterThan(0));
  });

  test('Stage 3 default page size is 20 for trips/shipments', () {
    final budgets = loadPerfBudgets();
    final defaultPageSize = getInt(budgets['flutter'] as Map<String, dynamic>, 'default_page_size', 20);
    expect(defaultPageSize, 20, reason: 'searchTrips and getRecentShipments use limit=20');
  });

  test('max rows per fetch is bounded', () {
    final budgets = loadPerfBudgets();
    final maxRows = getInt(budgets['backend'] as Map<String, dynamic>, 'max_rows_per_fetch', 50);
    expect(maxRows, lessThanOrEqualTo(100));
    expect(maxRows, greaterThanOrEqualTo(20));
  });
}
