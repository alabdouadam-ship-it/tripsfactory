'use client';

import { useState } from 'react';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { Search, Loader2 } from 'lucide-react';
import { GeographyConfig } from '@/lib/geographyConfig';

// Fix for default marker icon
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

type CoordinatePickerMapProps = {
  initialLat: number | null;
  initialLng: number | null;
  onCoordinateSelect: (lat: number, lng: number, locationData?: {
    country?: string;
    state?: string;
    city?: string;
    countryCode?: string;
  }) => void;
};

type SearchResult = {
  display_name: string;
  lat: string;
  lon: string;
  address: {
    country?: string;
    state?: string;
    province?: string;
    city?: string;
    town?: string;
    village?: string;
    country_code?: string;
  };
};

function MapClickHandler({ onCoordinateSelect }: { onCoordinateSelect: (lat: number, lng: number) => void }) {
  useMapEvents({
    click: (e) => {
      onCoordinateSelect(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export default function CoordinatePickerMap({ initialLat, initialLng, onCoordinateSelect }: CoordinatePickerMapProps) {
  const [position, setPosition] = useState<[number, number] | null>(
    initialLat !== null && initialLng !== null ? [initialLat, initialLng] : null
  );
  const [isGeocoding, setIsGeocoding] = useState(false);
  const [locationInfo, setLocationInfo] = useState<string | null>(null);
  
  // Search state
  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [showResults, setShowResults] = useState(false);
  const [mapKey, setMapKey] = useState(0); // Force map re-center

  // Default center: the configured home country, or the chosen position.
  const center: [number, number] = position || GeographyConfig.defaultMapCenter;
  const zoom = position ? 13 : 6;

  const handleClick = async (lat: number, lng: number) => {
    setPosition([lat, lng]);
    setLocationInfo(null);
    setIsGeocoding(true);
    
    let geocodedData: {
      country?: string;
      state?: string;
      city?: string;
      countryCode?: string;
    } | undefined;
    
    try {
      // Reverse geocoding using Nominatim (OpenStreetMap)
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&accept-language=en`,
        {
          headers: {
            'User-Agent': 'TripsFactoryAdmin/1.0' // Required by Nominatim
          }
        }
      );
      
      if (response.ok) {
        const data = await response.json();
        const address = data.address || {};
        
        // Extract location information
        const country = address.country || '';
        const state = address.state || address.province || '';
        const city = address.city || address.town || address.village || '';
        const countryCode = address.country_code?.toUpperCase() || '';
        
        geocodedData = {
          country,
          state,
          city,
          countryCode
        };
        
        setLocationInfo(`${city}${city && state ? ', ' : ''}${state}${(city || state) && country ? ', ' : ''}${country}`);
      }
    } catch (error) {
      console.error('Geocoding failed:', error);
    } finally {
      setIsGeocoding(false);
    }
    
    onCoordinateSelect(lat, lng, geocodedData);
  };
  
  const handleSearch = async () => {
    if (!searchQuery.trim()) return;
    
    setIsSearching(true);
    setShowResults(false);
    
    try {
      // Forward geocoding using Nominatim
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=5&addressdetails=1`,
        {
          headers: {
            'User-Agent': 'TripsFactoryAdmin/1.0'
          }
        }
      );
      
      if (response.ok) {
        const data: SearchResult[] = await response.json();
        setSearchResults(data);
        setShowResults(data.length > 0);
      }
    } catch (error) {
      console.error('Search failed:', error);
    } finally {
      setIsSearching(false);
    }
  };
  
  const handleSelectResult = (result: SearchResult) => {
    const lat = parseFloat(result.lat);
    const lon = parseFloat(result.lon);
    
    setPosition([lat, lon]);
    setSearchQuery('');
    setShowResults(false);
    setSearchResults([]);
    setMapKey(prev => prev + 1); // Force map to re-center
    
    // Extract location data
    const address = result.address || {};
    const geocodedData = {
      country: address.country || '',
      state: address.state || address.province || '',
      city: address.city || address.town || address.village || '',
      countryCode: address.country_code?.toUpperCase() || ''
    };
    
    setLocationInfo(result.display_name);
    onCoordinateSelect(lat, lon, geocodedData);
  };

  return (
    <div className="h-full w-full relative flex flex-col">
      {/* Search Bar */}
      <div className="absolute top-4 left-4 right-4 z-[1000]">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-2 p-3">
            <Search className="w-5 h-5 text-gray-400 flex-shrink-0" />
            <input
              type="text"
              placeholder="Search for a city (e.g., Beijing, Shanghai, Damascus)..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleSearch();
                if (e.key === 'Escape') {
                  setSearchQuery('');
                  setShowResults(false);
                }
              }}
              className="flex-1 bg-transparent border-none outline-none text-sm text-gray-900 dark:text-gray-100 placeholder-gray-400"
            />
            <button
              onClick={handleSearch}
              disabled={isSearching || !searchQuery.trim()}
              className="px-4 py-1.5 bg-blue-600 text-white rounded text-sm font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {isSearching ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Searching...
                </>
              ) : (
                'Search'
              )}
            </button>
          </div>
          
          {/* Search Results */}
          {showResults && searchResults.length > 0 && (
            <div className="border-t border-gray-200 dark:border-gray-700 max-h-60 overflow-y-auto">
              {searchResults.map((result, index) => (
                <button
                  key={index}
                  onClick={() => handleSelectResult(result)}
                  className="w-full text-left px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700 last:border-b-0 transition-colors"
                >
                  <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                    {result.display_name}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                    📍 {result.lat}, {result.lon}
                  </p>
                </button>
              ))}
            </div>
          )}
          
          {showResults && searchResults.length === 0 && (
            <div className="border-t border-gray-200 dark:border-gray-700 px-4 py-3">
              <p className="text-sm text-gray-500 dark:text-gray-400">
                No results found. Try a different search term.
              </p>
            </div>
          )}
        </div>
      </div>
      
      {/* Map */}
      <MapContainer
        key={mapKey}
        center={center}
        zoom={zoom}
        className="h-full w-full"
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <MapClickHandler onCoordinateSelect={handleClick} />
        {position && <Marker position={position} />}
      </MapContainer>
      
      {/* Coordinate Display */}
      {position && (
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-[1000] bg-white dark:bg-gray-800 px-4 py-2 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 max-w-md">
          <p className="text-sm font-mono font-bold text-gray-900 dark:text-gray-100 text-center">
            {position[0].toFixed(6)}, {position[1].toFixed(6)}
          </p>
          {isGeocoding && (
            <p className="text-xs text-gray-500 dark:text-gray-400 text-center mt-1">
              Loading location info...
            </p>
          )}
          {locationInfo && !isGeocoding && (
            <p className="text-xs text-gray-600 dark:text-gray-300 text-center mt-1">
              📍 {locationInfo}
            </p>
          )}
        </div>
      )}
      
      {/* Instructions */}
      <div className="absolute top-24 left-1/2 -translate-x-1/2 z-[999] bg-blue-600 text-white px-4 py-2 rounded-lg shadow-lg text-sm font-bold max-w-md text-center">
        Search for a city above or click anywhere on the map
      </div>
    </div>
  );
}
