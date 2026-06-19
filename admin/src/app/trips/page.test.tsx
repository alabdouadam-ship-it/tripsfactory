import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import TripsPage from './page';

const { state, mockPush, mockToast, mockConfirm, mockFrom, mockSelect, mockOrder, mockRange } = vi.hoisted(() => {
  const state = { trips: [] as any[] };
  const mockRange = vi.fn(() => Promise.resolve({ data: state.trips, count: state.trips.length, error: null }));
  const mockOrder = vi.fn(() => ({ range: mockRange }));
  const chain = () => ({
    eq: vi.fn(function (this: unknown) { return this; }),
    gte: vi.fn(function (this: unknown) { return this; }),
    lte: vi.fn(function (this: unknown) { return this; }),
    lt: vi.fn(function (this: unknown) { return this; }),
    in: vi.fn(function (this: unknown) { return this; }),
    not: vi.fn(function (this: unknown) { return this; }),
    is: vi.fn(function (this: unknown) { return this; }),
    or: vi.fn(function (this: unknown) { return this; }),
    order: mockOrder,
  });
  const mockSelect = vi.fn(() => chain());
  const mockFrom = vi.fn(() => ({ select: mockSelect }));
  return {
    state,
    mockPush: vi.fn(),
    mockToast: vi.fn(),
    mockConfirm: vi.fn(),
    mockFrom,
    mockSelect,
    mockOrder,
    mockRange,
  };
});

vi.mock('next/navigation', () => ({
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
  useI18n: () => ({ language: 'en' as const }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: vi.fn(() => Promise.resolve()),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/app/actions/trip-actions', () => ({
  cancelTripAdmin: vi.fn(() => Promise.resolve({ success: true })),
}));

describe('TripsPage', () => {
  beforeEach(() => {
    state.trips = [];
    mockFrom.mockClear();
    mockSelect.mockClear();
    mockOrder.mockClear();
    mockRange.mockClear();
  });

  it('renders page title and loads empty list (smoke)', async () => {
    render(<TripsPage />);
    await waitFor(() => {
      expect(screen.getByText('Trips & Routes')).toBeInTheDocument();
    }, { timeout: 3000 });
    expect(screen.getByText(/Total/)).toBeInTheDocument();
  });

  it('shows trip route and traveler badges with a clickable traveler name', async () => {
    state.trips = [{
      id: 'trip-1',
      traveler_id: 'driver-1',
      origin_location_id: 'loc-sy',
      dest_location_id: 'loc-lb',
      max_weight_kg: 50,
      current_load_kg: 10,
      suggested_price_per_kg: null,
      suggested_flat_price: 75,
      departure_time: '2026-05-07T10:00:00.000Z',
      status: 'available',
      created_at: '2026-05-01T10:00:00.000Z',
      profile: { id: 'driver-1', full_name: 'Alice Driver', is_driver: true },
      origin: { country_code: 'AE', city_name_en: 'Dubai' },
      dest: { country_code: 'LB', city_name_en: 'Beirut' },
    }];

    render(<TripsPage />);

    const driverLink = await screen.findByRole('link', { name: 'Alice Driver' });
    expect(driverLink).toHaveAttribute('href', '/users/driver-1');
    expect(screen.getByText('Driver')).toBeInTheDocument();
    expect(screen.getByText('external')).toBeInTheDocument();
    expect(screen.getByText('10 / 50 KG')).toBeInTheDocument();
  });
});
