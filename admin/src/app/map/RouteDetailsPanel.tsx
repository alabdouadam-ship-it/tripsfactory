import { X } from 'lucide-react';
import { useT, useI18n } from '@/lib/i18n';
import type { CityNode } from './mapDataUtils';
import { ConnectionListItem } from './ConnectionListItem';

// ============================================================================
// Types
// ============================================================================

type RouteDetailsPanelProps = {
  routeKey: string | null;
  allCities: Map<string, CityNode>;
  isOpen: boolean;
  onClose: () => void;
};

// ============================================================================
// Component
// ============================================================================

export function RouteDetailsPanel({ routeKey, allCities, isOpen, onClose }: RouteDetailsPanelProps) {
  const t = useT();
  const { language } = useI18n();
  
  if (!isOpen || !routeKey) return null;
  
  // Parse route key
  const [originId, destId] = routeKey.split('-');
  const originCity = allCities.get(originId);
  const destCity = allCities.get(destId);
  
  if (!originCity || !destCity) return null;
  
  // Get trips and shipments for this specific route
  const trips = originCity.outgoingTrips.filter(t => t.dest_location_id === destId);
  const shipments = originCity.outgoingShipments.filter(s => s.dropoff_location_id === destId);
  
  const originName = language === 'ar' ? originCity.cityNameAr : originCity.cityName;
  const destName = language === 'ar' ? destCity.cityNameAr : destCity.cityName;
  
  return (
    <div className="fixed top-0 right-0 h-full w-full sm:w-96 bg-white dark:bg-gray-900 shadow-2xl z-[9999] overflow-hidden flex flex-col border-l border-gray-200 dark:border-gray-700">
      {/* Header */}
      <div className="p-4 border-b border-gray-200 dark:border-gray-700 bg-gradient-to-r from-blue-50 to-purple-50 dark:from-gray-800 dark:to-gray-800">
        <div className="flex items-start justify-between mb-2">
          <div className="flex-1">
            <h2 className="text-lg font-bold theme-text flex items-center gap-2">
              <span>{originName}</span>
              <span className="text-gray-400">→</span>
              <span>{destName}</span>
            </h2>
            <p className="text-sm theme-muted mt-1">
              {t('map.routeDetails.subtitle', '{{total}} active connections')
                .replace('{{total}}', String(trips.length + shipments.length))}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-lg transition-colors"
            aria-label={t('common.close', 'Close')}
          >
            <X className="w-5 h-5 theme-text" />
          </button>
        </div>
        
        {/* Stats */}
        <div className="flex items-center gap-4 mt-3">
          {trips.length > 0 && (
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-orange-500"></div>
              <span className="text-sm font-medium theme-text">
                {trips.length} {t('map.routeDetails.trips', 'Trips')}
              </span>
            </div>
          )}
          {shipments.length > 0 && (
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-green-500"></div>
              <span className="text-sm font-medium theme-text">
                {shipments.length} {t('map.routeDetails.shipments', 'Shipments')}
              </span>
            </div>
          )}
        </div>
      </div>
      
      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4">
        {trips.length === 0 && shipments.length === 0 ? (
          <div className="text-center py-8 theme-muted">
            <p>{t('map.routeDetails.noConnections', 'No active connections on this route')}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {/* Trips */}
            {trips.length > 0 && (
              <div>
                <h3 className="text-xs font-bold uppercase tracking-wide theme-muted mb-2">
                  {t('map.routeDetails.tripsSection', 'Trips ({{count}})')
                    .replace('{{count}}', String(trips.length))}
                </h3>
                <div className="space-y-2">
                  {trips.map(trip => (
                    <ConnectionListItem
                      key={trip.id}
                      item={trip}
                      type="trip"
                      direction="outgoing"
                    />
                  ))}
                </div>
              </div>
            )}
            
            {/* Shipments */}
            {shipments.length > 0 && (
              <div className={trips.length > 0 ? 'mt-4 pt-4 border-t border-gray-200 dark:border-gray-700' : ''}>
                <h3 className="text-xs font-bold uppercase tracking-wide theme-muted mb-2">
                  {t('map.routeDetails.shipmentsSection', 'Shipments ({{count}})')
                    .replace('{{count}}', String(shipments.length))}
                </h3>
                <div className="space-y-2">
                  {shipments.map(shipment => (
                    <ConnectionListItem
                      key={shipment.id}
                      item={shipment}
                      type="shipment"
                      direction="outgoing"
                    />
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
