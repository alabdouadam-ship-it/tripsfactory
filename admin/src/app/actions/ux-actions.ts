// Client-side data module. Authorization is enforced at the database layer:
//   * profiles / bookings UPDATE — RLS `is_admin()` (00006 / 00007) blocks
//     non-admins from bulk-updating, regardless of what the client asks for.
//   * admin_preferences / saved_filters / export_jobs — RLS
//     `auth.uid() = admin_id` (00017) means each admin can only read/write
//     rows they own; the WITH CHECK clause enforces this on insert/update.
//   * admin_audit_log — RLS allows admins to INSERT (00006/00007).

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { getErrorMessage, JsonObject, JsonValue } from './action-utils';

interface PaginationParams {
    page: number;
    pageSize: number;
    search?: string;
    filters?: QueryFilter[];
    orderBy?: string;
    orderDir?: 'asc' | 'desc';
}

interface QueryFilter {
    field?: string;
    op: string;
    value?: JsonValue;
}

const BOOKING_ORDER_FIELDS = new Set([
    'id',
    'status',
    'price',
    'created_at',
    'updated_at',
    'traveler_id',
    'trip_id',
]);

const USER_ORDER_FIELDS = new Set([
    'id',
    'full_name',
    'created_at',
    'updated_at',
    'account_type',
    'traveler_status',
    'is_admin',
    'is_suspended',
    'is_blocked',
    'is_trusted',
    'is_featured',
]);

function sanitizePostgrestSearchInput(value: string): string {
    return value
        .trim()
        .replace(/\s+/g, ' ')
        // Remove PostgREST filter control chars to prevent brittle parsing.
        .replace(/[,%()"]/g, '');
}

/** Fetch the current authenticated admin user, or throw Unauthorized. */
async function requireUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) throw new Error('Unauthorized');
    return user;
}

/**
 * High-performance paginated user fetch.
 */
export async function getPaginatedUsers({
    page,
    pageSize,
    search,
    filters,
    orderBy = 'created_at',
    orderDir = 'desc',
}: PaginationParams) {
    try {
        const from = (page - 1) * pageSize;
        const to = from + pageSize - 1;
        const normalizedSearch = search ? sanitizePostgrestSearchInput(search) : '';
        const safeOrderBy = USER_ORDER_FIELDS.has(orderBy) ? orderBy : 'created_at';

        let query = supabase
            .from('profiles')
            .select('*', { count: 'exact' });

        if (normalizedSearch) {
            query = query.or(`full_name.ilike.%${normalizedSearch}%,phone_number.ilike.%${normalizedSearch}%,id.ilike.%${normalizedSearch}%`);
        }

        if (filters) {
            filters.forEach((f) => {
                if (!f.field && f.op !== 'or') return;
                if (f.op === 'eq') query = query.eq(f.field!, f.value);
                else if (f.op === 'neq') query = query.neq(f.field!, f.value);
                else if (f.op === 'in' && Array.isArray(f.value)) query = query.in(f.field!, f.value);
                else if (f.op === 'is') query = query.is(f.field!, f.value);
                else if (f.op === 'not_is') query = query.not(f.field!, 'is', f.value);
                else if (f.op === 'gte') query = query.gte(f.field!, f.value);
                else if (f.op === 'lte') query = query.lte(f.field!, f.value);
                else if (f.op === 'or' && typeof f.value === 'string') query = query.or(f.value);
                else if (f.op === 'ilike') query = query.ilike(f.field!, `%${String(f.value)}%`);
            });
        }

        const { data, count, error } = await query
            .order(safeOrderBy, { ascending: orderDir === 'asc' })
            .range(from, to);

        if (error) throw error;

        return { data: data || [], totalCount: count || 0, success: true };
    } catch (error: unknown) {
        console.error('[UXAction] getPaginatedUsers failed:', error);
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Bulk update user profiles. RLS `is_admin()` blocks non-admins from
 * touching any profile they don't own; the `protect_profile_metadata`
 * trigger (00011) further enforces governance-field locking by role.
 */
export async function bulkUpdateUserStatus(userIds: string[], updates: JsonObject, actionName: string) {
    try {
        const { error } = await supabase
            .from('profiles')
            .update(updates)
            .in('id', userIds);

        if (error) throw error;

        await logAdminAction(
            `bulk_${actionName}`,
            'user',
            userIds[0],
            { count: userIds.length, updates }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * High-performance paginated bookings fetch.
 */
export async function getPaginatedBookings({
    page,
    pageSize,
    search,
    filters,
    orderBy = 'created_at',
    orderDir = 'desc',
}: PaginationParams) {
    try {
        const from = (page - 1) * pageSize;
        const to = from + pageSize - 1;
        const normalizedSearch = search ? sanitizePostgrestSearchInput(search) : '';
        const safeOrderBy = BOOKING_ORDER_FIELDS.has(orderBy) ? orderBy : 'created_at';

        let query = supabase
            .from('bookings')
            .select(`
                *,
                trips (
                    *,
                    traveler_profile:profiles!trips_traveler_id_fkey(id, full_name, avatar_url),
                    origin:locations!trips_origin_location_id_fkey(id, city_name_en, city_name_ar),
                    dest:locations!trips_dest_location_id_fkey(id, city_name_en, city_name_ar)
                ),
                driver_profile:profiles!bookings_traveler_id_fkey (id, full_name, avatar_url, phone_number, is_driver),
                requester_profile:profiles!bookings_requester_id_profiles_fkey (id, full_name, avatar_url, phone_number)
            `, { count: 'exact' });

        if (normalizedSearch) {
            const numericSearch = Number(normalizedSearch);
            const isNumericSearch = Number.isFinite(numericSearch);
            const idFilter = `id.ilike.%${normalizedSearch}%`;
            query = query.or(
                isNumericSearch
                    ? `${idFilter},price.eq.${numericSearch}`
                    : idFilter
            );
        }

        if (filters) {
            filters.forEach((f) => {
                if (!f.field) return;
                if (f.op === 'eq') query = query.eq(f.field, f.value);
                if (f.op === 'ilike') query = query.ilike(f.field, `%${f.value}%`);
                if (f.op === 'gte') query = query.gte(f.field, f.value);
                if (f.op === 'lte') query = query.lte(f.field, f.value);
            });
        }

        const { data, count, error } = await query
            .order(safeOrderBy, { ascending: orderDir === 'asc' })
            .range(from, to);

        if (error) throw error;

        return { data: data || [], totalCount: count || 0, success: true };
    } catch (error: unknown) {
        console.error('[UXAction] getPaginatedBookings failed:', error);
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Bulk update booking statuses. RLS on `bookings` allows admins (and only
 * admins, in this code path) to update any booking; the FSM guard trigger
 * still applies for status transitions.
 */
export async function bulkUpdateBookingStatus(bookingIds: string[], updates: JsonObject, actionName: string) {
    try {
        const { error } = await supabase
            .from('bookings')
            .update(updates)
            .in('id', bookingIds);

        if (error) throw error;

        await logAdminAction(
            `bulk_booking_${actionName}`,
            'booking',
            bookingIds[0],
            { count: bookingIds.length, updates }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Save filter configuration for an admin. RLS on `saved_filters`
 * (`auth.uid() = admin_id`) means a non-admin can never own a row here;
 * the user_roles check from BUG-17 is replaced by RLS's owner check.
 */
export async function saveAdminFilter(tableName: string, name: string, config: JsonValue) {
    try {
        const adminUser = await requireUser();

        const { error } = await supabase
            .from('saved_filters')
            .insert({
                admin_id: adminUser.id,
                table_name: tableName,
                filter_name: name,
                filter_config: config,
            });

        if (error) throw error;
        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/** Update table preferences (column visibility + page size) for the calling admin. */
export async function updateTablePreferences(tableName: string, visibility: JsonObject, pageSize: number) {
    try {
        const user = await requireUser();

        const { error } = await supabase
            .from('admin_preferences')
            .upsert(
                {
                    admin_id: user.id,
                    table_name: tableName,
                    column_visibility: visibility,
                    page_size: pageSize,
                    updated_at: new Date().toISOString(),
                },
                { onConflict: 'admin_id,table_name' }
            );

        if (error) throw error;
        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Request a server-side data export job.
 * BUG-25 fix: corrected column name (filters → filter_config), status value
 * (pending → queued to match DB default and CHECK constraint added in 00047),
 * and count query now checks its own error before trusting the count value.
 */
export async function requestDataExport(tableName: string, filters: JsonValue) {
    try {
        const adminUser = await requireUser();

        // Check for existing active jobs to prevent flooding
        const { count, error: countError } = await supabase
            .from('export_jobs')
            .select('*', { count: 'exact', head: true })
            .eq('admin_id', adminUser.id)
            .in('status', ['queued', 'processing']);

        if (countError) throw countError;

        if (count !== null && count >= 3) {
            throw new Error('Too many active export jobs. Please wait for completion.');
        }

        const { data, error } = await supabase
            .from('export_jobs')
            .insert({
                admin_id: adminUser.id,
                table_name: tableName,
                filter_config: filters,
                status: 'queued',
                created_at: new Date().toISOString(),
            })
            .select()
            .single();

        if (error) throw error;

        await logAdminAction('request_export', tableName, data.id, { filters });

        return { success: true, jobId: data.id };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
