import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import Home from './page';

const { mockPush, mockToast, mockFrom, mockRpc, selectCalls } = vi.hoisted(() => {
  const selectCalls: Array<{ table: string; columns: string; options?: any }> = [];

  function hasFilter(filters: any[], method: string, column: string, value?: any) {
    return filters.some((filter) => (
      filter.method === method &&
      filter.column === column &&
      (arguments.length < 4 || filter.value === value)
    ));
  }

  function countFor(table: string, filters: any[]) {
    if (table === 'profiles') {
      if (hasFilter(filters, 'eq', 'account_type', 'company') && hasFilter(filters, 'eq', 'company_status', 'pending')) return 2;
      if (hasFilter(filters, 'eq', 'account_type', 'company') && hasFilter(filters, 'neq', 'company_status', 'none')) return 4;
      if (hasFilter(filters, 'eq', 'traveler_status', 'pending')) return 3;
      if (hasFilter(filters, 'neq', 'traveler_status', 'none')) return 5;
      return 10;
    }

    if (table === 'shipments') {
      if (hasFilter(filters, 'in', 'status')) return 9;
      if (hasFilter(filters, 'eq', 'moderation_status', 'pending_review')) return 4;
      if (hasFilter(filters, 'eq', 'status', 'pending')) return 2;
      if (hasFilter(filters, 'eq', 'status', 'delivered')) return 1;
      if (hasFilter(filters, 'eq', 'status')) return 0;
      return 50;
    }

    if (table === 'bookings') {
      if (hasFilter(filters, 'eq', 'status', 'disputed')) return 1;
      return 6;
    }

    if (table === 'trips') {
      if (hasFilter(filters, 'in', 'status')) return 7;
      if (hasFilter(filters, 'eq', 'status', 'available')) return 5;
      if (hasFilter(filters, 'eq', 'status', 'in_transit')) return 2;
      if (hasFilter(filters, 'eq', 'status', 'completed')) return 8;
      if (hasFilter(filters, 'eq', 'status')) return 0;
      return 50;
    }

    if (table === 'offers') return 11;
    return 0;
  }

  function resultFor(table: string, columns: string, options: any, filters: any[]) {
    if (options?.head) {
      return Promise.resolve({ data: null, count: countFor(table, filters), error: null });
    }

    const current = new Date(Date.now() + 30_000).toISOString();
    const older = new Date(Date.now() - 60 * 60 * 1000).toISOString();

    if (table === 'profiles' && hasFilter(filters, 'eq', 'traveler_status', 'pending')) {
      return Promise.resolve({
        data: [{ id: 'driver-1', traveler_status: 'pending', created_at: current }],
        error: null,
      });
    }

    if (table === 'profiles') {
      return Promise.resolve({
        data: [{ id: 'user-1', full_name: 'Test User', created_at: current }],
        error: null,
      });
    }

    if (table === 'bookings') {
      return Promise.resolve({
        data: [{ id: 'booking-1', status: 'disputed', created_at: older }],
        error: null,
      });
    }

    if (table === 'shipments') {
      return Promise.resolve({
        data: [{ id: 'shipment-1', created_at: older }],
        error: null,
      });
    }

    return Promise.resolve({ data: [], error: null });
  }

  function createQuery(table: string, columns: string, options?: any) {
    const filters: any[] = [];
    const query: any = {
      eq: vi.fn((column: string, value: any) => {
        filters.push({ method: 'eq', column, value });
        return query;
      }),
      neq: vi.fn((column: string, value: any) => {
        filters.push({ method: 'neq', column, value });
        return query;
      }),
      in: vi.fn((column: string, value: any) => {
        filters.push({ method: 'in', column, value });
        return query;
      }),
      order: vi.fn(() => query),
      limit: vi.fn(() => query),
      then: (onFulfilled: any, onRejected: any) => resultFor(table, columns, options, filters).then(onFulfilled, onRejected),
      catch: (onRejected: any) => resultFor(table, columns, options, filters).catch(onRejected),
      finally: (onFinally: any) => resultFor(table, columns, options, filters).finally(onFinally),
    };
    return query;
  }

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns: string, options?: any) => {
      selectCalls.push({ table, columns, options });
      return createQuery(table, columns, options);
    }),
  }));

  const mockRpc = vi.fn(() => Promise.resolve({
    data: {
      total_users: 10,
      total_drivers: 5,
      active_trips: 8,
      monthly_growth: [
        { month: 'Feb', users: 10, drivers: 5, trips: 3 },
        { month: 'Jan', users: 8, drivers: 4, trips: 2 },
      ],
    },
    error: null,
  }));

  return {
    mockPush: vi.fn(),
    mockToast: vi.fn(),
    mockFrom,
    mockRpc,
    selectCalls,
  };
});

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mockPush }),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mockFrom,
    rpc: mockRpc,
  },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

vi.mock('recharts', () => ({
  ResponsiveContainer: ({ children }: { children: React.ReactNode }) => <div data-testid="responsive-container">{children}</div>,
  AreaChart: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="area-chart">
      {React.Children.toArray(children).filter((child: any) => child?.type !== 'defs')}
    </div>
  ),
  Area: ({ dataKey }: { dataKey: string }) => <div data-testid={`area-${dataKey}`} />,
  CartesianGrid: () => <div data-testid="cartesian-grid" />,
  XAxis: () => <div data-testid="x-axis" />,
  YAxis: () => <div data-testid="y-axis" />,
  Tooltip: () => <div data-testid="tooltip" />,
  PieChart: ({ children }: { children: React.ReactNode }) => <div data-testid="pie-chart">{children}</div>,
  Pie: ({ children }: { children: React.ReactNode }) => <div data-testid="pie">{children}</div>,
  Cell: () => <div data-testid="cell" />,
}));

describe('Dashboard page', () => {
  beforeEach(() => {
    mockPush.mockClear();
    mockToast.mockClear();
    mockFrom.mockClear();
    mockRpc.mockClear();
    selectCalls.length = 0;
  });

  it('renders corrected metrics, actions, activity links, and count-based status distribution', async () => {
    render(<Home />);

    await waitFor(() => {
    expect(screen.getByText('System Overview')).toBeInTheDocument();
    }, { timeout: 3000 });

    expect(screen.getByText('Companies')).toBeInTheDocument();
    expect(screen.getByText('Trips')).toBeInTheDocument();
    expect(screen.getByText('7/50')).toBeInTheDocument();
    expect(screen.getByText('Shipments')).toBeInTheDocument();
    expect(screen.getByText('9/50')).toBeInTheDocument();
    expect(screen.getByText('Offers')).toBeInTheDocument();
    expect(screen.getByText('11')).toBeInTheDocument();
    expect(screen.getByText('Trip Status')).toBeInTheDocument();
    expect(screen.getByText('available')).toBeInTheDocument();
    expect(screen.getByTestId('area-trips')).toBeInTheDocument();
    expect(screen.getByText('pending')).toBeInTheDocument();
    expect(screen.getAllByText('Just now').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole('button', { name: /traveler approvals/i }));
    expect(mockPush).toHaveBeenCalledWith('/users');

    fireEvent.click(screen.getByRole('button', { name: /disputes/i }));
    expect(mockPush).toHaveBeenCalledWith('/bookings?status=disputed');

    fireEvent.click(screen.getByRole('button', { name: /shipment reviews/i }));
    expect(mockPush).toHaveBeenCalledWith('/shipments?moderation=pending_review');

    const userActivity = screen.getByText(/Test User/).closest('button');
    expect(userActivity).not.toBeNull();
    fireEvent.click(userActivity!);
    expect(mockPush).toHaveBeenCalledWith('/users/user-1');

    const shipmentHeadCounts = selectCalls.filter((call) => call.table === 'shipments' && call.options?.head);
    expect(shipmentHeadCounts.length).toBeGreaterThanOrEqual(14);
    expect(selectCalls.some((call) => call.table === 'shipments' && call.columns === 'status')).toBe(false);
    const tripHeadCounts = selectCalls.filter((call) => call.table === 'trips' && call.options?.head);
    expect(tripHeadCounts.length).toBeGreaterThanOrEqual(11);
    expect(selectCalls.some((call) => call.table === 'trips' && call.columns === 'status')).toBe(false);
  });
});
