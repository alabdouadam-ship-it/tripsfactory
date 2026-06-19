import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [Connectivity] instance.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Stream provider for connectivity status changes.
final connectivityStatusProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged;
});
