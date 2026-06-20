'use client';

import 'leaflet/dist/leaflet.css';
import { useEffect, useState, useMemo, useCallback } from 'react';
import { MapContainer, TileLayer, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { useT, useI18n } from '@/lib/i18n';
import { GeographyConfig } from '@/lib/geographyConfig';
import type { Trip } from '@/lib/types';
import type { CityNode, FilterState, SearchState } from './mapDataUtils';
import { aggregateLocationData, applyFilters } from './mapDataUtils';
import { CityMarker } from './CityMarker';
import { RouteLines } from './RouteLines';
import { RouteArrows } from './RouteArrows';
import { ConnectionsPanel } from './ConnectionsPanel';
import { RouteDetailsPanel } from './RouteDetailsPanel';
import { RouteSearch } from './RouteSearch';
import { MapFilters } from './MapFilters';
import { MapLegend } from './MapLegend';
import { RefreshCw, Loader2, Filter as FilterIcon, Maximize, Minimize, MapPin, Route } from 'lucide-react';

// Fix Leaflet default icon issue (only in browser)
if (typeof window !== 'undefined' && L.Icon?.Default) {
  delete (L.Icon.Default.prototype as any)._getIconUrl;
  L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
  });
}

// ============================================================================
// Map Click Handler Component
// ============================================================================

function MapClickHandler({ onMapClick }: { onMapClick: () => void }) {
  useMapEvents({
    click: (e) => {
      // Only deselect if clicking on the map itself, not on markers
      const target = e.originalEvent.target as HTMLElement;
      if (!target.closest('.city-marker')) {
        onMapClick();
      }
    },
  });
  return null;
}

// ============================================================================
// Main Component
// ============================================================================

export default function MapComponent() {
  const t = useT();
  const { toast } = useToast();
  const { language } = useI18n();
  
  // Data state
  const [trips, setTrips] = useState<Trip[]>([]);
  
  // UI state
  const [selectedCityId, setSelectedCityId] = useState<string | null>(null);
  const [selectedRouteKey, setSelectedRouteKey] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [isFilterPanelOpen, setIsFilterPanelOpen] = useState(false);
  const [isLegendOpen, setIsLegendOpen] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [viewMode, setViewMode] = useState<'cities' | 'routes'>('cities');
  const [isEmptyStateDismissed, setIsEmptyStateDismissed] = useState(false);
  
  // Filter state
  const [filters, setFilters] = useState<FilterState>({
    types: ['trips'],
    statuses: [],
    dateFrom: null,
    dateTo: null,
  });
  
  // Search state
  const [searchState, setSearchState] = useState<SearchState>({
    from: null,
    to: null,
  });
  
  // ============================================================================
  // Data Fetching
  // ============================================================================
  
  const loadData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    // Reset dismissed state when reloading data
    setIsEmptyStateDismissed(false);
    
    try {
      // Fetch trips (exclude completed and cancelled)
      const { data: tripsData, error: tripsError } = await supabase
        .from('trips')
        .select(`
          *,
          profile:profiles!trips_traveler_id_fkey(*),
          origin:locations!trips_origin_location_id_fkey(*),
          dest:locations!trips_dest_location_id_fkey(*)
        `)
        .not('status', 'in', '(completed,cancelled)')
        .order('created_at', { ascending: false });

      if (tripsError) {
        throw new Error('Failed to load map data');
      }

      setTrips(tripsData || []);
      setLastUpdated(new Date());
      setError(null);
    } catch (err) {
      console.error('Failed to load map data:', err);
      setError(t('map.error.loadFailed', 'Failed to load map data. Please try again.'));
      toast(t('map.error.loadFailed', 'Failed to load map data'), 'error');
    } finally {
      setIsLoading(false);
    }
  }, [t, toast]);
  
  // Load data on mount
  useEffect(() => {
    loadData();
  }, [loadData]);
  
  // ============================================================================
  // Data Aggregation
  // ============================================================================
  
  const aggregatedCities = useMemo(() => {
    return aggregateLocationData(trips);
  }, [trips]);
  
  // Apply filters to cities
  const cities = useMemo(() => {
    return applyFilters(aggregatedCities, filters);
  }, [aggregatedCities, filters]);
  
  // ============================================================================
  // Selection Handlers
  // ============================================================================
  
  const handleCityClick = useCallback((cityId: string) => {
    setSelectedCityId(prevId => prevId === cityId ? null : cityId);
  }, []);
  
  const handleRouteClick = useCallback((routeKey: string) => {
    setSelectedRouteKey(prevKey => prevKey === routeKey ? null : routeKey);
  }, []);
  
  const handleMapClick = useCallback(() => {
    setSelectedCityId(null);
    setSelectedRouteKey(null);
  }, []);
  
  // ============================================================================
  // Search Handlers
  // ============================================================================
  
  const handleSearch = useCallback(() => {
    const { from, to } = searchState;
    
    if (!from && !to) return;
    
    // Origin only: select that city
    if (from && !to) {
      setSelectedCityId(from);
      return;
    }
    
    // Destination only: highlight all cities with connections to that destination
    // For now, just select the destination city
    if (!from && to) {
      setSelectedCityId(to);
      return;
    }
    
    // Both: select origin city (connections panel will show route to destination)
    if (from && to) {
      setSelectedCityId(from);
    }
  }, [searchState]);
  
  const handleSearchClear = useCallback(() => {
    setSearchState({ from: null, to: null });
    setSelectedCityId(null);
  }, []);
  
  // ============================================================================
  // Filter Handlers
  // ============================================================================
  
  const handleFilterChange = useCallback((newFilters: FilterState) => {
    setFilters(newFilters);
    // Reset dismissed state when filters change
    setIsEmptyStateDismissed(false);
  }, []);
  
  const handleFilterApply = useCallback(() => {
    // Filters are already applied via useMemo
    // Close the filter panel
    setIsFilterPanelOpen(false);
    
    // Deselect city if it no longer exists after filtering
    // Note: We can't check cities here because it's computed, so we'll let the selectedCity useMemo handle it
  }, []);
  
  const handleFilterReset = useCallback(() => {
    const resetFilters: FilterState = {
      types: ['trips'],
      statuses: [],
      dateFrom: null,
      dateTo: null,
    };
    setFilters(resetFilters);
  }, []);
  
  // ============================================================================
  // Fullscreen Handlers
  // ============================================================================
  
  const toggleFullscreen = useCallback(() => {
    if (!document.fullscreenElement) {
      // Enter fullscreen
      const mapContainer = document.getElementById('operations-map-container');
      if (mapContainer) {
        mapContainer.requestFullscreen().then(() => {
          setIsFullscreen(true);
        }).catch((err) => {
          console.error('Failed to enter fullscreen:', err);
          toast(t('map.error.fullscreenFailed', 'Failed to enter fullscreen mode'), 'error');
        });
      }
    } else {
      // Exit fullscreen
      document.exitFullscreen().then(() => {
        setIsFullscreen(false);
      }).catch((err) => {
        console.error('Failed to exit fullscreen:', err);
      });
    }
  }, [t, toast]);
  
  // Listen for fullscreen changes (e.g., user presses ESC)
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };
    
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
    };
  }, []);
  
  // ============================================================================
  // Computed Values
  // ============================================================================
  
  const selectedCity = useMemo(() => {
    return selectedCityId ? cities.get(selectedCityId) || null : null;
  }, [selectedCityId, cities]);
  
  const stats = useMemo(() => {
    return {
      cityCount: cities.size,
      tripCount: trips.length,
      totalRoutes: trips.length,
    };
  }, [cities, trips]);
  
  // Calculate map center (average of all city positions) - MUST be before early returns
  const mapCenter = useMemo(() => {
    if (cities.size === 0) return GeographyConfig.defaultMapCenter; // Default: home country
    
    let totalLat = 0;
    let totalLng = 0;
    cities.forEach(city => {
      totalLat += city.position[0];
      totalLng += city.position[1];
    });
    
    return [totalLat / cities.size, totalLng / cities.size] as [number, number];
  }, [cities]);
  
  // ============================================================================
  // Render
  // ============================================================================
  
  if (isLoading) {
    return (
      <div className="h-full w-full flex flex-col items-center justify-center theme-bg-secondary">
        <Loader2 className="w-12 h-12 animate-spin theme-text mb-4" />
        <p className="theme-text text-sm">
          {t('map.loading', 'Loading map data...')}
        </p>
      </div>
    );
  }
  
  if (error) {
    return (
      <div className="h-full w-full flex flex-col items-center justify-center theme-bg-secondary p-6">
        <div className="text-red-500 mb-4 text-center">
          <p className="font-semibold mb-2">{t('map.error.title', 'Error Loading Map')}</p>
          <p className="text-sm">{error}</p>
        </div>
        <button
          onClick={loadData}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors flex items-center gap-2"
        >
          <RefreshCw className="w-4 h-4" />
          {t('map.retry', 'Retry')}
        </button>
      </div>
    );
  }
  
  // Don't block rendering when there's no data - show empty map instead
  // This allows users to access filters and change them
  
  return (
    <div id="operations-map-container" className="h-full w-full flex flex-col bg-[var(--surface)]">
      {/* Header */}
      <div className="theme-bg-secondary border-b border-[var(--surface-border)] p-4">
        <div className="flex items-center justify-between mb-3">
          <div>
            <h1 className="text-xl font-bold theme-text flex items-center gap-2">
              🗺️ {t('map.title', 'Operations Map')}
            </h1>
            <p className="text-sm theme-muted mt-1">
              {t('map.stats', '{{cities}} cities · {{trips}} trips · {{routes}} total routes')
                .replace('{{cities}}', String(stats.cityCount))
                .replace('{{trips}}', String(stats.tripCount))
                .replace('{{routes}}', String(stats.totalRoutes))}
            </p>
          </div>
          
          <div className="flex items-center gap-2">
            {lastUpdated && (
              <span className="text-xs theme-muted hidden sm:inline">
                {t('map.lastUpdated', 'Last: {{time}}').replace('{{time}}', lastUpdated.toLocaleTimeString())}
              </span>
            )}
            <div className="flex items-center gap-1 bg-gray-200 dark:bg-gray-700 rounded-lg p-1">
              <button
                onClick={() => setViewMode('cities')}
                className={`px-3 py-1.5 rounded-md transition-colors flex items-center gap-2 text-sm font-medium ${
                  viewMode === 'cities'
                    ? 'bg-blue-500 text-white shadow-sm'
                    : 'theme-text hover:bg-gray-300 dark:hover:bg-gray-600'
                }`}
                title={t('map.viewMode.cities', 'Cities View')}
              >
                <MapPin className="w-4 h-4" />
                <span className="hidden sm:inline">{t('map.viewMode.cities', 'Cities')}</span>
              </button>
              <button
                onClick={() => setViewMode('routes')}
                className={`px-3 py-1.5 rounded-md transition-colors flex items-center gap-2 text-sm font-medium ${
                  viewMode === 'routes'
                    ? 'bg-blue-500 text-white shadow-sm'
                    : 'theme-text hover:bg-gray-300 dark:hover:bg-gray-600'
                }`}
                title={t('map.viewMode.routes', 'Routes View')}
              >
                <Route className="w-4 h-4" />
                <span className="hidden sm:inline">{t('map.viewMode.routes', 'Routes')}</span>
              </button>
            </div>
            <button
              onClick={() => setIsFilterPanelOpen(!isFilterPanelOpen)}
              className="px-3 py-2 bg-gray-200 dark:bg-gray-700 theme-text rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors flex items-center gap-2"
              title={t('map.filters.toggle', 'Toggle Filters')}
            >
              <FilterIcon className="w-4 h-4" />
              <span className="hidden sm:inline">{t('map.filters.title', 'Filters')}</span>
            </button>
            <button
              onClick={toggleFullscreen}
              className="px-3 py-2 bg-gray-200 dark:bg-gray-700 theme-text rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors flex items-center gap-2"
              title={isFullscreen ? t('map.exitFullscreen', 'Exit Fullscreen') : t('map.fullscreen', 'Fullscreen')}
            >
              {isFullscreen ? <Minimize className="w-4 h-4" /> : <Maximize className="w-4 h-4" />}
              <span className="hidden sm:inline">{isFullscreen ? t('map.exitFullscreen', 'Exit') : t('map.fullscreen', 'Fullscreen')}</span>
            </button>
            <button
              onClick={loadData}
              disabled={isLoading}
              className="px-3 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
              title={t('map.refresh', 'Refresh')}
            >
              <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
              <span className="hidden sm:inline">{t('map.refresh', 'Refresh')}</span>
            </button>
          </div>
        </div>
        
        {/* Search Bar */}
        <RouteSearch
          cities={aggregatedCities}
          searchState={searchState}
          onChange={setSearchState}
          onSearch={handleSearch}
          onClear={handleSearchClear}
        />
      </div>
      
      {/* Map */}
      <div className="flex-1 relative" style={{ minHeight: 0 }}>
        <MapContainer
          center={mapCenter}
          zoom={7}
          style={{ height: '100%', width: '100%' }}
          zoomControl={true}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            key={language}
          />
          
          {/* Map click handler */}
          <MapClickHandler onMapClick={handleMapClick} />
          
          {/* Cities View */}
          {viewMode === 'cities' && (
            <>
              {/* Route lines (rendered first, below markers) */}
              <RouteLines selectedCity={selectedCity} allCities={cities} />
              
              {/* City markers */}
              {Array.from(cities.values()).map(city => (
                <CityMarker
                  key={city.locationId}
                  city={city}
                  isSelected={city.locationId === selectedCityId}
                  isFaded={selectedCityId !== null && city.locationId !== selectedCityId}
                  onClick={handleCityClick}
                />
              ))}
            </>
          )}
          
          {/* Routes View */}
          {viewMode === 'routes' && (
            <RouteArrows
              allCities={cities}
              selectedRouteKey={selectedRouteKey}
              onRouteClick={handleRouteClick}
            />
          )}
        </MapContainer>
        
        {/* Empty State Overlay */}
        {cities.size === 0 && !isEmptyStateDismissed && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none z-[1000]">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl p-8 text-center max-w-md pointer-events-auto border-2 border-gray-200 dark:border-gray-700 relative">
              {/* Close Button */}
              <button
                onClick={() => setIsEmptyStateDismissed(true)}
                className="absolute top-3 right-3 p-1 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors theme-muted hover:theme-text"
                title={t('common.close', 'Close')}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
              
              <div className="text-6xl mb-4">🗺️</div>
              <h3 className="text-xl font-bold theme-text mb-2">
                {t('map.noData.title', 'No Data to Display')}
              </h3>
              <p className="theme-muted text-sm mb-4">
                {t('map.noData.message', 'No active trips match your current filters. Try adjusting the filters or refresh the data.')}
              </p>
              <div className="flex gap-2 justify-center">
                <button
                  onClick={() => setIsFilterPanelOpen(true)}
                  className="px-4 py-2 bg-gray-200 dark:bg-gray-700 theme-text rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors flex items-center gap-2"
                >
                  <FilterIcon className="w-4 h-4" />
                  {t('map.filters.adjust', 'Adjust Filters')}
                </button>
                <button
                  onClick={loadData}
                  className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors flex items-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  {t('map.refresh', 'Refresh')}
                </button>
              </div>
            </div>
          </div>
        )}
        
        {/* Legend */}
        <MapLegend
          isOpen={isLegendOpen}
          onToggle={() => setIsLegendOpen(!isLegendOpen)}
        />
        
        {/* Filters Panel */}
        <MapFilters
          filters={filters}
          isOpen={isFilterPanelOpen}
          onChange={handleFilterChange}
          onApply={handleFilterApply}
          onReset={handleFilterReset}
          onClose={() => setIsFilterPanelOpen(false)}
        />
        
        {/* Connections Panel (Cities View) */}
        {viewMode === 'cities' && (
          <ConnectionsPanel
            city={selectedCity}
            isOpen={selectedCityId !== null}
            onClose={handleMapClick}
          />
        )}
        
        {/* Route Details Panel (Routes View) */}
        {viewMode === 'routes' && (
          <RouteDetailsPanel
            routeKey={selectedRouteKey}
            allCities={cities}
            isOpen={selectedRouteKey !== null}
            onClose={handleMapClick}
          />
        )}
      </div>
    </div>
  );
}
