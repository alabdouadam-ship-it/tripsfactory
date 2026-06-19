// Client-side data module. Authorization is enforced at the database layer:
//   * trips UPDATE — RLS `auth.uid() = traveler_id OR is_admin()`
//     (00006:198). The FSM trigger and load-guard preserve invariants.
//     ⚠️ RLS GAP: original JS checkRole restricted to `ops_admin`+; current
//     RLS allows any admin role. Tighten in planned 00049 migration.
//   * trips audit trigger (00012) auto-records changes to audit_logs_v2.

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { getErrorMessage } from './action-utils';

export async function updateTrip(tripId: string, updates: {
    origin_location_id?: string;
    dest_location_id?: string;
    departure_time?: string;
    max_weight_kg?: number | null;
    suggested_price_per_kg?: number | null;
    suggested_flat_price?: number | null;
    notes?: string | null;
    internal_notes?: string | null;
    trip_type?: string;
    status?: string;
}) {
    try {
        const allowed: Record<string, unknown> = {};
        const safeStatus = [
            'pending_approval', 'available', 'in_communication',
            'pending_confirmation', 'booked', 'in_transit', 'full', 'cancelled', 'completed',
        ];
        const safeKeys = [
            'origin_location_id', 'dest_location_id', 'departure_time',
            'max_weight_kg', 'suggested_price_per_kg', 'suggested_flat_price',
            'notes', 'internal_notes', 'trip_type',
        ] as const;
        for (const k of safeKeys) {
            const v = updates[k];
            if (v !== undefined) allowed[k] = v;
        }
        if (updates.status !== undefined) {
            if (!safeStatus.includes(updates.status)) {
                throw new Error(`Invalid status: ${updates.status}`);
            }
            allowed.status = updates.status;
        }

        if (Object.keys(allowed).length === 0) return { success: true, noop: true };

        if (allowed.max_weight_kg !== null && allowed.max_weight_kg !== undefined) {
            const { data: current } = await supabase
                .from('trips').select('current_load_kg').eq('id', tripId).single();
            if (current && current.current_load_kg && Number(allowed.max_weight_kg) < Number(current.current_load_kg)) {
                throw new Error('Cannot reduce max_weight_kg below the trip current load.');
            }
        }

        const { error } = await supabase.from('trips').update(allowed).eq('id', tripId);
        if (error) throw error;

        await logAdminAction('admin_edit_trip', 'trip', tripId, { fields: Object.keys(allowed) });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Approve a trip in `pending_approval` status — moves it to `available`.
 */
export async function approveTrip(tripId: string, notes?: string) {
    try {
        const { data, error } = await supabase
            .from('trips')
            .update({ status: 'available', internal_notes: notes ?? null })
            .eq('id', tripId)
            .eq('status', 'pending_approval')
            .select('id');
        if (error) throw error;
        if (!data || data.length === 0) {
            return { success: false, error: 'Trip is no longer pending approval.' };
        }
        await logAdminAction('approve_trip', 'trip', tripId, { notes });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Reject a pending trip.
 * Uses cancellation_reason column added by migration 00046.
 */
export async function rejectTrip(tripId: string, reason: string) {
    try {
        if (!reason || !reason.trim()) {
            throw new Error('A rejection reason is required.');
        }
        const { error } = await supabase
            .from('trips')
            .update({
                status: 'cancelled',
                cancellation_reason: `[admin-rejected] ${reason.trim()}`,
            })
            .eq('id', tripId);
        if (error) throw error;
        await logAdminAction('reject_trip', 'trip', tripId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Cancel a trip (admin override). Historical note (BUG-18): originally moved
 * from a client direct-call (no auth) to a server action with role check.
 * Now reverts to a client direct-call but with RLS enforcing admin-only.
 */
export async function cancelTripAdmin(tripId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('trips')
            .update({
                status: 'cancelled',
                cancellation_reason: `[admin-cancelled] ${reason.trim()}`,
            })
            .eq('id', tripId);

        if (error) throw error;

        await logAdminAction('cancel_trip', 'trip', tripId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Reopen a cancelled trip back to available (admin override). Same RLS gate
 * as cancelTripAdmin.
 */
export async function reopenTripAdmin(tripId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('trips')
            .update({
                status: 'available',
                internal_notes: `[admin-reopened] ${reason.trim()}`,
            })
            .eq('id', tripId);

        if (error) throw error;

        await logAdminAction('reopen_trip', 'trip', tripId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}
