import Link from 'next/link';
import { useI18n } from '@/lib/i18n';
import type { Trip } from '@/lib/types';
import { ArrowRight, ArrowLeft, Truck, ExternalLink } from 'lucide-react';

// ============================================================================
// Types
// ============================================================================

type ConnectionListItemProps = {
  item: Trip;
  type: 'trip';
  direction: 'outgoing' | 'incoming';
};

// ============================================================================
// Helper Functions
// ============================================================================

function getStatusColor(status: string): string {
  const statusColors: Record<string, string> = {
    // Trip statuses
    'available': 'bg-green-100 text-green-800 border-green-200',
    'booked': 'bg-blue-100 text-blue-800 border-blue-200',
    'in_transit': 'bg-purple-100 text-purple-800 border-purple-200',
    'completed': 'bg-gray-100 text-gray-800 border-gray-200',
    'cancelled': 'bg-red-100 text-red-800 border-red-200',
    'pending_approval': 'bg-yellow-100 text-yellow-800 border-yellow-200',
    'in_communication': 'bg-orange-100 text-orange-800 border-orange-200',
    'pending_confirmation': 'bg-yellow-100 text-yellow-800 border-yellow-200',
    'full': 'bg-gray-100 text-gray-800 border-gray-200',
  };

  return statusColors[status] || 'bg-gray-100 text-gray-800 border-gray-200';
}

function formatStatus(status: string): string {
  return status
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

// ============================================================================
// Component
// ============================================================================

export function ConnectionListItem({ item, direction }: ConnectionListItemProps) {
  const { language } = useI18n();

  const trip = item;

  // Choose location name based on admin language
  const locationNameEn = direction === 'outgoing'
    ? trip.dest?.city_name_en || 'Unknown'
    : trip.origin?.city_name_en || 'Unknown';
  const locationNameAr = direction === 'outgoing'
    ? trip.dest?.city_name_ar || 'غير معروف'
    : trip.origin?.city_name_ar || 'غير معروف';

  const displayName = language === 'ar' ? locationNameAr : locationNameEn;
  const secondaryName = language === 'ar' ? locationNameEn : locationNameAr;

  return (
    <Link
      href={`/trips/${trip.id}`}
      className="block p-3 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors border-b border-gray-100 dark:border-gray-700 last:border-b-0"
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          {/* Direction and Location */}
          <div className="flex items-center gap-2 mb-2">
            {direction === 'outgoing' ? (
              <ArrowRight className="w-4 h-4 text-orange-500 flex-shrink-0" />
            ) : (
              <ArrowLeft className="w-4 h-4 text-orange-500 flex-shrink-0" />
            )}
            <span className="font-medium theme-text truncate">
              {displayName}
            </span>
            <span className="text-xs theme-muted truncate">
              {secondaryName}
            </span>
          </div>

          {/* Status Badge */}
          <div className="flex items-center gap-2 mb-2">
            <span className={`text-xs px-2 py-1 rounded-full border ${getStatusColor(trip.status)}`}>
              {formatStatus(trip.status)}
            </span>
            <Truck className="w-3 h-3 theme-muted" />
          </div>

          {/* Details */}
          <div className="flex items-center gap-3 text-xs theme-muted">
            {trip.max_weight_kg && (
              <span>📦 {trip.max_weight_kg}kg</span>
            )}
            {trip.profile?.full_name && (
              <span className="truncate">👤 {trip.profile.full_name}</span>
            )}
          </div>
        </div>

        {/* View Details Icon */}
        <ExternalLink className="w-4 h-4 theme-muted flex-shrink-0 mt-1" />
      </div>
    </Link>
  );
}
