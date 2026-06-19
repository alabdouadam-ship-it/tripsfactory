import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import ReportsPage from './page';

const mocks = vi.hoisted(() => {
  const reports = [
    {
      id: 'report-1',
      reporter_id: 'reporter-1',
      reported_id: 'reported-1',
      reason: 'Pending reason',
      comment: 'Pending comment',
      status: 'pending',
      escalation_level: 'support',
      internal_comments: [],
      created_at: '2026-05-05T10:00:00.000Z',
      reporter: { full_name: 'Reporter One' },
      reported: { full_name: 'Reported One' },
      target_type: 'user',
    },
    {
      id: 'report-2',
      reporter_id: 'reporter-2',
      reported_id: 'reported-2',
      reason: 'Resolved reason',
      comment: 'Resolved comment',
      status: 'resolved',
      escalation_level: 'support',
      internal_comments: [],
      created_at: '2026-05-05T11:00:00.000Z',
      reporter: { full_name: 'Reporter Two' },
      reported: { full_name: 'Reported Two' },
      target_type: 'user',
    },
    {
      id: 'report-3',
      reporter_id: 'reporter-3',
      reported_id: 'reported-3',
      reason: 'Investigating reason',
      comment: 'Investigating comment',
      status: 'investigating',
      escalation_level: 'support',
      internal_comments: [],
      created_at: '2026-05-05T12:00:00.000Z',
      reporter: { full_name: 'Reporter Three' },
      reported: { full_name: 'Reported Three' },
      target_type: 'user',
    },
  ];

  const mockOrder = vi.fn(() => Promise.resolve({ data: reports, error: null }));
  const query: any = {
    gte: vi.fn(() => query),
    lte: vi.fn(() => query),
    order: mockOrder,
  };
  const mockSelect = vi.fn(() => query);

  return {
    reports,
    mockFrom: vi.fn(() => ({ select: mockSelect })),
    mockSelect,
    mockOrder,
    mockToast: vi.fn(),
    mockConfirm: vi.fn(),
    mockSearchParams: new URLSearchParams(),
  };
});

vi.mock('next/navigation', () => ({
  useSearchParams: () => mocks.mockSearchParams,
}));

vi.mock('next/link', () => ({
  default: ({ children, href, className }: { children: React.ReactNode; href: string; className?: string }) => (
    <a href={href} className={className}>{children}</a>
  ),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mocks.mockFrom,
    auth: { getUser: vi.fn(() => Promise.resolve({ data: { user: { id: 'admin-1' } } })) },
  },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast, confirm: mocks.mockConfirm }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
  useI18n: () => ({ dir: 'ltr' as const, language: 'en' as const }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: vi.fn(() => Promise.resolve()),
}));

vi.mock('@/lib/utils', () => ({
  cn: (...classes: Array<string | false | null | undefined>) => classes.filter(Boolean).join(' '),
  exportToCSV: vi.fn(),
}));

vi.mock('@/app/actions/moderation-actions', () => ({
  applyReportAction: vi.fn(() => Promise.resolve({ success: true })),
}));

describe('ReportsPage URL filters', () => {
  beforeEach(() => {
    mocks.mockFrom.mockClear();
    mocks.mockSelect.mockClear();
    mocks.mockOrder.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockConfirm.mockClear();
    mocks.mockSearchParams = new URLSearchParams();
  });

  it('initializes the status filter from the URL', async () => {
    mocks.mockSearchParams = new URLSearchParams('status=pending');

    render(<ReportsPage />);

    await waitFor(() => {
      expect(screen.getByText('Reports & Disputes')).toBeInTheDocument();
    });

    expect(screen.getByText('Pending reason')).toBeInTheDocument();
    expect(screen.queryByText('Investigating reason')).not.toBeInTheDocument();
    expect(screen.queryByText('Resolved reason')).not.toBeInTheDocument();
  });

  it('defaults to the open queue and includes investigating reports', async () => {
    render(<ReportsPage />);

    await waitFor(() => {
      expect(screen.getByText('Pending reason')).toBeInTheDocument();
    });

    expect(screen.getByText('Investigating reason')).toBeInTheDocument();
    expect(screen.queryByText('Resolved reason')).not.toBeInTheDocument();
  });

  it('does not show Delete target for generic user reports', async () => {
    render(<ReportsPage />);

    await waitFor(() => {
      expect(screen.getByText('Pending reason')).toBeInTheDocument();
    });

    expect(screen.queryByRole('button', { name: /delete target/i })).not.toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: /mark upheld/i }).length).toBeGreaterThan(0);
  });

  it('highlights a focused report from the URL', async () => {
    mocks.mockSearchParams = new URLSearchParams('status=all&focus=report-2');

    render(<ReportsPage />);

    await waitFor(() => {
      expect(screen.getByText('Resolved reason')).toBeInTheDocument();
    });

    const focusedCard = screen.getByText('Resolved reason').closest('[data-report-id]');
    expect(focusedCard).toHaveAttribute('data-report-id', 'report-2');
    expect(focusedCard).toHaveClass('border-orange-500/50');
  });
});
