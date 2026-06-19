import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:tripship/core/config/storage_buckets.dart';
import 'package:path/path.dart' as p;

final profileServiceProvider = Provider<ProfileService>((ref) {
  final prefs = ref.read(preferencesServiceProvider);
  return ProfileService(Supabase.instance.client, prefs);
});

class ProfileService {
  final SupabaseClient _client;
  final PreferencesService _prefs;

  ProfileService(this._client, this._prefs);

  // Fetch Profile Data (Network First, Cache Fallback)
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*, vehicles(*)')
          .eq('id', userId)
          .single();

      final data = Map<String, dynamic>.from(response);

      // Update Cache
      await _cacheProfile(userId, data);

      return Profile.fromJson(data);
    } catch (e, st) {
      StructuredLogger.error('ProfileService', 'Profile fetch failed', e, st);
      final cached = await _getFromCache(userId);
      try {
        return cached != null ? Profile.fromJson(cached) : null;
      } catch (cacheErr, cacheSt) {
        StructuredLogger.error(
          'ProfileService',
          'Profile cache parse failed',
          cacheErr,
          cacheSt,
        );
        return null;
      }
    }
  }

  static const _cacheTtl = Duration(minutes: 10);

  Future<void> _cacheProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _prefs.setString('profile_$userId', jsonEncode(data));
      await _prefs.setInt(
        'profile_ts_$userId',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<Map<String, dynamic>?> _getFromCache(String userId) async {
    try {
      final jsonStr = await _prefs.getString('profile_$userId');
      if (jsonStr == null) return null;

      // Check TTL: return stale data as offline fallback if expired
      // (getProfile always tries network first, so this is safe)
      final ts = await _prefs.getInt('profile_ts_$userId') ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _cacheTtl.inMilliseconds) {
        StructuredLogger.info(
          'ProfileService',
          'Profile cache for $userId is stale (${age ~/ 60000}min old), serving as offline fallback',
        );
      }

      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  // Update Profile Data
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phoneNumber,
    String? bio,
    String? accountType,
  }) async {
    final updates = <String, dynamic>{'full_name': fullName.trim()};
    if (phoneNumber != null) {
      updates['phone_number'] = phoneNumber.trim().isEmpty
          ? null
          : phoneNumber.trim();
    }
    if (bio != null) {
      updates['bio'] = bio.trim().isEmpty ? null : bio.trim();
    }
    // account_type omitted - column may not exist in profiles table; name/phone/bio are core fields

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // Toggle Availability
  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await _client
        .from('profiles')
        .update({'is_available': isAvailable})
        .eq('id', userId);
  }

  // Get Traveler Status
  Future<String> getTravelerStatus(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('traveler_status')
          .eq('id', userId)
          .single();
      final status = response['traveler_status'] as String? ?? 'none';
      _cacheString('driver_status_$userId', status);
      return status;
    } catch (e) {
      return await _getStringFromCache('driver_status_$userId') ?? 'none';
    }
  }

  // Submit Traveler Application
  Future<void> submitTravelerApplication({
    required String userId,
    required TravelerType travelerType,
    IdentityType? identityType,
    String? identityDocUrl,
    String? licenseUrl,
    String? rentalContractUrl,
    Map<String, dynamic>? vehicleData,
    String? phoneNumber,
  }) async {
    try {
      final updates = <String, dynamic>{
        'traveler_status': DomainConfig.statusPending,
        'traveler_type': travelerType.toStringValue(),
        'traveler_license_url': licenseUrl,
        'rental_contract_url': rentalContractUrl,
      };

      if (identityType != null) {
        updates['identity_type'] = identityType.toStringValue();
      }
      if (identityDocUrl != null) {
        updates['identity_doc_url'] = identityDocUrl;
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        updates['phone_number'] = phoneNumber;
      }

      // 1. Update Profile (including is_driver status)
      if (travelerType == TravelerType.withVehicle) {
        if (vehicleData != null) {
          // Insert Vehicle
          await _client.from('vehicles').insert({
            'owner_id': userId,
            ...vehicleData,
          });
          StructuredLogger.info(
            'ProfileService',
            'Vehicle inserted successfully for user $userId',
          );
        }
        updates['is_driver'] = true;
      } else {
        updates['is_driver'] = false;
      }

      await _client.from('profiles').update(updates).eq('id', userId);
      
      StructuredLogger.info(
        'ProfileService',
        'Traveler application submitted successfully for user $userId with status pending',
      );
    } catch (e, st) {
      StructuredLogger.error(
        'ProfileService',
        'Failed to submit traveler application',
        e,
        st,
      );
      rethrow;
    }
  }

  // Get Company Status
  Future<String> getCompanyStatus(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('company_status')
          .eq('id', userId)
          .single();
      final status = response['company_status'] as String? ?? 'none';
      _cacheString('company_status_$userId', status);
      return status;
    } catch (e) {
      return await _getStringFromCache('company_status_$userId') ?? 'none';
    }
  }

  // Submit Company Application
  Future<void> submitCompanyApplication({
    required String userId,
    required String companyName,
    required String companyAddress,
    required String crNumber,
    required String crUrl,
    String? phoneNumber,
  }) async {
    final updates = {
      'company_status': DomainConfig.statusPending,
      'company_name': companyName,
      'company_address': companyAddress,
      'company_cr_number': crNumber,
      'company_cr_url': crUrl,
      // We don't set 'account_type' to 'company' yet. Admin approval does that.
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      updates['phone_number'] = phoneNumber;
    }

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // Search Travelers (Available & Approved)
  Future<List<Map<String, dynamic>>> searchTravelers({String? city}) async {
    var query = _client
        .from('profiles')
        .select(
          'id, full_name, avatar_url, traveler_type, traveler_rating_avg, '
          'is_available, city, vehicles(id, type, make, model)',
        )
        .eq('traveler_status', DomainConfig.statusApproved)
        .eq('is_available', true);

    // Apply city filter when specified
    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }

    return await query.limit(50);
  }

  // Get Public Profile (cross-user): use the safe vehicles_public view so
  // other users never receive plate_number / document columns. (Own profile
  // uses getProfile, which keeps full vehicles via owner RLS.)
  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('*, vehicles:vehicles_public(*)')
        .eq('id', userId)
        .maybeSingle();
    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  // Get Ratings for a User
  Future<List<Map<String, dynamic>>> getRatings(
    String userId,
    String role,
  ) async {
    final response = await _client
        .from('ratings')
        .select('''
          *,
          rater:profiles!rater_id(full_name, avatar_url)
        ''')
        .eq('rated_id', userId)
        .eq('role_rated', role)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> _cacheString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      // Ignore
    }
  }

  Future<String?> _getStringFromCache(String key) async {
    try {
      return await _prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  // Upload File to Supabase Storage
  Future<String?> uploadFile(File file, String path) async {
    try {
      final fileExt = p.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final fullPath = '$path/$fileName';

      await _client.storage
          .from(StorageBuckets.userDocuments)
          .upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Store the storage PATH (not a public URL): user_documents is a
      // private bucket (identity/license/CR documents). Viewers resolve the
      // path to a short-lived signed URL via [resolveDocumentUrl].
      return fullPath;
    } catch (e, st) {
      StructuredLogger.error('ProfileService', 'Document upload failed', e, st);
      throw TripShipException('upload_failed');
    }
  }

  /// Resolves a stored `user_documents` reference (a storage path, or a
  /// legacy full public URL) to a short-lived signed URL. Works whether the
  /// bucket is public or private. Returns [stored] unchanged when it is not a
  /// user_documents reference (e.g. an external URL).
  Future<String> resolveDocumentUrl(String stored) async {
    final path = _userDocPath(stored);
    if (path == null) return stored;
    try {
      return await _client.storage
          .from(StorageBuckets.userDocuments)
          .createSignedUrl(path, 3600); // 1 hour
    } catch (e, st) {
      StructuredLogger.error(
        'ProfileService',
        'Sign document URL failed',
        e,
        st,
      );
      return stored;
    }
  }

  String? _userDocPath(String stored) {
    const marker = '/user_documents/';
    if (stored.startsWith('http')) {
      final i = stored.indexOf(marker);
      if (i == -1) return null; // external URL — leave untouched
      var path = stored.substring(i + marker.length);
      final q = path.indexOf('?');
      if (q != -1) path = path.substring(0, q);
      return Uri.decodeComponent(path);
    }
    return stored; // already a storage path
  }

  static const _allowedProfileDocColumns = {
    'identity_doc_url',
    'identity_doc_url_pending',
    'traveler_license_url',
    'traveler_license_url_pending',
    'rental_contract_url',
    'rental_contract_url_pending',
    'company_cr_url',
    'company_cr_url_pending',
    'avatar_url',
  };

  static const _allowedVehicleDocColumns = {
    'vehicle_photo_url',
    'vehicle_photo_url_pending',
    'registration_url',
    'registration_doc_url_pending',
    'insurance_url',
    'insurance_url_pending',
  };

  // Update specific document URL
  Future<void> updateDocumentUrl(
    String userId,
    String column,
    String url,
  ) async {
    if (!_allowedProfileDocColumns.contains(column)) {
      throw ArgumentError('Invalid document column: $column');
    }
    await _client.from('profiles').update({column: url}).eq('id', userId);
  }

  // Ensure a vehicle record exists and return its ID
  Future<String> getOrCreateVehicleId(String userId) async {
    final existing = await _client
        .from('vehicles')
        .select('id')
        .eq('owner_id', userId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    // Create a default vehicle record
    final response = await _client
        .from('vehicles')
        .insert({
          'owner_id': userId,
          'type': 'small_car', // Valid default type from VehicleType enum
          'created_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  // Update specific vehicle document URL
  Future<void> updateVehicleDocument(
    String vehicleId,
    String column,
    String url,
  ) async {
    if (!_allowedVehicleDocColumns.contains(column)) {
      throw ArgumentError('Invalid vehicle document column: $column');
    }
    await _client.from('vehicles').update({column: url}).eq('id', vehicleId);
  }

  // Update Avatar
  Future<String?> updateAvatar(String userId, File file) async {
    try {
      // 1. Upload file
      final fileExt = p.extension(file.path);
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final fullPath = '$userId/$fileName';

      // Use 'avatars' bucket (ensure it exists in Supabase)
      await _client.storage
          .from(StorageBuckets.avatars)
          .upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _client.storage.from(StorageBuckets.avatars).getPublicUrl(fullPath);

      // 2. Update Profile with new URL and timestamp
      await _client
          .from('profiles')
          .update({
            'avatar_url': publicUrl,
            'avatar_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      // 3. Update Cache
      final cached = await _getFromCache(userId);
      if (cached != null) {
        cached['avatar_url'] = publicUrl;
        cached['avatar_updated_at'] = DateTime.now().toUtc().toIso8601String();
        _cacheProfile(userId, cached);
      }

      return publicUrl;
    } catch (e, st) {
      StructuredLogger.error('ProfileService', 'Avatar upload failed', e, st);
      throw TripShipException('avatar_upload_failed');
    }
  }
}
