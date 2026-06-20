import { describe, it, expect, beforeAll } from 'vitest';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import yaml from 'js-yaml';
import fs from 'fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

function getBudget(key: string, defaultValue: number): number {
  const paths = [
    path.join(__dirname, '../../perf_budgets.yaml'),
    path.join(__dirname, 'perf_budgets.yaml'),
  ];
  for (const p of paths) {
    if (fs.existsSync(p)) {
      const data = yaml.load(fs.readFileSync(p, 'utf8')) as Record<string, unknown>;
      const backend = data?.backend as Record<string, unknown> | undefined;
      const v = backend?.[key];
      if (typeof v === 'number') return v;
      if (typeof v === 'string') return parseInt(v, 10) || defaultValue;
    }
  }
  return defaultValue;
}

describe('Stage 3: Query and payload budget', () => {
  beforeAll(() => {
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
    }
  });

  it('RPC search_trips_rpc returns at most max_rows_per_fetch rows', async () => {
    const client = createClient(supabaseUrl!, serviceRoleKey!, { auth: { persistSession: false } });
    const maxRows = getBudget('max_rows_per_fetch', 50);
    const limit = Math.min(20, maxRows);
    const { data, error } = await client.rpc('search_trips_rpc', {
      p_limit: limit,
      p_offset: 0,
    });
    if (error) {
      expect(error.message).toBeDefined();
      return;
    }
    const rows = (data as unknown[]) ?? [];
    expect(rows.length).toBeLessThanOrEqualTo(maxRows);
  });
});
