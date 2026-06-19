import 'dart:io';

import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/config/storage_buckets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingPhotoUploadService {
  BookingPhotoUploadService(
    this._supabase, {
    DateTime Function()? nowProvider,
    Future<void> Function(String path, File file)? uploadFile,
    String Function(String path)? publicUrlForPath,
  }) : _nowProvider = nowProvider ?? DateTime.now,
       _uploadFile = uploadFile,
       _publicUrlForPath = publicUrlForPath;

  final SupabaseClient _supabase;
  final DateTime Function() _nowProvider;
  final Future<void> Function(String path, File file)? _uploadFile;
  final String Function(String path)? _publicUrlForPath;

  Future<String?> uploadShipmentPhoto(
    File? photo,
    String bookingId,
    String type,
  ) async {
    if (photo == null) return null;

    try {
      final ext = photo.path.split('.').last;
      final fileName =
          '${bookingId}_${type}_${_nowProvider().millisecondsSinceEpoch}.$ext';

      final upload =
          _uploadFile ??
          (String path, File file) =>
              _supabase.storage.from(StorageBuckets.shipmentPhotos).upload(path, file);
      await upload(fileName, photo);

      final getPublicUrl =
          _publicUrlForPath ??
          (String path) =>
              _supabase.storage.from(StorageBuckets.shipmentPhotos).getPublicUrl(path);
      final publicUrl = getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw TripShipException.withKey(
        'photo_upload_failed',
        'Failed to upload $type photo. Ensure the "shipment_photos" bucket exists.',
      );
    }
  }
}
