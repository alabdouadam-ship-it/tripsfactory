import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import BookingDetailPage from './page.client';

const mocks = vi.hoisted(() => {
  const state = {
    bookingError: null as any,
    messagesError: null as any,
    messages: [] as any[],
    booking: {
      id: 'booking-12345678',
      trip_id: 'trip-1',
      traveler_id: 'traveler-1',
      requester_id: 'requester-1',
      price: 180,
      status: 'accepted',
      created_at: '2026-05-01T10:00:00.000Z',
      driver_profile: {
        id: 'traveler-1',
        full_name: 'Traveler One',
        phone_number: '+9631',
        is_suspended: false,
      },
      requester_profile: {
        id: 'requester-1',
        full_name: 'Requester One',
        phone_number: '+9632',
        is_suspended: false,
      },
      trips: {
        id: 'trip-1',
        status: 'available',
        origin: { city_name_en: 'Damascus' },
        dest: { city_name_en: 'Aleppo' },
        driver: { id: 'traveler-1', full_name: 'Traveler One' },
      },
    },
  };
  const selectCalls: Array<{ table: string; columns: string }> = [];

  return {
    state,
    selectCalls,
    mockPush: vi.fn(),
    mockToast: vi.fn(),
    mockConfirm: vi.fn(),
    mockFrom: vi.fn((table: string) => ({
      select: vi.fn((columns: string) => {
        selectCalls.push({ table, columns });
        if (table === 'bookings') {
          return {
            eq: vi.fn(() => ({
              single: vi.fn(() => Promise.resolve({ data: state.booking, error: state.bookingError })),
            })),
          };
        }
        if (table === 'messages') {
          return {
            eq: vi.fn(() => ({
              order: vi.fn(() => Promise.resolve({ data: state.messages, error: state.messagesError })),
            })),
          };
        }
        return {};
      }),
    })),
  };
});

vi.mock('next/navigation', () => ({
  useParams: () => ({ id: 'booking-12345678' }),
  usePathname: () => '/bookings/booking-12345678',
  useRouter: () => ({ push: mocks.mockPush }),
}));

vi.mock('next/link', () => ({
  default: ({ href, children, ...props }: React.AnchorHTMLAttributes<HTMLAnchorElement> & { href: string }) => (
    <a href={href} {...props}>{children}</a>
  ),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast, confirm: mocks.mockConfirm }),
}));

vi.mock('@/lib/i18n', () => {
  const t = (key: string, fallback?: string) => fallback ?? key;
  return {
    useT: () => t,
    useI18n: () => ({
      t,
      language: 'en' as const,
      dir: 'ltr' as const,
    }),
  };
});

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mocks.mockFrom },
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: vi.fn(() => Promise.resolve()),
}));

vi.mock('@/lib/export-dynamic-route', () => ({
  resolveExportedDynamicRouteId: () => 'booking-12345678',
}));

vi.mock('@/app/actions/operational-actions', () => ({
  forceBookingStatus: vi.fn(() => Promise.resolve({ success: true })),
  toggleBookingFreeze: vi.fn(() => Promise.resolve({ success: true })),
  setBookingEscalation: vi.fn(() => Promise.resolve({ success: true })),
  forcePaymentRelease: vi.fn(() => Promise.resolve({ success: true })),
  forceRefund: vi.fn(() => Promise.resolve({ success: true })),
}));

vi.mock('@/app/actions/governance-actions', () => ({
  resolveBookingDispute: vi.fn(() => Promise.resolve({ success: true })),
}));

describe('BookingDetailPage', () => {
  beforeEach(() => {
    mocks.mockFrom.mockClear();
    mocks.mockPush.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockConfirm.mockClear();
    mocks.selectCalls.length = 0;
    mocks.state.bookingError = null;
    mocks.state.messagesError = null;
  });

  it('loads the requester profile through the profiles FK and keeps bookings trip-only', async () => {
    render(<BookingDetailPage />);

    expect(await screen.findByText('Traveler / Driver')).toBeInTheDocument();
    expect(screen.getByText('Reservation Price')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Traveler One' })).toHaveAttribute('href', '/users/traveler-1');
    expect(screen.getByRole('link', { name: 'Requester One' })).toHaveAttribute('href', '/users/requester-1');
    expect(screen.getByRole('link', { name: /Damascus -> Aleppo/ })).toHaveAttribute('href', '/trips/trip-1');

    const bookingSelect = mocks.selectCalls.find((call) => call.table === 'bookings')?.columns ?? '';
    expect(bookingSelect).toContain('requester_profile:profiles!bookings_requester_id_profiles_fkey');
    expect(bookingSelect).not.toContain('requester_profile:profiles!bookings_requester_id_fkey');
  });
});
