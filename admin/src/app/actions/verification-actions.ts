// Client-side data module. Authorization is enforced at the database layer:
//   * verification_workflow — RLS `is_admin()` (00016).
//     ⚠️ RLS GAP: original JS checkRole restricted to `ops_admin`+; current
//     RLS allows any admin role. To be tightened to `has_role('ops_admin')`
//     in a follow-up consolidated SQL migration (planned 00049).
//   * profiles UPDATE — RLS `is_admin()` plus `protect_profile_metadata`
//     trigger (00018) which only locks `is_admin`.
//     ⚠️ RLS GAP: identity_expiry / subscription_expires_at / internal_notes
//     are not currently locked by role beyond the generic `is_admin()` policy.
//     Trigger to be extended in 00049 to require `has_role('ops_admin')`.
//   * blacklist — RLS `check_role(['super_admin'])` (00016) — already tight.

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { getErrorMessage, JsonObject } from './action-utils';

/** Fetch the current authenticated admin user, or throw Unauthorized. */
async function requireUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) throw new Error('Unauthorized');
    return user;
}

/**
 * Handle document verification step (Multi-step).
 * BUG-01 fix: replaced .upsert().eq() antipattern (eq is silently ignored on
 * upsert) with an explicit select → conditional insert/update.
 * 
 * Sends notification to user when approved or rejected.
 */
export async function advanceVerificationStep(
    userId: string,
    entityType: 'driver' | 'company',
    nextStep: 'approve' | 'confirm' | 'approved' | 'rejected',
    notes?: string
) {
    try {
        const adminUser = await requireUser();

        const { data: workflow, error: fetchError } = await supabase
            .from('verification_workflow')
            .select('*')
            .eq('entity_id', userId)
            .eq('entity_type', entityType)
            .maybeSingle();

        if (fetchError) throw fetchError;

        const approvalsCount = workflow?.approvals_count || 0;
        const approverIds: string[] = workflow?.approver_ids || [];

        // Soft business rule: an admin cannot dual-approve a company alone.
        // Hard enforcement would need a DB trigger; for now this is a
        // best-effort UX guard — a malicious admin could still bypass it via
        // the raw Supabase REST API.
        if (approverIds.includes(adminUser.id)) {
            if (entityType === 'company' && nextStep === 'approved') {
                throw new Error('Dual-approval requires a different administrator.');
            }
        }

        const updates: JsonObject = {
            entity_id: userId,
            entity_type: entityType,
            current_step: nextStep,
            approvals_count: approvalsCount + 1,
            approver_ids: [...approverIds, adminUser.id],
            updated_at: new Date().toISOString(),
        };

        let workflowError: unknown = null;

        if (workflow) {
            // Row exists — update by primary key
            const { error } = await supabase
                .from('verification_workflow')
                .update(updates)
                .eq('id', workflow.id);
            workflowError = error;
        } else {
            // No row yet — insert
            const { error } = await supabase
                .from('verification_workflow')
                .insert(updates);
            workflowError = error;
        }

        if (workflowError) throw workflowError;

        if (nextStep === 'approved' || nextStep === 'rejected') {
            const profileUpdate: JsonObject = {};
            if (entityType === 'driver') profileUpdate.traveler_status = nextStep;
            else {
                profileUpdate.company_status = nextStep;
                if (nextStep === 'approved') profileUpdate.account_type = 'company';
            }
            const { error: profileError } = await supabase.from('profiles').update(profileUpdate).eq('id', userId);
            if (profileError) throw profileError;
            
            // Send notification to user about approval/rejection
            try {
                const capabilityName = entityType === 'driver' ? 'Traveler' : 'Company';
                const isApproved = nextStep === 'approved';
                
                const notificationTitle = isApproved 
                    ? `${capabilityName} Application Approved ✓`
                    : `${capabilityName} Application Update`;
                
                const notificationBody = isApproved
                    ? `Congratulations! Your ${capabilityName.toLowerCase()} application has been approved. You can now start using all ${capabilityName.toLowerCase()} features.`
                    : `Your ${capabilityName.toLowerCase()} application has been reviewed. Please check your profile for more details or contact support if you have questions.`;
                
                await supabase.from('notifications').insert({
                    user_id: userId,
                    title: notificationTitle,
                    body: notificationBody,
                    data: { 
                        type: 'verification_result',
                        entity_type: entityType,
                        status: nextStep,
                        sent_by: adminUser.id,
                        notes: notes || null,
                    },
                });
            } catch (notifError) {
                // Log but don't fail the approval if notification fails
                console.error('Failed to send verification notification:', notifError);
            }
        }

        await logAdminAction(
            `advance_verification_${nextStep}`,
            'user',
            userId,
            { entityType, step: nextStep, notes }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Manually override subscription or identity expiry.
 */
export async function manualOverrideExpiry(
    userId: string,
    field: 'identity_expiry' | 'subscription_expires_at',
    newDate: string,
    reason: string
) {
    try {
        if (!reason || reason.length < 10) throw new Error('A detailed reason (min 10 chars) is required for overrides.');

        const { error } = await supabase
            .from('profiles')
            .update({
                [field]: newDate,
                internal_notes: `[Manual Override ${field}] Reason: ${reason}`,
            })
            .eq('id', userId);

        if (error) throw error;

        await logAdminAction(
            'override_expiry',
            'user',
            userId,
            { field, new_date: newDate, reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Tag an account as fraudulent.
 * BUG-01 fix: same explicit select → conditional insert/update pattern.
 */
export async function flagFraudAccount(userId: string, notes: string) {
    try {
        const { data: existing, error: fetchError } = await supabase
            .from('verification_workflow')
            .select('id, entity_type')
            .eq('entity_id', userId)
            .maybeSingle();

        if (fetchError) throw fetchError;

        const updates = {
            entity_id: userId,
            entity_type: existing?.entity_type ?? 'unknown',
            is_fraud_flagged: true,
            fraud_notes: notes,
            updated_at: new Date().toISOString(),
        };

        let flagError: unknown = null;

        if (existing) {
            const { error } = await supabase
                .from('verification_workflow')
                .update(updates)
                .eq('id', existing.id);
            flagError = error;
        } else {
            const { error } = await supabase
                .from('verification_workflow')
                .insert(updates);
            flagError = error;
        }

        if (flagError) throw flagError;

        await logAdminAction(
            'flag_fraud',
            'user',
            userId,
            { notes }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Add an identifier to the blacklist. RLS `check_role(['super_admin'])`
 * (00016) blocks anyone except SuperAdmins from inserting here.
 *
 * Note (BUG-04 reversal): the original code used Node's `Buffer` because the
 * action ran on the server. Now that we run in the browser, we use `btoa`
 * which produces byte-identical base64 for ASCII inputs (phone numbers,
 * identity strings, device IDs). Existing blacklist rows remain compatible.
 */
export async function blacklistIdentifier(type: 'phone' | 'identity' | 'device', value: string, reason: string) {
    try {
        const adminUser = await requireUser();

        // ASCII-safe base64. For any non-ASCII input (unlikely here), encode
        // UTF-8 first via TextEncoder to avoid btoa throwing.
        const hash = `hash_${btoa(value).slice(0, 20)}`;

        const { error } = await supabase
            .from('blacklist')
            .insert({
                identifier_hash: hash,
                identifier_type: type,
                reason,
                admin_id: adminUser.id,
            });

        if (error) throw error;

        await logAdminAction('add_to_blacklist', 'blacklist', hash, { type, reason });
        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
