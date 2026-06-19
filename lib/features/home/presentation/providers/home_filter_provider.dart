import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/enums/app_enums.dart';

@immutable
class HomeFilterState {
  final TransportType transportType;
  final String? vehicleType;
  final String? originCity;
  final String? destinationCity;
  final String? originLocationId;
  final String? destLocationId;
  final double? minWeight;
  final DateTime? date;
  final String? originProvince;
  final String? destProvince;

  const HomeFilterState({
    required this.transportType,
    this.vehicleType,
    this.originCity,
    this.destinationCity,
    this.originLocationId,
    this.destLocationId,
    this.minWeight,
    this.date,
    this.originProvince,
    this.destProvince,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HomeFilterState &&
        other.transportType == transportType &&
        other.vehicleType == vehicleType &&
        other.originCity == originCity &&
        other.destinationCity == destinationCity &&
        other.originLocationId == originLocationId &&
        other.destLocationId == destLocationId &&
        other.minWeight == minWeight &&
        other.date == date &&
        other.originProvince == originProvince &&
        other.destProvince == destProvince;
  }

  @override
  int get hashCode {
    return Object.hash(
      transportType,
      vehicleType,
      originCity,
      destinationCity,
      originLocationId,
      destLocationId,
      minWeight,
      date,
      originProvince,
      destProvince,
    );
  }

  HomeFilterState copyWith({
    TransportType? transportType,
    String? vehicleType,
    String? originCity,
    String? destinationCity,
    String? originLocationId,
    String? destLocationId,
    double? minWeight,
    DateTime? date,
    String? originProvince,
    String? destProvince,
    bool clearOrigin = false,
    bool clearDest = false,
    bool clearProvinceOrigin = false,
    bool clearProvinceDest = false,
  }) {
    return HomeFilterState(
      transportType: transportType ?? this.transportType,
      vehicleType: vehicleType ?? this.vehicleType,
      originCity: clearOrigin ? null : (originCity ?? this.originCity),
      destinationCity: clearDest
          ? null
          : (destinationCity ?? this.destinationCity),
      originLocationId: clearOrigin
          ? null
          : (originLocationId ?? this.originLocationId),
      destLocationId: clearDest
          ? null
          : (destLocationId ?? this.destLocationId),
      minWeight: minWeight ?? this.minWeight,
      date: date ?? this.date,
      originProvince: clearProvinceOrigin
          ? null
          : (originProvince ?? this.originProvince),
      destProvince: clearProvinceDest
          ? null
          : (destProvince ?? this.destProvince),
    );
  }
}

class HomeFilterNotifier extends Notifier<HomeFilterState> {
  @override
  HomeFilterState build() {
    return const HomeFilterState(transportType: TransportType.none);
  }

  void setTransportType(TransportType type) {
    state = state.copyWith(transportType: type);
  }

  void setVehicleType(String? type) {
    state = state.copyWith(vehicleType: type);
  }

  void setOriginCity(String? val) {
    state = state.copyWith(originCity: val, clearOrigin: val == null);
  }

  void setDestinationCity(String? val) {
    state = state.copyWith(destinationCity: val, clearDest: val == null);
  }

  void setOriginLocationId(String? val) {
    if (val == null) {
      state = state.copyWith(clearOrigin: true, clearProvinceOrigin: true);
    } else if (val.startsWith('prov#')) {
      // It's a province selection
      state = state.copyWith(
        originProvince: val.substring(5),
        clearOrigin: true, // effectively clearing specific location/city
      );
    } else {
      state = state.copyWith(originLocationId: val, clearProvinceOrigin: true);
    }
  }

  void setDestLocationId(String? val) {
    if (val == null) {
      state = state.copyWith(clearDest: true, clearProvinceDest: true);
    } else if (val.startsWith('prov#')) {
      state = state.copyWith(destProvince: val.substring(5), clearDest: true);
    } else {
      state = state.copyWith(destLocationId: val, clearProvinceDest: true);
    }
  }

  void setAdvancedFilters({
    double? minWeight,
    DateTime? date,
    String? vehicleType,
    String? originProvince,
    String? destProvince,
    String? originLocationId,
    String? destLocationId,
  }) {
    state = state.copyWith(
      minWeight: minWeight,
      date: date,
      vehicleType: vehicleType,
      originProvince: originProvince,
      destProvince: destProvince,
      originLocationId: originLocationId,
      destLocationId: destLocationId,
    );
  }

  void reset() {
    // Keep the current transport type, clear other filters
    state = HomeFilterState(transportType: state.transportType);
  }
}

final homeFilterProvider =
    NotifierProvider<HomeFilterNotifier, HomeFilterState>(
      HomeFilterNotifier.new,
    );

final clientFilterProvider =
    NotifierProvider<HomeFilterNotifier, HomeFilterState>(
      HomeFilterNotifier.new,
    );

final travelerFilterProvider =
    NotifierProvider<HomeFilterNotifier, HomeFilterState>(
      HomeFilterNotifier.new,
    );
