// Client-side data module. Authorization is enforced at the database layer:
//   * notifications INSERT — RLS `auth.uid() = user_id OR is_admin()`
//     (00006:158); admins can create rows for any user.
//
//     ⚠️ RLS GAP: original JS checkRole was `['ops_admin', 'support_agent']`;
//     current RLS allows any admin role. Tighten in planned 00049.
//
// Push delivery: a database webhook on `notifications` INSERT triggers the
// `push-notification` Edge Function (see notif-test.md), which fetches FCM
// tokens and sends via the FCM v1 API. So inserting a row here is
// sufficient — we do not need to invoke any Edge Function from this module.
//
// Future optimisation: for very large broadcasts, switching to the
// `send-push-notification` Edge Function (single invocation, batched
// inserts + batched FCM) avoids N webhook invocations.

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
 * Send an admin notification to a single user, a segment, or all users.
 * Inserts rows into `notifications`; the DB webhook fires the
 * `push-notification` Edge Function for delivery to FCM.
 */
export async function sendAdminNotification(opts: {
    mode: 'single' | 'segment' | 'broadcast';
    title: string;
    body: string;
    targetUserId?: string;
    segment?: 'all' | 'drivers' | 'clients' | 'individuals';
}) {
    try {
        const adminUser = await requireUser();

        const { mode, title, body, targetUserId, segment } = opts;

        if (!title.trim() || !body.trim()) {
            throw new Error('Title and body are required.');
        }

        if (mode === 'single') {
            if (!targetUserId?.trim()) throw new Error('User ID is required for single-user notifications.');

            const { error } = await supabase.from('notifications').insert({
                user_id: targetUserId.trim(),
                title,
                body,
                data: { type: 'admin_notification', sent_by: adminUser.id },
            });

            if (error) throw error;

            await logAdminAction('send_notification_single', 'notification', targetUserId, {
                title,
            });

            return { success: true, recipientCount: 1 };
        }

        // Segment or broadcast — fetch matching user IDs.
        let query = supabase.from('profiles').select('id');

        if (mode === 'segment' && segment && segment !== 'all') {
            if (segment === 'drivers') {
                query = query.neq('traveler_status', 'none').not('traveler_status', 'is', null);
            } else if (segment === 'clients') {
                query = query.or('traveler_status.is.null,traveler_status.eq.none');
            } else if (segment === 'individuals') {
                query = query.or('traveler_status.is.null,traveler_status.eq.none');
            }
        }

        const { data: users, error: usersError } = await query;
        if (usersError) throw usersError;
        if (!users?.length) throw new Error('No users found for the selected segment.');

        const inserts = users.map(u => ({
            user_id: u.id,
            title,
            body,
            data: { type: 'admin_broadcast', sent_by: adminUser.id },
        }));

        const BATCH_SIZE = 500;
        for (let i = 0; i < inserts.length; i += BATCH_SIZE) {
            const { error } = await supabase.from('notifications').insert(inserts.slice(i, i + BATCH_SIZE));
            if (error) throw error;
        }

        await logAdminAction('send_notification_broadcast', 'notification', null, {
            mode,
            segment: mode === 'segment' ? segment : 'all',
            title,
            recipient_count: users.length,
        });

        return { success: true, recipientCount: users.length };
    } catch (error: unknown) {
        return { success: false, error: getErrorMessage(error) };
    }
}
