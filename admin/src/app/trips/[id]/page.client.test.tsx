import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import TripDetailPage from './page.client';

const {
  mockPush,
  mockToast,
  mockConfirm,
  mockFrom,
  selectCalls,
  state,
} = vi.hoisted(() => {
  const selectCalls: Array<{ table: string; columns: string }> = [];
  const state = {
    tripError: null as any,
    bookingsError: null as any,
    trip: {
      id: 'trip-12345678',
      status: 'available',
      created_at: '2026-05-01T10:00:00.000Z',
      departure_time: '2026-05-07T10:00:00.000Z',
      max_weight_kg: 40,
      current_load_kg: 5,
      suggested_price_per_kg: null,
      suggested_flat_price: 100,
      profile: {
        id: 'driver-1',
        full_name: 'Driver User',
        is_driver: true,
        is_suspended: false,
      },
      origin: {
        country_code: 'AE',
        city_name_en: 'Dubai',
        province_name_en: 'Dubai',
      },
      dest: {
        country_code: 'JO',
        city_name_en: 'Amman',
        province_name_en: 'Amman',
      },
    },
    bookings: [{
      id: '12345678-abcd',
      trip_id: 'trip-12345678',
      status: 'accepted',
      offer_price: 120,
      created_at: '2026-05-02T10:00:00.000Z',
      requester_profile: {
        id: 'requester-1',
        full_name: 'Sender User',
      },
      driver_profile: {
        id: 'driver-1',
        full_name: 'Driver User',
        is_driver: true,
      },
    }],
  };

  const makeTripQuery = () => ({
    eq: vi.fn(() => ({
      single: vi.fn(() => Promise.resolve({ data: state.trip, error: state.tripError })),
    })),
  });

  const makeBookingsQuery = () => ({
    eq: vi.fn(() => ({
      order: vi.fn(() => Promise.resolve({ data: state.bookings, error: state.bookingsError })),
    })),
  });

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns: string) => {
      selectCalls.push({ table, columns });
      if (table === 'trips') return makeTripQuery();
      if (table === 'bookings') return makeBookingsQuery();
      return {
        eq: vi.fn(function (this: unknown) { return this; }),
        order: vi.fn(() => Promise.resolve({ data: [], error: null })),
      };
    }),
    update: vi.fn(() => ({
      in: vi.fn(() => Promise.resolve({ error: null })),
      eq: vi.fn(() => Promise.resolve({ error: null })),
    })),
  }));

  return {
    mockPush: vi.fn(),
    mockToast: vi.fn(),
    mockConfirm: vi.fn(),
    mockFrom,
    selectCalls,
    state,
  };
});

vi.mock('next/navigation', () => ({
  useParams: () => ({ id: 'trip-12345678' }),
  usePathname: () => '/trips/trip-12345678',
  useRouter: () => ({ push: mockPush }),
}));

vi.mock('next/link', () => ({
  default: ({ href, children, ...props }: React.AnchorHTMLAttributes<HTMLAnchorElement> & { href: string }) => (
    <a href={href} {...props}>{children}</a>
  ),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast, confirm: mockConfirm }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/lib/export-dynamic-route', () => ({
  resolveExportedDynamicRouteId: () => 'trip-12345678',
}));

vi.mock('@/app/actions/operational-actions', () => ({
  forceTripStatus: vi.fn(() => Promise.resolve({ success: true })),
}));

vi.mock('@/app/actions/trip-actions', () => ({
  approveTrip: vi.fn(() => Promise.resolve({ success: true })),
  rejectTrip: vi.fn(() => Promise.resolve({ success: true })),
  cancelTripAdmin: vi.fn(() => Promise.resolve({ success: true })),
  reopenTripAdmin: vi.fn(() => Promise.resolve({ success: true })),
}));

vi.mock('@/components/TripEditModal', () => ({
  TripEditModal: () => null,
}));

describe('TripDetailPage', () => {
  beforeEach(() => {
    mockFrom.mockClear();
    mockToast.mockClear();
    selectCalls.length = 0;
    state.tripError = null;
    state.bookingsError = null;
  });

  it('shows trip bookings with links to booking, requester, and traveler profiles', async () => {
    render(<TripDetailPage />);

    const bookingLink = await screen.findByRole('link', { name: '#12345678' });
    expect(bookingLink).toHaveAttribute('href', '/bookings/12345678-abcd');
    expect(screen.getByRole('link', { name: 'Sender User' })).toHaveAttribute('href', '/users/requester-1');
    expect(screen.getAllByRole('link', { name: 'Driver User' })[0]).toHaveAttribute('href', '/users/driver-1');
    expect(screen.getByText('external')).toBeInTheDocument();
    expect(screen.getByText(/Bookings/)).toBeInTheDocument();

    const bookingSelect = selectCalls.find((call) => call.table === 'bookings')?.columns ?? '';
    expect(bookingSelect).toContain('requester_profile');
    expect(bookingSelect).toContain('driver_profile');
    expect(bookingSelect).not.toContain('shipments');
  });

  it('shows a retryable bookings error instead of an empty state', async () => {
    state.bookingsError = { message: 'RLS blocked' };

    render(<TripDetailPage />);

    await waitFor(() => {
      expect(screen.getByText('Failed to load trip bookings.')).toBeInTheDocument();
    });
    expect(screen.getByRole('button', { name: 'Retry' })).toBeInTheDocument();
    expect(screen.queryByText('No bookings for this trip yet')).not.toBeInTheDocument();
  });
});
