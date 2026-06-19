import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import ShipmentsPage from './page';

const {
  mockPush,
  mockToast,
  mockConfirm,
  mockFrom,
  mockEq,
  mockIn,
  mockSearchParams,
  mockDeleteShipment,
  state,
} = vi.hoisted(() => {
  const state = {
    shipments: [{
      id: 'shipment-12345678',
      status: 'accepted',
      price: 90,
      weight_kg: 12,
      created_at: '2026-05-01T10:00:00.000Z',
      profile: { full_name: 'Sender One' },
      pickup: { city_name_en: 'Damascus' },
      dropoff: { city_name_en: 'Aleppo' },
    }],
    offers: [{
      id: 'offer-12345678',
      shipment_id: 'shipment-12345678',
      driver_id: 'driver-1',
      price: 120,
      status: 'accepted',
      driver_profile: { full_name: 'Driver One' },
    }],
  };
  const mockEq = vi.fn();
  const mockIn = vi.fn();

  const makeShipmentsQuery = () => {
    const query: any = {
      eq: vi.fn((column: string, value: any) => {
        mockEq(column, value);
        return query;
      }),
      gte: vi.fn(() => query),
      lte: vi.fn(() => query),
      order: vi.fn(() => query),
      range: vi.fn(() => Promise.resolve({ data: state.shipments, count: state.shipments.length, error: null })),
    };
    return query;
  };

  const makeOffersQuery = () => {
    const query: any = {
      in: vi.fn((column: string, values: string[]) => {
        mockIn(column, values);
        return Promise.resolve({ data: state.offers, error: null });
      }),
    };
    return query;
  };

  return {
    mockPush: vi.fn(),
    mockToast: vi.fn(),
    mockConfirm: vi.fn(({ onConfirm }) => onConfirm?.()),
    mockFrom: vi.fn((table: string) => ({
      select: vi.fn(() => {
        if (table === 'shipments') return makeShipmentsQuery();
        if (table === 'offers') return makeOffersQuery();
        return makeShipmentsQuery();
      }),
      update: vi.fn(() => ({ eq: vi.fn(() => Promise.resolve({ error: null })) })),
    })),
    mockEq,
    mockIn,
    mockSearchParams: new URLSearchParams('moderation=pending_review'),
    mockDeleteShipment: vi.fn(() => Promise.resolve({ success: true })),
    state,
  };
});

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mockPush }),
  useSearchParams: () => mockSearchParams,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast, confirm: mockConfirm }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => {
    const translations: Record<string, string> = {
      'shipments.status.all': 'All',
      'shipments.status.pending_approval': 'Pending approval',
      'shipments.status.pending': 'Pending',
      'shipments.status.in_communication': 'In communication',
      'shipments.status.accepted': 'Accepted',
      'shipments.status.picked_up': 'Picked up',
      'shipments.status.in_transit': 'In transit',
      'shipments.status.delivered': 'Delivered',
      'shipments.status.completed': 'Completed',
      'shipments.status.cancelled': 'Cancelled',
      'shipments.status.rejected': 'Rejected',
      'shipments.status.expired': 'Expired',
      'shipments.status.frozen': 'Frozen',
      'shipments.status.disputed': 'Disputed',
      'shipments.dialog.deleteShipment.title': 'Delete Shipment',
      'shipments.dialog.deleteShipment.message': 'Delete shipment?',
      'shipments.dialog.deleteShipment.confirmLabel': 'Delete',
      'shipments.toast.shipmentDeleted': 'Shipment deleted',
      'common.viewDetails': 'View Details',
    };
    return translations[key] ?? fallback ?? key;
  },
  useI18n: () => ({ language: 'en' as const }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: vi.fn(() => Promise.resolve()),
}));

vi.mock('@/lib/utils', () => ({
  cn: (...classes: Array<string | false | null | undefined>) => classes.filter(Boolean).join(' '),
  exportToCSV: vi.fn(),
  getCityLabel: vi.fn((loc?: { city_name_en?: string }) => loc?.city_name_en || 'City'),
}));

vi.mock('@/app/actions/shipment-actions', () => ({
  deleteShipment: mockDeleteShipment,
}));

vi.mock('@/components/ShipmentEditModal', () => ({
  ShipmentEditModal: () => null,
}));

vi.mock('@/components/ShipmentModerationModal', () => ({
  ShipmentModerationModal: () => null,
}));

describe('ShipmentsPage', () => {
  beforeEach(() => {
    mockPush.mockClear();
    mockToast.mockClear();
    mockConfirm.mockClear();
    mockFrom.mockClear();
    mockEq.mockClear();
    mockIn.mockClear();
    mockDeleteShipment.mockClear();
  });

  it('initializes pending review moderation from the URL query and loads offer summaries', async () => {
    render(<ShipmentsPage />);

    await waitFor(() => {
      expect(screen.getByText('Shipments Management')).toBeInTheDocument();
    });

    expect(mockEq).toHaveBeenCalledWith('moderation_status', 'pending_review');
    expect(mockIn).toHaveBeenCalledWith('shipment_id', ['shipment-12345678']);
    expect(screen.getByText('1 offer(s)')).toBeInTheDocument();
    expect(screen.getByText('Driver One')).toBeInTheDocument();
    expect(screen.getAllByText('120')[0]).toBeInTheDocument();
  });

  it('renders every shipment status filter used by the admin vocabulary', async () => {
    render(<ShipmentsPage />);

    expect(await screen.findByRole('button', { name: 'Pending approval' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Picked up' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Completed' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Rejected' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Expired' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Frozen' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Disputed' })).toBeInTheDocument();
  });

  it('uses the shipment delete action instead of querying bookings', async () => {
    render(<ShipmentsPage />);

    const deleteButton = await screen.findByTitle('Delete Shipment');
    fireEvent.click(deleteButton);

    await waitFor(() => {
      expect(mockDeleteShipment).toHaveBeenCalledWith('shipment-12345678');
    });
    expect(mockFrom).not.toHaveBeenCalledWith('bookings');
  });
});
