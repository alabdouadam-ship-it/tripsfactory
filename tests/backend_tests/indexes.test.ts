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

function loadRequiredIndexes(): string[] {
  const paths = [
    path.join(__dirname, '../../perf_budgets.yaml'),
    path.join(__dirname, 'perf_budgets.yaml'),
  ];
  for (const p of paths) {
    if (fs.existsSync(p)) {
      const content = fs.readFileSync(p, 'utf8');
      const data = yaml.load(content) as { backend?: { required_indexes?: string[] } };
      const list = data?.backend?.required_indexes;
      if (Array.isArray(list)) return list;
    }
  }
  return [
    'idx_bookings_shipment_id', 'idx_bookings_traveler_id', 'idx_bookings_trip_id',
    'idx_bookings_requester_id', 'idx_bookings_status',
    'idx_trips_traveler_id', 'idx_trips_origin_location', 'idx_trips_dest_location', 'idx_trips_status',
    'idx_shipments_sender_id', 'idx_shipments_locations', 'idx_shipments_status',
    'idx_messages_booking_id', 'idx_notifications_user_id', 'idx_notification_tokens_user_id',
    'idx_blocks_blocker_id', 'idx_blocks_blocked_id', 'idx_reports_reported_id', 'idx_reports_status',
    'idx_vehicles_owner_id',
  ];
}

describe('Stage 3: Index existence', () => {
  let existingIndexes: string[] = [];

  beforeAll(async () => {
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
    }
    const client = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });
    const { data, error } = await client.rpc('get_public_index_names');
    if (error) throw new Error(`get_public_index_names failed: ${error.message}`);
    existingIndexes = (data as string[]) ?? [];
  });

  it('all required Stage 3 indexes exist', () => {
    const required = loadRequiredIndexes();
    const missing = required.filter((name) => !existingIndexes.includes(name));
    expect(missing).toEqual([]);
    expect(existingIndexes.length).toBeGreaterThanOrEqualTo(required.length);
  });

  it('bookings and trips indexes exist', () => {
    const bookingIndexes = ['idx_bookings_shipment_id', 'idx_bookings_trip_id', 'idx_bookings_status'];
    for (const name of bookingIndexes) {
      expect(existingIndexes).toContain(name);
    }
    const tripIndexes = ['idx_trips_traveler_id', 'idx_trips_status'];
    for (const name of tripIndexes) {
      expect(existingIndexes).toContain(name);
    }
  });
});
