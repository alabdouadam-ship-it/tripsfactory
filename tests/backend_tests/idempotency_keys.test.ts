import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

describe('Stage 4: Idempotency keys', () => {
  let client: ReturnType<typeof createClient>;
  let testUserId: string;

  beforeAll(async () => {
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
    }
    client = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
    const { data: users } = await client.auth.admin.listUsers();
    testUserId = users?.users?.[0]?.id ?? '00000000-0000-0000-0000-000000000001';
  });

  let lastUsedKey: string;

  afterAll(async () => {
    if (lastUsedKey) {
      await client.from('notifications').delete().eq('idempotency_key', lastUsedKey);
    }
  });

  it('notifications table has idempotency_key unique constraint', async () => {
    const key = 'reliability-test-key-' + Date.now();
    lastUsedKey = key;
    const { error: e1 } = await client.from('notifications').insert({
      user_id: testUserId,
      title: 'Test',
      body: 'Body',
      idempotency_key: key,
    });
    expect(e1).toBeNull();

    const { error: e2 } = await client.from('notifications').insert({
      user_id: testUserId,
      title: 'Test2',
      body: 'Body2',
      idempotency_key: key,
    });
    expect(e2).toBeTruthy();
    expect(String(e2?.code ?? e2?.message)).toMatch(/duplicate|unique|23505/i);
  });
});
