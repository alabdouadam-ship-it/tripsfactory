import { useState, useEffect } from 'react';
import { useT } from '@/lib/i18n';
import type { FilterState } from './mapDataUtils';
import { X, Filter, RotateCcw } from 'lucide-react';

// ============================================================================
// Types
// ============================================================================

type MapFiltersProps = {
  filters: FilterState;
  isOpen: boolean;
  onChange: (filters: FilterState) => void;
  onApply: () => void;
  onReset: () => void;
  onClose: () => void;
};

// ============================================================================
// Component
// ============================================================================

export function MapFilters({
  filters,
  isOpen,
  onChange,
  onApply,
  onReset,
  onClose,
}: MapFiltersProps) {
  const t = useT();
  const [isMobile, setIsMobile] = useState(false);
  const [localFilters, setLocalFilters] = useState<FilterState>(filters);
  
  // Check if mobile
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);
  
  // Update local filters when prop changes
  useEffect(() => {
    setLocalFilters(filters);
  }, [filters]);
  
  // Handle escape key
  useEffect(() => {
    if (!isOpen) return;
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);
  
  if (!isOpen) return null;
  
  const handleTypeChange = (type: 'trips' | 'shipments') => {
    const newTypes = localFilters.types.includes(type)
      ? localFilters.types.filter(t => t !== type)
      : [...localFilters.types, type];
    setLocalFilters({ ...localFilters, types: newTypes });
  };
  
  const handleStatusChange = (status: string) => {
    const newStatuses = localFilters.statuses.includes(status)
      ? localFilters.statuses.filter(s => s !== status)
      : [...localFilters.statuses, status];
    setLocalFilters({ ...localFilters, statuses: newStatuses });
  };
  
  const handleDateFromChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalFilters({
      ...localFilters,
      dateFrom: e.target.value ? new Date(e.target.value) : null,
    });
  };
  
  const handleDateToChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalFilters({
      ...localFilters,
      dateTo: e.target.value ? new Date(e.target.value) : null,
    });
  };
  
  const handleApply = () => {
    onChange(localFilters);
    onApply();
  };
  
  const handleReset = () => {
    const resetFilters: FilterState = {
      types: ['trips', 'shipments'],
      statuses: [],
      dateFrom: null,
      dateTo: null,
    };
    setLocalFilters(resetFilters);
    onChange(resetFilters);
    onReset();
  };
  
  const tripStatuses = [
    'available',
    'booked',
    'in_transit',
    'pending_approval',
    'in_communication',
  ];
  
  const shipmentStatuses = [
    'pending',
    'accepted',
    'picked_up',
    'in_transit',
    'delivered',
  ];
  
  const allStatuses = [...new Set([...tripStatuses, ...shipmentStatuses])];
  
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
          className="fixed bottom-0 left-0 right-0 bg-white dark:bg-gray-900 rounded-t-2xl shadow-2xl z-[9999] max-h-[70vh] flex flex-col animate-slide-up"
          role="dialog"
          aria-labelledby="filters-title"
        >
          {/* Header */}
          <div className="flex-shrink-0 px-4 py-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between">
              <h2 id="filters-title" className="text-lg font-bold theme-text flex items-center gap-2">
                <Filter className="w-5 h-5" />
                {t('map.filters.title', 'Filters')}
              </h2>
              <button
                onClick={onClose}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
                aria-label={t('map.filters.close', 'Close')}
              >
                <X className="w-5 h-5 theme-text" />
              </button>
            </div>
          </div>
          
          {/* Content */}
          <div className="flex-1 overflow-y-auto p-4 space-y-6">
            {/* Type Filters */}
            <div>
              <h3 className="font-semibold theme-text mb-3">
                {t('map.filters.type', 'Type')}
              </h3>
              <div className="space-y-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={localFilters.types.includes('trips')}
                    onChange={() => handleTypeChange('trips')}
                    className="w-4 h-4 text-blue-500 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="theme-text">{t('map.filters.trips', 'Trips')}</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={localFilters.types.includes('shipments')}
                    onChange={() => handleTypeChange('shipments')}
                    className="w-4 h-4 text-blue-500 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="theme-text">{t('map.filters.shipments', 'Shipments')}</span>
                </label>
              </div>
            </div>
            
            {/* Status Filters */}
            <div>
              <h3 className="font-semibold theme-text mb-3">
                {t('map.filters.status', 'Status')}
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {allStatuses.map(status => (
                  <label key={status} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={localFilters.statuses.includes(status)}
                      onChange={() => handleStatusChange(status)}
                      className="w-4 h-4 text-blue-500 rounded focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="theme-text text-sm capitalize">
                      {status.replace(/_/g, ' ')}
                    </span>
                  </label>
                ))}
              </div>
            </div>
            
            {/* Date Range */}
            <div>
              <h3 className="font-semibold theme-text mb-3">
                {t('map.filters.dateRange', 'Date Range')}
              </h3>
              <div className="space-y-3">
                <div>
                  <label htmlFor="date-from" className="block text-sm theme-muted mb-1">
                    {t('map.filters.from', 'From')}
                  </label>
                  <input
                    id="date-from"
                    type="date"
                    value={localFilters.dateFrom ? localFilters.dateFrom.toISOString().split('T')[0] : ''}
                    onChange={handleDateFromChange}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg theme-bg theme-text focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label htmlFor="date-to" className="block text-sm theme-muted mb-1">
                    {t('map.filters.to', 'To')}
                  </label>
                  <input
                    id="date-to"
                    type="date"
                    value={localFilters.dateTo ? localFilters.dateTo.toISOString().split('T')[0] : ''}
                    onChange={handleDateToChange}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg theme-bg theme-text focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>
          </div>
          
          {/* Footer */}
          <div className="flex-shrink-0 p-4 border-t border-gray-200 dark:border-gray-700 flex gap-2">
            <button
              onClick={handleReset}
              className="flex-1 px-4 py-2 bg-gray-200 dark:bg-gray-700 theme-text rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors flex items-center justify-center gap-2"
            >
              <RotateCcw className="w-4 h-4" />
              {t('map.filters.reset', 'Reset')}
            </button>
            <button
              onClick={handleApply}
              className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
            >
              {t('map.filters.apply', 'Apply Filters')}
            </button>
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
      className="fixed top-0 left-0 h-full w-[320px] bg-white dark:bg-gray-900 shadow-2xl z-[9999] flex flex-col animate-slide-in-left"
      role="dialog"
      aria-labelledby="filters-title"
    >
      {/* Header */}
      <div className="flex-shrink-0 px-4 py-4 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center justify-between">
          <h2 id="filters-title" className="text-lg font-bold theme-text flex items-center gap-2">
            <Filter className="w-5 h-5" />
            {t('map.filters.title', 'Filters')}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
            aria-label={t('map.filters.close', 'Close')}
          >
            <X className="w-5 h-5 theme-text" />
          </button>
        </div>
      </div>
      
      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        {/* Type Filters */}
        <div>
          <h3 className="font-semibold theme-text mb-3">
            {t('map.filters.type', 'Type')}
          </h3>
          <div className="space-y-2">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={localFilters.types.includes('trips')}
                onChange={() => handleTypeChange('trips')}
                className="w-4 h-4 text-blue-500 rounded focus:ring-2 focus:ring-blue-500"
              />
              <span className="theme-text">{t('map.filters.trips', 'Trips')}</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={localFilters.types.includes('shipments')}
                onChange={() => handleTypeChange('shipments')}
                className="w-4 h-4 text-blue-500 rounded focus:ring-2 focus:ring-blue-500"
              />
              <span className="theme-text">{t('map.filters.shipments', 'Shipments')}</span>
            </label>
          </div>
        </div>
        
        {/* Status Filters */}
        <div>
          <h3 className="font-semibold theme-text mb-3">
            {t('map.filters.status', 'Status')}
          </h3>
          <div className="space-y-2">
            {allStatuses.map(status => (
              <label key={status} className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={localFilters.statuses.includes(status)}
                  onChange={() => handleStatusChange(status)}
                  className="w-4 h-4 text-blue-500 rounded focus:ring-2 focus:ring-blue-500"
                />
                <span className="theme-text text-sm capitalize">
                  {status.replace(/_/g, ' ')}
                </span>
              </label>
            ))}
          </div>
        </div>
        
        {/* Date Range */}
        <div>
          <h3 className="font-semibold theme-text mb-3">
            {t('map.filters.dateRange', 'Date Range')}
          </h3>
          <div className="space-y-3">
            <div>
              <label htmlFor="date-from" className="block text-sm theme-muted mb-1">
                {t('map.filters.from', 'From')}
              </label>
              <input
                id="date-from"
                type="date"
                value={localFilters.dateFrom ? localFilters.dateFrom.toISOString().split('T')[0] : ''}
                onChange={handleDateFromChange}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg theme-bg theme-text focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label htmlFor="date-to" className="block text-sm theme-muted mb-1">
                {t('map.filters.to', 'To')}
              </label>
              <input
                id="date-to"
                type="date"
                value={localFilters.dateTo ? localFilters.dateTo.toISOString().split('T')[0] : ''}
                onChange={handleDateToChange}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg theme-bg theme-text focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>
      </div>
      
      {/* Footer */}
      <div className="flex-shrink-0 p-4 border-t border-gray-200 dark:border-gray-700 flex gap-2">
        <button
          onClick={handleReset}
          className="flex-1 px-4 py-2 bg-gray-200 dark:bg-gray-700 theme-text rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors flex items-center justify-center gap-2"
        >
          <RotateCcw className="w-4 h-4" />
          {t('map.filters.reset', 'Reset')}
        </button>
        <button
          onClick={handleApply}
          className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
        >
          {t('map.filters.apply', 'Apply')}
        </button>
      </div>
      
      <style jsx>{`
        @keyframes slide-in-left {
          from { transform: translateX(-100%); }
          to { transform: translateX(0); }
        }
        .animate-slide-in-left {
          animation: slide-in-left 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
