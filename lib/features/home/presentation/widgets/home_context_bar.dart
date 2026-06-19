import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/features/home/presentation/home_filters.dart';
import 'package:tripship/features/home/presentation/providers/home_filter_provider.dart';

class HomeContextBar extends ConsumerWidget {
  final bool isClientMode;
  final bool isInternal;
  final List<Location> locations;
  final Key? homeFiltersKey;
  final NotifierProvider<HomeFilterNotifier, HomeFilterState> filterProvider;

  const HomeContextBar({
    super.key,
    required this.isClientMode,
    required this.isInternal,
    required this.locations,
    this.homeFiltersKey,
    required this.filterProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            (isClientMode
                    ? Theme.of(context).primaryColor
                    : const Color(0xFF2563EB)) // Consistent blue
                .withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: HomeFilters(
        key: homeFiltersKey,
        isInternal: isInternal,
        locations: locations,
        selectedVehicleType: state.vehicleType,
        selectedOrigin: state.originCity,
        selectedDestination: state.destinationCity,
        selectedOriginLocationId: state.originLocationId,
        selectedDestLocationId: state.destLocationId,
        minWeight: state.minWeight,
        date: state.date,
        selectedOriginProvince: state.originProvince,
        selectedDestProvince: state.destProvince,
        onVehicleTypeChanged: notifier.setVehicleType,
        onOriginChanged: notifier.setOriginCity,
        onDestinationChanged: notifier.setDestinationCity,
        onOriginLocationIdChanged: notifier.setOriginLocationId,
        onDestLocationIdChanged: notifier.setDestLocationId,
        onAdvancedFiltersChanged: (w, d, v, oP, dP, oL, dL) {
          notifier.setAdvancedFilters(
            minWeight: w,
            date: d,
            vehicleType: v,
            originProvince: oP,
            destProvince: dP,
            originLocationId: oL,
            destLocationId: dL,
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}
