'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { DriverProfile } from '@/lib/types';
import type { Vehicle } from '@/lib/types';
import { Check, X, Truck, FileText, Download, Calendar, Eye, ChevronLeft, ChevronRight, User } from 'lucide-react';
import { exportToCSV } from '@/lib/utils';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import { useI18n } from '@/lib/i18n';
import { advanceVerificationStep } from '@/app/actions/verification-actions';

const PAGE_SIZE = 24;
const DAY_MS = 24 * 60 * 60 * 1000;
type ExpiryFilter = 'all' | 'license_soon';
type TravelerStatus = 'pending' | 'approved' | 'rejected' | 'suspended' | 'blocked';
type StatusFilter = TravelerStatus | 'all';

const STATUS_FILTERS: StatusFilter[] = ['pending', 'approved', 'rejected', 'suspended', 'blocked', 'all'];

function isProtectedStatus(status?: string | null) {
    return status === 'blocked' || status === 'suspended';
}

export default function DriversPage() {
    const searchParams = useSearchParams();
    const { toast } = useToast();
    const { t, language } = useI18n();
    const locale = language === 'ar' ? 'ar-SA' : 'en-US';
    const [drivers, setDrivers] = useState<DriverProfile[]>([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
    const [page, setPage] = useState(0);
    const [totalCount, setTotalCount] = useState(0);
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [expiryFilter, setExpiryFilter] = useState<ExpiryFilter>('all');
    const [vehicleWarning, setVehicleWarning] = useState(false);

    useEffect(() => {
        setPage(0);
    }, [statusFilter, dateFrom, dateTo, expiryFilter]);

    useEffect(() => {
        fetchDrivers();
    }, [page, statusFilter, dateFrom, dateTo, expiryFilter]);

    useEffect(() => {
        const expiry = searchParams.get('expiry');
        if (expiry === 'license_soon') {
            setExpiryFilter('license_soon');
        }
    }, [searchParams]);

    function applyExpiryFilter(query: any) {
        if (expiryFilter !== 'license_soon') return query;
        const now = new Date();
        return query
            .gte('license_expires_at', now.toISOString())
            .lt('license_expires_at', new Date(now.getTime() + 7 * DAY_MS).toISOString());
    }

    function formatDate(value?: string | null) {
        if (!value) return t('common.never', 'Never');
        return new Intl.DateTimeFormat(locale).format(new Date(value));
    }

    function inputDateValue(value?: string | null) {
        return value ? new Date(value).toISOString().split('T')[0] : '';
    }

    function statusLabel(status?: string | null) {
        return t(`drivers.filter.${status || 'all'}`, status || t('common.unknown', 'Unknown'));
    }

    function statusClass(status?: string | null) {
        if (status === 'approved') return 'bg-green-50 text-green-700 border-green-100';
        if (status === 'rejected') return 'bg-red-50 text-red-700 border-red-100';
        if (status === 'blocked') return 'bg-slate-100 text-slate-700 border-slate-200';
        if (status === 'suspended') return 'bg-orange-50 text-orange-700 border-orange-100';
        return 'bg-yellow-50 text-yellow-700 border-yellow-100';
    }

    async function fetchDrivers() {
        setLoading(true);
        setVehicleWarning(false);
        try {
            // vehicles.owner_id references auth.users; profiles.id = auth.users.id — no direct FK to embed, so fetch separately
            let query = supabase
                .from('profiles')
                .select('*', { count: 'exact' })
                .neq('traveler_status', 'none');

            if (statusFilter !== 'all') {
                query = query.eq('traveler_status', statusFilter);
            }
            query = applyExpiryFilter(query);
            if (dateFrom) query = query.gte('created_at', `${dateFrom}T00:00:00.000Z`);
            if (dateTo) query = query.lte('created_at', `${dateTo}T23:59:59.999Z`);

            const from = page * PAGE_SIZE;
            const to = from + PAGE_SIZE - 1;

            const { data: profilesData, count, error } = await query
                .order('created_at', { ascending: false })
                .range(from, to);

            if (error) throw error;

            const driversList = (profilesData as DriverProfile[]) || [];
            if (driversList.length > 0) {
                const ids = driversList.map(d => d.id);
                const { data: vehiclesData, error: vehiclesError } = await supabase.from('vehicles').select('*').in('owner_id', ids);
                if (vehiclesError) {
                    console.error('Error fetching traveler vehicles:', vehiclesError);
                    setVehicleWarning(true);
                    toast(t('drivers.toast.vehiclesLoadFailed', 'Traveler vehicles could not be loaded.'), 'error');
                }
                const vehiclesByOwner = ((vehiclesData || []) as Vehicle[]).reduce((acc, v) => {
                    const oid = v.owner_id;
                    if (!acc[oid]) acc[oid] = [];
                    acc[oid].push(v);
                    return acc;
                }, {} as Record<string, Vehicle[]>);
                driversList.forEach(d => { d.vehicles = vehiclesByOwner[d.id] || []; });
            }

            setDrivers(driversList);
            setTotalCount(count || 0);

        } catch (error) {
            console.error('Error fetching drivers:', error);
            setDrivers([]);
            setTotalCount(0);
            toast(t('drivers.toast.loadFailed'), 'error');
        } finally {
            setLoading(false);
        }
    }

    async function updateStatus(driver: DriverProfile, newStatus: 'approved' | 'rejected') {
        if (isProtectedStatus(driver.traveler_status)) {
            toast(t('drivers.toast.protectedStatus', 'Blocked or suspended travelers must be managed from the user profile.'), 'error');
            return;
        }

        const res = await advanceVerificationStep(
            driver.id,
            'driver',
            newStatus,
            'Travelers screen status update',
        );

        if (!res.success) {
            toast(res.error || t('drivers.toast.updateFailed'), 'error');
        } else {
            setDrivers(drivers.map(d => d.id === driver.id ? { ...d, traveler_status: newStatus } : d));
            toast(t('drivers.toast.statusSuccess').replace('{status}', statusLabel(newStatus)), 'success');
        }
    }

    async function extendSubscription(id: string, currentExpiry: string | undefined | null, months: number) {
        let baseDate = currentExpiry ? new Date(currentExpiry) : new Date();
        if (baseDate < new Date()) baseDate = new Date();

        const newExpiry = new Date(baseDate.setMonth(baseDate.getMonth() + months)).toISOString();

        const { error } = await supabase
            .from('profiles')
            .update({ subscription_expires_at: newExpiry })
            .eq('id', id);

        if (error) {
            toast(t('drivers.toast.extendFailed'), 'error');
            console.error(error);
        } else {
            setDrivers(drivers.map(d => d.id === id ? { ...d, subscription_expires_at: newExpiry } : d));
            await logAdminAction('extend_subscription', 'user', id, { months, newExpiry });
            toast(t('drivers.toast.subscriptionExtended').replace('{months}', String(months)), 'success');
        }
    }

    async function updateLicenseExpiry(id: string, date: string) {
        const { error } = await supabase
            .from('profiles')
            .update({ license_expires_at: date || null })
            .eq('id', id);

        if (error) {
            toast(t('drivers.toast.licenseFailed'), 'error');
            console.error(error);
        } else {
            setDrivers(drivers.map(d => d.id === id ? { ...d, license_expires_at: date || null } : d));
            await logAdminAction('update_license_expiry', 'user', id, { date: date || null });
        }
    }

    async function setSubscriptionExpiry(id: string, date: string) {
        const nextDate = date || null;
        const { error } = await supabase
            .from('profiles')
            .update({ subscription_expires_at: nextDate })
            .eq('id', id);

        if (error) {
            toast(t('drivers.toast.subscriptionFailed'), 'error');
            console.error(error);
        } else {
            setDrivers(drivers.map(d => d.id === id ? { ...d, subscription_expires_at: nextDate } : d));
            await logAdminAction('set_subscription_expiry', 'user', id, { date: nextDate });
            toast(nextDate ? t('drivers.toast.subscriptionSet') : t('drivers.toast.subscriptionCleared', 'Subscription date cleared'), 'success');
        }
    }

    // Export all matching the current filter
    async function handleExport() {
        toast(t('drivers.toast.exporting'), 'success');
        let query = supabase
            .from('profiles')
            .select('*')
            .neq('traveler_status', 'none');

        if (statusFilter !== 'all') {
            query = query.eq('traveler_status', statusFilter);
        }
        query = applyExpiryFilter(query);
        if (dateFrom) query = query.gte('created_at', `${dateFrom}T00:00:00.000Z`);
        if (dateTo) query = query.lte('created_at', `${dateTo}T23:59:59.999Z`);

        const { data: profilesData, error: profilesError } = await query.order('created_at', { ascending: false });
        if (profilesError) {
            toast(profilesError.message || t('drivers.toast.exportFailed', 'Export failed'), 'error');
            return;
        }
        if (!profilesData?.length) {
            exportToCSV([], 'drivers_export', (msg) => toast(msg, 'error'));
            return;
        }
        const ids = profilesData.map((d: { id: string }) => d.id);
        const { data: vehiclesData, error: vehiclesError } = await supabase.from('vehicles').select('*').in('owner_id', ids);
        if (vehiclesError) {
            toast(vehiclesError.message || t('drivers.toast.exportFailed', 'Export failed'), 'error');
            return;
        }
        const vehiclesByOwner = ((vehiclesData || []) as Vehicle[]).reduce((acc: Record<string, Vehicle[]>, v) => {
            const oid = v.owner_id;
            if (!acc[oid]) acc[oid] = [];
            acc[oid].push(v);
            return acc;
        }, {});
        const data = (profilesData as DriverProfile[]).map((d) => ({ ...d, vehicles: vehiclesByOwner[d.id] || [] }));
        exportToCSV(data, 'drivers_export', (msg) => toast(msg, 'error'));
    }

    const totalPages = Math.ceil(totalCount / PAGE_SIZE);

    if (loading) return <Loading />;

    return (
        <div className="space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black theme-heading tracking-tight">
                        {t('drivers.title', 'Travelers')}
                    </h1>
                    <p className="theme-muted text-sm mt-1 font-medium italic opacity-80">
                        {t('drivers.subtitle', 'Manage traveler and driver approvals, documents, and expiry dates')}
                    </p>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={handleExport}
                        className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition font-black text-[0.625rem] uppercase tracking-widest shadow-sm"
                    >
                        <Download className="h-4 w-4" /> {t('drivers.export', 'Export')}
                    </button>
                    <div className="theme-bg-secondary px-4 py-2 rounded-lg border border-[var(--surface-border)] font-black text-[0.625rem] theme-heading uppercase tracking-widest">
                        {t('common.total', 'Total')}: <span className="text-blue-500">{totalCount}</span>
                    </div>
                </div>
            </div>

            {/* Filter Bar */}
            <div className="flex flex-col gap-4 md:flex-row md:items-center theme-bg-secondary p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
                <div className="flex flex-wrap items-center gap-2">
                    <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
                        {t('drivers.dateRange', 'Date range')}
                    </span>
                    <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-1.5 text-xs theme-heading focus:border-blue-500 focus:outline-none transition" />
                    <span className="theme-muted opacity-30">-</span>
                    <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-1.5 text-xs theme-heading focus:border-blue-500 focus:outline-none transition" />
                </div>
                <div className="flex flex-wrap gap-2">
                    {STATUS_FILTERS.map((f) => (
                        <button
                            key={f}
                            onClick={() => setStatusFilter(f)}
                            className={`px-4 py-1.5 rounded-lg text-[0.625rem] font-black capitalize tracking-widest transition-all ${statusFilter === f
                                ? 'bg-blue-600 text-white shadow-md'
                                : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)] opacity-80 hover:opacity-100'
                                }`}
                        >
                            {t(`drivers.filter.${f}`, f)}
                        </button>
                    ))}
                </div>
                <div className="flex flex-wrap gap-2">
                    {(['all', 'license_soon'] as const).map((f) => (
                        <button
                            key={f}
                            onClick={() => setExpiryFilter(f)}
                            className={`px-4 py-1.5 rounded-lg text-[0.625rem] font-black capitalize tracking-widest transition-all ${expiryFilter === f
                                ? 'bg-orange-600 text-white shadow-md'
                                : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)] opacity-80 hover:opacity-100'
                                }`}
                        >
                            {f === 'license_soon' ? t('drivers.filter.licenseSoon', 'License expiring') : t('drivers.filter.expiryAll', 'All expiry')}
                        </button>
                    ))}
                </div>
            </div>

            <p className="text-xs theme-muted font-medium">
                {t('drivers.filterHelp', 'Filters use profile creation date, traveler status, and licenses expiring in the next 7 days. This screen includes both travelers and drivers.')}
            </p>

            {vehicleWarning && (
                <div className="rounded-xl border border-orange-500/20 bg-orange-500/10 px-4 py-3 text-sm font-semibold text-orange-700">
                    {t('drivers.warning.vehiclesLoadFailed', 'Vehicle details could not be loaded. Open the user profile before approving driver access.')}
                </div>
            )}

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {drivers.map((driver) => {
                    const isSubExpired = driver.subscription_expires_at && new Date(driver.subscription_expires_at) < new Date();
                    const isLicenseExpired = driver.license_expires_at && new Date(driver.license_expires_at) < new Date();
                    const vehicle = driver.vehicles?.[0];
                    const protectedStatus = isProtectedStatus(driver.traveler_status);

                    return (
                        <div key={driver.id} className={`bg-[var(--surface)] rounded-2xl border ${isSubExpired || isLicenseExpired ? 'border-orange-500/30' : 'border-[var(--surface-border)]'} shadow-sm overflow-hidden hover:shadow-lg transition-all flex flex-col group`}>
                            <div className="p-6 flex-1">
                                <div className="flex justify-between items-start mb-6">
                                    <div className="flex items-center gap-3">
                                        <div className="h-12 w-12 rounded-xl bg-gradient-to-br from-blue-400 to-blue-600 shadow-lg flex items-center justify-center text-white text-xl font-black">
                                            {driver.full_name?.[0]?.toUpperCase() || 'D'}
                                        </div>
                                        <div>
                                            <h3 className="font-black theme-heading leading-tight">{driver.full_name || t('common.unknown', 'Unknown')}</h3>
                                            <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest mt-0.5 opacity-60">{driver.phone_number || t('drivers.card.noPhone', 'No phone')}</p>
                                        </div>
                                    </div>
                                    <span className={`px-2 py-0.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest border-2 shadow-sm ${statusClass(driver.traveler_status)}`}>
                                        {statusLabel(driver.traveler_status)}
                                    </span>
                                </div>

                                <div className="grid grid-cols-2 gap-3 mb-6">
                                    <div className="theme-bg-secondary p-3 rounded-xl border border-[var(--surface-border)]">
                                        <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1.5 flex items-center gap-1 opacity-60">
                                            <Truck className="h-3 w-3" /> {t('drivers.card.capability', 'Capability')}
                                        </p>
                                        <p className="text-xs font-black theme-heading leading-none">
                                            {driver.is_driver ? t('drivers.card.driver', 'Driver') : t('drivers.card.traveler', 'Traveler')}
                                        </p>
                                    </div>
                                    <div className="theme-bg-secondary p-3 rounded-xl border border-[var(--surface-border)]">
                                        <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1.5 flex items-center gap-1 opacity-60">
                                            <FileText className="h-3 w-3" /> {t('drivers.card.vehicle', 'Vehicle')}
                                        </p>
                                        <p className="text-xs font-black theme-heading leading-none">
                                            {vehicle ? `${vehicle.make} ${vehicle.model}` : t('common.na', 'N/A')}
                                        </p>
                                    </div>
                                </div>

                                {/* Subscription & License Expiry */}
                                <div className="space-y-4 pt-4 border-t border-[var(--surface-border)]">
                                    <div>
                                        <div className="flex justify-between items-center mb-2">
                                            <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest flex items-center gap-1 opacity-60">
                                                <Calendar className="h-3 w-3" /> {t('drivers.card.subscription', 'Subscription')}
                                            </p>
                                            <div className="flex gap-1 flex-wrap">
                                                {[1, 6].map(m => (
                                                    <button
                                                        key={m}
                                                        onClick={() => extendSubscription(driver.id, driver.subscription_expires_at, m)}
                                                        className="text-[0.5rem] font-black bg-blue-500/10 text-blue-600 px-1.5 py-0.5 rounded border border-blue-500/20 hover:bg-blue-600 hover:text-white transition-colors"
                                                    >
                                                        +{m}M
                                                    </button>
                                                ))}
                                            </div>
                                        </div>
                                        <p className={`text-xs font-black mb-1.5 ${isSubExpired ? 'text-red-500' : 'theme-heading'}`}>
                                            {driver.subscription_expires_at ? formatDate(driver.subscription_expires_at) : t('drivers.card.neverSet', 'Never set')}
                                            {isSubExpired && <span className="ml-2 uppercase text-[0.5rem] bg-red-500/10 text-red-600 px-1 py-0.5 rounded border border-red-500/20">{t('drivers.card.expired', 'Expired')}</span>}
                                        </p>
                                        <input
                                            type="date"
                                            className="text-xs font-black w-full theme-bg-secondary border border-[var(--surface-border)] p-2 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 theme-heading"
                                            value={inputDateValue(driver.subscription_expires_at)}
                                            onChange={(e) => setSubscriptionExpiry(driver.id, e.target.value)}
                                        />
                                    </div>

                                    <div>
                                        <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-2 opacity-60">{t('drivers.card.licenseExpiry', 'License expiry')}</p>
                                        <input
                                            type="date"
                                            className={`text-xs font-black w-full theme-bg-secondary border p-2 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 ${isLicenseExpired ? 'border-red-500/30 text-red-500' : 'border-[var(--surface-border)] theme-heading'}`}
                                            value={inputDateValue(driver.license_expires_at)}
                                            onChange={(e) => updateLicenseExpiry(driver.id, e.target.value)}
                                        />
                                    </div>
                                </div>

                                {/* Document links */}
                                {(driver.identity_doc_url || driver.traveler_license_url) && (
                                    <div className="mt-6 pt-4 border-t border-[var(--surface-border)]">
                                        <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-3 opacity-60">{t('drivers.card.documents', 'Documents')}</p>
                                        <div className="flex flex-wrap gap-2">
                                            {driver.identity_doc_url && (
                                                <a href={driver.identity_doc_url} target="_blank" rel="noreferrer"
                                                    className="flex items-center gap-1 text-blue-600 bg-blue-500/10 hover:bg-blue-500/20 px-3 py-2 rounded-xl border border-blue-500/20 transition-all font-black text-[0.625rem] uppercase">
                                                    <Eye className="h-3 w-3" /> {t('drivers.card.identityDocument', 'ID document')}
                                                </a>
                                            )}
                                            {driver.traveler_license_url && (
                                                <a href={driver.traveler_license_url} target="_blank" rel="noreferrer"
                                                    className="flex items-center gap-1 text-blue-600 bg-blue-500/10 hover:bg-blue-500/20 px-3 py-2 rounded-xl border border-blue-500/20 transition-all font-black text-[0.625rem] uppercase">
                                                    <Eye className="h-3 w-3" /> {t('drivers.card.licenseDocument', 'License')}
                                                </a>
                                            )}
                                        </div>
                                    </div>
                                )}
                            </div>

                            <div className="theme-bg-secondary px-6 py-4 flex gap-3 border-t border-[var(--surface-border)]">
                                <Link
                                    href={`/users/${driver.id}`}
                                    className="flex-1 flex items-center justify-center gap-2 theme-bg-secondary border border-[var(--surface-border)] theme-heading py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm hover:opacity-80"
                                >
                                    <User className="h-4 w-4" /> {t('drivers.action.openProfile', 'Open profile')}
                                </Link>
                                {!protectedStatus && driver.traveler_status !== 'approved' && (
                                    <button
                                        onClick={() => updateStatus(driver, 'approved')}
                                        className="flex-1 flex items-center justify-center gap-2 bg-green-600 hover:bg-green-700 text-white py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95"
                                    >
                                        <Check className="h-4 w-4" /> {t('drivers.action.approve', 'Approve')}
                                    </button>
                                )}
                                {!protectedStatus && driver.traveler_status !== 'rejected' && (
                                    <button
                                        onClick={() => updateStatus(driver, 'rejected')}
                                        className="flex-1 flex items-center justify-center gap-2 bg-orange-600/10 border border-orange-600/20 text-orange-600 hover:bg-orange-600 hover:text-white py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95"
                                    >
                                        <X className="h-4 w-4" /> {t('drivers.action.reject', 'Reject')}
                                    </button>
                                )}
                            </div>
                        </div>
                    );
                })}
            </div>

            {drivers.length === 0 && !loading && (
                <div className="text-center py-32 bg-[var(--surface)] rounded-2xl border border-dashed border-[var(--surface-border)]">
                    <p className="theme-muted font-bold uppercase tracking-widest opacity-60">
                        {t('drivers.empty', 'No drivers found.')}
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
        </div>
    );
}
