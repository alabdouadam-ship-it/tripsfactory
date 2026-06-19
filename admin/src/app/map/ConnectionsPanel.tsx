import { useState, useEffect } from 'react';
import { useT, useI18n } from '@/lib/i18n';
import type { CityNode } from './mapDataUtils';
import { ConnectionListItem } from './ConnectionListItem';
import { X, ChevronDown, ChevronRight } from 'lucide-react';

// ============================================================================
// Types
// ============================================================================

type ConnectionsPanelProps = {
  city: CityNode | null;
  isOpen: boolean;
  onClose: () => void;
};

// ============================================================================
// Collapsible Section Component
// ============================================================================

function CollapsibleSection({
  title,
  count,
  children,
  defaultOpen = true,
}: {
  title: string;
  count: number;
  children: React.ReactNode;
  defaultOpen?: boolean;
}) {
  const [isOpen, setIsOpen] = useState(defaultOpen);
  
  if (count === 0) return null;
  
  return (
    <div className="border-b border-gray-200 dark:border-gray-700">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
      >
        <div className="flex items-center gap-2">
          {isOpen ? (
            <ChevronDown className="w-4 h-4 theme-muted" />
          ) : (
            <ChevronRight className="w-4 h-4 theme-muted" />
          )}
          <span className="font-medium theme-text">{title}</span>
          <span className="text-sm theme-muted">({count})</span>
        </div>
      </button>
      
      {isOpen && (
        <div className="bg-white dark:bg-gray-900">
          {children}
        </div>
      )}
    </div>
  );
}

// ============================================================================
// Main Component
// ============================================================================

export function ConnectionsPanel({ city, isOpen, onClose }: ConnectionsPanelProps) {
  const t = useT();
  const { language } = useI18n();
  const [isMobile, setIsMobile] = useState(false);
  
  // Choose city name based on admin language
  const displayName = language === 'ar' ? city?.cityNameAr : city?.cityName;
  const secondaryName = language === 'ar' ? city?.cityName : city?.cityNameAr;
  
  // Check if mobile on mount and resize
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);
  
  // Handle click outside to close
  useEffect(() => {
    if (!isOpen) return;
    
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest('.connections-panel')) return;
      if (target.closest('.city-marker')) return;
      onClose();
    };
    
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen, onClose]);
  
  // Handle escape key
  useEffect(() => {
    if (!isOpen) return;
    
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);
  
  if (!city || !isOpen) return null;
  
  const totalOutgoing = city.outgoingTrips.length + city.outgoingShipments.length;
  const totalIncoming = city.incomingTrips.length + city.incomingShipments.length;
  
  // Mobile: bottom sheet
  if (isMobile) {
    return (
      <>
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-[9998] animate-fade-in"
          onClick={onClose}
        />
        
        {/* Bottom Sheet */}
        <div
          className="connections-panel fixed bottom-0 left-0 right-0 bg-white dark:bg-gray-900 rounded-t-2xl shadow-2xl z-[9999] max-h-[60vh] flex flex-col animate-slide-up"
          role="dialog"
          aria-labelledby="panel-title"
        >
          {/* Header */}
          <div className="flex-shrink-0 px-4 py-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-start justify-between">
              <div className="flex-1 min-w-0">
                <h2 id="panel-title" className="text-lg font-bold theme-text truncate">
                  📍 {displayName}
                </h2>
                <p className="text-sm theme-muted truncate">{secondaryName}</p>
              </div>
              <button
                onClick={onClose}
                className="ml-2 p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors flex-shrink-0"
                aria-label={t('map.panel.close', 'Close')}
              >
                <X className="w-5 h-5 theme-text" />
              </button>
            </div>
            
            {/* Summary */}
            <div className="flex items-center gap-4 mt-3 text-sm">
              <span className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-blue-500"></span>
                <span className="theme-text">{totalOutgoing} {t('map.panel.outgoing', 'Outgoing')}</span>
              </span>
              <span className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-purple-500"></span>
                <span className="theme-text">{totalIncoming} {t('map.panel.incoming', 'Incoming')}</span>
              </span>
            </div>
          </div>
          
          {/* Content */}
          <div className="flex-1 overflow-y-auto">
            <CollapsibleSection
              title={t('map.panel.outgoingTrips', 'Outgoing Trips')}
              count={city.outgoingTrips.length}
            >
              {city.outgoingTrips.map(trip => (
                <ConnectionListItem
                  key={trip.id}
                  item={trip}
                  type="trip"
                  direction="outgoing"
                />
              ))}
            </CollapsibleSection>
            
            <CollapsibleSection
              title={t('map.panel.incomingTrips', 'Incoming Trips')}
              count={city.incomingTrips.length}
            >
              {city.incomingTrips.map(trip => (
                <ConnectionListItem
                  key={trip.id}
                  item={trip}
                  type="trip"
                  direction="incoming"
                />
              ))}
            </CollapsibleSection>
            
            <CollapsibleSection
              title={t('map.panel.outgoingShipments', 'Outgoing Shipments')}
              count={city.outgoingShipments.length}
            >
              {city.outgoingShipments.map(shipment => (
                <ConnectionListItem
                  key={shipment.id}
                  item={shipment}
                  type="shipment"
                  direction="outgoing"
                />
              ))}
            </CollapsibleSection>
            
            <CollapsibleSection
              title={t('map.panel.incomingShipments', 'Incoming Shipments')}
              count={city.incomingShipments.length}
            >
              {city.incomingShipments.map(shipment => (
                <ConnectionListItem
                  key={shipment.id}
                  item={shipment}
                  type="shipment"
                  direction="incoming"
                />
              ))}
            </CollapsibleSection>
          </div>
        </div>
        
        <style jsx>{`
          @keyframes fade-in {
            from { opacity: 0; }
            to { opacity: 1; }
          }
          
          @keyframes slide-up {
            from { transform: translateY(100%); }
            to { transform: translateY(0); }
          }
          
          .animate-fade-in {
            animation: fade-in 0.2s ease-out;
          }
          
          .animate-slide-up {
            animation: slide-up 0.3s ease-out;
          }
        `}</style>
      </>
    );
  }
  
  // Desktop: side panel
  return (
    <div
      className="connections-panel fixed top-0 right-0 h-full w-[400px] bg-white dark:bg-gray-900 shadow-2xl z-[9999] flex flex-col animate-slide-in-right"
      role="dialog"
      aria-labelledby="panel-title"
    >
      {/* Header */}
      <div className="flex-shrink-0 px-4 py-4 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <h2 id="panel-title" className="text-lg font-bold theme-text truncate">
              📍 {displayName}
            </h2>
            <p className="text-sm theme-muted truncate">{secondaryName}</p>
          </div>
          <button
            onClick={onClose}
            className="ml-2 p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors flex-shrink-0"
            aria-label={t('map.panel.close', 'Close')}
          >
            <X className="w-5 h-5 theme-text" />
          </button>
        </div>
        
        {/* Summary */}
        <div className="flex items-center gap-4 mt-3 text-sm">
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-blue-500"></span>
            <span className="theme-text">{totalOutgoing} {t('map.panel.outgoing', 'Outgoing')}</span>
          </span>
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-purple-500"></span>
            <span className="theme-text">{totalIncoming} {t('map.panel.incoming', 'Incoming')}</span>
          </span>
        </div>
      </div>
      
      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <CollapsibleSection
          title={t('map.panel.outgoingTrips', 'Outgoing Trips')}
          count={city.outgoingTrips.length}
        >
          {city.outgoingTrips.map(trip => (
            <ConnectionListItem
              key={trip.id}
              item={trip}
              type="trip"
              direction="outgoing"
            />
          ))}
        </CollapsibleSection>
        
        <CollapsibleSection
          title={t('map.panel.incomingTrips', 'Incoming Trips')}
          count={city.incomingTrips.length}
        >
          {city.incomingTrips.map(trip => (
            <ConnectionListItem
              key={trip.id}
              item={trip}
              type="trip"
              direction="incoming"
            />
          ))}
        </CollapsibleSection>
        
        <CollapsibleSection
          title={t('map.panel.outgoingShipments', 'Outgoing Shipments')}
          count={city.outgoingShipments.length}
        >
          {city.outgoingShipments.map(shipment => (
            <ConnectionListItem
              key={shipment.id}
              item={shipment}
              type="shipment"
              direction="outgoing"
            />
          ))}
        </CollapsibleSection>
        
        <CollapsibleSection
          title={t('map.panel.incomingShipments', 'Incoming Shipments')}
          count={city.incomingShipments.length}
        >
          {city.incomingShipments.map(shipment => (
            <ConnectionListItem
              key={shipment.id}
              item={shipment}
              type="shipment"
              direction="incoming"
            />
          ))}
        </CollapsibleSection>
      </div>
      
      <style jsx>{`
        @keyframes slide-in-right {
          from { transform: translateX(100%); }
          to { transform: translateX(0); }
        }
        
        .animate-slide-in-right {
          animation: slide-in-right 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
