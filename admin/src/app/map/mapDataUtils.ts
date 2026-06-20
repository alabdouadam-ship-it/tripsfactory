import type { Trip, LocationLabel } from '@/lib/types';

// ============================================================================
// Type Definitions
// ============================================================================

export type ActivityLevel = 'low' | 'medium' | 'high' | 'very-high';

export type CityNode = {
  // Identity
  locationId: string;
  cityName: string;
  cityNameAr: string;
  position: [number, number]; // [latitude, longitude]

  // Connections
  outgoingTrips: Trip[];
  incomingTrips: Trip[];

  // Computed metrics
  totalConnections: number;
  activityLevel: ActivityLevel;

  // Visual properties (computed)
  markerColor: string;
  markerSize: number;
};

export type FilterState = {
  types: ('trips')[];
  statuses: string[]; // TripStatus values
  dateFrom: Date | null;
  dateTo: Date | null;
};

export type SearchState = {
  from: string | null; // locationId
  to: string | null;   // locationId
};

export type RouteLineData = {
  from: [number, number];
  to: [number, number];
  type: 'trip';
  count: number;
};

// ============================================================================
// Activity Level Calculation
// ============================================================================

/**
 * Calculate activity level based on total connection count
 * @param count - Total number of connections (trips)
 * @returns Activity level classification
 */
export function calculateActivityLevel(count: number): ActivityLevel {
  if (count >= 31) return 'very-high';
  if (count >= 16) return 'high';
  if (count >= 6) return 'medium';
  return 'low';
}

/**
 * Get marker color for activity level
 * @param level - Activity level
 * @returns Hex color code
 */
export function getColorForActivity(level: ActivityLevel): string {
  const colors: Record<ActivityLevel, string> = {
    'low': '#ef4444',      // red
    'medium': '#f97316',   // orange
    'high': '#eab308',     // yellow
    'very-high': '#3b82f6' // blue
  };
  return colors[level];
}

/**
 * Get marker size based on connection count
 * @param count - Total number of connections
 * @returns Marker diameter in pixels
 */
export function getSizeForConnections(count: number): number {
  if (count >= 31) return 44;
  if (count >= 16) return 36;
  if (count >= 6) return 28;
  return 20;
}

// ============================================================================
// City Aggregation
// ============================================================================

/**
 * Aggregate trips into city nodes
 * @param trips - Array of trips
 * @returns Map of locationId to CityNode
 */
export function aggregateLocationData(
  trips: Trip[]
): Map<string, CityNode> {
  const locations = new Map<string, CityNode>();

  /**
   * Helper to create or get city node
   */
  const getOrCreateCity = (
    locationId: string,
    location: LocationLabel | undefined
  ): CityNode | null => {
    // Skip if missing coordinates
    if (!location?.latitude || !location?.longitude) {
      return null;
    }

    if (!locations.has(locationId)) {
      locations.set(locationId, {
        locationId,
        cityName: location.city_name_en || 'Unknown',
        cityNameAr: location.city_name_ar || 'غير معروف',
        position: [location.latitude, location.longitude],
        outgoingTrips: [],
        incomingTrips: [],
        totalConnections: 0,
        activityLevel: 'low',
        markerColor: '',
        markerSize: 0,
      });
    }
    return locations.get(locationId)!;
  };

  // Process trips
  for (const trip of trips) {
    // Add origin city
    const originCity = getOrCreateCity(trip.origin_location_id, trip.origin);
    if (originCity) {
      originCity.outgoingTrips.push(trip);
    }

    // Add destination city
    const destCity = getOrCreateCity(trip.dest_location_id, trip.dest);
    if (destCity) {
      destCity.incomingTrips.push(trip);
    }
  }

  // Calculate metrics for each city
  locations.forEach(city => {
    city.totalConnections =
      city.outgoingTrips.length +
      city.incomingTrips.length;

    city.activityLevel = calculateActivityLevel(city.totalConnections);
    city.markerColor = getColorForActivity(city.activityLevel);
    city.markerSize = getSizeForConnections(city.totalConnections);
  });

  return locations;
}

// ============================================================================
// Filter Application
// ============================================================================

/**
 * Check if status matches filter
 */
function matchesStatusFilter(status: string, statuses: string[]): boolean {
  return statuses.length === 0 || statuses.includes(status);
}

/**
 * Check if date matches filter range
 */
function matchesDateFilter(
  dateStr: string,
  from: Date | null,
  to: Date | null
): boolean {
  if (!from && !to) return true;
  const date = new Date(dateStr);
  if (from && date < from) return false;
  if (to && date > to) return false;
  return true;
}

/**
 * Apply filters to city nodes
 * @param cities - Map of city nodes
 * @param filters - Filter state
 * @returns Filtered map of city nodes
 */
export function applyFilters(
  cities: Map<string, CityNode>,
  filters: FilterState
): Map<string, CityNode> {
  const filtered = new Map<string, CityNode>();

  cities.forEach((city, locationId) => {
    // Clone the city node
    const filteredCity: CityNode = {
      ...city,
      outgoingTrips: [],
      incomingTrips: [],
    };

    // Filter trips
    if (filters.types.includes('trips')) {
      filteredCity.outgoingTrips = city.outgoingTrips.filter(trip =>
        matchesStatusFilter(trip.status, filters.statuses) &&
        matchesDateFilter(trip.departure_time, filters.dateFrom, filters.dateTo)
      );
      filteredCity.incomingTrips = city.incomingTrips.filter(trip =>
        matchesStatusFilter(trip.status, filters.statuses) &&
        matchesDateFilter(trip.departure_time, filters.dateFrom, filters.dateTo)
      );
    }

    // Recalculate metrics
    filteredCity.totalConnections =
      filteredCity.outgoingTrips.length +
      filteredCity.incomingTrips.length;

    // Only include cities with connections
    if (filteredCity.totalConnections > 0) {
      filteredCity.activityLevel = calculateActivityLevel(filteredCity.totalConnections);
      filteredCity.markerColor = getColorForActivity(filteredCity.activityLevel);
      filteredCity.markerSize = getSizeForConnections(filteredCity.totalConnections);
      filtered.set(locationId, filteredCity);
    }
  });

  return filtered;
}

// ============================================================================
// Route Line Generation
// ============================================================================

/**
 * Generate route lines from selected city to connected cities
 * @param selectedCity - The selected city node
 * @param allCities - Map of all city nodes
 * @returns Array of route line data
 */
export function generateRouteLines(
  selectedCity: CityNode,
  allCities: Map<string, CityNode>
): RouteLineData[] {
  const lines: RouteLineData[] = [];
  const routeMap = new Map<string, { type: 'trip'; count: number }>();

  // Process outgoing trips
  selectedCity.outgoingTrips.forEach(trip => {
    const destCity = allCities.get(trip.dest_location_id);
    if (destCity) {
      const key = `${selectedCity.locationId}-${destCity.locationId}-trip`;
      const existing = routeMap.get(key);
      if (existing) {
        existing.count++;
      } else {
        routeMap.set(key, { type: 'trip', count: 1 });
      }
    }
  });

  // Process incoming trips
  selectedCity.incomingTrips.forEach(trip => {
    const originCity = allCities.get(trip.origin_location_id);
    if (originCity) {
      const key = `${originCity.locationId}-${selectedCity.locationId}-trip`;
      const existing = routeMap.get(key);
      if (existing) {
        existing.count++;
      } else {
        routeMap.set(key, { type: 'trip', count: 1 });
      }
    }
  });

  // Convert to line data
  routeMap.forEach((data, key) => {
    const parts = key.split('-');
    const fromId = parts[0];
    const toId = parts[1];
    const fromCity = allCities.get(fromId);
    const toCity = allCities.get(toId);

    if (fromCity && toCity) {
      lines.push({
        from: fromCity.position,
        to: toCity.position,
        type: data.type,
        count: data.count,
      });
    }
  });

  return lines;
}
