'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { CheckCircle2, Clock, Search, ShieldAlert, ShieldCheck, XCircle } from 'lucide-react';
import { Profile } from '@/lib/types';
import Loading from '@/app/loading';
import { useT } from '@/lib/i18n';
import { advanceVerificationStep } from '@/app/actions/verification-actions';

type VerificationFilter = 'all' | 'traveler' | 'company';
type Capability = {
    entityType: 'driver' | 'company';
    label: string;
    buttonLabel: string;
};

const FILTERS: VerificationFilter[] = ['all', 'traveler', 'company'];

function hasIdentityDoc(user: Profile) {
    return Boolean(user.identity_doc_url || user.identity_doc_url_pending);
}

function hasTravelerDoc(user: Profile, vehicles: any[]) {
    const hasLicense = Boolean(
        user.traveler_license_url ||
        user.traveler_license_url_pending ||
        user.rental_contract_url ||
        user.rental_contract_url_pending,
    );
    
    // If user is a driver with vehicle, also check vehicle documents
    if (user.is_driver && vehicles.length > 0) {
        const hasVehicleDocs = vehicles.some(v => 
            v.vehicle_photo_url || v.registration_doc_url
        );
        return hasLicense && hasVehicleDocs;
    }
    
    return hasLicense;
}

function hasCompanyDoc(user: Profile) {
    return Boolean(user.company_cr_url || user.company_cr_url_pending);
}

export default function VerificationCenter() {
    const t = useT();
    const { toast } = useToast();
    const [pendingUsers, setPendingUsers] = useState<Profile[]>([]);
    const [userVehicles, setUserVehicles] = useState<Record<string, any[]>>({});
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [activeFilter, setActiveFilter] = useState<VerificationFilter>('all');
    const [approvingKey, setApprovingKey] = useState<string | null>(null);

    useEffect(() => {
        fetchVerificationData();
    }, []);

    async function fetchVerificationData() {
        setLoading(true);
        setLoadError(null);
        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .or('traveler_status.eq.pending,company_status.eq.pending')
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error fetching verification queue:', error);
            const message = t('verification.errorLoad', 'Failed to load verification queue.');
            setPendingUsers([]);
            setUserVehicles({});
            setLoadError(message);
            toast(message, 'error');
        } else {
            const users = (data as Profile[]) || [];
            setPendingUsers(users);
            
            // Fetch vehicles for all pending users
            if (users.length > 0) {
                const userIds = users.map(u => u.id);
                try {
                    const { data: vehiclesData } = await supabase
                        .from('vehicles')
                        .select('*')
                        .in('owner_id', userIds);
                    
                    if (vehiclesData) {
                        const vehiclesByUser: Record<string, any[]> = {};
                        vehiclesData.forEach((vehicle: any) => {
                            if (!vehiclesByUser[vehicle.owner_id]) {
                                vehiclesByUser[vehicle.owner_id] = [];
                            }
                            vehiclesByUser[vehicle.owner_id].push(vehicle);
                        });
                        setUserVehicles(vehiclesByUser);
                    }
                } catch (vehicleError) {
                    console.error('Error fetching vehicles:', vehicleError);
                    // Continue without vehicles if fetch fails
                    setUserVehicles({});
                }
            } else {
                setUserVehicles({});
            }
        }
        setLoading(false);
    }

    function pendingCapabilities(user: Profile): Capability[] {
        const capabilities: Capability[] = [];
        if (user.traveler_status === 'pending') {
            capabilities.push({
                entityType: 'driver',
                label: user.is_driver ? t('verification.driver', 'Driver') : t('verification.traveler', 'Traveler'),
                buttonLabel: t('verification.approveTraveler', 'Approve traveler'),
            });
        }
        if (user.company_status === 'pending') {
            capabilities.push({
                entityType: 'company',
                label: t('verification.company', 'Company'),
                buttonLabel: t('verification.approveCompany', 'Approve company'),
            });
        }
        return capabilities;
    }

    async function approveCapability(user: Profile, capability: Capability) {
        const key = `${user.id}-${capability.entityType}`;
        setApprovingKey(key);
        const res = await advanceVerificationStep(
            user.id,
            capability.entityType,
            'approved',
            `${capability.label} approved from Verification Center`,
        );
        setApprovingKey(null);

        if (res.success) {
            const successKey = capability.entityType === 'company'
                ? 'verification.toast.companyApproved'
                : 'verification.toast.travelerApproved';
            toast(t(successKey, '{capability} approved').replace('{capability}', capability.label), 'success');
            fetchVerificationData();
        } else {
            toast(res.error || t('verification.toast.approveFailed', 'Approval failed'), 'error');
        }
    }

    function renderDocStatus(label: string, available: boolean) {
        return (
            <p className="flex items-center justify-between gap-3">
                <span className="font-black uppercase tracking-widest opacity-60">{label}</span>
                {available ? (
                    <CheckCircle2
                        aria-label={t('verification.docAvailable', 'Document available')}
                        className="h-3.5 w-3.5 theme-heading opacity-80"
                    />
                ) : (
                    <XCircle
                        aria-label={t('verification.docMissing', 'Document missing')}
                        className="h-3.5 w-3.5 opacity-20"
                    />
                )}
            </p>
        );
    }

    const filteredUsers = pendingUsers.filter((user) => {
        const query = searchQuery.toLowerCase();
        const matchesSearch = !query ||
            user.full_name?.toLowerCase().includes(query) ||
            user.phone_number?.includes(searchQuery);
        const matchesFilter = activeFilter === 'all'
            ? true
            : activeFilter === 'traveler'
                ? user.traveler_status === 'pending'
                : user.company_status === 'pending';
        return matchesSearch && matchesFilter;
    });

    if (loading) return <Loading />;

    return (
        <div className="space-y-8">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                <div>
                    <h1 className="text-3xl font-black theme-heading flex items-center gap-3 tracking-tight">
                        <ShieldCheck className="h-8 w-8 opacity-80" />
                        {t('verification.title', 'Verification Center')}
                    </h1>
                    <p className="theme-muted mt-1 font-medium opacity-70">
                        {t('verification.queueSubtitle', 'Review pending traveler and company approvals.')}
                    </p>
                </div>
                <div className="theme-bg-secondary px-5 py-3 rounded-2xl border border-[var(--surface-border)] flex items-center gap-4 shadow-sm">
                    <div className="h-10 w-10 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center">
                        <Clock className="h-5 w-5 theme-muted" />
                    </div>
                    <div>
                        <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest">
                            {t('verification.pendingApproval', 'Pending Approval')}
                        </p>
                        <p className="text-xl font-black theme-heading">{pendingUsers.length}</p>
                    </div>
                </div>
            </div>

            {loadError ? (
                <div className="theme-card rounded-3xl border border-[var(--surface-border)] shadow-sm p-10 text-center space-y-4">
                    <ShieldAlert className="h-10 w-10 theme-muted mx-auto opacity-40" />
                    <p className="theme-muted font-bold">{loadError}</p>
                    <button
                        type="button"
                        onClick={fetchVerificationData}
                        className="px-6 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm"
                        style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}
                    >
                        {t('common.retry', 'Retry')}
                    </button>
                </div>
            ) : (
                <div className="theme-card rounded-3xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
                    <div className="p-6 border-b border-[var(--surface-border)] flex flex-col gap-4 md:flex-row md:items-center md:justify-between theme-bg-secondary/30">
                        <div className="flex flex-wrap items-center gap-3">
                            {FILTERS.map((filter) => (
                                <button
                                    key={filter}
                                    onClick={() => setActiveFilter(filter)}
                                    className={`px-5 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm ${activeFilter === filter
                                        ? 'theme-bg-secondary theme-heading shadow-inner border border-[var(--surface-border)]'
                                        : 'theme-bg-secondary/50 theme-muted hover:theme-heading border border-[var(--surface-border)] opacity-60'}`}
                                >
                                    {t(`verification.${filter}`, filter)}
                                </button>
                            ))}
                        </div>
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 theme-muted opacity-50" />
                            <input
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                placeholder={t('verification.searchPlaceholder', 'Search by name or phone...')}
                                className="pl-10 pr-4 py-2.5 theme-bg-secondary/50 border border-[var(--surface-border)] rounded-xl text-sm theme-heading w-full md:w-72 focus:ring-2 focus:ring-[var(--surface-border)] outline-none transition-all shadow-sm"
                            />
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 divide-x divide-y divide-[var(--surface-border)]">
                        {filteredUsers.length === 0 ? (
                            <div className="col-span-full py-20 text-center space-y-4 theme-bg-secondary/10">
                                <CheckCircle2 className="h-12 w-12 theme-muted mx-auto opacity-20" />
                                <p className="theme-muted text-[0.625rem] font-black uppercase tracking-widest opacity-60">
                                    {t('verification.emptyQueue', 'Queue is empty. All users are current.')}
                                </p>
                            </div>
                        ) : (
                            filteredUsers.map((user) => {
                                const capabilities = pendingCapabilities(user);
                                const vehicles = userVehicles[user.id] || [];

                                return (
                                    <div key={user.id} className="p-6 hover:theme-bg-secondary/30 transition-colors flex flex-col h-full theme-bg-secondary/5">
                                        <div className="flex items-start justify-between gap-3 mb-4">
                                            <div className="flex items-center gap-3 min-w-0">
                                                <div className="h-12 w-12 rounded-2xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center opacity-80 uppercase font-black theme-heading shadow-sm shrink-0">
                                                    {user.full_name?.slice(0, 2) || '??'}
                                                </div>
                                                <div className="min-w-0">
                                                    <p className="font-black theme-heading tracking-tight truncate">{user.full_name}</p>
                                                    <p className="text-[0.625rem] theme-muted font-bold font-mono uppercase opacity-60 truncate">{user.phone_number}</p>
                                                </div>
                                            </div>
                                            <div className="flex flex-col items-end gap-1">
                                                {capabilities.map((capability) => (
                                                    <span key={capability.entityType} className="px-2 py-0.5 rounded theme-bg-secondary border border-[var(--surface-border)] theme-heading text-[0.5rem] font-black uppercase tracking-widest">
                                                        {capability.label}
                                                    </span>
                                                ))}
                                            </div>
                                        </div>

                                        <div className="flex-1 space-y-4 mb-6">
                                            <div className="theme-bg-secondary/30 rounded-2xl p-4 border border-dashed border-[var(--surface-border)] text-[0.625rem] font-bold theme-muted space-y-2">
                                                {renderDocStatus(t('verification.identityDocs', 'Identity Docs'), hasIdentityDoc(user))}
                                                {user.traveler_status === 'pending' && renderDocStatus(t('verification.travelerDocs', 'Traveler documents'), hasTravelerDoc(user, vehicles))}
                                                {user.traveler_status === 'pending' && user.is_driver && vehicles.length > 0 && (
                                                    <>
                                                        {renderDocStatus(t('verification.vehiclePhoto', 'Vehicle Photo'), vehicles.some(v => v.vehicle_photo_url))}
                                                        {renderDocStatus(t('verification.vehicleRegistration', 'Vehicle Registration'), vehicles.some(v => v.registration_doc_url))}
                                                    </>
                                                )}
                                                {user.company_status === 'pending' && renderDocStatus(t('verification.companyDocs', 'Company documents'), hasCompanyDoc(user))}
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <ShieldAlert className="h-3.5 w-3.5 theme-muted opacity-40" />
                                                <span className="text-[0.625rem] theme-muted font-bold opacity-60">
                                                    {t('verification.reviewRiskInProfile', 'Review profile for risk signals, restrictions, and notes.')}
                                                </span>
                                            </div>
                                        </div>

                                        <div className="flex flex-col gap-2 mt-auto">
                                            <Link href={`/users/${user.id}`} className="py-2.5 theme-bg-secondary/50 theme-muted text-center rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:theme-heading hover:theme-bg-secondary border border-[var(--surface-border)] transition-all shadow-sm">
                                                {t('verification.openProfile', 'Open profile')}
                                            </Link>
                                            <div className="flex flex-wrap gap-2">
                                                {capabilities.map((capability) => {
                                                    const key = `${user.id}-${capability.entityType}`;
                                                    return (
                                                        <button
                                                            key={capability.entityType}
                                                            type="button"
                                                            disabled={approvingKey === key}
                                                            onClick={() => approveCapability(user, capability)}
                                                            className="flex-1 min-w-32 py-2.5 theme-bg-secondary theme-heading border border-[var(--surface-border)] rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:opacity-80 transition-all shadow-sm disabled:opacity-50"
                                                        >
                                                            {capability.buttonLabel}
                                                        </button>
                                                    );
                                                })}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
