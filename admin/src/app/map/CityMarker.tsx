import { useMemo } from 'react';
import { Marker, Tooltip } from 'react-leaflet';
import L from 'leaflet';
import type { CityNode } from './mapDataUtils';
import { useI18n } from '@/lib/i18n';

// ============================================================================
// Types
// ============================================================================

type CityMarkerProps = {
  city: CityNode;
  isSelected: boolean;
  isFaded: boolean;
  onClick: (cityId: string) => void;
};

// ============================================================================
// Component
// ============================================================================

export function CityMarker({ city, isSelected, isFaded, onClick }: CityMarkerProps) {
  const { language } = useI18n();
  
  // Choose city name based on admin language
  const displayName = language === 'ar' ? city.cityNameAr : city.cityName;
  const secondaryName = language === 'ar' ? city.cityName : city.cityNameAr;
  
  const icon = useMemo(() => {
    const size = city.markerSize;
    const color = city.markerColor;
    const fontSize = size > 30 ? '14px' : '11px';
    
    // Build CSS classes
    const classes = ['city-marker'];
    if (isSelected) classes.push('selected');
    if (isFaded) classes.push('faded');
    
    return new L.DivIcon({
      html: `
        <style>
          .city-marker {
            background: ${color};
            width: ${size}px;
            height: ${size}px;
            border-radius: 50%;
            border: 3px solid white;
            box-shadow: 0 2px 8px rgba(0,0,0,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: ${fontSize};
            color: white;
            cursor: pointer;
            transition: all 0.3s ease;
            opacity: 1;
          }
          
          .city-marker.selected {
            transform: scale(1.2);
            animation: pulse 2s infinite;
            z-index: 1000 !important;
          }
          
          .city-marker.faded {
            opacity: 0.3;
          }
          
          @keyframes pulse {
            0%, 100% {
              box-shadow: 0 2px 8px rgba(0,0,0,0.3), 0 0 0 0 ${color}80;
            }
            50% {
              box-shadow: 0 2px 8px rgba(0,0,0,0.3), 0 0 0 10px ${color}00;
            }
          }
        </style>
        <div class="${classes.join(' ')}" role="button" tabindex="0" aria-label="${displayName}, ${city.totalConnections} connections">
          ${city.totalConnections}
        </div>
      `,
      iconSize: [size, size],
      iconAnchor: [size / 2, size / 2],
      className: '', // Prevent Leaflet from adding default classes
    });
  }, [city, isSelected, isFaded, displayName]);
  
  return (
    <Marker
      position={city.position}
      icon={icon}
      eventHandlers={{
        click: () => onClick(city.locationId),
      }}
      zIndexOffset={isSelected ? 1000 : 0}
    >
      <Tooltip direction="top" offset={[0, -city.markerSize / 2]} permanent={false}>
        <div className="text-center">
          <div className="font-semibold">{displayName}</div>
          <div className="text-xs text-gray-500">{secondaryName}</div>
          <div className="text-xs text-gray-600 mt-1">
            {city.totalConnections} {city.totalConnections === 1 ? 'connection' : 'connections'}
          </div>
        </div>
      </Tooltip>
    </Marker>
  );
}
