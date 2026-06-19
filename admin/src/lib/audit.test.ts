import { describe, it, expect, vi, beforeEach } from 'vitest';
import { logAdminAction } from './audit';

vi.mock('./supabase', () => ({
  supabase: {
    auth: {
      getUser: vi.fn(),
    },
    from: vi.fn(() => ({
      insert: vi.fn(() => ({ select: vi.fn() })),
    })),
  },
}));

const { supabase } = await import('./supabase');

const insertMock = vi.fn();

describe('logAdminAction', () => {
  beforeEach(() => {
    insertMock.mockClear();
    insertMock.mockResolvedValue({ error: null });
    vi.mocked(supabase.auth.getUser).mockResolvedValue({
      data: { user: { id: 'user-1' } },
      error: null,
    });
    vi.mocked(supabase.from).mockReturnValue({ insert: insertMock } as any);
  });

  it('does not insert when user is null', async () => {
    vi.mocked(supabase.auth.getUser).mockResolvedValue({
      data: { user: null },
      error: null,
    });
    await logAdminAction('test_action');
    expect(insertMock).not.toHaveBeenCalled();
  });

  it('inserts with action and user id when user present', async () => {
    await logAdminAction('suspend_user', 'profiles', 'profile-123', { reason: 'test' });
    expect(supabase.from).toHaveBeenCalledWith('admin_audit_log');
    expect(insertMock).toHaveBeenCalledWith({
      admin_id: 'user-1',
      action: 'suspend_user',
      target_type: 'profiles',
      target_id: 'profile-123',
      details: { reason: 'test' },
    });
  });

  it('uses null for optional params when not provided', async () => {
    await logAdminAction('login');
    expect(insertMock).toHaveBeenCalledWith({
      admin_id: 'user-1',
      action: 'login',
      target_type: null,
      target_id: null,
      details: null,
    });
  });

  it('does not throw when insert fails', async () => {
    vi.mocked(supabase.from).mockReturnValue({
      insert: vi.fn().mockRejectedValue(new Error('DB error')),
    } as any);
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    await expect(logAdminAction('test')).resolves.not.toThrow();
    expect(consoleSpy).toHaveBeenCalled();
    consoleSpy.mockRestore();
  });

  it('does not insert when getUser returns error', async () => {
    vi.mocked(supabase.auth.getUser).mockResolvedValueOnce({
      data: { user: null },
      error: { message: 'Session expired', name: 'AuthError', status: 401 },
    } as any);
    await logAdminAction('test_action');
    expect(insertMock).not.toHaveBeenCalled();
  });

  it('does not throw when getUser throws', async () => {
    vi.mocked(supabase.auth.getUser).mockRejectedValueOnce(new Error('Network error'));
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    await expect(logAdminAction('test')).resolves.not.toThrow();
    expect(consoleSpy).toHaveBeenCalled();
    expect(insertMock).not.toHaveBeenCalled();
    consoleSpy.mockRestore();
  });
});
