'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { useI18n, useT } from '@/lib/i18n';
import {
    ShieldAlert, User, Activity,
    CheckCircle, Flag, ArrowRight,
    Search, TrendingDown, Scale
} from 'lucide-react';
import { UserReport, RiskScore, RiskHistory, UserRestriction } from '@/lib/types';
import Loading from '@/app/loading';
import Link from 'next/link';
import { StatusBadge } from '@/components/StatusBadge';

export default function ModerationDashboard() {
    const { toast } = useToast();
    const t = useT();
    const { dir, language } = useI18n();
    const searchParams = useSearchParams();
    const [reports, setReports] = useState<UserReport[]>([]);
    const [highRiskUsers, setHighRiskUsers] = useState<(RiskScore & { profile: { full_name: string } })[]>([]);
    const [riskHistory, setRiskHistory] = useState<(RiskHistory & { profile: { full_name: string } })[]>([]);
    const [activeRestrictions, setActiveRestrictions] = useState<(UserRestriction & { profile?: { full_name: string | null } })[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [activeFilter, setActiveFilter] = useState<'all' | 'pending'>('all');

    useEffect(() => {
        fetchModerationData();
    }, []);

    async function fetchModerationData() {
        setLoading(true);
        setError(null);
        try {
            const [reportsResult, riskResult, historyResult, restrictionsResult] = await Promise.all([
                supabase
                    .from('reports')
                    .select(`
          *,
          reporter:profiles!reports_reporter_id_fkey(full_name),
          reported:profiles!reports_reported_id_fkey(full_name)
        `)
                    .order('created_at', { ascending: false })
                    .limit(50),
                supabase
                    .from('user_risk_scores')
                    .select('*, profile:profiles!user_id(full_name)')
                    .lt('risk_score', 60)
                    .order('risk_score', { ascending: true })
                    .limit(25),
                supabase
                    .from('risk_score_history')
                    .select('*, profile:profiles!user_id(full_name)')
                    .order('created_at', { ascending: false })
                    .limit(15),
                supabase
                    .from('user_restrictions')
                    .select('*, profile:profiles!user_id(full_name)')
                    .or('expires_at.is.null,expires_at.gt.' + new Date().toISOString())
                    .order('created_at', { ascending: false })
                    .limit(10),
            ]);

            const failedResult = [reportsResult, riskResult, historyResult, restrictionsResult].find(result => result.error);
            if (failedResult?.error) {
                console.error(failedResult.error);
                const message = t('moderation.errorLoad', 'Failed to load moderation data. Please try again.');
                setError(message);
                toast(message, 'error');
                return;
            }

            setReports((reportsResult.data as any) || []);
            setHighRiskUsers((riskResult.data as any) || []);
            setRiskHistory((historyResult.data as any) || []);
            setActiveRestrictions((restrictionsResult.data as any) || []);
        } catch (error) {
            console.error(error);
            const message = t('moderation.errorLoad', 'Failed to load moderation data. Please try again.');
            setError(message);
            toast(message, 'error');
        } finally {
            setLoading(false);
        }
    }

    const filteredReports = reports.filter(r => {
        const matchesSearch = r.reported?.full_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            r.reason.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesFilter = activeFilter === 'all' ? true : (r.status || 'pending') === 'pending';
        return matchesSearch && matchesFilter;
    });
    const highlightRestrictions = searchParams.get('focus') === 'restrictions';
    const isRtl = dir === 'rtl';
    const locale = language === 'ar' ? 'ar' : 'en';
    const formatDateTime = (value: string) => new Date(value).toLocaleString(locale);
    const formatDate = (value: string) => new Date(value).toLocaleDateString(locale);

    if (loading) return <Loading />;
    if (error) {
        return (
            <div className="flex flex-col items-center justify-center py-16 gap-4">
                <ShieldAlert className="h-10 w-10 text-orange-600 opacity-70" />
                <p className="theme-muted text-center">{error}</p>
                <button
                    type="button"
                    onClick={() => fetchModerationData()}
                    className="px-4 py-2 rounded-lg font-medium"
                    style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}
                >
                    {t('common.retry', 'Retry')}
                </button>
            </div>
        );
    }

    return (
        <div className="space-y-8" dir={dir}>
            {/* Header & Stats */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black theme-heading flex items-center gap-3">
                        <Scale className="h-8 w-8 text-orange-600" />
                        {t('moderation.title', 'Trust & Moderation Center')}
                    </h1>
                    <p className="theme-muted mt-1">{t('moderation.subtitle', 'Algorithmic risk engine and proactive trust enforcement.')}</p>
                </div>
                <div className="flex items-center gap-3">
                    <div className="bg-red-500/10 px-4 py-2 rounded-2xl border border-red-500/20 flex items-center gap-3 shadow-sm transition-colors hover:bg-red-500/15">
                        <div className="h-8 w-8 rounded-full bg-red-500/20 flex items-center justify-center">
                            <ShieldAlert className="h-4 w-4 text-red-600" />
                        </div>
                        <div>
                            <p className="text-[0.625rem] text-red-600 font-black uppercase">{t('moderation.stats.highRisk', 'High Risk Offenders')}</p>
                            <p className="text-lg font-black theme-heading">{highRiskUsers.length}</p>
                        </div>
                    </div>
                    <div className="bg-orange-500/10 px-4 py-2 rounded-2xl border border-orange-500/20 flex items-center gap-3 shadow-sm transition-colors hover:bg-orange-500/15">
                        <div className="h-8 w-8 rounded-full bg-orange-500/20 flex items-center justify-center">
                            <Flag className="h-4 w-4 text-orange-600" />
                        </div>
                        <div>
                            <p className="text-[0.625rem] text-orange-600 font-black uppercase">{t('moderation.stats.pendingReports', 'Pending Reports')}</p>
                            <p className="text-lg font-black theme-heading">{reports.filter(r => r.status === 'pending').length}</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Main Feed: Reports Queue */}
                <div className="lg:col-span-2 space-y-6">
                    <div className="bg-[var(--surface)] rounded-3xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
                        <div className="p-6 border-b border-[var(--surface-border)] flex flex-col md:flex-row md:items-center justify-between gap-4">
                            <div className="flex items-center gap-4">
                                <button
                                    onClick={() => setActiveFilter('all')}
                                    className={`px-4 py-1.5 rounded-full text-xs font-black uppercase tracking-widest transition ${activeFilter === 'all' ? 'bg-orange-600 text-white shadow-md' : 'theme-muted hover:theme-heading hover:theme-bg-secondary'}`}
                                >
                                    {t('moderation.filter.all', 'All')}
                                </button>
                                <button
                                    onClick={() => setActiveFilter('pending')}
                                    className={`px-4 py-1.5 rounded-full text-xs font-black uppercase tracking-widest transition ${activeFilter === 'pending' ? 'bg-orange-600 text-white shadow-md' : 'theme-muted hover:theme-heading hover:theme-bg-secondary'}`}
                                >
                                    {t('moderation.filter.pending', 'Pending')}
                                </button>
                            </div>
                            <div className="relative">
                                <Search className={`absolute ${isRtl ? 'right-3' : 'left-3'} top-1/2 -translate-y-1/2 h-4 w-4 theme-muted opacity-50`} />
                                <input
                                    value={searchQuery}
                                    onChange={(e) => setSearchQuery(e.target.value)}
                                    placeholder={t('moderation.search.placeholder', 'Search offenders or reasons...')}
                                    className={`${isRtl ? 'pr-9 pl-4' : 'pl-9 pr-4'} py-2 theme-bg-secondary theme-heading border border-[var(--surface-border)] rounded-xl text-sm w-full md:w-64 focus:ring-2 focus:ring-orange-500/20 outline-none transition`}
                                />
                            </div>
                        </div>

                        <div className="divide-y divide-[var(--surface-border)]">
                            {filteredReports.length === 0 ? (
                                <div className="py-20 text-center space-y-3">
                                    <CheckCircle className="h-12 w-12 text-green-500 mx-auto opacity-20" />
                                    <p className="theme-muted font-medium tracking-tight">{t('moderation.empty', 'System is healthy. No pending reports match your focus.')}</p>
                                </div>
                            ) : (
                                filteredReports.map(report => (
                                    <div key={report.id} className="p-6 hover:theme-bg-secondary transition-colors">
                                        <div className="flex items-start justify-between gap-4 mb-3">
                                            <div className="flex items-center gap-3">
                                                <div className="h-10 w-10 rounded-full theme-bg-secondary flex items-center justify-center border border-[var(--surface-border)]">
                                                    <User className="h-5 w-5 theme-muted" />
                                                </div>
                                                <div>
                                                    <p className="text-sm font-bold theme-heading">
                                                        {report.reported?.full_name || t('moderation.report.anonymous', 'Anonymous User')}
                                                        <span className={`theme-muted font-normal ${isRtl ? 'mr-2' : 'ml-2'} text-xs opacity-70`}>{t('moderation.report.reportedFor', 'Reported for {reason}').replace('{reason}', report.reason)}</span>
                                                    </p>
                                                    <div className="flex items-center gap-2 mt-0.5">
                                                        <span className="text-[0.625rem] theme-muted uppercase font-bold opacity-60">{t('moderation.report.reporter', 'Reporter: {name}').replace('{name}', report.reporter?.full_name || t('moderation.report.discovery', 'Discovery'))}</span>
                                                        <span className="h-1 w-1 rounded-full theme-bg-secondary opacity-30" />
                                                        <span className="text-[0.625rem] theme-muted opacity-60">{formatDateTime(report.created_at)}</span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                {report.escalation_level !== 'support' && (
                                                    <span className="px-2 py-0.5 rounded bg-red-100 text-red-700 text-[0.625rem] font-black uppercase tracking-widest">
                                                        {report.escalation_level}
                                                    </span>
                                                )}
                                                <StatusBadge status={report.status} />
                                            </div>
                                        </div>
                                        <div className={isRtl ? 'md:pr-[3.25rem]' : 'md:pl-[3.25rem]'}>
                                            <p className="text-sm theme-muted theme-bg-secondary p-3 rounded-xl border border-dashed border-[var(--surface-border)] mb-4 italic opacity-90">
                                                "{report.comment || t('moderation.report.noEvidence', 'No detailed evidence comment provided.')}"
                                            </p>
                                            <div className="flex flex-wrap items-center gap-3">
                                                <Link href={`/users/${report.reported_id}`} className="flex items-center gap-1 text-[0.625rem] font-black uppercase tracking-widest text-orange-600 hover:underline">
                                                    {t('moderation.report.investigate', 'Investigate Profile')} <ArrowRight className={`h-3 w-3 ${isRtl ? 'rotate-180' : ''}`} />
                                                </Link>
                                                <Link
                                                    href={`/reports?status=all&focus=${report.id}`}
                                                    className={`flex items-center gap-1 text-[0.625rem] font-black uppercase tracking-widest text-blue-600 hover:underline ${isRtl ? 'mr-auto' : 'ml-auto'}`}
                                                >
                                                    {t('moderation.report.openInReports', 'Open in Reports')} <ArrowRight className={`h-3 w-3 ${isRtl ? 'rotate-180' : ''}`} />
                                                </Link>
                                            </div>
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </div>
                </div>

                {/* Sidebar: Intelligence & Activity */}
                <div className="space-y-8">
                    {/* High Risk Offenders */}
                    <div className="bg-[var(--surface)] rounded-3xl border border-red-500/20 shadow-sm p-6 overflow-hidden">
                        <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2 mb-6">
                            <TrendingDown className="h-4 w-4 text-red-600" />
                            {t('moderation.sidebar.criticalFeed', 'Critical Risk Feed')}
                        </h3>
                        <div className="space-y-4">
                            {highRiskUsers.length === 0 ? (
                                <p className="text-xs text-green-600 italic">{t('moderation.sidebar.noCritical', 'No critical risk users currently detected.')}</p>
                            ) : (
                                highRiskUsers.map(user => (
                                    <Link key={user.user_id} href={`/users/${user.user_id}`} className="flex items-center justify-between p-3 bg-red-500/5 rounded-2xl border border-red-500/10 hover:border-red-500/30 transition group">
                                        <div>
                                            <p className="text-xs font-bold theme-heading group-hover:text-red-700 transition">{user.profile?.full_name || t('common.unknown', 'Unknown')}</p>
                                            <p className="text-[0.625rem] text-red-600 font-bold uppercase tracking-widest">{user.restriction_tier.replace('_', ' ')}</p>
                                        </div>
                                        <div className="text-end">
                                            <p className="text-lg font-black text-red-600 leading-none">{user.risk_score}</p>
                                            <p className="text-[0.5rem] theme-muted font-bold uppercase opacity-60">{t('moderation.sidebar.riskScore', 'Risk Score')}</p>
                                        </div>
                                    </Link>
                                ))
                            )}
                        </div>
                    </div>

                    {/* Active Restrictions */}
                    <div
                        id="active-restrictions"
                        className={`bg-[var(--surface)] rounded-3xl border shadow-sm p-6 overflow-hidden transition-colors ${highlightRestrictions ? 'border-orange-500/40' : 'border-[var(--surface-border)]'}`}
                    >
                        <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2 mb-6">
                            <ShieldAlert className="h-4 w-4 text-orange-600" />
                            {t('moderation.sidebar.activeRestrictions', 'Active Restrictions')}
                        </h3>
                        <div className="space-y-3">
                            {activeRestrictions.length === 0 ? (
                                <p className="text-xs text-green-600 italic">{t('moderation.sidebar.noRestrictions', 'No active restrictions.')}</p>
                            ) : (
                                activeRestrictions.map((restriction) => (
                                    <Link
                                        key={restriction.id}
                                        href={`/users/${restriction.user_id}`}
                                        className="flex items-center justify-between gap-3 p-3 theme-bg-secondary rounded-2xl border border-[var(--surface-border)] hover:border-orange-500/30 transition group"
                                    >
                                        <div className="min-w-0">
                                            <p className="text-xs font-bold theme-heading truncate group-hover:text-orange-700 transition">
                                                {restriction.profile?.full_name || t('common.unknown', 'Unknown')}
                                            </p>
                                            <p className="text-[0.625rem] text-orange-600 font-bold uppercase tracking-widest">
                                                {restriction.restriction_type.replace('_', ' ')}
                                            </p>
                                        </div>
                                        <div className="text-end flex-shrink-0">
                                            <p className="text-[0.5rem] theme-muted font-bold uppercase opacity-60">
                                                {t('moderation.sidebar.expires', 'Expires')}
                                            </p>
                                            <p className="text-[0.625rem] font-black theme-heading">
                                                {restriction.expires_at ? formatDate(restriction.expires_at) : t('common.never', 'Never')}
                                            </p>
                                        </div>
                                    </Link>
                                ))
                            )}
                        </div>
                    </div>

                    {/* Activity Log */}
                    <div className="bg-[var(--surface)] rounded-3xl border border-[var(--surface-border)] shadow-sm p-6 overflow-hidden">
                        <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2 mb-6">
                            <Activity className="h-4 w-4 text-orange-600" />
                            {t('moderation.sidebar.activityLog', 'Risk Activity Log')}
                        </h3>
                        <div className={`space-y-6 relative before:absolute ${isRtl ? 'before:right-2' : 'before:left-2'} before:top-2 before:bottom-2 before:w-0.5 before:theme-bg-secondary before:opacity-20`}>
                            {riskHistory.length === 0 ? (
                                <p className="text-xs text-green-600 italic">{t('moderation.sidebar.noRiskHistory', 'No risk activity recorded yet.')}</p>
                            ) : (
                                riskHistory.map(entry => (
                                <div key={entry.id} className={`relative ${isRtl ? 'pr-8' : 'pl-8'}`}>
                                    <div className={`absolute ${isRtl ? 'right-0' : 'left-0'} top-1 h-4 w-4 rounded-full border-4 border-[var(--surface)] shadow-sm ${entry.new_score < entry.old_score ? 'bg-red-500' : 'bg-green-500'}`} />
                                    <p className="text-xs theme-heading font-bold leading-none">{entry.profile?.full_name}</p>
                                    <p className="text-[0.625rem] theme-muted mt-1 line-clamp-1 opacity-70">{entry.reason}</p>
                                    <div className="flex items-center gap-2 mt-1">
                                        <span className="text-[0.625rem] font-black theme-heading">{entry.old_score} -&gt; {entry.new_score}</span>
                                        <span className="text-[0.5rem] theme-muted opacity-50">{formatDate(entry.created_at)}</span>
                                    </div>
                                </div>
                                ))
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
