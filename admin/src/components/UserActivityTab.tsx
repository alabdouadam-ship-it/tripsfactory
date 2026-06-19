'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Profile } from '@/lib/types';
import { useT } from '@/lib/i18n';
import {
    Activity,
    Clock,
    LogIn,
    Package,
    Route,
    MessageSquare,
    Star,
    Flag,
    ShieldAlert,
} from 'lucide-react';

interface Props {
    user: Profile;
}

type TimelineEvent = {
    id: string;
    at: string;
    icon: any;
    iconClass: string;
    title: string;
    detail?: string;
    href?: string;
};

/**
 * Cross-table user activity timeline. Pulls from:
 *   - profiles (created_at, last_seen_at if present)
 *   - admin_audit_log (admin actions targeting this user)
 *   - trips, shipments, bookings, ratings, reports (recent rows)
 *
 * Everything is loaded with a low row-cap and merged client-side. The page
 * gracefully degrades if any individual source fails (e.g. table doesn't have
 * the column yet); admins still see whatever is available.
 */
export function UserActivityTab({ user }: Props) {
    const t = useT();
    const [events, setEvents] = useState<TimelineEvent[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let cancelled = false;
        async function load() {
            setLoading(true);
            const merged: TimelineEvent[] = [];

            // 1) Profile lifecycle
            if (user.created_at) {
                merged.push({
                    id: `profile-created-${user.id}`,
                    at: user.created_at,
                    icon: LogIn,
                    iconClass: 'bg-blue-500/10 text-blue-600',
                    title: t('users.activity.created', 'Account created'),
                });
            }
            const lastSeen = (user as any).last_seen_at as string | null | undefined;
            if (lastSeen) {
                merged.push({
                    id: `profile-lastseen-${user.id}`,
                    at: lastSeen,
                    icon: Clock,
                    iconClass: 'bg-emerald-500/10 text-emerald-600',
                    title: t('users.activity.lastSeen', 'Last seen'),
                });
            }

            // 2) Admin actions taken against the user
            try {
                const { data, error } = await (supabase
                    .from('admin_audit_log') as any)
                    .select('id, created_at, action, details')
                    .eq('target_type', 'user')
                    .eq('target_id', user.id)
                    .order('created_at', { ascending: false })
                    .limit(50);
                if (error) {
                    console.warn('[UserActivityTab] Failed to load admin audit events:', error.message);
                }
                (data || []).forEach((row: any) => {
                    merged.push({
                        id: `audit-${row.id}`,
                        at: row.created_at,
                        icon: ShieldAlert,
                        iconClass: 'bg-amber-500/10 text-amber-600',
                        title: t(`users.activity.admin.${row.action}`, row.action),
                        detail: row.details ? JSON.stringify(row.details).slice(0, 160) : undefined,
                    });
                });
            } catch { /* table may be missing; ignore */ }

            // 3) Trips published
            try {
                const { data, error } = await supabase
                    .from('trips')
                    .select('id, created_at, status')
                    .eq('traveler_id', user.id)
                    .order('created_at', { ascending: false })
                    .limit(10);
                if (error) {
                    console.warn('[UserActivityTab] Failed to load user trips:', error.message);
                }
                (data || []).forEach((row: any) => {
                    merged.push({
                        id: `trip-${row.id}`,
                        at: row.created_at,
                        icon: Route,
                        iconClass: 'bg-orange-500/10 text-orange-600',
                        title: t('users.activity.tripPublished', 'Published a trip'),
                        detail: `#${String(row.id).slice(0, 8)} · ${row.status}`,
                        href: `/trips/${row.id}`,
                    });
                });
            } catch { /* ignore */ }

            // 4) Shipments published
            try {
                const { data, error } = await supabase
                    .from('shipments')
                    .select('id, created_at, status')
                    .eq('sender_id', user.id)
                    .order('created_at', { ascending: false })
                    .limit(10);
                if (error) {
                    console.warn('[UserActivityTab] Failed to load user shipments:', error.message);
                }
                (data || []).forEach((row: any) => {
                    merged.push({
                        id: `shipment-${row.id}`,
                        at: row.created_at,
                        icon: Package,
                        iconClass: 'bg-indigo-500/10 text-indigo-600',
                        title: t('users.activity.shipmentPublished', 'Published a shipment'),
                        detail: `#${String(row.id).slice(0, 8)} · ${row.status}`,
                        href: `/shipments/${row.id}`,
                    });
                });
            } catch { /* ignore */ }

            // 5) Bookings
            try {
                const { data, error } = await (supabase
                    .from('bookings') as any)
                    .select('id, created_at, status')
                    .or(`requester_id.eq.${user.id},traveler_id.eq.${user.id}`)
                    .order('created_at', { ascending: false })
                    .limit(15);
                if (error) {
                    console.warn('[UserActivityTab] Failed to load user bookings:', error.message);
                }
                (data || []).forEach((row: any) => {
                    merged.push({
                        id: `booking-${row.id}`,
                        at: row.created_at,
                        icon: MessageSquare,
                        iconClass: 'bg-sky-500/10 text-sky-600',
                        title: t('users.activity.booking', 'Booking activity'),
                        detail: `#${String(row.id).slice(0, 8)} · ${row.status}`,
                    });
                });
            } catch { /* ignore */ }

            // 6) Ratings written
            try {
                const { data, error } = await supabase
                    .from('ratings')
                    .select('id, created_at, rating')
                    .eq('rater_id', user.id)
                    .order('created_at', { ascending: false })
                    .limit(10);
                if (error) {
                    console.warn('[UserActivityTab] Failed to load user ratings:', error.message);
                }
                (data || []).forEach((row: any) => {
                    merged.push({
                        id: `rating-${row.id}`,
                        at: row.created_at,
                        icon: Star,
                        iconClass: 'bg-yellow-500/10 text-yellow-600',
                        title: t('users.activity.rated', 'Submitted a rating'),
                        detail: `★ ${row.rating}`,
                    });
                });
            } catch { /* ignore */ }

            // 7) Reports filed by this user
            try {
                const { data, error } = await supabase
                    .from('reports')
                    .select('id, created_at, reason, status')
                    .eq('reporter_id', user.id)
                    .order('created_at', { ascending: false })
                    .limit(10);
                if (error) {
                    console.warn('[UserActivityTab] Failed to load user reports:', error.message);
                }
                (data || []).forEach((row: any) => {
                    merged.push({
                        id: `report-${row.id}`,
                        at: row.created_at,
                        icon: Flag,
                        iconClass: 'bg-red-500/10 text-red-600',
                        title: t('users.activity.reported', 'Filed a report'),
                        detail: `${row.reason ?? ''} · ${row.status ?? ''}`,
                    });
                });
            } catch { /* ignore */ }

            merged.sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());
            if (!cancelled) {
                setEvents(merged);
                setLoading(false);
            }
        }
        load();
        return () => { cancelled = true; };
    }, [user.id, t]);

    if (loading) {
        return (
            <div className="theme-card rounded-2xl p-8 border border-[var(--surface-border)] flex items-center gap-3 theme-muted text-sm">
                <Activity className="h-5 w-5 animate-pulse" />
                {t('users.activity.loading', 'Loading activity timeline…')}
            </div>
        );
    }

    if (!events.length) {
        return (
            <div className="theme-card rounded-2xl p-8 border border-[var(--surface-border)] text-center theme-muted text-sm">
                {t('users.activity.empty', 'No recorded activity yet for this user.')}
            </div>
        );
    }

    return (
        <div className="theme-card rounded-2xl border border-[var(--surface-border)] overflow-hidden">
            <ol className="relative">
                {events.map((ev) => (
                    <li key={ev.id} className="flex gap-4 px-6 py-4 border-b border-[var(--surface-border)] last:border-b-0 hover:theme-bg-secondary transition">
                        <div className={`h-10 w-10 rounded-xl flex items-center justify-center flex-shrink-0 ${ev.iconClass}`}>
                            <ev.icon className="h-5 w-5" />
                        </div>
                        <div className="flex-1 min-w-0">
                            <div className="flex items-baseline justify-between gap-3">
                                <p className="font-bold theme-heading text-sm truncate">
                                    {ev.href ? (
                                        <a href={ev.href} className="hover:underline">{ev.title}</a>
                                    ) : ev.title}
                                </p>
                                <span className="text-[0.625rem] theme-muted font-mono uppercase tracking-widest whitespace-nowrap">
                                    {new Date(ev.at).toLocaleString()}
                                </span>
                            </div>
                            {ev.detail && (
                                <p className="text-xs theme-muted mt-0.5 truncate">{ev.detail}</p>
                            )}
                        </div>
                    </li>
                ))}
            </ol>
        </div>
    );
}
