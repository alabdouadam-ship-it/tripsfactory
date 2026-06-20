// Client-side data module. Authorization is enforced at the database layer:
//   * profiles UPDATE — RLS `auth.uid() = id OR (is_admin() AND NOT
//     is_admin)` (00007); the `protect_profile_metadata` trigger (00018)
//     locks `is_admin` to super_admin only and prevents self-demotion.
//
//     ⚠️ RLS GAP: original JS checkRole was strict (`ops_admin` for most
//     ops, `support_agent`+ for profile edits); current RLS allows any
//     admin role. Tighten in planned 00049.
//
// Privileged ops via Edge Function `admin-action` (uses service_role inside
// the function and re-checks the caller's role from JWT):
//   * setUserBlocked  → `block_user`  (needs auth.admin.updateUserById ban)
//   * createUserAccount → `create_user` (needs auth.admin.createUser +
//                                       admin_provision_profile RPC)

import { supabase } from '@/lib/supabase';
import { logAdminAction } from '@/lib/audit';
import { getErrorMessage, JsonObject } from './action-utils';

async function getInvokeErrorMessage(error: unknown): Promise<string> {
    if (!error || typeof error !== 'object') return getErrorMessage(error);

    const withContext = error as {
        message?: unknown;
        context?: { json?: () => Promise<unknown>; text?: () => Promise<string> };
    };

    const context = withContext.context;
    if (context?.json) {
        try {
            const payload = await context.json();
            if (payload && typeof payload === 'object') {
                const maybeError = payload as { error?: unknown; message?: unknown };
                if (typeof maybeError.error === 'string' && maybeError.error.trim()) return maybeError.error;
                if (typeof maybeError.message === 'string' && maybeError.message.trim()) return maybeError.message;
            }
        } catch {
            // Fall through to text/message fallback.
        }
    }

    if (context?.text) {
        try {
            const raw = await context.text();
            if (raw && raw.trim()) return raw;
        } catch {
            // Fall through to default message fallback.
        }
    }

    return getErrorMessage(error);
}

/** Fetch the current authenticated admin user, or throw Unauthorized. */
async function requireUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) throw new Error('Unauthorized');
    return user;
}

/**
 * Toggle user account suspension
 */
export async function toggleUserSuspension(userId: string, currentStatus: boolean, reason?: string) {
    try {
        const newStatus = !currentStatus;
        const { error: updateError } = await supabase
            .from('profiles')
            .update({
                is_suspended: newStatus,
                internal_notes: reason ? `[Suspension Toggle] ${reason}` : undefined
            })
            .eq('id', userId);

        if (updateError) throw updateError;

        await logAdminAction(
            newStatus ? 'suspend_user' : 'unsuspend_user',
            'user',
            userId,
            { reason }
        );

        return { success: true };
    } catch (error: unknown) {
        console.error('[UserAction] toggleUserSuspension failed:', error);
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Update user governance fields (strikes, freeze, soft-delete)
 */
export async function updateUserGovernance(userId: string, updates: {
    strike_count?: number;
    is_frozen?: boolean;
    deleted_at?: string | null;
    internal_notes?: string;
}) {
    try {
        const { error: updateError } = await supabase
            .from('profiles')
            .update(updates)
            .eq('id', userId);

        if (updateError) throw updateError;

        await logAdminAction(
            'update_governance',
            'user',
            userId,
            { ...updates }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}

/**
 * Edit core profile data (full name, phone, account type, etc.).
 * Only governance-safe fields are allowed via this action.
 */
export async function updateUserProfile(userId: string, updates: {
    full_name?: string;
    phone_number?: string | null;
    bio?: string | null;
    identity_number?: string | null;
    identity_expiry?: string | null;
    identity_type?: string | null;
    traveler_type?: string | null;
    is_available?: boolean;
}) {
    try {
        // Whitelist guard.
        const allowed: Record<string, unknown> = {};
        const keys = [
            'full_name', 'phone_number', 'bio',
            'identity_number', 'identity_expiry', 'identity_type', 'traveler_type', 'is_available',
        ] as const;
        for (const k of keys) {
            const v = updates[k];
            if (v !== undefined) allowed[k] = v;
        }

        if (Object.keys(allowed).length === 0) {
            return { success: true, noop: true };
        }

        const { error } = await supabase.from('profiles').update(allowed).eq('id', userId);
        if (error) throw error;

        await logAdminAction('update_profile', 'user', userId, {
            fields: Object.keys(allowed),
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

type CapabilityStatus = 'none' | 'pending' | 'approved' | 'rejected' | 'suspended' | 'blocked';

/**
 * Update role/capability flags on a profile.
 *
 * Traveler and driver are capabilities in this app:
 * - traveler: traveler_status
 * - driver: traveler_status='approved' + is_driver=true
 */
export async function updateUserCapabilities(userId: string, updates: {
    traveler_status?: CapabilityStatus;
    traveler_type?: 'with_vehicle' | 'no_vehicle' | 'without_vehicle' | null;
    is_driver?: boolean;
}) {
    try {
        const allowed: Record<string, unknown> = {};
        const keys = [
            'traveler_status',
            'traveler_type',
            'is_driver',
        ] as const;

        for (const k of keys) {
            const v = updates[k];
            if (v !== undefined) allowed[k] = v;
        }

        if (Object.keys(allowed).length === 0) {
            return { success: true, noop: true };
        }

        const { error } = await supabase.from('profiles').update(allowed).eq('id', userId);
        if (error) throw error;

        await logAdminAction('update_user_capabilities', 'user', userId, {
            fields: Object.keys(allowed),
            updates: allowed,
        });

        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Hard-block (cannot use the app). Independent from `is_suspended`.
 *
 * Delegates to the `admin-action` Edge Function which performs both writes
 * server-side using the service role: (a) `profiles.is_blocked` toggle and
 * (b) `auth.admin.updateUserById(ban_duration)` so the user cannot mint a
 * new session even if their cached JWT is unexpired.
 */
export async function setUserBlocked(userId: string, blocked: boolean, reason?: string) {
    try {
        const { data, error } = await supabase.functions.invoke('admin-action', {
            body: {
                action: 'block_user',
                target_id: userId,
                params: { blocked, reason: reason ?? null },
            },
        });
        if (error) throw error;
        if (data?.error) throw new Error(data.error);

        await logAdminAction(blocked ? 'block_user' : 'unblock_user', 'user', userId, {
            reason,
            auth_ban_error: data?.authBanError ?? null,
        });

        return { success: true, authBanError: data?.authBanError ?? null };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Enable / disable (soft) — same as suspend but uses an explicit verb so the
 * UI can present "Disable account" without conflating with moderation.
 */
export async function setUserDisabled(userId: string, disabled: boolean, reason?: string) {
    return toggleUserSuspension(userId, !disabled, reason);
}

/**
 * Set / clear trusted or featured badge. Needs adminUser.id for
 * `trust_badge_set_by`.
 */
export async function setTrustBadge(userId: string, opts: {
    is_trusted?: boolean;
    is_featured?: boolean;
    trust_badge?: string | null;
}) {
    try {
        const adminUser = await requireUser();
        const updates: JsonObject = {};
        if (opts.is_trusted !== undefined) updates.is_trusted = opts.is_trusted;
        if (opts.is_featured !== undefined) updates.is_featured = opts.is_featured;
        if (opts.trust_badge !== undefined) updates.trust_badge = opts.trust_badge;
        updates.trust_badge_set_at = new Date().toISOString();
        updates.trust_badge_set_by = adminUser.id;

        const { error } = await supabase.from('profiles').update(updates).eq('id', userId);
        if (error) throw error;

        await logAdminAction('set_trust_badge', 'user', userId, { ...opts });
        return { success: true };
    } catch (e: unknown) {
        return { success: false, error: getErrorMessage(e) };
    }
}

/**
 * Create a new user from the admin panel.
 *
 * Delegates to the `admin-action` Edge Function (`create_user` case) which
 * runs server-side with the service role to invoke `auth.admin.createUser`
 * (or `inviteUserByEmail`) and then `admin_provision_profile` RPC. The Edge
 * Function rolls back the auth user if profile provisioning fails, avoiding
 * orphan auth rows.
 */
export async function createUserAccount(input: {
    email?: string;
    phone?: string;
    password?: string;
    full_name: string;
    make_driver?: boolean;
    send_invitation?: boolean;
}) {
    try {
        if (!input.email && !input.phone) {
            throw new Error('Either email or phone is required.');
        }

        const { data, error } = await supabase.functions.invoke('admin-action', {
            body: {
                action: 'create_user',
                params: {
                    email: input.email,
                    phone: input.phone,
                    password: input.password,
                    full_name: input.full_name,
                    make_driver: input.make_driver,
                    send_invitation: input.send_invitation,
                },
            },
        });
        if (error) throw error;
        if (data?.error) throw new Error(data.error);

        const createdUserId: string | undefined = data?.userId;
        if (!createdUserId) throw new Error('Edge Function returned no userId');

        await logAdminAction('create_user', 'user', createdUserId, {
            email: input.email,
            phone: input.phone,
            make_driver: !!input.make_driver,
            invited: !!input.send_invitation,
        });

        return {
            success: true,
            userId: createdUserId,
            generatedPassword: data?.generatedPassword ?? null,
        };
    } catch (e: unknown) {
        console.error('[createUserAccount] failed:', e);
        return { success: false, error: await getInvokeErrorMessage(e) };
    }
}

/**
 * Update Driver verification status
 */
export async function updateVerificationStatus(
    userId: string,
    type: 'driver',
    status: string,
    reason?: string
) {
    try {
        const updates: JsonObject = {};
        if (type === 'driver') updates.traveler_status = status;

        if (reason) updates.internal_notes = `[Verification ${status}] ${reason}`;

        const { error: updateError } = await supabase
            .from('profiles')
            .update(updates)
            .eq('id', userId);

        if (updateError) throw updateError;

        await logAdminAction(
            `verify_${type}_${status}`,
            'user',
            userId,
            { status, reason }
        );

        return { success: true };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
