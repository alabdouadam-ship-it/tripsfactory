import { describe, expect, it, vi, beforeEach } from 'vitest';
import { applyReportAction } from './moderation-actions';

const mocks = vi.hoisted(() => {
  const mockReportsUpdate = vi.fn();
  const reportSelectChain = {
    eq: vi.fn(() => ({
      single: vi.fn(() => Promise.resolve({
        data: {
          id: 'report-1',
          reported_id: 'user-1',
          reason: 'spam',
          target_type: 'user',
        },
        error: null,
      })),
    })),
  };

  return {
    mockReportsUpdate,
    mockFrom: vi.fn((table: string) => {
      if (table === 'reports') {
        return {
          select: vi.fn(() => reportSelectChain),
          update: mockReportsUpdate,
        };
      }
      return {};
    }),
    mockGetUser: vi.fn(() => Promise.resolve({ data: { user: { id: 'admin-1' } }, error: null })),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
  };
});

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mocks.mockFrom,
    auth: { getUser: mocks.mockGetUser },
  },
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: mocks.mockLogAdminAction,
}));

describe('applyReportAction', () => {
  beforeEach(() => {
    mocks.mockFrom.mockClear();
    mocks.mockGetUser.mockClear();
    mocks.mockReportsUpdate.mockClear();
    mocks.mockLogAdminAction.mockClear();
  });

  it('does not resolve a user report when Delete target has no deletable target', async () => {
    const result = await applyReportAction('report-1', { action: 'delete_target' });

    expect(result.success).toBe(false);
    expect(result.error).toContain('no deletable trip or rating target');
    expect(mocks.mockReportsUpdate).not.toHaveBeenCalled();
    expect(mocks.mockLogAdminAction).not.toHaveBeenCalled();
  });
});
