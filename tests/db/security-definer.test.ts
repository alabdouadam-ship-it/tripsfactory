import { describe, it, expect, beforeAll } from 'vitest';
import { setupTestUsers, requester, admin, serviceRoleClient } from './setup.js';

describe('Stage 1: SECURITY DEFINER (set_user_admin)', () => {
  beforeAll(async () => {
    await setupTestUsers();
  });

  it('non-admin cannot call set_user_admin (caller must be admin when admins exist)', async () => {
    const { error } = await requester.client.rpc('set_user_admin', {
      target_id: requester.userId,
    });
    expect(error).toBeTruthy();
    expect(error?.message).toMatch(/Access denied|not an admin/i);
  });

  it('admin can call set_user_admin (when admins exist)', async () => {
    const crypto = await import('crypto');
    const targetId = crypto.randomUUID();
    const { error } = await admin.client.rpc('set_user_admin', {
      target_id: targetId,
    });
    expect(error).toBeNull();
  });
});
