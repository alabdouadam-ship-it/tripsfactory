import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:tripship/features/trips/data/trip_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockSupabaseClient mockClient;
  late ProviderContainer container;
  late Ref realRef;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    final mockPrefs = MockPreferencesService();
    container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(mockPrefs)],
    );
    realRef = container.read(Provider((ref) => ref));

    // Default mock behavior
    when(() => mockPrefs.getString(any())).thenAnswer((_) async => null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
  });

  tearDown(() {
    container.dispose();
  });

  group('TripService', () {
    test('searchTrips throws Exception on RPC error', () async {
      final service = TripService(mockClient, realRef);

      when(
        () => mockClient.rpc(any(), params: any(named: 'params')),
      ).thenThrow(Exception('Network error'));

      expect(
        () => service.searchTrips(isInternal: true),
        throwsA(isA<Exception>()),
      );
    });

    test('getMyTrips throws Exception on error', () async {
      final service = TripService(mockClient, realRef);

      when(() => mockClient.from(any())).thenThrow(Exception('DB error'));

      expect(() => service.getMyTrips('driver-123'), throwsA(isA<Exception>()));
    });

    test('getLocations returns empty list on error', () async {
      final service = TripService(mockClient, realRef);

      when(() => mockClient.from(any())).thenThrow(Exception('Network error'));

      final result = await service.getLocations();
      expect(result, isEmpty);
    });
  });
}
