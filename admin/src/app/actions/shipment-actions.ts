// Client-side data module. Authorization is enforced at the database layer:
//   * shipments UPDATE — RLS `auth.uid() = sender_id OR is_admin()`
//     (00006:190).
//     ⚠️ RLS GAP: original JS checkRole was `['ops_admin']` for most ops and
//     `['ops_admin', 'support_agent']` for flag. Current RLS allows any
//     admin role. Tighten in planned 00049 migration.
//   * shipments audit trigger (00012) auto-records changes to audit_logs_v2.

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { getErrorMessage, JsonObject } from './action-utils';

/** Fetch the current authenticated admin user, or throw Unauthorized. */
async function requireUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) throw new Error('Unauthorized');
    return user;
}

export type FlagCategory =
    | 'illegal_goods'
    | 'fraudulent_pricing'
    | 'spam'
    | 'inappropriate_content'
    | 'duplicate'
    | 'other';

export type ModerationStatus = 'clean' | 'pending_review' | 'cleared' | 'removed' | 'escalated';

/**
 * Flag a shipment for moderation review (or clear it).
 */
export async function flagShipment(shipmentId: string, opts: {
    flag: boolean;
    category?: FlagCategory;
    reason?: string;
    moderation_status?: ModerationStatus;
}) {
    try {
        const adminUser = await requireUser();

        const updates: JsonObject = {
            is_flagged: opts.flag,
            flag_category: opts.flag ? (opts.category ?? null) : null,
            flag_reason: opts.flag ? (opts.reason ?? null) : null,
            flagged_at: opts.flag ? new Date().toISOString() : null,
            flagged_by: opts.flag ? adminUser.id : null,
            moderation_status: opts.moderation_status ?? (opts.flag ? 'pending_review' : 'clean'),
        };

        const { error } = await supabase.from('shipments').update(updates).eq('id', shipmentId);
        if (error) throw error;

        await logAdminAction(opts.flag ? 'flag_shipment' : 'unflag_shipment', 'shipment', shipmentId, {
            ...opts,
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Resolve a flagged shipment with an outcome.
 */
export async function resolveShipmentModeration(shipmentId: string, opts: {
    outcome: 'cleared' | 'removed' | 'escalated';
    notes?: string;
}) {
    try {
        const adminUser = await requireUser();

        const updates: JsonObject = {
            moderation_status: opts.outcome,
            moderation_notes: opts.notes ?? null,
            moderation_reviewed_at: new Date().toISOString(),
            moderation_reviewed_by: adminUser.id,
        };
        if (opts.outcome === 'cleared') {
            updates.is_flagged = false;
        }

        const { error } = await supabase.from('shipments').update(updates).eq('id', shipmentId);
        if (error) throw error;

        if (opts.outcome === 'removed') {
            await supabase.from('shipments').update({ status: 'cancelled' }).eq('id', shipmentId);
        }

        await logAdminAction('resolve_shipment_moderation', 'shipment', shipmentId, {
            outcome: opts.outcome, notes: opts.notes,
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Update shipment fields (admin override).
 * BUG-13 fix: added 'rejected' to safeStatus list (requires migration 00045).
 */
export async function updateShipment(shipmentId: string, updates: {
    weight_kg?: number;
    description?: string | null;
    transport_type?: string;
    pickup_date?: string | null;
    pickup_location_id?: string;
    dropoff_location_id?: string;
    width_cm?: number | null;
    height_cm?: number | null;
    length_cm?: number | null;
    price?: number | null;
    pickup_notes?: string | null;
    dropoff_notes?: string | null;
    status?: string;
}) {
    try {
        const safeStatus = [
            'pending_approval', 'pending', 'in_communication', 'accepted',
            'picked_up', 'in_transit', 'delivered', 'completed', 'cancelled', 'rejected',
            'expired', 'frozen', 'disputed',
        ];
        const allowed: Record<string, unknown> = {};
        const safeKeys = [
            'weight_kg', 'description', 'transport_type', 'pickup_date',
            'pickup_location_id', 'dropoff_location_id',
            'width_cm', 'height_cm', 'length_cm', 'price',
            'pickup_notes', 'dropoff_notes',
        ] as const;
        for (const k of safeKeys) {
            const v = updates[k];
            if (v !== undefined) allowed[k] = v;
        }
        if (updates.status !== undefined) {
            if (!safeStatus.includes(updates.status)) throw new Error(`Invalid status: ${updates.status}`);
            allowed.status = updates.status;
        }

        if (Object.keys(allowed).length === 0) return { success: true, noop: true };

        const { error } = await supabase.from('shipments').update(allowed).eq('id', shipmentId);
        if (error) throw error;

        await logAdminAction('admin_edit_shipment', 'shipment', shipmentId, {
            fields: Object.keys(allowed),
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Hard-delete a shipment after admin moderation. RLS on `shipments` does not
 * include a DELETE policy in 00006 — only the `is_admin()` UPDATE policy.
 * Confirm shipments DELETE is admin-only in 00049.
 *
 * Bug fix during migration: the previous active-booking guard queried
 * `bookings.shipment_id`, which was dropped in migration 00021. The query
 * silently failed and the guard was bypassed. Replaced with a status-based
 * guard on the shipment itself, which is both correct and cheaper.
 */
export async function deleteShipment(shipmentId: string) {
    try {
        const { data: shipment, error: fetchErr } = await supabase
            .from('shipments')
            .select('status')
            .eq('id', shipmentId)
            .single();
        if (fetchErr) throw fetchErr;

        const inFlight = ['accepted', 'picked_up', 'in_transit'];
        if (shipment && inFlight.includes(shipment.status)) {
            throw new Error(`Cannot delete a shipment in status '${shipment.status}'. Cancel it first.`);
        }

        const { error } = await supabase.from('shipments').delete().eq('id', shipmentId);
        if (error) throw error;

        await logAdminAction('delete_shipment', 'shipment', shipmentId, {});
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Approve a shipment in `pending_approval` status — moves it to `pending`.
 * Bug fix during migration: previously wrote to non-existent columns
 * `moderation_resolved_at/by`. Schema has `moderation_reviewed_at/by`
 * (00042); corrected here to match.
 */
export async function approveShipment(shipmentId: string, notes?: string) {
    try {
        const adminUser = await requireUser();
        const { data, error } = await supabase
            .from('shipments')
            .update({
                status: 'pending',
                moderation_status: 'cleared',
                moderation_notes: notes ?? null,
                moderation_reviewed_at: new Date().toISOString(),
                moderation_reviewed_by: adminUser.id,
            })
            .eq('id', shipmentId)
            .eq('status', 'pending_approval')
            .select('id');
        if (error) throw error;
        if (!data || data.length === 0) {
            return { success: false, error: 'Shipment is no longer pending approval.' };
        }
        await logAdminAction('approve_shipment', 'shipment', shipmentId, { notes });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Reject a pending shipment.
 * BUG-13 fix: uses status 'rejected' (enabled by migration 00045) instead of
 * 'cancelled', so rejected and genuinely cancelled shipments are distinguishable.
 */
export async function rejectShipment(shipmentId: string, reason: string) {
    try {
        if (!reason || !reason.trim()) {
            throw new Error('A rejection reason is required.');
        }
        const adminUser = await requireUser();
        const { error } = await supabase
            .from('shipments')
            .update({
                status: 'rejected',
                moderation_status: 'removed',
                moderation_notes: `[admin-rejected] ${reason.trim()}`,
                moderation_reviewed_at: new Date().toISOString(),
                moderation_reviewed_by: adminUser.id,
            })
            .eq('id', shipmentId);
        if (error) throw error;
        await logAdminAction('reject_shipment', 'shipment', shipmentId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Cancel a shipment (admin override). Historical note (BUG-18): originally
 * moved from client direct-call to server action; now reverts to client
 * direct-call with RLS enforcing admin-only.
 */
export async function cancelShipmentAdmin(shipmentId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('shipments')
            .update({
                status: 'cancelled',
                moderation_notes: `[admin-cancelled] ${reason.trim()}`,
            })
            .eq('id', shipmentId);

        if (error) throw error;

        await logAdminAction('cancel_shipment', 'shipment', shipmentId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Reopen a cancelled shipment back to pending (admin override). Same RLS
 * gate as cancelShipmentAdmin.
 */
export async function reopenShipmentAdmin(shipmentId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('shipments')
            .update({
                status: 'pending',
                moderation_notes: `[admin-reopened] ${reason.trim()}`,
            })
            .eq('id', shipmentId);

        if (error) throw error;

        await logAdminAction('reopen_shipment', 'shipment', shipmentId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}
