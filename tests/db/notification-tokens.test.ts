import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { setupTestUsers, traveler, serviceRoleClient } from './setup.js';

const TOKEN_PREFIX = 'test-unique-token-';

describe('Stage 1: Notification token uniqueness', () => {
  beforeAll(async () => {
    await setupTestUsers();
  });

  afterAll(async () => {
    await serviceRoleClient.from('notification_tokens').delete().like('token', TOKEN_PREFIX + '%');
  });

  it('duplicate token for same user is rejected or upserted (unique constraint exists)', async () => {
    const token = TOKEN_PREFIX + 'dup-' + Date.now();
    const { data: first, error: e1 } = await traveler.client
      .from('notification_tokens')
      .insert({ user_id: traveler.userId, token, platform: 'test' })
      .select('id')
      .single();
    expect(e1).toBeNull();
    expect(first?.id).toBeDefined();

    const { data: second, error: e2 } = await traveler.client
      .from('notification_tokens')
      .insert({ user_id: traveler.userId, token, platform: 'android' })
      .select('id')
      .single();
    expect(e2).toBeTruthy();
    expect(String(e2?.code ?? e2?.message)).toMatch(/duplicate|unique|23505/i);
  });

  it('same token for different user is rejected (unique on token)', async () => {
    const token = TOKEN_PREFIX + 'cross-' + Date.now();
    const { error: e1 } = await traveler.client
      .from('notification_tokens')
      .insert({ user_id: traveler.userId, token, platform: 'test' });
    expect(e1).toBeNull();

    const { data: requester } = await import('./setup.js').then((m) => m.requester);
    const { error: e2 } = await requester.client
      .from('notification_tokens')
      .insert({ user_id: requester.userId, token, platform: 'test' });
    expect(e2).toBeTruthy();
    expect(String(e2?.code ?? e2?.message)).toMatch(/duplicate|unique|23505/i);
  });
});
