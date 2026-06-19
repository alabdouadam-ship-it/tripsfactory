import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import SettingsPage from './page';

const mocks = vi.hoisted(() => ({
  mockPush: vi.fn(),
  mockRefresh: vi.fn(),
  mockToast: vi.fn(),
  mockGetUser: vi.fn(),
  mockProfileSingle: vi.fn(),
  mockLoginHistoryLimit: vi.fn(),
  mockFrom: vi.fn(),
  mockSetLanguage: vi.fn(),
  mockSetTheme: vi.fn(),
  mockSetFontSize: vi.fn(),
}));

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mocks.mockPush, refresh: mocks.mockRefresh }),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({
    language: 'en',
    setLanguage: mocks.mockSetLanguage,
  }),
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

vi.mock('@/lib/theme', () => ({
  useTheme: () => ({
    theme: 'light',
    setTheme: mocks.mockSetTheme,
    themes: [
      { id: 'light', label: 'Light', labelAr: 'فاتح' },
      { id: 'dark', label: 'Dark', labelAr: 'داكن' },
    ],
    fontSize: 'normal',
    setFontSize: mocks.mockSetFontSize,
    fontSizes: [
      { id: 'small', label: 'Compact', labelAr: 'مضغوط' },
      { id: 'normal', label: 'Standard', labelAr: 'قياسي' },
    ],
  }),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getUser: () => mocks.mockGetUser(),
      signOut: vi.fn(),
      updateUser: vi.fn(),
    },
    from: mocks.mockFrom,
  },
}));

describe('SettingsPage', () => {
  beforeEach(() => {
    mocks.mockPush.mockClear();
    mocks.mockRefresh.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockSetLanguage.mockClear();
    mocks.mockSetTheme.mockClear();
    mocks.mockSetFontSize.mockClear();
    mocks.mockFrom.mockImplementation((table: string) => {
      // Create a query builder that chains properly
      const createQuery = () => {
        const query: any = {
          eq: vi.fn(() => query),
          gte: vi.fn(() => query),
          order: vi.fn(() => query),
          limit: vi.fn((n: number) => {
            // For admin_login_events, return the mock data
            if (table === 'admin_login_events') {
              return mocks.mockLoginHistoryLimit();
            }
            // For other tables, continue the chain
            return query;
          }),
          single: vi.fn(() => mocks.mockProfileSingle()),
          maybeSingle: vi.fn(() => {
            // For app_settings table, return empty to avoid errors
            if (table === 'app_settings') {
              return Promise.resolve({ data: null, error: null });
            }
            return mocks.mockProfileSingle();
          }),
        };
        return query;
      };
      
      return {
        select: vi.fn(() => createQuery()),
      };
    });
    mocks.mockGetUser.mockResolvedValue({
      data: { user: { id: 'admin-1', email: 'admin@test.com' } },
    });
    mocks.mockProfileSingle.mockResolvedValue({
      data: { is_admin: true },
      error: null,
    });
    mocks.mockLoginHistoryLimit.mockResolvedValue({
      data: [],
      error: null,
    });
  });

  it('renders language and appearance controls in settings', async () => {
    render(<SettingsPage />);

    expect(screen.getByRole('heading', { name: 'Language & Appearance' })).toBeInTheDocument();
    // Admin defaults to a single language (English), so the language switcher is
    // hidden — there is nothing to choose between.
    expect(screen.queryByRole('button', { name: 'Arabic' })).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Light' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Dark' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Compact' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Standard' })).toBeInTheDocument();
    await expect(screen.findByText('admin@test.com')).resolves.toBeInTheDocument();
  });

  it('updates theme and font size from settings', async () => {
    const user = userEvent.setup();
    render(<SettingsPage />);

    await user.click(screen.getByRole('button', { name: 'Dark' }));
    await user.click(screen.getByRole('button', { name: 'Compact' }));

    expect(mocks.mockSetTheme).toHaveBeenCalledWith('dark');
    expect(mocks.mockSetFontSize).toHaveBeenCalledWith('small');
  });

  it('renders recent admin login history in settings', async () => {
    mocks.mockLoginHistoryLimit.mockResolvedValue({
      data: [{
        id: 'login-1',
        created_at: '2026-05-07T09:30:00.000Z',
        ip_address: '203.0.113.10',
        country: 'FR',
        user_agent: 'Mozilla/5.0 Chrome/120.0.0.0 Safari/537.36',
      }],
      error: null,
    });

    render(<SettingsPage />);

    await expect(screen.findByRole('heading', { name: 'Recent Admin Activity' })).resolves.toBeInTheDocument();
    expect(await screen.findByText('203.0.113.10')).toBeInTheDocument();
    expect(screen.getByText('France (FR)')).toBeInTheDocument();
    expect(screen.getByText('Chrome')).toBeInTheDocument();
    expect(mocks.mockFrom).toHaveBeenCalledWith('admin_login_events');
  });
});
