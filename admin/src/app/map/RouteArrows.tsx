import { useMemo } from 'react';
import { Polyline, Popup } from 'react-leaflet';
import type { CityNode } from './mapDataUtils';
import { useT, useI18n } from '@/lib/i18n';

// ============================================================================
// Types
// ============================================================================

type RouteArrowsProps = {
  allCities: Map<string, CityNode>;
  selectedRouteKey: string | null;
  onRouteClick: (routeKey: string) => void;
};

type RouteData = {
  key: string;
  origin: CityNode;
  destination: CityNode;
  trips: Array<{ id: string; status: string }>;
  totalCount: number;
};

// ============================================================================
// Component
// ============================================================================

export function RouteArrows({ allCities, selectedRouteKey, onRouteClick }: RouteArrowsProps) {
  const t = useT();
  const { language } = useI18n();
  
  // Aggregate all routes
  const routes = useMemo(() => {
    const routeMap = new Map<string, RouteData>();
    
    allCities.forEach(city => {
      // Process outgoing trips from this city
      city.outgoingTrips.forEach(trip => {
        const destCity = allCities.get(trip.dest_location_id);
        if (!destCity) return;
        
        const routeKey = `${city.locationId}-${trip.dest_location_id}`;
        
        if (!routeMap.has(routeKey)) {
          routeMap.set(routeKey, {
            key: routeKey,
            origin: city,
            destination: destCity,
            trips: [],
            totalCount: 0,
          });
        }
        
        const route = routeMap.get(routeKey)!;
        route.trips.push({ id: trip.id, status: trip.status });
        route.totalCount++;
      });
    });
    
    return Array.from(routeMap.values());
  }, [allCities]);
  
  return (
    <>
      {routes.map(route => {
        const isSelected = route.key === selectedRouteKey;
        const isFaded = selectedRouteKey !== null && !isSelected;
        
        // Determine color based on content
        const color = '#f97316'; // Orange for trips
        
        // Calculate line weight based on count
        const baseWeight = 2;
        const maxWeight = 8;
        const weight = Math.min(baseWeight + Math.log2(route.totalCount + 1), maxWeight);
        
        const originName = language === 'ar' ? route.origin.cityNameAr : route.origin.cityName;
        const destName = language === 'ar' ? route.destination.cityNameAr : route.destination.cityName;
        
        return (
          <Polyline
            key={route.key}
            positions={[route.origin.position, route.destination.position]}
            pathOptions={{
              color: color,
              weight: isSelected ? weight + 2 : weight,
              opacity: isFaded ? 0.2 : isSelected ? 1 : 0.7,
              dashArray: undefined, // Solid line
            }}
            eventHandlers={{
              click: () => onRouteClick(route.key),
            }}
          >
            <Popup>
              <div className="p-2 min-w-[200px]">
                <div className="font-bold text-sm mb-2 flex items-center gap-2">
                  <span>{originName}</span>
                  <span className="text-gray-400">→</span>
                  <span>{destName}</span>
                </div>
                
                <div className="space-y-1 text-xs">
                  {route.trips.length > 0 && (
                    <div className="flex items-center justify-between">
                      <span className="text-orange-600 font-medium">
                        {t('map.routes.trips', 'Trips')}:
                      </span>
                      <span className="font-bold">{route.trips.length}</span>
                    </div>
                  )}
                  
                  <div className="pt-1 mt-1 border-t border-gray-200">
                    <div className="flex items-center justify-between font-bold">
                      <span>{t('map.routes.total', 'Total')}:</span>
                      <span>{route.totalCount}</span>
                    </div>
                  </div>
                </div>
                
                <div className="mt-2 pt-2 border-t border-gray-200 text-xs text-gray-500 italic">
                  {t('map.routes.clickForDetails', 'Click line for details')}
                </div>
              </div>
            </Popup>
          </Polyline>
        );
      })}
    </>
  );
}
