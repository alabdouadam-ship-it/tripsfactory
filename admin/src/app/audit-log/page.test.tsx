import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import AuditLogPage from './page';

const mocks = vi.hoisted(() => {
  const state = {
    logs: [] as any[],
    profiles: [] as any[],
    auditError: null as any,
    profilesError: null as any,
  };
  const selectCalls: Array<{ table: string; columns: string }> = [];
  const gteCalls: Array<{ table: string; column: string; value: string }> = [];
  const lteCalls: Array<{ table: string; column: string; value: string }> = [];
  const inCalls: Array<{ table: string; column: string; values: string[] }> = [];

  const makeAuditQuery = () => {
    const query: any = {
      gte: vi.fn((column: string, value: string) => {
        gteCalls.push({ table: 'admin_audit_log', column, value });
        return query;
      }),
      lte: vi.fn((column: string, value: string) => {
        lteCalls.push({ table: 'admin_audit_log', column, value });
        return query;
      }),
      order: vi.fn(() => query),
      limit: vi.fn(() => Promise.resolve({ data: state.logs, error: state.auditError })),
    };
    return query;
  };

  const makeProfilesQuery = () => ({
    in: vi.fn((column: string, values: string[]) => {
      inCalls.push({ table: 'profiles', column, values });
      return Promise.resolve({ data: state.profiles, error: state.profilesError });
    }),
  });

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns: string) => {
      selectCalls.push({ table, columns });
      if (table === 'profiles') return makeProfilesQuery();
      return makeAuditQuery();
    }),
  }));

  return {
    state,
    selectCalls,
    gteCalls,
    lteCalls,
    inCalls,
    mockFrom,
    mockToast: vi.fn(),
    mockExportToCSV: vi.fn(),
    mockSearchParams: new URLSearchParams(),
  };
});

vi.mock('next/navigation', () => ({
  useSearchParams: () => mocks.mockSearchParams,
}));

vi.mock('@/app/loading', () => ({
  default: () => <div>Loading</div>,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mocks.mockFrom,
  },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
  useI18n: () => ({ language: 'en' as const, dir: 'ltr' as const }),
}));

vi.mock('@/lib/utils', () => ({
  exportToCSV: mocks.mockExportToCSV,
}));

describe('AuditLogPage', () => {
  beforeEach(() => {
    mocks.state.logs = [{
      id: 'audit-1',
      admin_id: 'admin-1',
      action: 'support_reply',
      target_type: 'support_ticket',
      target_id: 'ticket-1',
      details: { user_id: 'user-1', note: 'Support answer sent' },
      created_at: '2026-05-06T10:00:00.000Z',
    }];
    mocks.state.profiles = [{ id: 'admin-1', full_name: 'Admin One' }];
    mocks.state.auditError = null;
    mocks.state.profilesError = null;
    mocks.selectCalls.length = 0;
    mocks.gteCalls.length = 0;
    mocks.lteCalls.length = 0;
    mocks.inCalls.length = 0;
    mocks.mockFrom.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockExportToCSV.mockClear();
    mocks.mockSearchParams = new URLSearchParams();
  });

  it('loads explicit admin audit actions from admin_audit_log', async () => {
    render(<AuditLogPage />);

    await expect(screen.findByText('Admin One', {}, { timeout: 3000 })).resolves.toBeInTheDocument();

    expect(mocks.mockFrom).toHaveBeenCalledWith('admin_audit_log');
    expect(mocks.mockFrom).not.toHaveBeenCalledWith('audit_logs_v2');
    expect(mocks.selectCalls).toContainEqual({
      table: 'admin_audit_log',
      columns: 'id, admin_id, action, target_type, target_id, details, created_at',
    });
    expect(mocks.inCalls).toContainEqual({ table: 'profiles', column: 'id', values: ['admin-1'] });
    expect(screen.getAllByText('support reply').length).toBeGreaterThan(0);
    expect(screen.getAllByText('support ticket').length).toBeGreaterThan(0);
  });

  it('searches admin names and JSON details without issuing a PostgREST OR search', async () => {
    mocks.state.logs = [
      ...mocks.state.logs,
      {
        id: 'audit-2',
        admin_id: 'admin-2',
        action: 'approve_traveler',
        target_type: 'user',
        target_id: 'user-2',
        details: { reason: 'Documents checked' },
        created_at: '2026-05-06T11:00:00.000Z',
      },
    ];
    mocks.state.profiles = [
      { id: 'admin-1', full_name: 'Admin One' },
      { id: 'admin-2', full_name: 'Verifier Two' },
    ];

    render(<AuditLogPage />);

    await screen.findByText('Verifier Two', {}, { timeout: 3000 });
    fireEvent.change(screen.getByPlaceholderText('Search admin, action, target, or details...'), {
      target: { value: 'Support answer' },
    });

    expect(screen.getAllByText('support reply').length).toBeGreaterThan(0);
    expect(screen.queryByText('user-2')).not.toBeInTheDocument();
    expect(mocks.selectCalls.find(call => call.table === 'admin_audit_log')?.columns).not.toContain('or(');
  });

  it('shows a retryable error state when audit logs fail to load', async () => {
    mocks.state.auditError = { message: 'permission denied' };

    render(<AuditLogPage />);

    await expect(screen.findByText('Audit logs could not be loaded', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(screen.getByText('permission denied')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    expect(screen.queryByText('No audit log entries found.')).not.toBeInTheDocument();
    expect(mocks.mockToast).toHaveBeenCalledWith('Failed to load audit logs', 'error');
  });

  it('opens details without claiming cryptographic sealing', async () => {
    render(<AuditLogPage />);

    await screen.findByText('Admin One', {}, { timeout: 3000 });
    fireEvent.click(screen.getByRole('button', { name: /inspect/i }));

    expect(screen.getByText('Action Details')).toBeInTheDocument();
    expect(screen.getByText('"note"')).toBeInTheDocument();
    expect(screen.getByText('"Support answer sent"')).toBeInTheDocument();
    expect(screen.getByText('This entry is stored in the append-only admin audit trail.')).toBeInTheDocument();
    expect(screen.queryByText(/cryptographically sealed/i)).not.toBeInTheDocument();
  });

  it('exports currently filtered admin audit rows', async () => {
    render(<AuditLogPage />);

    await screen.findByText('Admin One', {}, { timeout: 3000 });
    fireEvent.click(screen.getByRole('button', { name: /export csv/i }));

    expect(mocks.mockExportToCSV).toHaveBeenCalledWith(
      [expect.objectContaining({
        admin: 'Admin One',
        action: 'support_reply',
        target_type: 'support_ticket',
        target_id: 'ticket-1',
        details: JSON.stringify({ user_id: 'user-1', note: 'Support answer sent' }),
      })],
      expect.stringMatching(/^admin_audit_log_/),
      expect.any(Function),
    );
  });

  it('initializes target focus from legacy entity URL params', async () => {
    mocks.mockSearchParams = new URLSearchParams('entity_id=ticket-1&entity_name=support_ticket');

    render(<AuditLogPage />);

    await screen.findByText('Admin One', {}, { timeout: 3000 });
    // Deep link filtering is applied via filteredLogs logic, not via UI indicator
    // Verify that only the matching log is shown
    expect(screen.getAllByText('support reply').length).toBeGreaterThan(0);
    expect(screen.getAllByRole('row').length).toBe(2); // header + 1 data row
  });
});
