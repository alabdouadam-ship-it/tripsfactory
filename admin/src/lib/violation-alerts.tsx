'use client';

/**
 * Realtime "violation alerts" provider.
 *
 * Subscribes to:
 *   - INSERT on `reports`              (a user filed a new report)
 *   - UPDATE on `shipments` is_flagged (a shipment was flagged)
 *   - INSERT on `shipments` is_flagged (rare: shipment created already flagged)
 *
 * Maintains a counts object that the Sidebar consumes to render badges, and
 * pops a toast when a new event arrives while the admin has the dashboard
 * open. Counts are also refreshed on a 60-second interval as a safety net for
 * dropped realtime events.
 */

import { createContext, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';

export type ViolationCounts = {
    openReports: number;
    pendingShipments: number;
    pendingTrips: number;
};

const DEFAULT_COUNTS: ViolationCounts = {
    openReports: 0,
    pendingShipments: 0,
    pendingTrips: 0,
};
const OPEN_REPORT_STATUSES = new Set(['open', 'pending', 'investigating']);
const PENDING_SHIPMENT_STATUSES = new Set(['pending_review', 'escalated']);

type ViolationAlertsValue = {
    counts: ViolationCounts;
    refresh: () => Promise<void>;
};

const Ctx = createContext<ViolationAlertsValue>({
    counts: DEFAULT_COUNTS,
    refresh: async () => { },
});

export function useViolationAlerts() {
    return useContext(Ctx);
}

export function ViolationAlertsProvider({ children }: { children: React.ReactNode }) {
    const { toast } = useToast();
    const t = useT();
    const [counts, setCounts] = useState<ViolationCounts>(DEFAULT_COUNTS);
    // Avoid surfacing a toast for the very first load (the admin already sees
    // the badge).
    const initialized = useRef(false);
    const toastRef = useRef(toast);
    const tRef = useRef(t);

    useEffect(() => {
        toastRef.current = toast;
        tRef.current = t;
    }, [toast, t]);

    async function refresh() {
        const [reportsRes, shipmentsRes, tripsRes] = await Promise.all([
            (supabase.from('reports') as any)
                .select('*', { count: 'exact', head: true })
                .or('status.is.null,status.eq.open,status.eq.pending,status.eq.investigating'),
            (supabase.from('shipments') as any)
                .select('*', { count: 'exact', head: true })
                .or('moderation_status.eq.pending_review,moderation_status.eq.escalated,is_flagged.eq.true'),
            (supabase.from('trips') as any)
                .select('*', { count: 'exact', head: true })
                .eq('status', 'pending_approval'),
        ]);

        setCounts({
            openReports: reportsRes.count ?? 0,
            pendingShipments: shipmentsRes.count ?? 0,
            pendingTrips: tripsRes.count ?? 0,
        });
    }

    useEffect(() => {
        let cancelled = false;
        refresh().then(() => {
            if (!cancelled) initialized.current = true;
        });

        const reportsChannel = supabase
            .channel('admin-violation-alerts-reports')
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'reports' }, (payload) => {
                const status = String((payload.new as any)?.status ?? 'open');
                const isOpenReport = OPEN_REPORT_STATUSES.has(status);
                if (initialized.current && isOpenReport) {
                    const reason = (payload.new as any)?.reason ?? '';
                    toastRef.current(
                        `${tRef.current('alerts.newReport', 'New report')}: ${String(reason).slice(0, 60) || '—'}`,
                        'info',
                    );
                }
                if (isOpenReport) refresh();
            })
            .subscribe();

        const shipmentsChannel = supabase
            .channel('admin-violation-alerts-shipments')
            .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'shipments' }, (payload) => {
                const newRow = payload.new as any;
                const oldRow = payload.old as any;
                if (initialized.current && newRow?.is_flagged && !oldRow?.is_flagged) {
                    toastRef.current(
                        tRef.current('alerts.shipmentFlagged', 'A shipment was flagged for moderation'),
                        'info',
                    );
                    refresh();
                } else if (initialized.current && newRow?.moderation_status !== oldRow?.moderation_status) {
                    refresh();
                }
            })
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'shipments' }, (payload) => {
                const newRow = payload.new as any;
                const isPending = PENDING_SHIPMENT_STATUSES.has(String(newRow?.moderation_status ?? ''));
                if (initialized.current && (newRow?.is_flagged || isPending)) {
                    toastRef.current(tRef.current('alerts.shipmentFlagged', 'A shipment was flagged for moderation'), 'info');
                    refresh();
                }
            })
            .subscribe();
        const tripsChannel = supabase
            .channel('admin-violation-alerts-trips')
            .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'trips' }, (payload) => {
                const row = payload.new as any;
                if (String(row?.status ?? '') === 'pending_approval') refresh();
            })
            .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'trips' }, (payload) => {
                const newRow = payload.new as any;
                const oldRow = payload.old as any;
                if (String(newRow?.status ?? '') !== String(oldRow?.status ?? '')) refresh();
            })
            .subscribe();

        const interval = setInterval(refresh, 60_000);

        return () => {
            cancelled = true;
            supabase.removeChannel(reportsChannel);
            supabase.removeChannel(shipmentsChannel);
            supabase.removeChannel(tripsChannel);
            clearInterval(interval);
        };
    }, []);

    const value = useMemo<ViolationAlertsValue>(() => ({ counts, refresh }), [counts]);

    return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}
