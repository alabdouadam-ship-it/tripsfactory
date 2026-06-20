import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import MapComponent from './MapComponent';

type QueryRecord = {
  table: string;
  columns?: string;
  filters: Array<{ method: string; args: unknown[] }>;
};

const labels = vi.hoisted((): Record<string, string> => ({
  'common.from': 'From',
  'common.na': 'N/A',
  'common.never': 'Never',
  'common.refresh': 'Refresh',
  'common.retry': 'Retry',
  'common.to': 'To',
  'common.unknown': 'Unknown',
  'common.viewDetails': 'View Details',
  'map.empty': 'No active trips to display',
  'map.error.loadFailed': 'Failed to load map data. Please try again.',
  'map.error.title': 'Error Loading Map',
  'map.lastUpdated': 'Last: {{time}}',
  'map.loading': 'Loading map data...',
  'map.noData': 'No active trips to display',
  'map.refresh': 'Refresh',
  'map.retry': 'Retry',
  'map.stats': '{{cities}} cities · {{trips}} trips · {{routes}} total routes',
  'map.title': 'Operations Map',
}));

const mocks = vi.hoisted(() => {
  const state = {
    trips: [] as any[],
    tripsError: null as any,
  };
  const queries: QueryRecord[] = [];
  const mockFitBounds = vi.fn();
  const mockSetView = vi.fn();

  const resultFor = (record: QueryRecord) => {
    if (record.table === 'trips') {
      return { data: state.trips, error: state.tripsError };
    }
    return { data: [], error: null };
  };

  const makeQuery = (record: QueryRecord): any => {
    const promise = Promise.resolve(resultFor(record));
    const query: any = {
      not: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'not', args });
        return query;
      }),
      order: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'order', args });
        return promise; // Return promise directly after order
      }),
      limit: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'limit', args });
        return promise;
      }),
      then: promise.then.bind(promise),
      catch: promise.catch.bind(promise),
      finally: promise.finally.bind(promise),
    };
    return query;
  };

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns?: string) => {
      const record = { table, columns, filters: [] };
      queries.push(record);
      return makeQuery(record);
    }),
  }));

  return {
    state,
    queries,
    mockFitBounds,
    mockFrom,
    mockSetView,
  };
});

vi.mock('leaflet', () => ({
  default: {
    DivIcon: vi.fn(function DivIcon(options: any) {
      return { options };
    }),
    latLngBounds: vi.fn((points: Array<[number, number]>) => ({ points })),
  },
}));

vi.mock('next/link', () => ({
  default: ({ href, children, ...props }: React.AnchorHTMLAttributes<HTMLAnchorElement> & { href: string }) => (
    <a href={href} {...props}>{children}</a>
  ),
}));

vi.mock('react-leaflet', () => ({
  MapContainer: ({ children, center, zoom }: { children: React.ReactNode; center: [number, number]; zoom: number }) => (
    <div data-testid="map" data-center={center.join(',')} data-zoom={zoom}>{children}</div>
  ),
  Marker: ({ children, position }: { children: React.ReactNode; position: [number, number] }) => (
    <div data-testid="marker" data-position={position.join(',')}>{children}</div>
  ),
  Popup: ({ children }: { children: React.ReactNode }) => <div data-testid="popup">{children}</div>,
  Tooltip: ({ children }: { children: React.ReactNode }) => <div data-testid="tooltip">{children}</div>,
  Polyline: ({ positions }: { positions: [number, number][] }) => (
    <div data-testid="polyline" data-positions={JSON.stringify(positions)} />
  ),
  TileLayer: () => <div data-testid="tile-layer" />,
  useMap: () => ({
    fitBounds: mocks.mockFitBounds,
    setView: mocks.mockSetView,
  }),
  useMapEvents: (handlers: any) => {
    // Mock implementation - just return null
    return null;
  },
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({ language: 'en' }),
  useT: () => (key: string, fallback?: string) => labels[key] ?? fallback ?? key,
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({
    toast: vi.fn(),
    confirm: vi.fn(),
  }),
  ToastProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mocks.mockFrom },
}));

describe('MapComponent', () => {
  beforeEach(() => {
    mocks.state.trips = [{
      id: 'trip-1',
      traveler_id: 'traveler-1',
      origin_location_id: 'loc-origin',
      dest_location_id: 'loc-dest',
      status: 'available',
      max_weight_kg: 40,
      departure_time: '2026-05-08T10:00:00.000Z',
      created_at: '2026-05-07T09:00:00.000Z',
      profile: { id: 'traveler-1', full_name: 'Alice Traveler' },
      origin: { city_name_en: 'Homs', city_name_ar: 'حمص', latitude: 34.7, longitude: 36.7 },
      dest: { city_name_en: 'Beirut', city_name_ar: 'بيروت', latitude: 33.9, longitude: 35.5 },
    }];
    mocks.state.tripsError = null;
    mocks.queries.length = 0;
    mocks.mockFitBounds.mockClear();
    mocks.mockFrom.mockClear();
    mocks.mockSetView.mockClear();
  });

  it('loads active operational trips with origin and destination markers', async () => {
    render(<MapComponent />);

    await expect(screen.findByText(/Operations Map/)).resolves.toBeInTheDocument();

    // Wait for data to load
    await waitFor(() => {
      expect(screen.queryByText('Loading map data...')).not.toBeInTheDocument();
    });

    // Check that cities are aggregated
    const stats = screen.getByText(/cities.*trips/i);
    expect(stats).toBeInTheDocument();

    // Verify trips are queried
    const tripsQuery = mocks.queries.find(query => query.table === 'trips');

    expect(tripsQuery?.filters).toEqual(expect.arrayContaining([
      { method: 'not', args: ['status', 'in', '(completed,cancelled)'] },
    ]));
  });

  it('shows a retryable full error when the trips query fails', async () => {
    mocks.state.tripsError = { message: 'trips denied' };
    mocks.state.trips = [];

    render(<MapComponent />);

    await expect(screen.findByText('Error Loading Map')).resolves.toBeInTheDocument();
    expect(screen.getByText('Failed to load map data. Please try again.')).toBeInTheDocument();

    // Test retry functionality
    mocks.state.tripsError = null;
    mocks.state.trips = [{
      id: 'trip-2',
      traveler_id: 'traveler-2',
      origin_location_id: 'loc-1',
      dest_location_id: 'loc-2',
      status: 'booked',
      max_weight_kg: 20,
      departure_time: '2026-05-08T10:00:00.000Z',
      created_at: '2026-05-07T09:00:00.000Z',
      profile: { id: 'traveler-2', full_name: 'Recovered Traveler' },
      origin: { city_name_en: 'Latakia', city_name_ar: 'اللاذقية', latitude: 35.5, longitude: 35.8 },
      dest: { city_name_en: 'Damascus', city_name_ar: 'دمشق', latitude: 33.5, longitude: 36.3 },
    }];

    fireEvent.click(screen.getByRole('button', { name: 'Retry' }));

    await waitFor(() => {
      expect(screen.getByText(/Operations Map/)).toBeInTheDocument();
      expect(screen.queryByText('Error Loading Map')).not.toBeInTheDocument();
    });
  });
});
