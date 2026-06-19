import { useState } from 'react';
import { useT } from '@/lib/i18n';
import { ChevronDown, ChevronUp, Info } from 'lucide-react';

// ============================================================================
// Types
// ============================================================================

type MapLegendProps = {
  isOpen: boolean;
  onToggle: () => void;
};

// ============================================================================
// Component
// ============================================================================

export function MapLegend({ isOpen, onToggle }: MapLegendProps) {
  const t = useT();
  
  return (
    <div className="fixed bottom-4 right-4 z-[9000] max-w-[280px]">
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow-2xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        {/* Header */}
        <button
          onClick={onToggle}
          className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors border-b border-gray-200 dark:border-gray-700"
          aria-expanded={isOpen}
          aria-label={t('map.legend.toggle', 'Toggle Legend')}
        >
          <div className="flex items-center gap-2">
            <Info className="w-4 h-4 theme-text" />
            <span className="font-semibold theme-text text-sm">
              {t('map.legend.title', 'Legend')}
            </span>
          </div>
          {isOpen ? (
            <ChevronDown className="w-4 h-4 theme-muted" />
          ) : (
            <ChevronUp className="w-4 h-4 theme-muted" />
          )}
        </button>
        
        {/* Content */}
        {isOpen && (
          <div className="p-4 space-y-4 bg-white dark:bg-gray-900 bg-opacity-95 dark:bg-opacity-95">
            {/* City Activity */}
            <div>
              <h3 className="text-xs font-semibold theme-text uppercase tracking-wide mb-2">
                {t('map.legend.cityActivity', 'City Activity')}
              </h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <div className="w-6 h-6 rounded-full bg-[#3b82f6] border-2 border-white shadow-sm flex items-center justify-center text-white text-xs font-bold">
                    31
                  </div>
                  <span className="text-xs theme-text">
                    {t('map.legend.veryHigh', '31+ connections (Very High)')}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 rounded-full bg-[#eab308] border-2 border-white shadow-sm flex items-center justify-center text-white text-xs font-bold">
                    16
                  </div>
                  <span className="text-xs theme-text">
                    {t('map.legend.high', '16-30 connections (High)')}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 rounded-full bg-[#f97316] border-2 border-white shadow-sm flex items-center justify-center text-white text-[10px] font-bold">
                    6
                  </div>
                  <span className="text-xs theme-text">
                    {t('map.legend.medium', '6-15 connections (Medium)')}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-[#ef4444] border-2 border-white shadow-sm flex items-center justify-center text-white text-[8px] font-bold">
                    1
                  </div>
                  <span className="text-xs theme-text">
                    {t('map.legend.low', '1-5 connections (Low)')}
                  </span>
                </div>
              </div>
            </div>
            
            {/* Route Lines */}
            <div>
              <h3 className="text-xs font-semibold theme-text uppercase tracking-wide mb-2">
                {t('map.legend.routes', 'Routes')}
              </h3>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <svg width="32" height="12" className="flex-shrink-0">
                    <line
                      x1="0"
                      y1="6"
                      x2="32"
                      y2="6"
                      stroke="#f97316"
                      strokeWidth="2"
                      strokeDasharray="4,4"
                      opacity="0.7"
                    />
                  </svg>
                  <span className="text-xs theme-text">
                    {t('map.legend.trips', 'Trips (Orange)')}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <svg width="32" height="12" className="flex-shrink-0">
                    <line
                      x1="0"
                      y1="6"
                      x2="32"
                      y2="6"
                      stroke="#10b981"
                      strokeWidth="2"
                      strokeDasharray="4,4"
                      opacity="0.7"
                    />
                  </svg>
                  <span className="text-xs theme-text">
                    {t('map.legend.shipments', 'Shipments (Green)')}
                  </span>
                </div>
              </div>
            </div>
            
            {/* Additional Info */}
            <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
              <p className="text-xs theme-muted italic">
                {t('map.legend.markerSize', 'Marker size = connection count')}
              </p>
              <p className="text-xs theme-muted italic mt-1">
                {t('map.legend.clickCity', 'Click a city to see connections')}
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
