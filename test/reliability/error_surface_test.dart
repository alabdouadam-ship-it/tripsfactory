import 'package:flutter_test/flutter_test.dart';
import 'package:tripsfactory/core/utils/result.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';

/// Errors are surfaced as Result.failure; no silent swallow. Critical flows use Result.
void main() {
  group('Error surfacing (Result)', () {
    test('Result.failure exposes error and does not throw', () {
      final e = TripsFactoryException.withKey(
        'test_key',
        'Message',
        Exception('cause'),
      );
      final result = Result<void>.failure(e);
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.errorOrNull, same(e));
      // No check for dataOrNull as T is void
    });

    test('Result.fold on failure calls onFailure not onSuccess', () {
      final e = TripsFactoryException.withKey('k', 'msg', null);
      final result = Result<void>.failure(e);
      var failureCalled = false;
      result.fold((_) => fail('onSuccess should not be called'), (err) {
        failureCalled = true;
        expect(err, same(e));
      });
      expect(failureCalled, true);
    });

    test('Result.success fold calls onSuccess', () {
      const data = 42;
      final result = Result<int>.success(data);
      var successCalled = false;
      result.fold((d) {
        successCalled = true;
        expect(d, data);
      }, (_) => fail('onFailure should not be called'));
      expect(successCalled, true);
    });
  });
}
