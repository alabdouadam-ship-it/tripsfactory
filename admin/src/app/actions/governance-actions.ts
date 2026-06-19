// Client-side data module. Authorization is enforced at the database layer:
//   * bookings UPDATE — RLS `is_admin()` (00006/00007); the FSM guard and
//     `sync_dispute_notes` trigger (00014) keep dispute lifecycle consistent.
//   * user_restrictions — RLS `has_role('ops_admin')` for ALL ops (00014);
//     non-OpsAdmins cannot insert/delete here.
//   * get_user_dispute_rate RPC — GRANT EXECUTE to authenticated (00048).

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { getErrorMessage } from './action-utils';

/** Fetch the current authenticated admin user, or throw Unauthorized. */
async function requireUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) throw new Error('Unauthorized');
    return user;
}

/**
 * Resolve a payment dispute.
 *
 * Historical note (BUG-09): the trigger `sync_dispute_notes` (00014) sets
 * `dispute_resolved_at/by = now() / auth.uid()` automatically when
 * `dispute_outcome` changes. Under the old service-role server-action path
 * `auth.uid()` was NULL, so we wrote those fields explicitly. Now that the
 * call runs with the admin's JWT in the browser, the trigger populates them
 * correctly — the explicit writes below are kept as defense-in-depth.
 */
export async function resolveBookingDispute(
    bookingId: string,
    outcome: 'favour_requester' | 'favour_traveler' | 'invalid_claim' | 'mutually_resolved',
    adminNotes: string
) {
    try {
        const adminUser = await requireUser();

        const { error } = await supabase
            .from('bookings')
            .update({
                dispute_outcome: outcome,
                dispute_resolved_at: new Date().toISOString(),
                dispute_resolved_by: adminUser.id,
                internal_notes: adminNotes,
                status: outcome === 'mutually_resolved' ? 'completed' : 'disputed',
            })
            .eq('id', bookingId);

        if (error) throw error;

        await logAdminAction(
            'resolve_dispute',
            'booking',
            bookingId,
            { outcome, reason: adminNotes }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Issue a restriction to a user. RLS `has_role('ops_admin')` (00014) ensures
 * only OpsAdmin and SuperAdmin can perform this; non-admins get a 403.
 */
export async function issueUserRestriction(
    userId: string,
    type: 'no_booking' | 'no_shipping' | 'read_only' | 'shadow_ban',
    reason: string,
    durationDays?: number
) {
    try {
        const adminUser = await requireUser();

        const expiresAt = durationDays
            ? new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString()
            : null;

        const { error } = await supabase
            .from('user_restrictions')
            .insert({
                user_id: userId,
                restriction_type: type,
                reason,
                expires_at: expiresAt,
                admin_id: adminUser.id,
            });

        if (error) throw error;

        await logAdminAction(
            'issue_restriction',
            'profile',
            userId,
            { type, reason, expires_at: expiresAt }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Lift an active restriction. Same RLS gate as `issueUserRestriction`.
 */
export async function liftUserRestriction(restrictionId: string, userId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('user_restrictions')
            .delete()
            .eq('id', restrictionId);

        if (error) throw error;

        await logAdminAction(
            'lift_restriction',
            'profile',
            userId,
            { restriction_id: restrictionId, reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Fetch risk metrics for a user via the get_user_dispute_rate RPC.
 * The RPC exists (migration 00014); migration 00048 ensures GRANT EXECUTE.
 */
export async function getUserRiskMetrics(userId: string) {
    try {
        const { data, error } = await supabase.rpc('get_user_dispute_rate', { p_user_id: userId });
        if (error) throw error;
        return { success: true, metrics: data };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
