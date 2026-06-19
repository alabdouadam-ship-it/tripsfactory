import { supabase } from './supabase';

/**
 * Log an admin action to the audit trail.
 * Call this after every destructive/mutating admin operation.
 */
export async function logAdminAction(
    action: string,
    targetType?: string | null,
    targetId?: string | null,
    details?: Record<string, any> | null,
) {
    try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;

        const { error } = await supabase.from('admin_audit_log').insert({
            admin_id: user.id,
            action: action.toLowerCase(),
            target_type: targetType ?? null,
            target_id: targetId ?? null,
            details: details ?? null,
        });

        if (error) {
            console.error(`[Audit:Error] DB Insert failed for action: ${action}`, error.message);
        }
    } catch (e: any) {
        // Never block the main action if logging fails, but provide visibility
        console.error('[Audit:CriticalFallback] Unexpected failure during logging:', e.message);
    }
}
