'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Shipment, ShipmentStatus } from '@/lib/types';
import { Package, Trash2, Calendar, Download, Weight, CreditCard, Eye, Ban, ChevronLeft, ChevronRight, Flag, Pencil, ShieldCheck, AlertTriangle, RefreshCw, Handshake } from 'lucide-react';
import { exportToCSV, getCityLabel } from '@/lib/utils';
import { StatusBadge } from '@/components/StatusBadge';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import { useRouter, useSearchParams } from 'next/navigation';
import { useT } from '@/lib/i18n';
import { ShipmentEditModal } from '@/components/ShipmentEditModal';
import { ShipmentModerationModal } from '@/components/ShipmentModerationModal';
import { deleteShipment as deleteShipmentAction } from '@/app/actions/shipment-actions';

const PAGE_SIZE = 24;
const QUERY_TIMEOUT_MS = 15000;
const MODERATION_FILTERS = ['all', 'flagged', 'pending_review', 'illegal', 'fraud', 'removed', 'cleared'];
const STATUS_FILTERS: Array<ShipmentStatus | 'all'> = [
    'all',
    'pending_approval',
    'pending',
    'in_communication',
    'accepted',
    'picked_up',
    'in_transit',
    'delivered',
    'completed',
    'cancelled',
    'rejected',
    'expired',
    'frozen',
    'disputed',
];

type OfferSummary = {
    total: number;
    accepted?: {
        id: string;
        price: number | string | null;
        driver_id: string | null;
        driver_name?: string | null;
        status: string;
    };
};

type OfferRow = {
    id: string;
    shipment_id: string | null;
    driver_id: string | null;
    price: number | string | null;
    status: string;
    driver_profile?: { full_name?: string | null } | null;
};

function getModerationFilter(value: string | null) {
    return value && MODERATION_FILTERS.includes(value) ? value : 'all';
}

export default function ShipmentsPage() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const { toast, confirm: confirmDialog } = useToast();
    const t = useT();
    const [shipments, setShipments] = useState<Shipment[]>([]);
    const [offerSummaries, setOfferSummaries] = useState<Record<string, OfferSummary>>({});
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [moderationFilter, setModerationFilter] = useState<string>(() => getModerationFilter(searchParams.get('moderation')));
    const [page, setPage] = useState(0);
    const [totalCount, setTotalCount] = useState(0);
    const [errorMessage, setErrorMessage] = useState('');
    const [offerSummaryError, setOfferSummaryError] = useState('');
    const [editTarget, setEditTarget] = useState<any | null>(null);
    const [moderationTarget, setModerationTarget] = useState<{ shipment: any; mode: 'flag' | 'resolve' } | null>(null);

    // Search is temporarily disabled for server-side pagination due to cross-table limitations
    // const [search, setSearch] = useState('');

    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');

    useEffect(() => {
        const nextModerationFilter = getModerationFilter(searchParams.get('moderation'));
        setModerationFilter(nextModerationFilter);
        setPage(0);
    }, [searchParams]);

    useEffect(() => {
        setPage(0);
    }, [statusFilter, moderationFilter, dateFrom, dateTo]);

    useEffect(() => {
        fetchShipments();
    }, [page, statusFilter, moderationFilter, dateFrom, dateTo]);

    function withTimeout<T>(promise: PromiseLike<T>, timeoutMs = QUERY_TIMEOUT_MS): Promise<T> {
        return new Promise<T>((resolve, reject) => {
            const timer = window.setTimeout(() => reject(new Error('Query timeout exceeded')), timeoutMs);
            Promise.resolve(promise)
                .then((value) => resolve(value))
                .catch((error) => reject(error))
                .finally(() => window.clearTimeout(timer));
        });
    }

    function buildOfferSummaries(rows: OfferRow[]) {
        return rows.reduce<Record<string, OfferSummary>>((acc, offer) => {
            if (!offer.shipment_id) return acc;
            const current = acc[offer.shipment_id] || { total: 0 };
            current.total += 1;
            if (offer.status === 'accepted' || offer.status === 'completed') {
                current.accepted = {
                    id: offer.id,
                    price: offer.price,
                    driver_id: offer.driver_id,
                    driver_name: offer.driver_profile?.full_name,
                    status: offer.status,
                };
            }
            acc[offer.shipment_id] = current;
            return acc;
        }, {});
    }

    function formatMoney(value: number | string | null | undefined) {
        if (value == null) return t('common.na', 'N/A');
        const amount = typeof value === 'string' ? Number(value) : value;
        if (!Number.isFinite(amount)) return t('common.na', 'N/A');
        return `${amount}`;
    }

    async function fetchShipments() {
        setLoading(true);
        setErrorMessage('');
        setOfferSummaryError('');
        try {
            let query: any = supabase
                .from('shipments')
                .select(`
                    *,
                    profile:profiles!sender_id(full_name, avatar_url),
                    pickup:locations!pickup_location_id(city_name_ar, city_name_en),
                    dropoff:locations!dropoff_location_id(city_name_ar, city_name_en)
                `, { count: 'exact' });

            if (statusFilter !== 'all') {
                query = query.eq('status', statusFilter);
            }
            if (moderationFilter === 'flagged') query = query.eq('is_flagged', true);
            else if (moderationFilter === 'pending_review') query = query.eq('moderation_status', 'pending_review');
            else if (moderationFilter === 'removed') query = query.eq('moderation_status', 'removed');
            else if (moderationFilter === 'cleared') query = query.eq('moderation_status', 'cleared');
            else if (moderationFilter === 'illegal') query = query.eq('flag_category', 'illegal');
            else if (moderationFilter === 'fraud') query = query.eq('flag_category', 'fraud');

            if (dateFrom) query = query.gte('created_at', `${dateFrom}T00:00:00.000Z`);
            if (dateTo) query = query.lte('created_at', `${dateTo}T23:59:59.999Z`);

            const from = page * PAGE_SIZE;
            const to = from + PAGE_SIZE - 1;

            const result: any = await withTimeout(
                query
                    .order('created_at', { ascending: false })
                    .range(from, to)
            );
            const { data, count, error } = result;

            if (error) throw error;

            const shipmentRows = (data as Shipment[]) || [];
            setShipments(shipmentRows);
            setTotalCount(count || 0);

            const shipmentIds = shipmentRows.map((shipment) => shipment.id);
            if (shipmentIds.length === 0) {
                setOfferSummaries({});
            } else {
                const offersResult: any = await withTimeout(
                    supabase
                        .from('offers')
                        .select(`
                            id,
                            shipment_id,
                            driver_id,
                            price,
                            status,
                            driver_profile:profiles!offers_driver_id_fkey(full_name)
                        `)
                        .in('shipment_id', shipmentIds),
                    8000,
                );

                if (offersResult.error) {
                    setOfferSummaries({});
                    setOfferSummaryError(t('shipments.offerSummary.loadFailed', 'Offer summaries could not be loaded.'));
                    toast(t('shipments.offerSummary.loadFailed', 'Offer summaries could not be loaded.'), 'error');
                } else {
                    setOfferSummaries(buildOfferSummaries((offersResult.data as OfferRow[]) || []));
                }
            }
        } catch (error) {
            console.error('Error fetching shipments:', error);
            setShipments([]);
            setOfferSummaries({});
            setTotalCount(0);
            const message = t('shipments.toast.loadFailed', 'Failed to load shipments');
            setErrorMessage(message);
            toast(message, 'error');
        } finally {
            setLoading(false);
        }
    }

    function cancelShipment(shipmentId: string) {
        confirmDialog({
            title: t('shipments.dialog.cancelShipment.title'),
            message: t('shipments.dialog.cancelShipment.message'),
            confirmLabel: t('shipments.dialog.cancelShipment.confirmLabel'),
            onConfirm: async () => {
                const { error } = await supabase.from('shipments').update({ status: 'cancelled' }).eq('id', shipmentId);
                if (error) {
                    toast(t('shipments.toast.cancelFailed'), 'error');
                } else {
                    setShipments(shipments.map(s => s.id === shipmentId ? { ...s, status: 'cancelled' } : s));
                    await logAdminAction('cancel_shipment', 'shipment', shipmentId);
                    toast(t('shipments.toast.shipmentCancelled'), 'success');
                }
            },
        });
    }

    function deleteShipment(id: string) {
        confirmDialog({
            title: t('shipments.dialog.deleteShipment.title'),
            message: t('shipments.dialog.deleteShipment.message'),
            confirmLabel: t('shipments.dialog.deleteShipment.confirmLabel'),
            onConfirm: async () => {
                const result = await deleteShipmentAction(id);
                if (!result.success) {
                    toast(result.error || t('shipments.toast.deleteFailed'), 'error');
                } else {
                    setShipments(shipments.filter(s => s.id !== id));
                    toast(t('shipments.toast.shipmentDeleted'), 'success');
                }
            },
        });
    }



    // Export function needs to fetch all matching current filters
    async function handleExport() {
        toast(t('shipments.toast.exporting'), 'success');
        let query = supabase
            .from('shipments')
            .select(`
                *,
                profile:profiles!sender_id(full_name, avatar_url),
                pickup:locations!pickup_location_id(city_name_ar, city_name_en),
                dropoff:locations!dropoff_location_id(city_name_ar, city_name_en)
            `);

        if (statusFilter !== 'all') {
            query = query.eq('status', statusFilter);
        }
        if (moderationFilter === 'flagged') query = query.eq('is_flagged', true);
        else if (moderationFilter === 'pending_review') query = query.eq('moderation_status', 'pending_review');
        else if (moderationFilter === 'removed') query = query.eq('moderation_status', 'removed');
        else if (moderationFilter === 'cleared') query = query.eq('moderation_status', 'cleared');
        else if (moderationFilter === 'illegal') query = query.eq('flag_category', 'illegal');
        else if (moderationFilter === 'fraud') query = query.eq('flag_category', 'fraud');
        if (dateFrom) query = query.gte('created_at', `${dateFrom}T00:00:00.000Z`);
        if (dateTo) query = query.lte('created_at', `${dateTo}T23:59:59.999Z`);

        const { data, error } = await query.order('created_at', { ascending: false });
        if (error) {
            toast(error.message || t('shipments.toast.exportFailed', 'Export failed'), 'error');
            return;
        }
        if (data) {
            exportToCSV(data, 'shipments_export', (msg) => toast(msg, 'error'));
        }
    }

    const totalPages = Math.ceil(totalCount / PAGE_SIZE);

    if (loading) return <Loading />;

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold theme-heading">
                    {t('shipments.title', 'Shipments Management')}
                </h1>
                <div className="flex items-center gap-2">
                    <button
                        onClick={fetchShipments}
                        className="flex items-center gap-2 border border-[var(--surface-border)] theme-bg-secondary theme-heading px-4 py-2 rounded-lg hover:opacity-80 transition"
                    >
                        <RefreshCw className="h-4 w-4" /> {t('common.refresh', 'Refresh')}
                    </button>
                    <button
                        onClick={handleExport}
                        className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition"
                    >
                        <Download className="h-4 w-4" /> {t('shipments.export', 'Export')}
                    </button>
                    <div className="theme-bg-secondary px-4 py-2 rounded-lg border border-[var(--surface-border)] font-medium theme-heading">
                        {t('common.total', 'Total')}: {totalCount}
                    </div>
                </div>
            </div>

            {errorMessage && (
                <div className="rounded-xl border border-red-500/20 bg-red-500/10 p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-center gap-3 text-red-700">
                        <AlertTriangle className="h-5 w-5" />
                        <p className="text-sm font-bold">{errorMessage}</p>
                    </div>
                    <button
                        type="button"
                        onClick={fetchShipments}
                        className="inline-flex items-center justify-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-xs font-black uppercase tracking-widest text-white hover:bg-red-700"
                    >
                        <RefreshCw className="h-4 w-4" />
                        {t('common.retry', 'Retry')}
                    </button>
                </div>
            )}

            {offerSummaryError && !errorMessage && (
                <div className="rounded-xl border border-amber-500/20 bg-amber-500/10 p-3 text-sm font-bold text-amber-700 flex items-center gap-2">
                    <AlertTriangle className="h-4 w-4" />
                    {offerSummaryError}
                </div>
            )}

            {/* Filter */}
            <div className="form-on-light flex flex-col gap-4 md:flex-row md:items-center theme-bg-secondary p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
                <div className="flex flex-wrap items-center gap-2">
                    <span className="text-xs font-bold theme-muted uppercase">
                        {t('shipments.dateRange', 'Date range')}
                    </span>
                    <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none transition" />
                    <span className="theme-muted opacity-40">-</span>
                    <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none transition" />
                </div>
                <div className="flex gap-2 flex-wrap">
                    {STATUS_FILTERS.map((status) => (
                        <button
                            key={status}
                            onClick={() => setStatusFilter(status)}
                            className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition-all ${statusFilter === status
                                ? 'bg-blue-600 text-white shadow-sm'
                                : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'
                                }`}
                        >
                            {t(`shipments.status.${status}`, status.replace('_', ' '))}
                        </button>
                    ))}
                </div>
                <div className="flex flex-wrap items-center gap-2 md:ml-auto">
                    <span className="text-xs font-bold theme-muted uppercase">{t('shipments.moderation', 'Moderation')}</span>
                    <select
                        value={moderationFilter}
                        onChange={e => setModerationFilter(e.target.value)}
                        className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none transition"
                    >
                        <option value="all">{t('shipments.moderation.all', 'All')}</option>
                        <option value="flagged">{t('shipments.moderation.flagged', 'Flagged')}</option>
                        <option value="pending_review">{t('shipments.moderation.pending', 'Pending review')}</option>
                        <option value="illegal">{t('shipments.moderation.illegal', 'Illegal')}</option>
                        <option value="fraud">{t('shipments.moderation.fraud', 'Fraudulent')}</option>
                        <option value="removed">{t('shipments.moderation.removed', 'Removed')}</option>
                        <option value="cleared">{t('shipments.moderation.cleared', 'Cleared')}</option>
                    </select>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
                {shipments.map((shipment) => {
                    const offerSummary = offerSummaries[shipment.id];
                    const acceptedOffer = offerSummary?.accepted;

                    return (
                    <div key={shipment.id} className="bg-[var(--surface)] rounded-xl border border-[var(--surface-border)] shadow-sm overflow-hidden hover:shadow-lg transition-all flex flex-col group">
                        <div className="p-6 flex-1">
                            <div className="flex justify-between items-start mb-6">
                                <div className="flex items-center gap-3">
                                    <div className="h-10 w-10 rounded-full bg-blue-500/10 flex items-center justify-center text-blue-600 group-hover:bg-blue-500/20 transition-colors">
                                        <Package className="h-5 w-5" />
                                    </div>
                                    <div>
                                        <h3 className="text-sm font-bold theme-heading leading-tight">{shipment.profile?.full_name || 'Anonymous'}</h3>
                                        <p className="text-[0.625rem] theme-muted font-mono opacity-80">ID: {shipment.id.slice(0, 8)}</p>
                                    </div>
                                </div>
                                <div className="flex flex-col items-end gap-1">
                                    <StatusBadge status={shipment.status} />
                                    {(shipment as any).is_flagged && (
                                        <span className="px-2 py-0.5 rounded-md text-[0.5625rem] font-black uppercase tracking-widest bg-red-500/10 text-red-600 border border-red-500/20 flex items-center gap-1">
                                            <Flag className="h-3 w-3" /> {(shipment as any).flag_category || 'flagged'}
                                        </span>
                                    )}
                                </div>
                            </div>

                            <div className="relative pl-6 space-y-6 before:absolute before:left-[11px] before:top-2 before:bottom-2 before:w-0.5 before:theme-bg-secondary before:opacity-20 before:dashed">
                                <div className="relative">
                                    <div className="absolute -left-[19px] top-1.5 h-2 w-2 rounded-full border-2 border-[var(--surface)] theme-bg-secondary ring-2 theme-bg-secondary/40"></div>
                                    <p className="text-[0.625rem] theme-muted uppercase font-bold tracking-widest opacity-60">{t('shipmentDetail.route.pickup', 'Pickup')}</p>
                                    <p className="font-bold theme-heading text-sm">{getCityLabel(shipment.pickup)}</p>
                                </div>
                                <div className="relative">
                                    <div className="absolute -left-[19px] top-1.5 h-2 w-2 rounded-full border-2 border-[var(--surface)] bg-blue-500 ring-2 ring-blue-500/20"></div>
                                    <p className="text-[0.625rem] theme-muted uppercase font-bold tracking-widest opacity-60">{t('shipmentDetail.route.dropoff', 'Dropoff')}</p>
                                    <p className="font-bold theme-heading text-sm">{getCityLabel(shipment.dropoff)}</p>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4 mt-8 pt-4 border-t border-[var(--surface-border)]">
                                <div className="bg-blue-500/5 p-3 rounded-lg border border-blue-500/10">
                                    <p className="text-[0.625rem] theme-muted uppercase font-bold mb-1 flex items-center gap-1 opacity-60">
                                        <CreditCard className="h-3 w-3" /> {t('shipments.card.basePrice', 'Base Price')}
                                    </p>
                                    <p className="text-lg font-black theme-heading">{formatMoney(shipment.price)}</p>
                                </div>
                                <div className="bg-blue-500/5 p-3 rounded-lg border border-blue-500/10">
                                    <p className="text-[0.625rem] theme-muted uppercase font-bold mb-1 flex items-center gap-1 opacity-60">
                                        <Weight className="h-3 w-3" /> {t('shipments.card.weight', 'Weight')}
                                    </p>
                                    <p className="text-lg font-black theme-heading">{shipment.weight_kg} <span className="text-xs font-normal theme-muted">KG</span></p>
                                </div>
                            </div>

                            <div className="mt-4 rounded-lg border border-[var(--surface-border)] theme-bg-secondary/50 p-3">
                                <div className="flex items-start justify-between gap-3">
                                    <div>
                                        <p className="text-[0.625rem] theme-muted uppercase font-bold tracking-widest opacity-60 flex items-center gap-1">
                                            <Handshake className="h-3 w-3" /> {t('shipments.card.offers', 'Offers')}
                                        </p>
                                        <p className="mt-1 text-sm font-black theme-heading">
                                            {t('shipments.card.offerCount', '{count} offer(s)').replace('{count}', String(offerSummary?.total || 0))}
                                        </p>
                                    </div>
                                    {acceptedOffer ? (
                                        <div className="text-right">
                                            <p className="text-[0.625rem] font-black uppercase tracking-widest text-blue-700">
                                                {t('offers.status.accepted', 'Accepted')}
                                            </p>
                                            <p className="text-sm font-black theme-heading">{formatMoney(acceptedOffer.price)}</p>
                                            {acceptedOffer.driver_id && (
                                                <button
                                                    type="button"
                                                    onClick={() => router.push(`/users/${acceptedOffer.driver_id}`)}
                                                    className="text-[0.625rem] font-bold text-blue-700 hover:underline"
                                                >
                                                    {acceptedOffer.driver_name || acceptedOffer.driver_id.slice(0, 8)}
                                                </button>
                                            )}
                                        </div>
                                    ) : (
                                        <p className="text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                            {t('shipments.card.noAcceptedOffer', 'No accepted offer')}
                                        </p>
                                    )}
                                </div>
                            </div>
                        </div>

                        <div className="theme-bg-secondary px-6 py-3 flex justify-between items-center border-t border-[var(--surface-border)]">
                            <div className="flex items-center gap-1.5 text-[0.625rem] theme-muted font-bold uppercase opacity-80">
                                <Calendar className="h-3.5 w-3.5" />
                                {new Date(shipment.created_at).toLocaleDateString()}
                            </div>
                            <div className="flex items-center gap-1">
                                <button
                                    onClick={() => router.push(`/shipments/${shipment.id}`)}
                                    className="theme-muted hover:text-blue-500 p-1.5 hover:bg-blue-500/10 rounded-lg transition-all"
                                    title={t('common.viewDetails')}
                                >
                                    <Eye className="h-4 w-4" />
                                </button>
                                <button
                                    onClick={() => setEditTarget(shipment)}
                                    className="theme-muted hover:text-blue-500 p-1.5 hover:bg-blue-500/10 rounded-lg transition-all"
                                    title={t('shipments.edit.title', 'Edit shipment')}
                                >
                                    <Pencil className="h-4 w-4" />
                                </button>
                                {!(shipment as any).is_flagged && (
                                    <button
                                        onClick={() => setModerationTarget({ shipment, mode: 'flag' })}
                                        className="theme-muted hover:text-red-500 p-1.5 hover:bg-red-500/10 rounded-lg transition-all"
                                        title={t('shipments.mod.flagBtn', 'Flag for review')}
                                    >
                                        <Flag className="h-4 w-4" />
                                    </button>
                                )}
                                {(shipment as any).is_flagged && (
                                    <button
                                        onClick={() => setModerationTarget({ shipment, mode: 'resolve' })}
                                        className="theme-muted hover:text-purple-500 p-1.5 hover:bg-purple-500/10 rounded-lg transition-all"
                                        title={t('shipments.mod.resolveTitle', 'Resolve moderation')}
                                    >
                                        <ShieldCheck className="h-4 w-4" />
                                    </button>
                                )}
                                {!['cancelled', 'delivered', 'completed', 'rejected'].includes(shipment.status) && (
                                    <button
                                        onClick={() => cancelShipment(shipment.id)}
                                        className="theme-muted hover:text-orange-500 p-1.5 hover:bg-orange-500/10 rounded-lg transition-all"
                                        title={t('shipments.dialog.cancelShipment.title')}
                                    >
                                        <Ban className="h-4 w-4" />
                                    </button>
                                )}
                                <button
                                    onClick={() => deleteShipment(shipment.id)}
                                    className="theme-muted hover:text-red-500 p-1.5 hover:bg-red-500/10 rounded-lg transition-all"
                                    title={t('shipments.dialog.deleteShipment.title')}
                                >
                                    <Trash2 className="h-4 w-4" />
                                </button>
                            </div>
                        </div>
                    </div>
                    );
                })}
            </div>

            {shipments.length === 0 && !loading && (
                <div className="text-center py-20 bg-[var(--surface)] rounded-xl border border-[var(--surface-border)]">
                    <p className="theme-muted font-medium">
                        {t('shipments.empty', 'No shipments match your filter.')}
                    </p>
                </div>
            )}

            {/* Pagination Controls */}
            {totalPages > 1 && (
                <div className="flex items-center justify-center gap-4 py-4">
                    <button onClick={() => setPage(Math.max(0, page - 1))} disabled={page === 0} className="flex items-center gap-1 px-4 py-2 rounded-lg border border-[var(--surface-border)] text-sm font-bold theme-muted hover:theme-heading hover:theme-bg-secondary transition-all disabled:opacity-30 disabled:cursor-not-allowed">
                        <ChevronLeft className="h-4 w-4" /> {t('common.previous', 'Previous')}
                    </button>
                    <div className="flex items-center gap-1">
                        <span className="text-sm font-bold theme-muted">
                            {t(
                                'common.pageOf',
                                `Page ${page + 1} of {total}`,
                            ).replace('{current}', String(page + 1)).replace('{total}', String(totalPages))}
                        </span>
                    </div>
                    <button onClick={() => setPage(Math.min(totalPages - 1, page + 1))} disabled={page === totalPages - 1} className="flex items-center gap-1 px-4 py-2 rounded-lg border border-[var(--surface-border)] text-sm font-bold theme-muted hover:theme-heading hover:theme-bg-secondary transition-all disabled:opacity-30 disabled:cursor-not-allowed">
                        {t('common.next', 'Next')} <ChevronRight className="h-4 w-4" />
                    </button>
                </div>
            )}

            {editTarget && (
                <ShipmentEditModal
                    shipment={editTarget}
                    onClose={() => setEditTarget(null)}
                    onSaved={(updates) => setShipments(prev => prev.map(s => s.id === editTarget.id ? { ...s, ...updates } : s))}
                />
            )}
            {moderationTarget && (
                <ShipmentModerationModal
                    shipment={moderationTarget.shipment}
                    mode={moderationTarget.mode}
                    onClose={() => setModerationTarget(null)}
                    onDone={(updates) => setShipments(prev => prev.map(s => s.id === moderationTarget.shipment.id ? { ...s, ...updates } : s))}
                />
            )}
        </div>
    );
}
