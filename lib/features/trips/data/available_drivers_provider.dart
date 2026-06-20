import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripsfactory/features/profile/data/profile_service.dart';

final availableTravelersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.searchTravelers();
});
