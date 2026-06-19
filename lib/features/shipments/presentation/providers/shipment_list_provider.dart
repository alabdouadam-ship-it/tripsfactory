import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/features/shipments/data/shipment_model.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';
import 'package:tripship/core/services/cache_service.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/home/presentation/providers/home_filter_provider.dart';

part 'shipment_list_provider.freezed.dart';

@freezed
abstract class ShipmentListState with _$ShipmentListState {
  const factory ShipmentListState({
    @Default([]) List<Shipment> shipments,
    @Default(true) bool hasMore,
    @Default(0) int offset,
    @Default(false) bool showCachedBanner,
    @Default(false) bool hasNewRealtimeUpdates,
  }) = _ShipmentListState;
}

class ShipmentListFilter {
  final TransportType transportType;
  final bool excludeInteracted;
  final HomeFilterState filterState;

  ShipmentListFilter({
    required this.transportType,
    required this.excludeInteracted,
    required this.filterState,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShipmentListFilter &&
          runtimeType == other.runtimeType &&
          transportType == other.transportType &&
          excludeInteracted == other.excludeInteracted &&
          filterState == other.filterState;

  @override
  int get hashCode =>
      transportType.hashCode ^
      excludeInteracted.hashCode ^
      filterState.hashCode;
}

class ShipmentListNotifier
    extends FamilyAsyncNotifier<ShipmentListState, ShipmentListFilter> {
  final int _limit = 20;
  RealtimeChannel? _subscription;

  @override
  FutureOr<ShipmentListState> build(ShipmentListFilter arg) {
    ref.onDispose(() {
      _subscription?.unsubscribe();
    });

    _setupRealtimeSubscription(arg.transportType);

    return _fetchInitial();
  }

  void _setupRealtimeSubscription(TransportType transportType) {
    _subscription?.unsubscribe();

    final channelName = 'public:shipments:transport_type=${transportType.name}';
    _subscription = Supabase.instance.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shipments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'transport_type',
            value: transportType.name,
          ),
          callback: (payload) {
            state.whenData((current) {
              state = AsyncData(current.copyWith(hasNewRealtimeUpdates: true));
            });
          },
        )
        .subscribe();
  }

  Future<ShipmentListState> _fetchInitial() async {
    try {
      final shipmentService = ref.read(shipmentServiceProvider);
      final filterState = arg.filterState;

      final results = await shipmentService.getRecentShipments(
        transportType: arg.transportType.name,
        pickupLocationId: filterState.originLocationId,
        dropoffLocationId: filterState.destLocationId,
        pickupProvince: filterState.originProvince,
        dropoffProvince: filterState.destProvince,
        minWeight: filterState.minWeight,
        date: filterState.date,
        limit: _limit,
        offset: 0,
        excludeOfferedByCurrentUser: arg.excludeInteracted,
      );

      // Cache the first page
      await ref
          .read(cacheServiceProvider)
          .cacheShipments(results, arg.transportType.name);

      return ShipmentListState(
        shipments: results,
        hasMore: results.length == _limit,
        offset: results.length,
        showCachedBanner: false,
        hasNewRealtimeUpdates: false,
      );
    } catch (e) {
      // Try cache
      final cached = await ref
          .read(cacheServiceProvider)
          .getCachedShipments(arg.transportType.name);
      if (cached != null && cached.isNotEmpty) {
        return ShipmentListState(
          shipments: cached,
          hasMore: false,
          offset: cached.length,
          showCachedBanner: true,
          hasNewRealtimeUpdates: false,
        );
      }
      rethrow;
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        currentState.hasMore == false ||
        state.isLoading) {
      return;
    }

    state = AsyncLoading<ShipmentListState>().copyWithPrevious(state);

    state = await AsyncValue.guard(() async {
      final filterState = arg.filterState;
      final results = await ref
          .read(shipmentServiceProvider)
          .getRecentShipments(
            transportType: arg.transportType.name,
            pickupLocationId: filterState.originLocationId,
            dropoffLocationId: filterState.destLocationId,
            pickupProvince: filterState.originProvince,
            dropoffProvince: filterState.destProvince,
            minWeight: filterState.minWeight,
            date: filterState.date,
            limit: _limit,
            offset: currentState.offset,
            excludeOfferedByCurrentUser: arg.excludeInteracted,
          );

      return currentState.copyWith(
        shipments: [...currentState.shipments, ...results],
        offset: currentState.offset + results.length,
        hasMore: results.length == _limit,
      );
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchInitial());
  }

  void clearRealtimeFlag() {
    state.whenData((current) {
      state = AsyncData(current.copyWith(hasNewRealtimeUpdates: false));
    });
  }

  Future<void> refreshInteractionForShipment(Shipment shipment) async {
    final currentState = state.valueOrNull;
    if (currentState == null || !arg.excludeInteracted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Check for existing offers from this user
      final response = await Supabase.instance.client
          .from('offers')
          .select('id')
          .eq('shipment_id', shipment.id)
          .eq('traveler_id', userId)
          .maybeSingle();

      if (response != null) {
        // Interaction found, remove from discovery list immediately
        state = AsyncValue.data(
          currentState.copyWith(
            shipments: currentState.shipments
                .where((s) => s.id != shipment.id)
                .toList(),
          ),
        );
      }
    } catch (e) {
      // Safe to ignore in local refresh
    }
  }
}

final shipmentListProvider =
    AsyncNotifierProviderFamily<
      ShipmentListNotifier,
      ShipmentListState,
      ShipmentListFilter
    >(() => ShipmentListNotifier());
