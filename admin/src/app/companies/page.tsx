'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { CompanyProfile } from '@/lib/types';
import { Check, X, Building2, FileText, Eye, Download, User } from 'lucide-react';
import { exportToCSV } from '@/lib/utils';
import Loading from '@/app/loading';
import { useI18n } from '@/lib/i18n';
import { advanceVerificationStep } from '@/app/actions/verification-actions';

type CompanyStatus = 'pending' | 'approved' | 'rejected' | 'suspended' | 'blocked';
type StatusFilter = CompanyStatus | 'all';

const STATUS_FILTERS: StatusFilter[] = ['pending', 'approved', 'rejected', 'suspended', 'blocked', 'all'];

function isProtectedStatus(status?: string | null) {
    return status === 'blocked' || status === 'suspended';
}

export default function CompaniesPage() {
    const { toast } = useToast();
    const { t, language } = useI18n();
    const locale = language === 'ar' ? 'ar-SA' : 'en-US';
    const [companies, setCompanies] = useState<CompanyProfile[]>([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState<StatusFilter>('all');

    const [page, setPage] = useState(0);
    const [totalCount, setTotalCount] = useState(0);
    const PAGE_SIZE = 24;

    useEffect(() => {
        setPage(0);
    }, [filter]);

    useEffect(() => {
        fetchCompanies();
    }, [page, filter]);

    function applyCompanyScope(query: any) {
        return query.or('account_type.eq.company,company_status.neq.none');
    }

    function applyStatusFilter(query: any) {
        if (filter === 'all') return query;
        return query.eq('company_status', filter);
    }

    function statusLabel(status?: string | null) {
        return t(`companies.filter.${status || 'all'}`, status || t('common.unknown', 'Unknown'));
    }

    function statusClass(status?: string | null) {
        if (status === 'approved') return 'bg-green-50 text-green-700 border-green-100';
        if (status === 'rejected') return 'bg-red-50 text-red-700 border-red-100';
        if (status === 'blocked') return 'bg-slate-100 text-slate-700 border-slate-200';
        if (status === 'suspended') return 'bg-orange-50 text-orange-700 border-orange-100';
        return 'bg-yellow-50 text-yellow-700 border-yellow-100';
    }

    function formatDate(value?: string | null) {
        if (!value) return t('common.na', 'N/A');
        return new Intl.DateTimeFormat(locale).format(new Date(value));
    }

    async function fetchCompanies() {
        setLoading(true);
        let query = applyCompanyScope(supabase
            .from('profiles')
            .select('*', { count: 'exact' }));

        query = applyStatusFilter(query);

        const { data, count, error } = await query
            .order('created_at', { ascending: false })
            .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1);

        if (error) {
            console.error('Error fetching companies:', error);
            toast(t('companies.toast.loadFailed'), 'error');
        } else {
            setCompanies((data as CompanyProfile[]) || []);
            setTotalCount(count || 0);
        }
        setLoading(false);
    }

    async function updateStatus(company: CompanyProfile, newStatus: 'approved' | 'rejected') {
        if (isProtectedStatus(company.company_status)) {
            toast(t('companies.toast.protectedStatus', 'Blocked or suspended companies must be managed from the user profile.'), 'error');
            return;
        }

        const res = await advanceVerificationStep(
            company.id,
            'company',
            newStatus,
            'Companies screen status update',
        );

        if (!res.success) {
            toast(res.error || t('companies.toast.updateFailed'), 'error');
        } else {
            setCompanies(companies.map(c => c.id === company.id ? {
                ...c,
                account_type: newStatus === 'approved' ? 'company' : c.account_type,
                company_status: newStatus,
            } : c));
            toast(t('companies.toast.statusSuccess').replace('{status}', statusLabel(newStatus)), 'success');
        }
    }

    async function handleExport() {
        toast(t('companies.toast.exporting', 'Exporting...'), 'success');
        let query = applyCompanyScope(supabase
            .from('profiles')
            .select('*'));
        query = applyStatusFilter(query);

        const { data, error } = await query.order('created_at', { ascending: false });
        if (error) {
            toast(error.message || t('companies.toast.exportFailed', 'Export failed'), 'error');
            return;
        }

        exportToCSV((data as CompanyProfile[]) || [], 'companies_export', (msg) => toast(msg, 'error'));
    }

    if (loading) return <Loading />;

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-black theme-heading tracking-tight">
                        {t('companies.title', 'Companies Verification')}
                    </h1>
                    <p className="theme-muted text-sm mt-1 font-medium">
                        {t('companies.subtitle', 'Manage company registrations and approvals')}
                    </p>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={handleExport}
                        className="flex items-center gap-2 bg-green-500/10 border border-green-500/20 text-green-600 px-4 py-2 rounded-xl hover:bg-green-500/20 transition shadow-sm font-black text-[0.625rem] uppercase tracking-widest"
                    >
                        <Download className="h-4 w-4" /> {t('companies.export', 'Export')}
                    </button>
                    <div className="flex gap-2 theme-bg-secondary p-1 rounded-xl border border-[var(--surface-border)] shadow-sm">
                        {STATUS_FILTERS.map((f) => (
                            <button
                                key={f}
                                onClick={() => setFilter(f)}
                                className={`px-4 py-1.5 rounded-lg text-[0.625rem] font-black capitalize tracking-widest transition-all ${filter === f
                                    ? 'bg-blue-600 text-white shadow-md'
                                    : 'theme-muted hover:theme-heading'
                                    }`}
                            >
                                {t(`companies.filter.${f}`, f)}
                            </button>
                        ))}
                    </div>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {companies.map((company) => {
                    const protectedStatus = isProtectedStatus(company.company_status);

                    return (
                    <div key={company.id} className="theme-card rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-hidden hover:shadow-xl transition-all flex flex-col group">
                        <div className="p-6 flex-1">
                            <div className="flex justify-between items-start mb-4">
                                <div className="flex items-center gap-3">
                                    <div className="h-12 w-12 rounded-xl bg-gradient-to-br from-purple-400 to-purple-600 shadow-lg flex items-center justify-center text-white">
                                        <Building2 className="h-6 w-6" />
                                    </div>
                                    <div>
                                        <h3 className="font-black theme-heading tracking-tight">
                                            {company.company_name || company.full_name || t('companies.card.unnamed', 'Unnamed Company')}
                                        </h3>
                                        <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest mt-0.5 opacity-60">
                                            {company.full_name || t('companies.card.noOwner', 'No owner name')}
                                        </p>
                                    </div>
                                </div>
                                <span className={`px-2 py-0.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest border-2 shadow-sm ${statusClass(company.company_status)}`}>
                                    {statusLabel(company.company_status)}
                                </span>
                            </div>

                            <div className="space-y-3 theme-muted mb-6">
                                <div className="flex items-center gap-2">
                                    <FileText className="h-4 w-4 opacity-40" />
                                    <span className="text-[0.6875rem] font-black uppercase tracking-widest opacity-60">{t('companies.card.crNumber')}:</span>
                                    <span className="font-mono theme-bg-secondary px-2 py-0.5 rounded-lg text-xs theme-heading font-black">
                                        {company.company_cr_number || t('common.na')}
                                    </span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="text-[0.6875rem] font-black uppercase tracking-widest opacity-60">{t('companies.card.address')}:</span>
                                    <span className="text-xs theme-heading font-medium">{company.company_address || t('common.na')}</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="text-[0.6875rem] font-black uppercase tracking-widest opacity-60">{t('companies.card.registered')}:</span>
                                    <span className="font-mono text-[0.6875rem] theme-heading font-black">{formatDate(company.created_at)}</span>
                                </div>
                                {company.company_cr_url && (
                                    <a href={company.company_cr_url} target="_blank" rel="noreferrer"
                                        className="inline-flex items-center gap-2 bg-blue-500/10 text-blue-600 border border-blue-500/20 px-3 py-1.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-blue-500/20 transition-all shadow-sm">
                                        <Eye className="h-3.5 w-3.5" /> {t('companies.card.viewCrDocument')}
                                    </a>
                                )}
                            </div>
                        </div>

                        <div className="theme-bg-secondary px-6 py-4 flex gap-3 border-t border-[var(--surface-border)]">
                            <Link
                                href={`/users/${company.id}`}
                                className="flex-1 flex items-center justify-center gap-2 theme-card border border-[var(--surface-border)] theme-heading py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm hover:opacity-80"
                            >
                                <User className="h-4 w-4" /> {t('companies.action.openProfile', 'Open profile')}
                            </Link>
                            {!protectedStatus && company.company_status !== 'approved' && (
                                <button
                                    onClick={() => updateStatus(company, 'approved')}
                                    className="flex-1 flex items-center justify-center gap-2 bg-green-600 hover:bg-green-700 text-white py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-lg shadow-green-600/10 active:scale-95"
                                >
                                    <Check className="h-4 w-4" /> {t('companies.action.approve')}
                                </button>
                            )}
                            {!protectedStatus && company.company_status !== 'rejected' && (
                                <button
                                    onClick={() => updateStatus(company, 'rejected')}
                                    className="flex-1 flex items-center justify-center gap-2 theme-card border border-red-500/20 text-red-600 hover:bg-red-500/10 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95"
                                >
                                    <X className="h-4 w-4" /> {t('companies.action.reject')}
                                </button>
                            )}
                        </div>
                    </div>
                    );
                })}
            </div>

            {companies.length === 0 && (
                <div className="text-center py-32 bg-[var(--surface)] rounded-2xl border border-dashed border-[var(--surface-border)]">
                    <p className="theme-muted font-black uppercase tracking-widest opacity-60">
                        {t('companies.empty', 'No companies found.')}
                    </p>
                </div>
            )}
            {/* Pagination Controls */}
            {Math.ceil(totalCount / PAGE_SIZE) > 1 && (
                <div className="flex items-center justify-center gap-4 py-8">
                    <button
                        onClick={() => setPage(Math.max(0, page - 1))}
                        disabled={page === 0}
                        className="px-6 py-2 rounded-xl border border-[var(--surface-border)] theme-bg-secondary text-[0.625rem] font-black theme-muted uppercase tracking-widest hover:theme-heading transition-all disabled:opacity-30 disabled:cursor-not-allowed shadow-sm"
                    >
                        {t('common.previous', 'Previous')}
                    </button>
                    <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
                        {t(
                            'common.pageOf',
                            `Page ${page + 1} of {total}`,
                        ).replace('{current}', String(page + 1)).replace('{total}', String(Math.ceil(totalCount / PAGE_SIZE)))}
                    </span>
                    <button
                        onClick={() => setPage(Math.min(Math.ceil(totalCount / PAGE_SIZE) - 1, page + 1))}
                        disabled={page === Math.ceil(totalCount / PAGE_SIZE) - 1}
                        className="px-6 py-2 rounded-xl border border-[var(--surface-border)] theme-bg-secondary text-[0.625rem] font-black theme-muted uppercase tracking-widest hover:theme-heading transition-all disabled:opacity-30 disabled:cursor-not-allowed shadow-sm"
                    >
                        {t('common.next', 'Next')}
                    </button>
                </div>
            )}
        </div>
    );
}
