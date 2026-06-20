import { beforeEach, describe, expect, it, vi } from 'vitest';
import { advanceVerificationStep } from './verification-actions';

const mocks = vi.hoisted(() => {
  const workflowEq = vi.fn();
  const workflowUpdate = vi.fn();
  const profilesUpdate = vi.fn();

  const workflowSelectChain: any = {
    select: vi.fn(() => workflowSelectChain),
    eq: vi.fn((column: string, value: unknown) => {
      workflowEq(column, value);
      return workflowSelectChain;
    }),
    maybeSingle: vi.fn(() => Promise.resolve({
      data: {
        id: 'workflow-1',
        approvals_count: 0,
        approver_ids: [],
      },
      error: null,
    })),
    update: workflowUpdate,
    insert: vi.fn(() => Promise.resolve({ error: null })),
  };

  workflowUpdate.mockReturnValue({
    eq: vi.fn(() => Promise.resolve({ error: null })),
  });

  profilesUpdate.mockReturnValue({
    eq: vi.fn(() => Promise.resolve({ error: null })),
  });

  return {
    workflowEq,
    workflowUpdate,
    profilesUpdate,
    mockFrom: vi.fn((table: string) => {
      if (table === 'verification_workflow') return workflowSelectChain;
      if (table === 'profiles') return { update: profilesUpdate };
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

describe('advanceVerificationStep', () => {
  beforeEach(() => {
    mocks.workflowEq.mockClear();
    mocks.workflowUpdate.mockClear();
    mocks.profilesUpdate.mockClear();
    mocks.mockFrom.mockClear();
    mocks.mockGetUser.mockClear();
    mocks.mockLogAdminAction.mockClear();
  });

  it('scopes workflow lookup to the requested capability type', async () => {
    const result = await advanceVerificationStep(
      'user-1',
      'driver',
      'approved',
      'Travelers screen status update',
    );

    expect(result.success).toBe(true);
    expect(mocks.workflowEq).toHaveBeenCalledWith('entity_id', 'user-1');
    expect(mocks.workflowEq).toHaveBeenCalledWith('entity_type', 'driver');
    expect(mocks.profilesUpdate).toHaveBeenCalledWith({ traveler_status: 'approved' });
  });
});
