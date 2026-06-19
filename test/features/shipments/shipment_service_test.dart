import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';
import '../../test_utils.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockClient;
  late ProviderContainer container;
  late Ref realRef;

  setUpAll(() {
    registerFallbackValue('shipments');
    silenceDebugPrint();
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    container = ProviderContainer();
    realRef = container.read(Provider((ref) => ref));
  });

  tearDown(() {
    container.dispose();
  });

  group('ShipmentService', () {
    test('getRecentShipments throws TripShipException on error', () async {
      final service = ShipmentService(mockClient, realRef);

      when(() => mockClient.from(any())).thenThrow(Exception('Network error'));

      expect(() => service.getRecentShipments(), throwsA(isA<TripShipException>()));
    });
  });
}
