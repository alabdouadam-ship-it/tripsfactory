import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import AnalyticsPage from './page';

const mocks = vi.hoisted(() => ({
  mockToast: vi.fn(),
  getTopOriginCities: vi.fn(),
  getTopDestinations: vi.fn(),
  getUserTypeDistribution: vi.fn(),
  getDailyTripCount: vi.fn(),
  getTotalUserCount: vi.fn(),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast }),
}));

vi.mock('@/lib/i18n', () => {
  const labels: Record<string, string> = {
    'analytics.userTypes.traveler': 'Traveler',
    'analytics.userTypes.driver': 'Driver',
    'analytics.userTypes.company': 'Company',
    'analytics.userTypes.individual': 'Individual',
  };
  // Stable function reference across renders — mirrors the real useT(), and
  // keeps the page's `fetchAll` useCallback stable so the load effect does not
  // re-run on every render (which previously made this suite flaky in CI).
  const translate = (key: string, fallback?: string) => labels[key] ?? fallback ?? key;
  return {
    useT: () => translate,
    useI18n: () => ({ language: 'en' }),
  };
});

vi.mock('@/app/actions/analytics-actions', () => ({
  getTopOriginCities: mocks.getTopOriginCities,
  getTopDestinations: mocks.getTopDestinations,
  getUserTypeDistribution: mocks.getUserTypeDistribution,
  getDailyTripCount: mocks.getDailyTripCount,
  getTotalUserCount: mocks.getTotalUserCount,
}));

vi.mock('recharts', () => ({
  ResponsiveContainer: ({ children }: { children: React.ReactNode }) => <div data-testid="responsive-container">{children}</div>,
  AreaChart: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="area-chart">
      {React.Children.toArray(children).filter((child: any) => child?.type !== 'defs')}
    </div>
  ),
  Area: ({ dataKey }: { dataKey: string }) => <div data-testid={`area-${dataKey}`} />,
  BarChart: ({ children }: { children: React.ReactNode }) => <div data-testid="bar-chart">{children}</div>,
  Bar: ({ dataKey }: { dataKey: string }) => <div data-testid={`bar-${dataKey}`} />,
  CartesianGrid: () => <div data-testid="cartesian-grid" />,
  XAxis: () => <div data-testid="x-axis" />,
  YAxis: () => <div data-testid="y-axis" />,
  Tooltip: () => <div data-testid="tooltip" />,
  PieChart: ({ children }: { children: React.ReactNode }) => <div data-testid="pie-chart">{children}</div>,
  Pie: ({ children }: { children: React.ReactNode }) => <div data-testid="pie">{children}</div>,
  Cell: () => <div data-testid="cell" />,
}));

describe('AnalyticsPage', () => {
  beforeEach(() => {
    mocks.mockToast.mockClear();
    mocks.getTopOriginCities.mockReset();
    mocks.getTopDestinations.mockReset();
    mocks.getUserTypeDistribution.mockReset();
    mocks.getDailyTripCount.mockReset();
    mocks.getTotalUserCount.mockReset();

    mocks.getTopOriginCities.mockResolvedValue({
      success: true,
      data: [{ city_en: 'Riyadh', city_ar: 'الرياض', total_trips: 4 }],
    });
    mocks.getTopDestinations.mockResolvedValue({
      success: true,
      data: [{ city_en: 'Jeddah', city_ar: 'جدة', total_trips: 3 }],
    });
    mocks.getUserTypeDistribution.mockResolvedValue({
      success: true,
      data: [
        { user_type: 'driver', total: 2 },
        { user_type: 'traveler', total: 3 },
        { user_type: 'company', total: 1 },
        { user_type: 'individual', total: 4 },
      ],
    });
    mocks.getDailyTripCount.mockResolvedValue({
      success: true,
      data: [
        { day: '2026-05-04', trip_count: 2 },
        { day: '2026-05-05', trip_count: 3 },
      ],
    });
    mocks.getTotalUserCount.mockResolvedValue({ success: true, data: 11 });
  });

  it('renders analytics data with actual total users and traveler bucket', async () => {
    render(<AnalyticsPage />);

    await waitFor(() => {
      expect(screen.getByText('Operational Analytics')).toBeInTheDocument();
    });

    expect(screen.getByText('Total users')).toBeInTheDocument();
    expect(screen.getByText('11')).toBeInTheDocument();
    expect(screen.getByText('Traveler')).toBeInTheDocument();
    expect(screen.getByText('Driver')).toBeInTheDocument();
    expect(screen.getByText('Company')).toBeInTheDocument();
    expect(screen.getByText('Individual')).toBeInTheDocument();
    expect(screen.getByTestId('area-trip_count')).toBeInTheDocument();
    expect(screen.getAllByTestId('bar-trips').length).toBeGreaterThan(0);
  });

  it('shows a retry state when analytics loading throws', async () => {
    // Persistent rejection so the error state stays put even if the load effect
    // re-runs; we flip it to success right before clicking Retry. This avoids a
    // race where a re-fetch resolves and clears the error before the assertion.
    mocks.getTopOriginCities.mockReset();
    mocks.getTopOriginCities.mockRejectedValue(new Error('network down'));

    render(<AnalyticsPage />);

    await waitFor(() => {
      expect(screen.getByText('Analytics could not be loaded. Please try again.')).toBeInTheDocument();
    });
    expect(mocks.mockToast).toHaveBeenCalled();

    // Allow the retry to succeed.
    mocks.getTopOriginCities.mockResolvedValue({
      success: true,
      data: [{ city_en: 'Riyadh', city_ar: 'الرياض', total_trips: 4 }],
    });

    fireEvent.click(screen.getByRole('button', { name: /retry/i }));

    await waitFor(() => {
      expect(screen.getByText('Operational Analytics')).toBeInTheDocument();
    });
  });
});
