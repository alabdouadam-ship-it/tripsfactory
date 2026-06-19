import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import TravelersPage from './page';

const {
  mockToast,
  mockSearchParams,
  mockFrom,
  mockAdvanceVerificationStep,
  mockLogAdminAction,
  state,
} = vi.hoisted(() => {
  const state = {
    profiles: [] as any[],
    vehicles: [] as any[],
    vehiclesError: null as any,
    updates: [] as Array<{ table: string; patch: any; column: string; value: any }>,
  };

  const makeProfilesQuery = () => {
    const query: any = {
      neq: vi.fn(() => query),
      eq: vi.fn(() => query),
      gte: vi.fn(() => query),
      lte: vi.fn(() => query),
      order: vi.fn(() => query),
      range: vi.fn(() => Promise.resolve({
        data: state.profiles,
        count: state.profiles.length,
        error: null,
      })),
    };
    return query;
  };

  const makeVehiclesQuery = () => ({
    in: vi.fn(() => Promise.resolve({
      data: state.vehicles,
      error: state.vehiclesError,
    })),
  });

  const makeUpdateQuery = (table: string, patch: any) => ({
    eq: vi.fn((column: string, value: any) => {
      state.updates.push({ table, patch, column, value });
      return Promise.resolve({ error: null });
    }),
  });

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn(() => (table === 'vehicles' ? makeVehiclesQuery() : makeProfilesQuery())),
    update: vi.fn((patch: any) => makeUpdateQuery(table, patch)),
  }));

  return {
    mockToast: vi.fn(),
    mockSearchParams: new URLSearchParams(''),
    mockFrom,
    mockAdvanceVerificationStep: vi.fn(() => Promise.resolve({ success: true })),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
    state,
  };
});

vi.mock('next/navigation', () => ({
  useSearchParams: () => mockSearchParams,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
  useI18n: () => ({
    t: (key: string, fallback?: string) => fallback ?? key,
    language: 'en',
    dir: 'ltr',
  }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: mockLogAdminAction,
}));

vi.mock('@/app/actions/verification-actions', () => ({
  advanceVerificationStep: mockAdvanceVerificationStep,
}));

describe('TravelersPage', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockFrom.mockClear();
    mockAdvanceVerificationStep.mockClear();
    mockLogAdminAction.mockClear();
    state.profiles = [];
    state.vehicles = [];
    state.vehiclesError = null;
    state.updates = [];
  });

  it('renders traveler-focused labels, combined traveler/driver records, and profile links', async () => {
    state.profiles = [
      {
        id: 'traveler-1',
        full_name: 'Simple Traveler',
        phone_number: '+111',
        traveler_status: 'approved',
        is_driver: false,
        created_at: '2026-01-01T00:00:00.000Z',
      },
      {
        id: 'driver-1',
        full_name: 'Driver User',
        phone_number: '+222',
        traveler_status: 'pending',
        is_driver: true,
        created_at: '2026-01-02T00:00:00.000Z',
      },
    ];
    state.vehicles = [{ id: 'vehicle-1', owner_id: 'driver-1', make: 'Toyota', model: 'Hiace' }];

    render(<TravelersPage />);

    expect(await screen.findByText('Travelers')).toBeInTheDocument();
    expect(screen.getByText(/This screen includes both travelers and drivers/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Suspended/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Blocked/i })).toBeInTheDocument();
    expect(screen.getByText('Simple Traveler')).toBeInTheDocument();
    expect(screen.getByText('Driver User')).toBeInTheDocument();
    expect(screen.getByText('Toyota Hiace')).toBeInTheDocument();
    expect(screen.getAllByRole('link', { name: /Open profile/i })[0]).toHaveAttribute('href', '/users/traveler-1');
    expect(screen.getByText('Traveler')).toBeInTheDocument();
    expect(screen.getByText('Driver')).toBeInTheDocument();
  });

  it('does not expose approve or reject actions for blocked travelers', async () => {
    state.profiles = [{
      id: 'blocked-1',
      full_name: 'Blocked Traveler',
      traveler_status: 'blocked',
      is_driver: true,
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<TravelersPage />);

    expect(await screen.findByText('Blocked Traveler')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /^Approve$/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /^Reject$/i })).not.toBeInTheDocument();
    expect(mockAdvanceVerificationStep).not.toHaveBeenCalled();
  });

  it('routes approval through the verification workflow action', async () => {
    state.profiles = [{
      id: 'pending-1',
      full_name: 'Pending Traveler',
      traveler_status: 'pending',
      is_driver: false,
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<TravelersPage />);

    await screen.findByText('Pending Traveler');
    fireEvent.click(screen.getByRole('button', { name: /^Approve$/i }));

    await waitFor(() => {
      expect(mockAdvanceVerificationStep).toHaveBeenCalledWith(
        'pending-1',
        'driver',
        'approved',
        'Travelers screen status update',
      );
    });
  });

  it('shows a visible warning when vehicle loading fails', async () => {
    state.profiles = [{
      id: 'driver-1',
      full_name: 'Driver User',
      traveler_status: 'pending',
      is_driver: true,
      created_at: '2026-01-01T00:00:00.000Z',
    }];
    state.vehiclesError = new Error('vehicles denied');

    render(<TravelersPage />);

    expect(await screen.findByText('Driver User')).toBeInTheDocument();
    expect(screen.getByText(/Vehicle details could not be loaded/)).toBeInTheDocument();
    expect(mockToast).toHaveBeenCalledWith('Traveler vehicles could not be loaded.', 'error');
  });

  it('clears subscription expiry by sending null', async () => {
    state.profiles = [{
      id: 'traveler-1',
      full_name: 'Simple Traveler',
      traveler_status: 'approved',
      is_driver: false,
      subscription_expires_at: '2026-06-01T00:00:00.000Z',
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<TravelersPage />);

    const card = await screen.findByText('Simple Traveler');
    const input = within(card.closest('.group') as HTMLElement).getByDisplayValue('2026-06-01');
    fireEvent.change(input, { target: { value: '' } });

    await waitFor(() => {
      expect(state.updates).toContainEqual({
        table: 'profiles',
        patch: { subscription_expires_at: null },
        column: 'id',
        value: 'traveler-1',
      });
    });
  });
});
