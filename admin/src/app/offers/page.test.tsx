import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import OffersPage from './page';

const {
  mockToast,
  mockFrom,
  state,
  mockT,
  selectCalls,
} = vi.hoisted(() => {
  const state = {
    offers: [] as any[],
    error: null as any,
  };
  const selectCalls: string[] = [];

  const makeOffersQuery = () => {
    const query: any = {
      order: vi.fn(() => query),
      limit: vi.fn(() => Promise.resolve({
        data: state.offers,
        error: state.error,
      })),
    };
    return query;
  };

  return {
    mockToast: vi.fn(),
    mockFrom: vi.fn(() => ({
      select: vi.fn((columns: string) => {
        selectCalls.push(columns);
        return makeOffersQuery();
      }),
    })),
    state,
    mockT: vi.fn((key: string, fallback?: string) => fallback ?? key),
    selectCalls,
  };
});

vi.mock('next/link', () => ({
  default: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => mockT,
  useI18n: () => ({ language: 'en' as const, dir: 'ltr' as const }),
}));

describe('OffersPage', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockFrom.mockClear();
    mockT.mockClear();
    selectCalls.length = 0;
    state.offers = [];
    state.error = null;
  });

  it('renders offers with route, traveler, and company links', async () => {
    state.offers = [
      {
        id: '11111111-1111-1111-1111-111111111111',
        shipment_id: '22222222-2222-2222-2222-222222222222',
        driver_id: '33333333-3333-3333-3333-333333333333',
        price: 250,
        status: 'sent',
        rejection_reason: null,
        created_at: '2026-05-01T10:00:00.000Z',
        updated_at: '2026-05-01T10:00:00.000Z',
        driver_profile: {
          id: '33333333-3333-3333-3333-333333333333',
          full_name: 'Driver One',
        },
        shipment: {
          id: '22222222-2222-2222-2222-222222222222',
          sender_id: '44444444-4444-4444-4444-444444444444',
          pickup: { city_name_en: 'Damascus' },
          dropoff: { city_name_en: 'Aleppo' },
          sender: {
            id: '44444444-4444-4444-4444-444444444444',
            company_name: 'TripShip Company',
            full_name: 'Company Owner',
          },
        },
      },
    ];

    render(<OffersPage />);

    await expect(screen.findByText('Offers', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(mockFrom).toHaveBeenCalledWith('offers');
    expect(screen.getByText('#11111111')).toBeInTheDocument();
    expect(screen.getByText('Sent')).toBeInTheDocument();
    expect(screen.getByText((content) => content.includes('250'))).toBeInTheDocument();
    expect(selectCalls[0]).toContain('driver_profile');
    expect(selectCalls[0]).toContain('shipment:shipments');
    expect(screen.getByRole('link', { name: /Damascus - Aleppo/i })).toHaveAttribute(
      'href',
      '/shipments/22222222-2222-2222-2222-222222222222'
    );
    expect(screen.getByRole('link', { name: /Driver One/i })).toHaveAttribute(
      'href',
      '/users/33333333-3333-3333-3333-333333333333'
    );
    expect(screen.getByRole('link', { name: /TripShip Company/i })).toHaveAttribute(
      'href',
      '/users/44444444-4444-4444-4444-444444444444'
    );
  });

  it('filters offers by status', async () => {
    state.offers = [
      {
        id: '11111111-1111-1111-1111-111111111111',
        shipment_id: '22222222-2222-2222-2222-222222222222',
        driver_id: '33333333-3333-3333-3333-333333333333',
        price: 250,
        status: 'sent',
        rejection_reason: null,
        created_at: '2026-05-01T10:00:00.000Z',
        updated_at: null,
        driver_profile: { full_name: 'Driver One' },
        shipment: {
          sender_id: 'company-1',
          pickup: { city_name_en: 'Damascus' },
          dropoff: { city_name_en: 'Aleppo' },
          sender: { company_name: 'TripShip Company' },
        },
      },
      {
        id: '44444444-4444-4444-4444-444444444444',
        shipment_id: '55555555-5555-5555-5555-555555555555',
        driver_id: '66666666-6666-6666-6666-666666666666',
        price: 400,
        status: 'accepted',
        rejection_reason: null,
        created_at: '2026-05-02T10:00:00.000Z',
        updated_at: null,
        driver_profile: { full_name: 'Driver Two' },
        shipment: {
          sender_id: 'company-2',
          pickup: { city_name_en: 'Homs' },
          dropoff: { city_name_en: 'Latakia' },
          sender: { company_name: 'Second Company' },
        },
      },
    ];

    render(<OffersPage />);

    await screen.findByText('#11111111', {}, { timeout: 3000 });
    fireEvent.click(screen.getByRole('button', { name: /Accepted/i }));

    expect(screen.queryByText('#11111111')).not.toBeInTheDocument();
    expect(screen.getByText('#44444444')).toBeInTheDocument();
  });

  it('searches offers by route, traveler, and company names', async () => {
    state.offers = [
      {
        id: '11111111-1111-1111-1111-111111111111',
        shipment_id: '22222222-2222-2222-2222-222222222222',
        driver_id: '33333333-3333-3333-3333-333333333333',
        price: 250,
        status: 'sent',
        rejection_reason: null,
        created_at: '2026-05-01T10:00:00.000Z',
        updated_at: null,
        driver_profile: { full_name: 'Driver One' },
        shipment: {
          sender_id: 'company-1',
          pickup: { city_name_en: 'Damascus' },
          dropoff: { city_name_en: 'Aleppo' },
          sender: { company_name: 'TripShip Company' },
        },
      },
      {
        id: '44444444-4444-4444-4444-444444444444',
        shipment_id: '55555555-5555-5555-5555-555555555555',
        driver_id: '66666666-6666-6666-6666-666666666666',
        price: 400,
        status: 'accepted',
        rejection_reason: null,
        created_at: '2026-05-02T10:00:00.000Z',
        updated_at: null,
        driver_profile: { full_name: 'Driver Two' },
        shipment: {
          sender_id: 'company-2',
          pickup: { city_name_en: 'Homs' },
          dropoff: { city_name_en: 'Latakia' },
          sender: { company_name: 'Second Company' },
        },
      },
    ];

    render(<OffersPage />);

    await screen.findByText('Driver One', {}, { timeout: 3000 });
    fireEvent.change(screen.getByPlaceholderText('Search by offer, route, driver, company, status...'), {
      target: { value: 'TripShip Company' },
    });

    expect(screen.getByText('Driver One')).toBeInTheDocument();
    expect(screen.queryByText('Driver Two')).not.toBeInTheDocument();
  });

  it('shows a visible retry state when offers fail to load', async () => {
    state.error = { message: 'permission denied' };

    render(<OffersPage />);

    await expect(screen.findByText('Failed to load offers.', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    expect(mockToast).toHaveBeenCalledWith('Failed to load offers.', 'error');
  });
});
