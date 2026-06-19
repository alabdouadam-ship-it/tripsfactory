import { useMemo } from 'react';
import { Polyline } from 'react-leaflet';
import type { CityNode, RouteLineData } from './mapDataUtils';
import { generateRouteLines } from './mapDataUtils';

// ============================================================================
// Types
// ============================================================================

type RouteLinesProps = {
  selectedCity: CityNode | null;
  allCities: Map<string, CityNode>;
};

// ============================================================================
// Component
// ============================================================================

export function RouteLines({ selectedCity, allCities }: RouteLinesProps) {
  const lines = useMemo(() => {
    if (!selectedCity) return [];
    return generateRouteLines(selectedCity, allCities);
  }, [selectedCity, allCities]);
  
  if (!selectedCity || lines.length === 0) {
    return null;
  }
  
  return (
    <>
      {lines.map((line, index) => {
        // Calculate line weight based on connection count (2-4px)
        const weight = Math.min(2 + line.count * 0.5, 4);
        
        // Color based on type
        const color = line.type === 'trip' ? '#f97316' : '#10b981';
        
        return (
          <Polyline
            key={`${line.from[0]}-${line.from[1]}-${line.to[0]}-${line.to[1]}-${line.type}-${index}`}
            positions={[line.from, line.to]}
            pathOptions={{
              color: color,
              weight: weight,
              dashArray: '10, 10',
              opacity: 0.7,
            }}
            // Render below markers
            pane="overlayPane"
          />
        );
      })}
    </>
  );
}
