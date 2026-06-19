import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import ShipmentDetailPage from './page.client';

const mocks = vi.hoisted(() => {
  const state = {
    shipment: {
      id: 'shipment-12345678',
      status: 'delivered',
      created_at: '2026-05-01T10:00:00.000Z',
      pickup_date: '2026-05-03T10:00:00.000Z',
      weight_kg: 10,
      price: 90,
      transport_type: 'external',
      volume_type: 'box',
      goods_received_by_driver_at: '2026-05-02T10:00:00.000Z',
      goods_delivered_by_driver_at: '2026-05-04T10:00:00.000Z',
      sender: { id: 'sender-1', full_name: 'Sender One', is_suspended: false },
      pickup: { city_name_en: 'Damascus', province_name_en: 'Damascus' },
      dropoff: { city_name_en: 'Aleppo', province_name_en: 'Aleppo' },
    },
    offers: [
      {
        id: 'offer-accepted',
        shipment_id: 'shipment-12345678',
        driver_id: 'driver-1',
        status: 'accepted',
        price: 125,
        created_at: '2026-05-01T11:00:00.000Z',
        updated_at: '2026-05-01T12:00:00.000Z',
        driver_profile: { id: 'driver-1', full_name: 'Driver One', is_driver: true },
      },
      {
        id: 'offer-rejected',
        shipment_id: 'shipment-12345678',
        driver_id: 'traveler-1',
        status: 'rejected',
        price: 115,
        rejection_reason: 'other_offer_accepted',
        created_at: '2026-05-01T10:30:00.000Z',
        updated_at: '2026-05-01T12:00:00.000Z',
        driver_profile: { id: 'traveler-1', full_name: 'Traveler One', is_driver: false },
      },
    ],
    messages: [{ id: 'message-1', sender_id: 'driver-1', content: 'Hello', type: 'text', created_at: '2026-05-01T12:30:00.000Z', sender: { full_name: 'Driver One' } }],
  };
  const selectCalls: Array<{ table: string; columns: string }> = [];
  const eqCalls: Array<{ table: string; column: string; value: string }> = [];

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns: string) => {
      selectCalls.push({ table, columns });
      if (table === 'shipments') {
        return {
          eq: vi.fn((column: string, value: string) => {
            eqCalls.push({ table, column, value });
            return {
              single: vi.fn(() => Promise.resolve({ data: state.shipment, error: null })),
            };
          }),
        };
      }
      if (table === 'offers') {
        return {
          eq: vi.fn((column: string, value: string) => {
            eqCalls.push({ table, column, value });
            return {
              order: vi.fn(() => Promise.resolve({ data: state.offers, error: null })),
            };
          }),
        };
      }
      if (table === 'messages') {
        return {
          eq: vi.fn((column: string, value: string) => {
            eqCalls.push({ table, column, value });
            return {
              order: vi.fn(() => Promise.resolve({ data: state.messages, error: null })),
            };
          }),
        };
      }
      return {};
    }),
  }));

  return {
    state,
    selectCalls,
    eqCalls,
    mockFrom,
    mockPush: vi.fn(),
    mockToast: vi.fn(),
    mockConfirm: vi.fn(),
  };
});

vi.mock('next/navigation', () => ({
  useParams: () => ({ id: 'shipment-12345678' }),
  usePathname: () => '/shipments/shipment-12345678',
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

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mocks.mockFrom },
}));

vi.mock('@/lib/export-dynamic-route', () => ({
  resolveExportedDynamicRouteId: () => 'shipment-12345678',
}));

vi.mock('@/app/actions/shipment-actions', () => ({
  approveShipment: vi.fn(() => Promise.resolve({ success: true })),
  rejectShipment: vi.fn(() => Promise.resolve({ success: true })),
  cancelShipmentAdmin: vi.fn(() => Promise.resolve({ success: true })),
  reopenShipmentAdmin: vi.fn(() => Promise.resolve({ success: true })),
}));

describe('ShipmentDetailPage', () => {
  beforeEach(() => {
    mocks.mockFrom.mockClear();
    mocks.mockPush.mockClear();
    mocks.mockToast.mockClear();
    mocks.selectCalls.length = 0;
    mocks.eqCalls.length = 0;
  });

  it('loads shipment offers instead of bookings and shows accepted-offer progress', async () => {
    render(<ShipmentDetailPage />);

    expect(await screen.findByText('Offers')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Driver One' })).toHaveAttribute('href', '/users/driver-1');
    expect(screen.getByRole('link', { name: 'Traveler One' })).toHaveAttribute('href', '/users/traveler-1');
    expect(screen.getByText('Rejected: another offer accepted')).toBeInTheDocument();
    expect(screen.getByText('Shipment progress')).toBeInTheDocument();
    expect(screen.getAllByText('Accepted').length).toBeGreaterThan(0);
    expect(screen.getByText('In transit')).toBeInTheDocument();
    expect(screen.getByText('Delivered')).toBeInTheDocument();

    expect(mocks.selectCalls.some((call) => call.table === 'offers')).toBe(true);
    expect(mocks.selectCalls.some((call) => call.table === 'bookings')).toBe(false);
    expect(mocks.eqCalls).toContainEqual({ table: 'offers', column: 'shipment_id', value: 'shipment-12345678' });
  });

  it('loads communications by offer_id', async () => {
    render(<ShipmentDetailPage />);

    const buttons = await screen.findAllByRole('button', { name: /Communications/ });
    fireEvent.click(buttons[0]);

    await waitFor(() => {
      expect(screen.getByText('Hello')).toBeInTheDocument();
    });
    expect(mocks.eqCalls).toContainEqual({ table: 'messages', column: 'offer_id', value: 'offer-accepted' });
  });
});
