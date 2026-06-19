import { createClient, SupabaseClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '.env') });

const supabaseUrl = process.env.SUPABASE_URL!;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
const anonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY!;

export const serviceRoleClient = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false },
});

async function ensureProfile(userId: string, fullName: string) {
  const { error } = await serviceRoleClient.from('profiles').upsert(
    { id: userId, full_name: fullName },
    { onConflict: 'id' }
  );
  if (error) throw new Error(`ensureProfile ${fullName}: ${error.message}`);
}

async function ensureAdminRole(userId: string) {
  const { data: existing } = await serviceRoleClient.from('user_roles').select('id').eq('user_id', userId).eq('role', 'admin').maybeSingle();
  if (existing) return;
  const { error } = await serviceRoleClient.from('user_roles').insert({
    user_id: userId,
    role: 'admin',
    granted_by: userId,
  });
  if (error) throw new Error(`ensureAdminRole: ${error.message}`);
}

let _locationId: string | null = null;
export async function ensureLocation(): Promise<string> {
  if (_locationId) return _locationId;
  const { data: existing } = await serviceRoleClient.from('locations').select('id').limit(1).maybeSingle();
  if (existing?.id) {
    _locationId = existing.id;
    return _locationId;
  }
  const { data: inserted, error } = await serviceRoleClient
    .from('locations')
    .insert({
      country_name_ar: 'السعودية',
      country_name_en: 'Saudi Arabia',
      province_name_ar: 'الرياض',
      province_name_en: 'Riyadh',
      city_name_ar: 'الرياض',
      city_name_en: 'Riyadh',
      is_active: true,
    })
    .select('id')
    .single();
  if (error) throw new Error(`ensureLocation: ${error.message}`);
  _locationId = inserted!.id;
  return _locationId;
}

async function signIn(email: string, password: string): Promise<{ client: SupabaseClient; userId: string }> {
  const client = createClient(supabaseUrl, anonKey, { auth: { persistSession: false } });
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error) throw new Error(`signIn ${email}: ${error.message}`);
  if (!data.user?.id) throw new Error(`signIn ${email}: no user id`);
  return { client, userId: data.user.id };
}

export let requester: { client: SupabaseClient; userId: string };
export let traveler: { client: SupabaseClient; userId: string };
export let admin: { client: SupabaseClient; userId: string };

export async function setupTestUsers() {
  const requesterEmail = process.env.TEST_USER_REQUESTER_EMAIL!;
  const requesterPassword = process.env.TEST_USER_REQUESTER_PASSWORD!;
  const travelerEmail = process.env.TEST_USER_TRAVELER_EMAIL!;
  const travelerPassword = process.env.TEST_USER_TRAVELER_PASSWORD!;
  const adminEmail = process.env.TEST_USER_ADMIN_EMAIL!;
  const adminPassword = process.env.TEST_USER_ADMIN_PASSWORD!;

  if (!requesterEmail || !requesterPassword || !travelerEmail || !travelerPassword || !adminEmail || !adminPassword) {
    throw new Error('Missing test user env: TEST_USER_REQUESTER_EMAIL/PASSWORD, TEST_USER_TRAVELER_*, TEST_USER_ADMIN_*');
  }
  if (!supabaseUrl || !serviceRoleKey) throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');

  requester = await signIn(requesterEmail, requesterPassword);
  traveler = await signIn(travelerEmail, travelerPassword);
  admin = await signIn(adminEmail, adminPassword);

  await ensureProfile(requester.userId, 'Test Requester');
  await ensureProfile(traveler.userId, 'Test Traveler');
  await ensureProfile(admin.userId, 'Test Admin');
  await ensureAdminRole(admin.userId);
  await ensureLocation();
}
