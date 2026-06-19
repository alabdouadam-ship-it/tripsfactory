// Client-side data module. Authorization is enforced at the database layer:
//   * `app_settings` RLS — `Ops and Super manage settings` (00011) restricts
//     UPDATE to has_role('ops_admin') / 'super_admin'; `app_settings admin
//     write` (00042) additionally allows profiles.is_admin = true.
//   * `admin_audit_log` RLS — admins can INSERT and SELECT (00006/00007).
//   * Audit trigger `proc_universal_audit` (00012) auto-records updates to
//     audit_logs_v2.

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { AppSettings } from '@/lib/types';
import { getErrorMessage } from './action-utils';

/** Fetch the singleton app_settings row. */
export async function getAppSettings(): Promise<{ success: true; data: AppSettings } | { success: false; error: string }> {
    const { data, error } = await supabase.from('app_settings').select('*').limit(1).maybeSingle();
    if (error) return { success: false, error: error.message };
    if (!data) return { success: false, error: 'app_settings row missing — run migration 00042' };
    return { success: true, data: data as AppSettings };
}

/** Update fields on the singleton app_settings row. RLS enforces ops_admin/super_admin. */
export async function updateAppSettings(updates: Partial<AppSettings>) {
    try {
        // Whitelist of editable fields. Defence-in-depth: even though RLS
        // restricts WHO can update, this keeps WHAT they can update bounded.
        const editable: (keyof AppSettings)[] = [
            'app_open', 'closed_message', 'closed_message_ar',
            'terms_of_service', 'terms_of_service_ar',
            'usage_policy', 'usage_policy_ar',
            'marketing_main_text', 'marketing_main_text_ar',
            'home_banner_text', 'home_banner_text_ar',
            'global_message_active', 'global_message_content',
            'force_update_message', 'android_min_version', 'ios_min_version',
            'first_launch_popup_active', 'first_launch_popup_title', 'first_launch_popup_title_ar',
            'first_launch_popup_body', 'first_launch_popup_body_ar',
            'first_launch_popup_image_url', 'first_launch_popup_action_url',
            'first_launch_popup_target', 'first_launch_popup_version',
            'occasional_popup_active', 'occasional_popup_title', 'occasional_popup_title_ar',
            'occasional_popup_body', 'occasional_popup_body_ar',
            'occasional_popup_image_url', 'occasional_popup_action_url',
            'occasional_popup_target', 'occasional_popup_published_at',
            'support_whatsapp',
        ] as const;

        const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
        for (const k of editable) {
            const v = updates[k];
            if (v !== undefined) {
                patch[k] = v;
            }
        }

        // Settings is a singleton row.
        const { data: existing } = await supabase.from('app_settings').select('id').limit(1).maybeSingle();
        if (!existing) throw new Error('app_settings row missing');

        const { error } = await supabase
            .from('app_settings')
            .update(patch as Partial<AppSettings> & { updated_at: string })
            .eq('id', existing.id);
        if (error) throw error;

        await logAdminAction('update_app_settings', 'app_settings', existing.id, {
            fields: Object.keys(patch),
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/** Convenience: toggle the global app open/closed switch. */
export async function setAppOpen(open: boolean, message?: string) {
    return updateAppSettings({
        app_open: open,
        closed_message: open ? null : (message ?? null),
    });
}

/** Bump the popup version so that all clients re-show it once after publish. */
export async function bumpPopupVersion() {
    const current = await getAppSettings();
    if (!current.success) return current;
    return updateAppSettings({
        first_launch_popup_version: (current.data.first_launch_popup_version ?? 0) + 1,
    });
}

/** Publish the occasional popup with current timestamp so all clients show it once. */
export async function publishOccasionalPopup() {
    return updateAppSettings({
        occasional_popup_published_at: new Date().toISOString(),
    });
}
