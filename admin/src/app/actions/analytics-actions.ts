// Client-side data module. Analytics RPCs enforce admin access in the database
// and are called directly under the admin's Supabase session.

import { supabase } from '@/lib/supabase';

export type CityCount = { city_en: string | null; city_ar: string | null; total_trips: number };
export type UserTypeCount = { user_type: string; total: number };
export type DailyTripCount = { day: string; trip_count: number };
type AnalyticsResult<T> = Promise<{ success: boolean; data?: T; error?: string }>;
type OriginTripRow = { origin?: { city_name_en?: string | null; city_name_ar?: string | null } | null };
type DestinationTripRow = { dest?: { city_name_en?: string | null; city_name_ar?: string | null } | null };
type CreatedAtRow = { created_at: string };

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error || 'Unknown analytics error');
}

function shouldFallbackFromRpc(error: { code?: string; message?: string; details?: string }) {
  const text = `${error.code || ''} ${error.message || ''} ${error.details || ''}`;
  return /PGRST202|could not find.*function|function .* does not exist|schema cache/i.test(text);
}

/** Top origin cities (most active starting points). */
export async function getTopOriginCities(days = 30, limit = 10): AnalyticsResult<CityCount[]> {
  try {
    const { data, error } = await supabase.rpc('admin_top_origin_cities', { p_days: days, p_limit: limit });
    if (error) {
      if (!shouldFallbackFromRpc(error)) return { success: false, error: error.message };
      // Fallback to a manual aggregation if the RPC is missing in a local/dev DB.
      const { data: trips, error: e2 } = await supabase
        .from('trips')
        .select('origin:locations!origin_location_id(city_name_en, city_name_ar)')
        .gte('created_at', new Date(Date.now() - days * 86400000).toISOString());
      if (e2) return { success: false, error: e2.message };

      const counts = new Map<string, CityCount>();
      for (const t of (trips ?? []) as OriginTripRow[]) {
        const key = (t.origin?.city_name_en || t.origin?.city_name_ar || '-') as string;
        const existing = counts.get(key);
        if (existing) {
          existing.total_trips += 1;
        } else {
          counts.set(key, {
            city_en: t.origin?.city_name_en ?? null,
            city_ar: t.origin?.city_name_ar ?? null,
            total_trips: 1,
          });
        }
      }

      const arr = Array.from(counts.values())
        .sort((a, b) => b.total_trips - a.total_trips)
        .slice(0, limit);
      return { success: true, data: arr };
    }
    return { success: true, data: (data ?? []) as CityCount[] };
  } catch (error) {
    return { success: false, error: errorMessage(error) };
  }
}

export async function getTopDestinations(days = 30, limit = 10): AnalyticsResult<CityCount[]> {
  try {
    const { data, error } = await supabase.rpc('admin_top_destinations', { p_days: days, p_limit: limit });
    if (error) {
      if (!shouldFallbackFromRpc(error)) return { success: false, error: error.message };
      const { data: trips, error: e2 } = await supabase
        .from('trips')
        .select('dest:locations!dest_location_id(city_name_en, city_name_ar)')
        .gte('created_at', new Date(Date.now() - days * 86400000).toISOString());
      if (e2) return { success: false, error: e2.message };

      const counts = new Map<string, CityCount>();
      for (const t of (trips ?? []) as DestinationTripRow[]) {
        const key = (t.dest?.city_name_en || t.dest?.city_name_ar || '-') as string;
        const existing = counts.get(key);
        if (existing) {
          existing.total_trips += 1;
        } else {
          counts.set(key, {
            city_en: t.dest?.city_name_en ?? null,
            city_ar: t.dest?.city_name_ar ?? null,
            total_trips: 1,
          });
        }
      }

      const arr = Array.from(counts.values())
        .sort((a, b) => b.total_trips - a.total_trips)
        .slice(0, limit);
      return { success: true, data: arr };
    }
    return { success: true, data: (data ?? []) as CityCount[] };
  } catch (error) {
    return { success: false, error: errorMessage(error) };
  }
}

export async function getTotalUserCount(): AnalyticsResult<number> {
  try {
    const { count, error } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true });
    if (error) return { success: false, error: error.message };
    return { success: true, data: count || 0 };
  } catch (error) {
    return { success: false, error: errorMessage(error) };
  }
}

export async function getUserTypeDistribution(): AnalyticsResult<UserTypeCount[]> {
  try {
    const { data, error } = await supabase.rpc('admin_user_type_distribution');
    if (error) {
      if (!shouldFallbackFromRpc(error)) return { success: false, error: error.message };
      const [total, drivers, travelers, companies] = await Promise.all([
        supabase.from('profiles').select('*', { count: 'exact', head: true }),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).neq('traveler_status', 'none').eq('is_driver', true),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).neq('traveler_status', 'none').or('is_driver.is.null,is_driver.eq.false'),
        supabase.from('profiles').select('*', { count: 'exact', head: true })
          .or('traveler_status.is.null,traveler_status.eq.none')
          .eq('account_type', 'company')
          .neq('company_status', 'none'),
      ]);
      const fallbackError = total.error || drivers.error || travelers.error || companies.error;
      if (fallbackError) return { success: false, error: fallbackError.message };

      const driverCount = drivers.count || 0;
      const travelerCount = travelers.count || 0;
      const companyCount = companies.count || 0;
      const individualCount = Math.max(0, (total.count || 0) - driverCount - travelerCount - companyCount);

      return {
        success: true,
        data: [
          { user_type: 'driver', total: driverCount },
          { user_type: 'traveler', total: travelerCount },
          { user_type: 'company', total: companyCount },
          { user_type: 'individual', total: individualCount },
        ],
      };
    }
    return { success: true, data: (data ?? []) as UserTypeCount[] };
  } catch (error) {
    return { success: false, error: errorMessage(error) };
  }
}

export async function getDailyTripCount(days = 30): AnalyticsResult<DailyTripCount[]> {
  try {
    const { data, error } = await supabase.rpc('admin_daily_trip_count', { p_days: days });
    if (error) {
      if (!shouldFallbackFromRpc(error)) return { success: false, error: error.message };
      const { data: trips, error: e2 } = await supabase
        .from('trips')
        .select('created_at')
        .gte('created_at', new Date(Date.now() - days * 86400000).toISOString());
      if (e2) return { success: false, error: e2.message };

      const counts = new Map<string, number>();
      for (const t of (trips ?? []) as CreatedAtRow[]) {
        const day = new Date(t.created_at).toISOString().slice(0, 10);
        counts.set(day, (counts.get(day) ?? 0) + 1);
      }
      const arr = Array.from(counts.entries())
        .map(([day, trip_count]) => ({ day, trip_count }))
        .sort((a, b) => a.day.localeCompare(b.day));
      return { success: true, data: arr };
    }
    return { success: true, data: (data ?? []) as DailyTripCount[] };
  } catch (error) {
    return { success: false, error: errorMessage(error) };
  }
}
