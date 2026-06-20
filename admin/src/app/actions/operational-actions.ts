// Client-side data module. Authorization is enforced at the database layer:
//   * bookings UPDATE — RLS `requester_id|traveler_id = auth.uid() OR
//     is_admin()` (00021); FSM trigger `booking_fsm_guard` enforces legal
//     transitions, but `admin_force_status_transition` RPC bypasses it.
//   * trips UPDATE — RLS `traveler_id = auth.uid() OR is_admin()` (00006).
//   * RPC `admin_force_status_transition` — GRANT EXECUTE to authenticated
//     (00048).
//     ⚠️ RLS GAP: original JS checkRole was strict (ops_admin / support_agent
//     / finance_admin per function); current RLS allows any admin role.
//     Tighten in planned 00049 migration.
//   * bookings audit trigger (00012) auto-records changes to audit_logs_v2.

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { BookingStatus, TripStatus } from '@/lib/types';
import { getErrorMessage } from './action-utils';

/**
 * Force a booking status transition, bypassing standard FSM rules.
 */
export async function forceBookingStatus(
    bookingId: string,
    newStatus: BookingStatus,
    reason: string
) {
    try {
        const { error } = await supabase.rpc('admin_force_status_transition', {
            p_booking_id: bookingId,
            p_new_status: newStatus,
            p_reason: reason,
        });

        if (error) throw error;

        await logAdminAction(
            'force_booking_status',
            'booking',
            bookingId,
            { new_status: newStatus, reason }
        );

        return { success: true };
    } catch (error: unknown) {
        console.error('[OpsAction] forceBookingStatus failed:', error);
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Toggle a booking "Freeze" state (Investigation Lock).
 *
 * Bug fix during migration: previously the freeze flow did two sequential
 * updates — the first appended `[PRE_FREEZE_STATUS:X]` to `internal_notes`,
 * the second overwrote `internal_notes` with the freeze marker, losing the
 * tag. On unfreeze the regex never matched, so restoration always fell back
 * to 'in_communication'. Now combined into a single atomic update that
 * keeps both the freeze marker and the PRE_FREEZE_STATUS tag.
 */
export async function toggleBookingFreeze(bookingId: string, currentIsFrozen: boolean, reason: string) {
    try {
        let targetStatus: string;
        let newNotes: string;

        if (currentIsFrozen) {
            // Unfreezing — read current notes to recover the pre-freeze status.
            const { data: booking } = await supabase
                .from('bookings')
                .select('internal_notes')
                .eq('id', bookingId)
                .single();

            const match = booking?.internal_notes?.match(/\[PRE_FREEZE_STATUS:(\w+)\]/);
            targetStatus = match ? match[1] : 'in_communication';
            newNotes = `[Freeze Toggle] UNFROZEN: ${reason}`;
        } else {
            // Freezing — read current status, embed it in the new notes so we
            // can recover it on unfreeze.
            const { data: booking } = await supabase
                .from('bookings')
                .select('status')
                .eq('id', bookingId)
                .single();

            targetStatus = 'frozen';
            const preFreezeTag = `[PRE_FREEZE_STATUS:${booking?.status ?? 'unknown'}]`;
            newNotes = `[Freeze Toggle] FROZEN: ${reason}\n${preFreezeTag}`;
        }

        const { error } = await supabase
            .from('bookings')
            .update({ status: targetStatus, internal_notes: newNotes })
            .eq('id', bookingId);

        if (error) throw error;

        await logAdminAction(
            currentIsFrozen ? 'unfreeze_booking' : 'freeze_booking',
            'booking',
            bookingId,
            { reason, restored_status: currentIsFrozen ? targetStatus : undefined }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Recalculate and sync trip capacity (Emergency Sync).
 * BUG-11 fix: PostgREST .not('in') requires bare values without quotes inside parens.
 * BUG-28 fix: clamp totalLoad to max_weight_kg to prevent negative available slots.
 */
export async function syncTripCapacity(tripId: string) {
    try {
        const { data: trip } = await supabase
            .from('trips')
            .select('max_weight_kg')
            .eq('id', tripId)
            .single();

        const { data: activeBookings } = await supabase
            .from('bookings')
            .select('reserved_weight_kg')
            .eq('trip_id', tripId)
            .not('status', 'in', '(cancelled,rejected)');

        // TODO: the legacy goods-listing table was removed in the trips-only
        // reorientation. Trip load can no longer be derived from a joined
        // package weight. We now sum the booking-level `reserved_weight_kg`
        // (the same column the canonical sync_trip_load trigger uses). If that
        // column is absent/null the contribution is 0, so this is a reduced
        // best-effort recompute compared to the previous joined-weight sum.
        const rawLoad = activeBookings?.reduce((sum, b: { reserved_weight_kg?: number | null }) => {
            return sum + (Number(b?.reserved_weight_kg) || 0);
        }, 0) ?? 0;

        // Clamp: current_load_kg must not exceed max_weight_kg.
        // Note: this diverges from the canonical sync_trip_load trigger (00021)
        // which uses bookings.reserved_weight_kg and does not clamp. Admin sync
        // is a manual recompute path that intentionally upper-bounds the value.
        const maxLoad = trip?.max_weight_kg ? Number(trip.max_weight_kg) : Infinity;
        const totalLoad = Math.min(rawLoad, maxLoad);

        if (rawLoad > maxLoad) {
            console.warn(`[syncTripCapacity] Calculated load ${rawLoad}kg exceeds max ${maxLoad}kg for trip ${tripId}. Clamping.`);
        }

        const { error } = await supabase
            .from('trips')
            .update({ current_load_kg: totalLoad })
            .eq('id', tripId);

        if (error) throw error;

        await logAdminAction(
            'sync_trip_capacity',
            'trip',
            tripId,
            { calculated_load: rawLoad, clamped_load: totalLoad }
        );

        return { success: true, newLoad: totalLoad };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Update trip status with admin override.
 */
export async function forceTripStatus(tripId: string, newStatus: TripStatus, reason: string) {
    try {
        const { error } = await supabase
            .from('trips')
            .update({
                status: newStatus,
                internal_notes: `[Force Status] ${newStatus}: ${reason}`,
            })
            .eq('id', tripId);

        if (error) throw error;

        await logAdminAction(
            'force_trip_status',
            'trip',
            tripId,
            { new_status: newStatus, reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Toggle escalation flag for investigation.
 */
export async function setBookingEscalation(bookingId: string, isEscalated: boolean, reason: string) {
    try {
        const { error } = await supabase
            .from('bookings')
            .update({
                is_escalated: isEscalated,
                internal_notes: `[Escalation ${isEscalated ? 'ON' : 'OFF'}] ${reason}`,
            })
            .eq('id', bookingId);

        if (error) throw error;

        await logAdminAction(
            isEscalated ? 'escalate_booking' : 'deescalate_booking',
            'booking',
            bookingId,
            { reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Force release payment (confirm payment on behalf of driver).
 */
export async function forcePaymentRelease(bookingId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('bookings')
            .update({
                payment_confirmed_by_traveler_at: new Date().toISOString(),
                internal_notes: `[Force Payment Release] ${reason}`,
            })
            .eq('id', bookingId);

        if (error) throw error;

        await logAdminAction(
            'force_payment_release',
            'booking',
            bookingId,
            { reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Force refund and cancel booking.
 */
export async function forceRefund(bookingId: string, reason: string) {
    try {
        const { error } = await supabase
            .from('bookings')
            .update({
                status: 'cancelled',
                refund_status: 'refunded',
                internal_notes: `[Force Refund & Cancel] ${reason}`,
            })
            .eq('id', bookingId);

        if (error) throw error;

        await logAdminAction(
            'force_refund',
            'booking',
            bookingId,
            { reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
