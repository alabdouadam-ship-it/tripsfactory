import { useState } from 'react';
import { useT } from '@/lib/i18n';
import type { CityNode, SearchState } from './mapDataUtils';
import { Search, X } from 'lucide-react';

// ============================================================================
// Types
// ============================================================================

type RouteSearchProps = {
  cities: Map<string, CityNode>;
  searchState: SearchState;
  onChange: (search: SearchState) => void;
  onSearch: () => void;
  onClear: () => void;
};

// ============================================================================
// Component
// ============================================================================

export function RouteSearch({
  cities,
  searchState,
  onChange,
  onSearch,
  onClear,
}: RouteSearchProps) {
  const t = useT();
  const [isMobile, setIsMobile] = useState(false);
  
  // Convert cities map to sorted array
  const cityOptions = Array.from(cities.values()).sort((a, b) =>
    a.cityName.localeCompare(b.cityName)
  );
  
  const handleFromChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange({
      ...searchState,
      from: e.target.value || null,
    });
  };
  
  const handleToChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange({
      ...searchState,
      to: e.target.value || null,
    });
  };
  
  const handleClear = () => {
    onChange({ from: null, to: null });
    onClear();
  };
  
  const hasSearch = searchState.from || searchState.to;
  
  return (
    <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 w-full">
      {/* From Dropdown */}
      <div className="flex-1 min-w-0">
        <label htmlFor="from-city" className="sr-only">
          {t('map.search.from', 'From')}
        </label>
        <select
          id="from-city"
          value={searchState.from || ''}
          onChange={handleFromChange}
          className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg theme-bg theme-text focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="">
            {t('map.search.fromPlaceholder', '📍 From: All Cities')}
          </option>
          {cityOptions.map(city => (
            <option key={city.locationId} value={city.locationId}>
              {city.cityName} ({city.cityNameAr}) - {city.totalConnections}
            </option>
          ))}
        </select>
      </div>
      
      {/* To Dropdown */}
      <div className="flex-1 min-w-0">
        <label htmlFor="to-city" className="sr-only">
          {t('map.search.to', 'To')}
        </label>
        <select
          id="to-city"
          value={searchState.to || ''}
          onChange={handleToChange}
          className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg theme-bg theme-text focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="">
            {t('map.search.toPlaceholder', '📍 To: All Cities')}
          </option>
          {cityOptions.map(city => (
            <option key={city.locationId} value={city.locationId}>
              {city.cityName} ({city.cityNameAr}) - {city.totalConnections}
            </option>
          ))}
        </select>
      </div>
      
      {/* Search Button */}
      <button
        onClick={onSearch}
        disabled={!hasSearch}
        className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
        title={t('map.search.search', 'Search Routes')}
      >
        <Search className="w-4 h-4" />
        <span className="hidden sm:inline">
          {t('map.search.search', 'Search')}
        </span>
      </button>
      
      {/* Clear Button */}
      {hasSearch && (
        <button
          onClick={handleClear}
          className="px-4 py-2 bg-gray-200 dark:bg-gray-700 theme-text rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors flex items-center justify-center gap-2 whitespace-nowrap"
          title={t('map.search.clear', 'Clear')}
        >
          <X className="w-4 h-4" />
          <span className="hidden sm:inline">
            {t('map.search.clear', 'Clear')}
          </span>
        </button>
      )}
    </div>
  );
}
