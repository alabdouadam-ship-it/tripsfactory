import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import UsersPage from './page';

const { mockPush, mockToast, mockConfirm, mockGetPaginated, mockBulkUpdate, mockCreate, mockBlock } = vi.hoisted(() => ({
  mockPush: vi.fn(),
  mockToast: vi.fn(),
  mockConfirm: vi.fn(),
  mockGetPaginated: vi.fn(() => Promise.resolve({ success: true, data: [], totalCount: 0 })),
  mockBulkUpdate: vi.fn(() => Promise.resolve({ success: true })),
  mockCreate: vi.fn(() => Promise.resolve({ success: true })),
  mockBlock: vi.fn(() => Promise.resolve({ success: true })),
}));

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mockPush }),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast, confirm: mockConfirm }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
  useI18n: () => ({
    t: (key: string, fallback?: string) => fallback ?? key,
    dir: 'ltr',
    language: 'en',
  }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: vi.fn(() => Promise.resolve()),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: vi.fn() },
  supabaseUrl: 'https://test.supabase.co',
}));

vi.mock('@/app/actions/ux-actions', () => ({
  getPaginatedUsers: mockGetPaginated,
  bulkUpdateUserStatus: mockBulkUpdate,
}));

vi.mock('@/app/actions/user-actions', () => ({
  createUserAccount: mockCreate,
  setUserBlocked: mockBlock,
}));

vi.mock('@/lib/utils', () => ({
  exportToCSV: vi.fn(),
  cn: (...inputs: any[]) => inputs.flat().filter(Boolean).join(' '),
}));

describe('UsersPage', () => {
  beforeEach(() => {
    mockGetPaginated.mockClear();
  });

  it('renders title, segment tabs, and total counter (smoke)', async () => {
    render(<UsersPage />);
    await waitFor(() => {
      expect(screen.getByText('User Management')).toBeInTheDocument();
    }, { timeout: 3000 });
    expect(screen.getByText('users')).toBeInTheDocument(); // Compact design shows "0 users" instead of "Total: 0"
    expect(screen.getByText('Individuals')).toBeInTheDocument();
    expect(screen.getByText('Drivers / Travelers')).toBeInTheDocument();
    expect(screen.getByText('Merchants / Companies')).toBeInTheDocument();
  });

  it('renders combined company and driver capability labels', async () => {
    mockGetPaginated.mockResolvedValueOnce({
      success: true,
      totalCount: 1,
      data: [{
        id: 'user-1',
        full_name: 'Multi Role User',
        phone_number: '+966500000000',
        account_type: 'company',
        company_status: 'approved',
        traveler_status: 'approved',
        is_driver: true,
        created_at: '2026-01-01T00:00:00.000Z',
      }],
    });

    render(<UsersPage />);

    expect(await screen.findByText('Multi Role User')).toBeInTheDocument();
    expect(screen.getByText('Company + Driver')).toBeInTheDocument();
  });
});
