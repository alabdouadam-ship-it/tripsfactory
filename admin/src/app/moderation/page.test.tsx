import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import ModerationDashboard from './page';

const mocks = vi.hoisted(() => {
  const responses = new Map<string, { data: any[] | null; error: any }>();
  const queries: Record<string, any[]> = {};
  const mockFrom = vi.fn((table: string) => {
    const query: any = {
      select: vi.fn(() => query),
      lt: vi.fn(() => query),
      or: vi.fn(() => query),
      order: vi.fn(() => query),
      limit: vi.fn((count: number) => {
        query.limitValue = count;
        return Promise.resolve(responses.get(table) ?? { data: [], error: null });
      }),
    };
    queries[table] = [...(queries[table] ?? []), query];
    return query;
  });

  return {
    responses,
    queries,
    mockFrom,
    mockToast: vi.fn(),
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
  supabase: { from: mocks.mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
  useI18n: () => ({ dir: 'ltr' as const, language: 'en' as const }),
}));

vi.mock('@/app/loading', () => ({
  default: () => <div>Loading...</div>,
}));

vi.mock('@/components/StatusBadge', () => ({
  StatusBadge: ({ status }: { status: string }) => <span>{status}</span>,
}));

const report = {
  id: 'report-1',
  reporter_id: 'reporter-1',
  reported_id: 'reported-1',
  reason: 'spam',
  comment: 'Suspicious behavior',
  status: 'pending',
  escalation_level: 'support',
  internal_comments: [],
  created_at: '2026-05-05T10:00:00.000Z',
  reporter: { full_name: 'Reporter User' },
  reported: { full_name: 'Reported User' },
};

function setSuccessfulResponses(overrides: Partial<Record<string, any[]>> = {}) {
  mocks.responses.set('reports', { data: overrides.reports ?? [report], error: null });
  mocks.responses.set('user_risk_scores', { data: overrides.user_risk_scores ?? [], error: null });
  mocks.responses.set('risk_score_history', { data: overrides.risk_score_history ?? [], error: null });
  mocks.responses.set('user_restrictions', { data: overrides.user_restrictions ?? [], error: null });
}

describe('ModerationDashboard', () => {
  beforeEach(() => {
    mocks.responses.clear();
    Object.keys(mocks.queries).forEach(key => delete mocks.queries[key]);
    mocks.mockFrom.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockSearchParams = new URLSearchParams();
    setSuccessfulResponses();
  });

  it('opens reports from report cards without direct resolve or dismiss actions', async () => {
    render(<ModerationDashboard />);

    await waitFor(() => {
      expect(screen.getByText('Trust & Moderation Center')).toBeInTheDocument();
    });

    expect(screen.getByRole('link', { name: /open in reports/i })).toHaveAttribute('href', '/reports?status=all&focus=report-1');
    expect(screen.queryByRole('button', { name: /^resolve$/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /^dismiss$/i })).not.toBeInTheDocument();
  });

  it('shows a retryable error when a moderation query fails', async () => {
    mocks.responses.set('reports', { data: null, error: { message: 'permission denied' } });

    render(<ModerationDashboard />);

    await waitFor(() => {
      expect(screen.getByText('Failed to load moderation data. Please try again.')).toBeInTheDocument();
    });
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    expect(mocks.mockToast).toHaveBeenCalledWith('Failed to load moderation data. Please try again.', 'error');
  });

  it('limits recent reports and renders an empty risk activity state', async () => {
    render(<ModerationDashboard />);

    await waitFor(() => {
      expect(screen.getByText('No risk activity recorded yet.')).toBeInTheDocument();
    });
    expect(mocks.queries.reports[0].limit).toHaveBeenCalledWith(50);
  });
});
