import { createClient } from '@supabase/supabase-js';

export function requirePublicEnv(name: string, value: string | undefined): string {
  if (value == null || value === '') {
    throw new Error(
      `Missing or empty environment variable: ${name}. Set it in your admin build environment.`
    );
  }
  return value;
}

// IMPORTANT: use static NEXT_PUBLIC_* access so Next.js can inline values
// into the client bundle at build time.
export const supabaseUrl = requirePublicEnv(
  'NEXT_PUBLIC_SUPABASE_URL',
  process.env.NEXT_PUBLIC_SUPABASE_URL
).trim();
const supabaseKey = requirePublicEnv(
  'NEXT_PUBLIC_SUPABASE_ANON_KEY',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
).trim();

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
