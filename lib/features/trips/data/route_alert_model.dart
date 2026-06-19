class RouteAlert {
  final String id;
  final String userId;
  final String? originLocationId;
  final String? destLocationId;
  final String? originProvince;
  final String? destProvince;
  final String? originCity;
  final String? destCity;
  final bool isInternal;
  final DateTime createdAt;
  /// Resolved from locations table when origin_location_id is set
  final String? originDisplayName;
  /// Resolved from locations table when dest_location_id is set
  final String? destDisplayName;

  RouteAlert({
    required this.id,
    required this.userId,
    this.originLocationId,
    this.destLocationId,
    this.originProvince,
    this.destProvince,
    this.originCity,
    this.destCity,
    required this.isInternal,
    required this.createdAt,
    this.originDisplayName,
    this.destDisplayName,
  });

  /// Display string for origin (uses resolved location name or province/city)
  String get effectiveOrigin => originDisplayName ?? originCity ?? originProvince ?? '—';

  /// Display string for destination (uses resolved location name or province/city)
  String get effectiveDest => destDisplayName ?? destCity ?? destProvince ?? '—';

  factory RouteAlert.fromJson(Map<String, dynamic> json) {
    return RouteAlert(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      originLocationId: json['origin_location_id'] as String?,
      destLocationId: json['dest_location_id'] as String?,
      originProvince: json['origin_province'] as String?,
      destProvince: json['dest_province'] as String?,
      originCity: json['origin_city'] as String?,
      destCity: json['dest_city'] as String?,
      isInternal: json['is_internal'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'origin_location_id': originLocationId,
      'dest_location_id': destLocationId,
      'origin_province': originProvince,
      'dest_province': destProvince,
      'origin_city': originCity,
      'dest_city': destCity,
      'is_internal': isInternal,
    };
  }
}
