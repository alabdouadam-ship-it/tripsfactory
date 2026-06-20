// Client-side data module. Authorization is enforced at the database layer:
//   * reports UPDATE — RLS `is_admin()` (00006:176).
//   * ratings UPDATE/DELETE — RLS `is_admin()` (00006:166-168).
//   * profiles UPDATE — RLS `is_admin() AND NOT is_admin` (00007); the
//     `protect_profile_metadata` trigger (00018) locks `is_admin` field.
//   * notifications INSERT — RLS `auth.uid() = user_id OR is_admin()`
//     (00006:158).
//
//     ⚠️ RLS GAP A: original JS checkRole was strict (support_agent+ops_admin
//     for soft ops, ops_admin for destructive ops); current RLS allows any
//     admin role. Tighten in planned 00049.
//
//     ⚠️ RLS GAP B: `user_risk_scores` and `risk_score_history` only have
//     SELECT policies (00015:48). The manual-override writes in
//     `adjustUserRiskScore` are currently blocked by RLS. The canonical sync
//     path is the `trg_profile_risk_sync` trigger (writes via SECURITY
//     DEFINER from profile updates). To make manual override work, 00049
//     must add admin-only INSERT/UPDATE policies on these two tables.
//
//   * reports/ratings/profiles audit triggers (00012) auto-record changes
//     to audit_logs_v2.

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
 * Resolve a user report.
 */
export async function resolveReport(
    reportId: string,
    status: 'resolved' | 'dismissed',
    action: string,
    notes: string
) {
    try {
        const adminUser = await requireUser();

        const { error } = await supabase
            .from('reports')
            .update({
                status,
                resolution_action: action,
                resolved_at: new Date().toISOString(),
                resolved_by: adminUser.id,
                admin_notes: notes,
            })
            .eq('id', reportId);

        if (error) throw error;

        await logAdminAction(
            'resolve_report',
            'user_report',
            reportId,
            { status, action, notes }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Add an internal comment to a report.
 */
export async function addReportComment(reportId: string, content: string) {
    try {
        const adminUser = await requireUser();

        const { data: report } = await supabase
            .from('reports')
            .select('internal_comments')
            .eq('id', reportId)
            .single();

        const comments = report?.internal_comments || [];
        const { data: profile } = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', adminUser.id)
            .single();

        const newComment = {
            admin_id: adminUser.id,
            admin_name: profile?.full_name || 'Admin',
            content,
            created_at: new Date().toISOString(),
        };

        const { error } = await supabase
            .from('reports')
            .update({ internal_comments: [...comments, newComment] })
            .eq('id', reportId);

        if (error) throw error;

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Escalate a report to higher management.
 */
export async function escalateReport(reportId: string, level: 'ops' | 'legal') {
    try {
        const { error } = await supabase
            .from('reports')
            .update({ escalation_level: level })
            .eq('id', reportId);

        if (error) throw error;

        await logAdminAction(
            'escalate_report',
            'user_report',
            reportId,
            { to_level: level }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Manual override for a user's risk score.
 *
 * ⚠️ Depends on RLS additions in the planned 00049 migration. Currently the
 * user_risk_scores / risk_score_history tables only have SELECT policies
 * (00015) so the upsert/insert below will be blocked by RLS. 00049 must add
 * admin-only INSERT/UPDATE policies on both tables for this action to work.
 *
 * Note (historical): this used to call `fn_sync_user_risk_score` as an RPC
 * after the manual write. That function is a TRIGGER function (returns
 * TRIGGER, uses NEW) and cannot be invoked as a regular RPC — the call has
 * always errored silently. Removed during migration since the manual upsert
 * already writes the aggregate row directly.
 */
export async function adjustUserRiskScore(userId: string, newScore: number, reason: string) {
    try {
        const { data: oldData, error: fetchError } = await supabase
            .from('user_risk_scores')
            .select('risk_score')
            .eq('user_id', userId)
            .maybeSingle();

        if (fetchError) throw fetchError;

        const { error: upsertError } = await supabase
            .from('user_risk_scores')
            .upsert(
                {
                    user_id: userId,
                    risk_score: newScore,
                    last_recalculated_at: new Date().toISOString(),
                },
                { onConflict: 'user_id' }
            );

        if (upsertError) throw upsertError;

        const { error: historyError } = await supabase
            .from('risk_score_history')
            .insert({
                user_id: userId,
                old_score: oldData?.risk_score ?? null,
                new_score: newScore,
                reason: `Manual override: ${reason}`,
            });

        if (historyError) throw historyError;

        await logAdminAction(
            'adjust_risk_score',
            'profile',
            userId,
            { old_score: oldData?.risk_score, new_score: newScore, reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Delete a rating's comment text only (keep the star rating).
 */
export async function deleteRatingComment(ratingId: string, reason?: string) {
    try {
        const { error } = await supabase
            .from('ratings')
            .update({ comment: null, comment_status: 'rejected' })
            .eq('id', ratingId);
        if (error) throw error;
        await logAdminAction('delete_rating_comment', 'rating', ratingId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Hard-delete the entire rating row.
 */
export async function deleteRating(ratingId: string, reason?: string) {
    try {
        const { error } = await supabase.from('ratings').delete().eq('id', ratingId);
        if (error) throw error;
        await logAdminAction('delete_rating', 'rating', ratingId, { reason });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Common report-resolution side-effects: warn / delete content / block target.
 *
 * Note: this performs multi-table writes (reports + profiles + notifications
 * + targeted ratings/trips) without a transaction. A failure
 * mid-flow leaves partial state. A future refactor could wrap this in a
 * SECURITY DEFINER Postgres function or a Supabase Edge Function for
 * atomicity.
 */
export async function applyReportAction(reportId: string, opts: {
    action: 'warn' | 'delete_target' | 'block_target' | 'dismiss';
    notes?: string;
}) {
    try {
        const adminUser = await requireUser();

        const { data: report, error: rerr } = await supabase
            .from('reports')
            .select('*')
            .eq('id', reportId)
            .single();
        if (rerr || !report) throw new Error('Report not found');

        const targetType = report.target_type ?? 'user';

        if (opts.action === 'warn') {
            if (report.reported_id) {
                const { data: prof, error: profErr } = await supabase
                    .from('profiles')
                    .select('strike_count')
                    .eq('id', report.reported_id)
                    .single();
                if (profErr) throw profErr;
                const { error: strikeErr } = await supabase.from('profiles').update({
                    strike_count: (prof?.strike_count ?? 0) + 1,
                }).eq('id', report.reported_id);
                if (strikeErr) throw strikeErr;
                const { error: notifyErr } = await supabase.from('notifications').insert({
                    user_id: report.reported_id,
                    title: 'Warning from admin',
                    body: opts.notes || `Your account received a warning related to: ${report.reason}`,
                    data: { type: 'admin_warning', report_id: reportId },
                });
                if (notifyErr) throw notifyErr;
            }
        } else if (opts.action === 'delete_target') {
            if (targetType === 'rating' && report.target_rating_id) {
                const { error } = await supabase
                    .from('ratings')
                    .update({ comment: null, comment_status: 'rejected' })
                    .eq('id', report.target_rating_id);
                if (error) throw error;
            } else if (targetType === 'trip' && report.target_trip_id) {
                const { error } = await supabase
                    .from('trips')
                    .update({ status: 'cancelled' })
                    .eq('id', report.target_trip_id);
                if (error) throw error;
            } else {
                throw new Error('This report has no deletable trip or rating target.');
            }
        } else if (opts.action === 'block_target') {
            if (report.reported_id) {
                const { error } = await supabase.from('profiles').update({
                    is_blocked: true,
                    is_suspended: true,
                    blocked_reason: opts.notes ?? `Blocked from report ${reportId}`,
                    blocked_at: new Date().toISOString(),
                    blocked_by: adminUser.id,
                }).eq('id', report.reported_id);
                if (error) throw error;
            }
        }

        const { error: reportUpdateError } = await supabase.from('reports').update({
            status: opts.action === 'dismiss' ? 'dismissed' : 'resolved',
            resolution_action: opts.action,
            resolved_by: adminUser.id,
            resolved_at: new Date().toISOString(),
            admin_notes: opts.notes ?? null,
        }).eq('id', reportId);
        if (reportUpdateError) throw reportUpdateError;

        await logAdminAction('apply_report_action', 'report', reportId, {
            action: opts.action, notes: opts.notes, target_type: targetType,
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Fetch risk score and history for a user.
 * BUG-22 fix: explicitly check scoreRes.error and historyRes.error instead of
 * silently returning undefined data on query failure.
 */
export async function getUserRiskData(userId: string) {
    try {
        const [scoreRes, historyRes] = await Promise.all([
            supabase.from('user_risk_scores').select('*').eq('user_id', userId).maybeSingle(),
            supabase.from('risk_score_history').select('*').eq('user_id', userId).order('created_at', { ascending: false }).limit(10),
        ]);

        if (scoreRes.error) throw scoreRes.error;
        if (historyRes.error) throw historyRes.error;

        return {
            success: true,
            score: scoreRes.data,
            history: historyRes.data ?? [],
        };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
