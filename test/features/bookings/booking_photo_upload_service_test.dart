import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tripsfactory/core/exceptions/tripsfactory_exception.dart';
import 'package:tripsfactory/features/bookings/data/lifecycle/booking_photo_upload_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient client;

  setUp(() {
    client = MockSupabaseClient();
  });

  test('returns null and skips upload when photo is null', () async {
    var uploadCalled = false;
    final service = BookingPhotoUploadService(
      client,
      uploadFile: (_, _) async => uploadCalled = true,
      publicUrlForPath: (_) => 'https://example.test/file.jpg',
    );

    final result = await service.uploadDeliveryPhoto(null, 'b1', 'pickup');

    expect(result, isNull);
    expect(uploadCalled, isFalse);
  });

  test('uploads photo and returns public URL', () async {
    String? uploadedPath;
    final service = BookingPhotoUploadService(
      client,
      nowProvider: () => DateTime.fromMillisecondsSinceEpoch(1714850000000),
      uploadFile: (path, file) async => uploadedPath = path,
      publicUrlForPath: (path) => 'https://cdn.example/$path',
    );

    final result = await service.uploadDeliveryPhoto(
      File('sample.png'),
      'booking-42',
      'delivery',
    );

    expect(uploadedPath, 'booking-42_delivery_1714850000000.png');
    expect(result, 'https://cdn.example/booking-42_delivery_1714850000000.png');
  });

  test('throws photo_upload_failed when upload throws', () async {
    final service = BookingPhotoUploadService(
      client,
      uploadFile: (_, _) async => throw Exception('storage down'),
      publicUrlForPath: (_) => 'https://unused',
    );

    expect(
      () => service.uploadDeliveryPhoto(File('sample.jpg'), 'b1', 'pickup'),
      throwsA(
        predicate<TripsFactoryException>((e) => e.messageKey == 'photo_upload_failed'),
      ),
    );
  });
}
