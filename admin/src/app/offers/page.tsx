'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { ExternalLink, Handshake, RefreshCw, Search } from 'lucide-react';
import Loading from '@/app/loading';
import { supabase } from '@/lib/supabase';
import { useI18n, useT } from '@/lib/i18n';
import { useToast } from '@/lib/toast';
import { cn } from '@/lib/utils';

type OfferStatus = 'sent' | 'accepted' | 'rejected' | 'cancelled' | 'completed';
type StatusFilter = OfferStatus | 'all';

type OfferRow = {
    id: string;
    shipment_id: string | null;
    driver_id: string | null;
    price: number | string | null;
    status: OfferStatus;
    rejection_reason: string | null;
    created_at: string;
    updated_at: string | null;
    driver_profile?: ProfileLite | null;
    shipment?: ShipmentLite | null;
};

type ProfileLite = {
    id?: string | null;
    full_name?: string | null;
    company_name?: string | null;
    account_type?: string | null;
};

type LocationLite = {
    city_name_en?: string | null;
    city_name_ar?: string | null;
};

type ShipmentLite = {
    id?: string | null;
    sender_id?: string | null;
    pickup?: LocationLite | null;
    dropoff?: LocationLite | null;
    sender?: ProfileLite | null;
};

const STATUS_FILTERS: StatusFilter[] = [
    'all',
    'sent',
    'accepted',
    'rejected',
    'cancelled',
    'completed',
];

function shortId(id: string | null | undefined) {
    if (!id) return 'N/A';
    return `#${id.slice(0, 8)}`;
}

function locationName(location: LocationLite | null | undefined) {
    return location?.city_name_en || location?.city_name_ar || '';
}

function profileDisplayName(profile: ProfileLite | null | undefined, fallbackId?: string | null) {
    return profile?.company_name || profile?.full_name || shortId(fallbackId);
}

function shipmentRouteLabel(offer: OfferRow) {
    const pickup = locationName(offer.shipment?.pickup);
    const dropoff = locationName(offer.shipment?.dropoff);
    if (pickup && dropoff) return `${pickup} - ${dropoff}`;
    if (pickup || dropoff) return pickup || dropoff;
    return shortId(offer.shipment_id);
}

function humanizeStatus(status: string) {
    return status
        .split('_')
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(' ');
}

function statusClass(status: OfferStatus) {
    switch (status) {
        case 'accepted':
            return 'bg-emerald-500/10 text-emerald-700 border-emerald-500/20';
        case 'completed':
            return 'bg-blue-500/10 text-blue-700 border-blue-500/20';
        case 'rejected':
            return 'bg-red-500/10 text-red-700 border-red-500/20';
        case 'cancelled':
            return 'bg-slate-500/10 text-slate-700 border-slate-500/20';
        case 'sent':
        default:
            return 'bg-amber-500/10 text-amber-700 border-amber-500/20';
    }
}

export default function OffersPage() {
    const t = useT();
    const { language, dir } = useI18n();
    const { toast } = useToast();
    const locale = language === 'ar' ? 'ar-SA' : 'en-US';

    const [offers, setOffers] = useState<OfferRow[]>([]);
    const [loading, setLoading] = useState(true);
    const [errorMessage, setErrorMessage] = useState('');
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');

    const fetchOffers = useCallback(async () => {
        setLoading(true);
        setErrorMessage('');

        const { data, error } = await supabase
            .from('offers')
            .select(`
                id,
                shipment_id,
                driver_id,
                price,
                status,
                rejection_reason,
                created_at,
                updated_at,
                driver_profile:profiles!offers_driver_id_fkey(id, full_name, company_name, account_type),
                shipment:shipments!offers_shipment_id_fkey(
                    id,
                    sender_id,
                    pickup:locations!shipments_pickup_location_id_fkey(city_name_ar, city_name_en),
                    dropoff:locations!shipments_dropoff_location_id_fkey(city_name_ar, city_name_en),
                    sender:profiles!shipments_sender_id_fkey(id, full_name, company_name, account_type)
                )
            `)
            .order('created_at', { ascending: false })
            .limit(100);

        if (error) {
            const message = t('offers.errorLoad', 'Failed to load offers.');
            setOffers([]);
            setErrorMessage(message);
            toast(message, 'error');
        } else {
            setOffers((data as OfferRow[]) || []);
        }

        setLoading(false);
    }, [t, toast]);

    useEffect(() => {
        fetchOffers();
    }, [fetchOffers]);

    const filteredOffers = useMemo(() => {
        const q = search.trim().toLowerCase();
        return offers.filter((offer) => {
            const statusMatches = statusFilter === 'all' || offer.status === statusFilter;
            if (!statusMatches) return false;
            if (!q) return true;
            return [
                offer.id,
                offer.shipment_id,
                offer.driver_id,
                shipmentRouteLabel(offer),
                profileDisplayName(offer.driver_profile, offer.driver_id),
                profileDisplayName(offer.shipment?.sender, offer.shipment?.sender_id),
                offer.status,
                rejectionLabel(offer.rejection_reason),
            ]
                .filter(Boolean)
                .some((value) => String(value).toLowerCase().includes(q));
        });
    }, [offers, search, statusFilter]);

    const statusCounts = useMemo(() => {
        return offers.reduce<Record<StatusFilter, number>>((acc, offer) => {
            acc.all += 1;
            acc[offer.status] += 1;
            return acc;
        }, {
            all: 0,
            sent: 0,
            accepted: 0,
            rejected: 0,
            cancelled: 0,
            completed: 0,
        });
    }, [offers]);

    function formatCurrency(value: OfferRow['price']) {
        const amount = typeof value === 'string' ? Number(value) : value;
        if (amount == null || !Number.isFinite(amount)) return t('common.na', 'N/A');
        return new Intl.NumberFormat(locale, {
            style: 'decimal',
            maximumFractionDigits: 0,
        }).format(amount);
    }

    function formatDate(value: string | null | undefined) {
        if (!value) return t('common.na', 'N/A');
        return new Intl.DateTimeFormat(locale, {
            dateStyle: 'medium',
            timeStyle: 'short',
        }).format(new Date(value));
    }

    function rejectionLabel(reason: string | null | undefined) {
        if (!reason) return '';
        if (reason === 'other_offer_accepted') {
            return t('offers.rejection.otherOfferAccepted', 'Another offer accepted');
        }
        return humanizeStatus(reason);
    }

    if (loading) return <Loading message={t('offers.loading', 'Loading offers...')} />;

    if (errorMessage) {
        return (
            <div className="space-y-6">
                <header className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                        <h1 className="text-3xl font-black theme-heading tracking-tight">
                            {t('offers.title', 'Offers')}
                        </h1>
                        <p className="theme-muted text-sm mt-1 font-medium">
                            {t('offers.subtitle', 'Review shipment offers submitted by travelers and drivers.')}
                        </p>
                    </div>
                </header>

                <div className="rounded-2xl border border-red-500/20 bg-red-500/10 p-6">
                    <p className="font-bold text-red-700">{errorMessage}</p>
                    <button
                        type="button"
                        onClick={fetchOffers}
                        className="mt-4 inline-flex items-center gap-2 rounded-xl bg-red-600 px-4 py-2 text-sm font-black text-white transition hover:bg-red-700"
                    >
                        <RefreshCw className="h-4 w-4" />
                        {t('common.retry', 'Retry')}
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <header className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                <div>
                    <h1 className="text-3xl font-black theme-heading tracking-tight">
                        {t('offers.title', 'Offers')}
                    </h1>
                    <p className="theme-muted text-sm mt-1 font-medium">
                        {t('offers.subtitle', 'Review shipment offers submitted by travelers and drivers.')}
                    </p>
                </div>
                <div className="flex items-center gap-2">
                    <div className="theme-bg-secondary rounded-xl border border-[var(--surface-border)] px-4 py-2 text-xs font-black uppercase tracking-widest theme-heading">
                        {t('offers.resultsCount', 'Showing {count} of {total}')
                            .replace('{count}', String(filteredOffers.length))
                            .replace('{total}', String(offers.length))}
                    </div>
                    <button
                        type="button"
                        onClick={fetchOffers}
                        className="inline-flex items-center gap-2 rounded-xl border border-[var(--surface-border)] px-4 py-2 text-xs font-black uppercase tracking-widest theme-heading transition hover:theme-bg-secondary"
                    >
                        <RefreshCw className="h-4 w-4" />
                        {t('common.refresh', 'Refresh')}
                    </button>
                </div>
            </header>

            <section className="theme-bg-secondary rounded-2xl border border-[var(--surface-border)] p-4 shadow-sm">
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
                    <div className="relative flex-1">
                        <Search
                            className={cn(
                                'absolute top-1/2 h-4 w-4 -translate-y-1/2 theme-muted opacity-50',
                                dir === 'rtl' ? 'right-3' : 'left-3'
                            )}
                        />
                        <input
                            value={search}
                            onChange={(event) => setSearch(event.target.value)}
                            placeholder={t('offers.search.placeholder', 'Search by offer, route, driver, company, status...')}
                            className={cn(
                                'w-full rounded-xl border border-[var(--surface-border)] theme-bg-secondary px-4 py-2.5 text-sm theme-heading outline-none transition focus:ring-2 focus:ring-blue-500/20',
                                dir === 'rtl' ? 'pr-10' : 'pl-10'
                            )}
                        />
                    </div>
                    <div className="flex gap-2 overflow-x-auto pb-1 lg:pb-0">
                        {STATUS_FILTERS.map((status) => (
                            <button
                                key={status}
                                type="button"
                                onClick={() => setStatusFilter(status)}
                                className={cn(
                                    'whitespace-nowrap rounded-xl border px-3 py-2 text-[0.625rem] font-black uppercase tracking-widest transition',
                                    statusFilter === status
                                        ? 'border-blue-600 bg-blue-600 text-white shadow-sm'
                                        : 'border-[var(--surface-border)] theme-bg-secondary theme-muted hover:theme-heading'
                                )}
                            >
                                {t(`offers.filter.${status}`, humanizeStatus(status))} ({statusCounts[status]})
                            </button>
                        ))}
                    </div>
                </div>
            </section>

            {filteredOffers.length === 0 ? (
                <section className="rounded-2xl border border-dashed border-[var(--surface-border)] p-10 text-center">
                    <Handshake className="mx-auto h-10 w-10 theme-muted opacity-40" />
                    <p className="mt-3 text-sm font-bold theme-heading">
                        {t('offers.empty', 'No offers match the current filters.')}
                    </p>
                </section>
            ) : (
                <section className="overflow-hidden rounded-2xl border border-[var(--surface-border)] theme-bg-secondary shadow-sm">
                    <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-[var(--surface-border)]">
                            <thead>
                                <tr className="theme-bg-secondary">
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.offer', 'Offer')}
                                    </th>
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.status', 'Status')}
                                    </th>
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.price', 'Price')}
                                    </th>
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.shipment', 'Shipment')}
                                    </th>
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.driver', 'Traveler / Driver')}
                                    </th>
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.company', 'Company / Sender')}
                                    </th>
                                    <th className="px-4 py-3 text-start text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                        {t('offers.table.created', 'Created')}
                                    </th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-[var(--surface-border)]">
                                {filteredOffers.map((offer) => (
                                    <tr key={offer.id} className="transition hover:theme-bg-secondary">
                                        <td className="px-4 py-4">
                                            <div className="font-black theme-heading uppercase">
                                                {shortId(offer.id)}
                                            </div>
                                            {offer.rejection_reason && (
                                                <p className="mt-1 max-w-xs truncate text-xs theme-muted">
                                                    {rejectionLabel(offer.rejection_reason)}
                                                </p>
                                            )}
                                        </td>
                                        <td className="px-4 py-4">
                                            <span className={cn('inline-flex rounded-full border px-2.5 py-1 text-[0.625rem] font-black uppercase tracking-widest', statusClass(offer.status))}>
                                                {t(`offers.status.${offer.status}`, humanizeStatus(offer.status))}
                                            </span>
                                        </td>
                                        <td className="px-4 py-4 text-sm font-black text-blue-700">
                                            {formatCurrency(offer.price)}
                                        </td>
                                        <td className="px-4 py-4">
                                            {offer.shipment_id ? (
                                                <Link
                                                    href={`/shipments/${offer.shipment_id}`}
                                                    className="inline-flex items-center gap-2 text-sm font-bold text-blue-700 hover:underline"
                                                >
                                                    {shipmentRouteLabel(offer)}
                                                    <ExternalLink className="h-3.5 w-3.5" />
                                                </Link>
                                            ) : (
                                                <span className="text-sm theme-muted">{t('common.na', 'N/A')}</span>
                                            )}
                                        </td>
                                        <td className="px-4 py-4">
                                            {offer.driver_id ? (
                                                <Link
                                                    href={`/users/${offer.driver_id}`}
                                                    className="inline-flex items-center gap-2 text-sm font-bold text-blue-700 hover:underline"
                                                >
                                                    {profileDisplayName(offer.driver_profile, offer.driver_id)}
                                                    <ExternalLink className="h-3.5 w-3.5" />
                                                </Link>
                                            ) : (
                                                <span className="text-sm theme-muted">{t('common.na', 'N/A')}</span>
                                            )}
                                        </td>
                                        <td className="px-4 py-4">
                                            {offer.shipment?.sender_id ? (
                                                <Link
                                                    href={`/users/${offer.shipment.sender_id}`}
                                                    className="inline-flex items-center gap-2 text-sm font-bold text-blue-700 hover:underline"
                                                >
                                                    {profileDisplayName(offer.shipment.sender, offer.shipment.sender_id)}
                                                    <ExternalLink className="h-3.5 w-3.5" />
                                                </Link>
                                            ) : (
                                                <span className="text-sm theme-muted">{t('common.na', 'N/A')}</span>
                                            )}
                                        </td>
                                        <td className="px-4 py-4 text-sm theme-muted">
                                            {formatDate(offer.created_at)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </section>
            )}
        </div>
    );
}
