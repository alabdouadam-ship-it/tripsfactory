'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import {
    AlertTriangle, ShieldAlert, Package,
    Users,
    ChevronRight, ArrowUpRight,
    Clock, RefreshCw
} from 'lucide-react';
import {
    AreaChart, Area, XAxis, YAxis,
    CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';
import Loading from '@/app/loading';
import { useI18n } from '@/lib/i18n';
import { cn } from '@/lib/utils';
import { useToast } from '@/lib/toast';

const ACTIVE_BOOKING_STATUSES = [
    'pending',
    'in_communication',
    'accepted',
    'in_transit',
    'delivered',
    'frozen',
    'disputed',
];

const RISK_REVIEW_THRESHOLD = 60;
const RISK_CRITICAL_THRESHOLD = 20;
const DAY_MS = 24 * 60 * 60 * 1000;

export default function FounderPage() {
    const router = useRouter();
    const { t, language, dir } = useI18n();
    const { toast } = useToast();
    const [loading, setLoading] = useState(true);
    const [stats, setStats] = useState({
        disputes: 0,
        restrictions: 0,
        activeBookings: 0,
        expiringDocs: 0,
        newUsersToday: 0,
        weeklyTrend: [] as any[],
        highRiskUsers: [] as any[]
    });

    useEffect(() => {
        fetchFounderData();
    }, [language]);

    async function fetchFounderData() {
        setLoading(true);
        try {
            const now = new Date();
            const nowIso = now.toISOString();
            const last24Hours = new Date(now.getTime() - DAY_MS).toISOString();
            const sevenDaysFromNow = new Date(now.getTime() + 7 * DAY_MS).toISOString();
            const chartLocale = language === 'ar' ? 'ar-SA' : 'en-US';

            const [
                disputesRes,
                restrictionsRes,
                activeRes,
                expiringRes,
                newUsersRes,
                riskRes,
                bookingsTrendRes,
            ] = await Promise.all([
                supabase.from('bookings').select('*', { count: 'exact', head: true }).eq('status', 'disputed'),
                supabase.from('user_restrictions').select('*', { count: 'exact', head: true }).or('expires_at.is.null,expires_at.gt.' + nowIso),
                supabase.from('bookings').select('*', { count: 'exact', head: true }).in('status', ACTIVE_BOOKING_STATUSES),
                supabase
                    .from('profiles')
                    .select('*', { count: 'exact', head: true })
                    .gte('license_expires_at', nowIso)
                    .lt('license_expires_at', sevenDaysFromNow)
                    .neq('traveler_status', 'none')
                    .not('traveler_status', 'is', null),
                supabase.from('profiles').select('*', { count: 'exact', head: true }).gte('created_at', last24Hours),
                supabase
                    .from('user_risk_scores')
                    .select('*, profile:profiles(full_name, phone_number)')
                    .lt('risk_score', RISK_REVIEW_THRESHOLD)
                    .order('risk_score', { ascending: true })
                    .limit(5),
                supabase
                    .from('bookings')
                    .select('created_at')
                    .gte('created_at', new Date(now.getTime() - 6 * DAY_MS).toISOString())
            ]);
            if (
                disputesRes.error ||
                restrictionsRes.error ||
                activeRes.error ||
                expiringRes.error ||
                newUsersRes.error ||
                riskRes.error ||
                bookingsTrendRes.error
            ) {
                throw (
                    disputesRes.error ||
                    restrictionsRes.error ||
                    activeRes.error ||
                    expiringRes.error ||
                    newUsersRes.error ||
                    riskRes.error ||
                    bookingsTrendRes.error
                );
            }

            const dayKey = (d: Date) => d.toISOString().slice(0, 10);
            const trendBase = Array.from({ length: 7 }).map((_, idx) => {
                const d = new Date();
                d.setDate(d.getDate() - (6 - idx));
                return { key: dayKey(d), day: d.toLocaleDateString(chartLocale, { weekday: 'short' }), bookings: 0 };
            });
            for (const row of bookingsTrendRes.data || []) {
                const key = dayKey(new Date(row.created_at));
                const point = trendBase.find(t => t.key === key);
                if (point) point.bookings += 1;
            }
            const trend = trendBase.map(({ key, ...rest }) => rest);

            setStats({
                disputes: disputesRes.count || 0,
                restrictions: restrictionsRes.count || 0,
                activeBookings: activeRes.count || 0,
                expiringDocs: expiringRes.count || 0,
                newUsersToday: newUsersRes.count || 0,
                weeklyTrend: trend,
                highRiskUsers: riskRes.data || []
            });
        } catch (e) {
            console.error(e);
            toast(t('founder.errorLoad', 'Failed to load founder dashboard data.'), 'error');
        } finally {
            setLoading(false);
        }
    }

    if (loading) return <Loading />;

    const signals = [
        { label: t('founder.signals.disputes'), value: stats.disputes, icon: AlertTriangle, color: 'text-red-500', bg: 'bg-red-500/10', href: '/bookings?status=disputed' },
        { label: t('founder.signals.restrictions'), value: stats.restrictions, icon: ShieldAlert, color: 'text-orange-500', bg: 'bg-orange-500/10', href: '/moderation?focus=restrictions#active-restrictions' },
        { label: t('founder.signals.activeBookings'), value: stats.activeBookings, icon: Package, color: 'text-blue-500', bg: 'bg-blue-500/10', href: '/bookings' },
        { label: t('founder.signals.expiringSoon'), value: stats.expiringDocs, icon: Clock, color: 'text-yellow-500', bg: 'bg-yellow-500/10', href: '/drivers?expiry=license_soon' },
        { label: t('founder.signals.newUsers'), value: stats.newUsersToday, icon: Users, color: 'text-green-500', bg: 'bg-green-500/10', href: '/users' },
    ];

    return (
        <div className="space-y-6 pb-12">
            <header className="flex justify-between items-end">
                <div>
                    <h1 className="text-4xl font-black theme-heading tracking-tighter uppercase italic">{t('founder.title')}</h1>
                    <p className="text-xs font-bold theme-muted uppercase tracking-widest mt-1">{t('founder.subtitle')}</p>
                </div>
                <div className="flex gap-2">
                    <button
                        onClick={() => fetchFounderData()}
                        className="p-2 theme-bg-secondary rounded-xl transition border border-[var(--surface-border)] shadow-sm"
                        aria-label={t('common.refresh', 'Refresh')}
                        title={t('common.refresh', 'Refresh')}
                    >
                        <RefreshCw className="h-4 w-4 theme-muted" />
                    </button>
                </div>
            </header>

            {/* Signal Grid */}
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                {signals.map((sig, i) => (
                    <button
                        key={i}
                        onClick={() => router.push(sig.href)}
                        className="p-6 theme-card rounded-3xl shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all group text-left"
                        style={{ textAlign: dir === 'rtl' ? 'right' : 'left' }}
                    >
                        <div className={cn("p-3 w-fit rounded-2xl mb-4 group-hover:scale-110 transition-transform", sig.bg)}>
                            <sig.icon className={cn("h-6 w-6", sig.color)} />
                        </div>
                        <p className="text-[0.625rem] font-black theme-muted uppercase tracking-widest leading-none mb-2">{sig.label}</p>
                        <div className="flex items-baseline justify-between transition-transform">
                            <span className="text-3xl font-black theme-heading">{sig.value}</span>
                            <ArrowUpRight className="h-4 w-4 opacity-0 group-hover:opacity-100 theme-muted transition-opacity" />
                        </div>
                    </button>
                ))}
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Weekly Trend */}
                <div className="lg:col-span-2 theme-card p-8 rounded-[2.5rem] shadow-2xl border border-[var(--surface-border)] relative overflow-hidden group">
                    {/* Background Glow */}
                    <div className="absolute top-0 right-0 -mr-20 -mt-20 w-80 h-80 bg-blue-500/5 rounded-full blur-[100px] pointer-events-none opacity-50"></div>

                    <div className="flex items-center justify-between mb-8 relative">
                        <div>
                            <h2 className="text-xl font-black theme-heading tracking-tight">{t('founder.velocity.title')}</h2>
                            <p className="text-[0.625rem] font-black text-blue-500 uppercase tracking-widest mt-1 opacity-80">{t('founder.velocity.subtitle')}</p>
                        </div>
                        <div className="flex gap-2">
                            <div className="px-4 py-1.5 theme-bg-secondary border border-[var(--surface-border)] rounded-full text-[0.625rem] font-black theme-heading uppercase tracking-widest shadow-sm">{t('founder.velocity.live')}</div>
                        </div>
                    </div>

                    <div className="h-64 w-full relative">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={stats.weeklyTrend}>
                                <defs>
                                    <linearGradient id="velocity" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                                        <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--surface-border)" opacity={0.5} />
                                <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 900, fill: 'var(--muted)', opacity: 0.6 }} dy={10} />
                                <YAxis hide />
                                <Tooltip
                                    contentStyle={{ backgroundColor: 'var(--surface)', border: '1px solid var(--surface-border)', borderRadius: '16px', color: 'var(--foreground)', fontSize: '0.75rem', fontWeight: 900 }}
                                />
                                <Area type="monotone" dataKey="bookings" stroke="#3b82f6" strokeWidth={4} fillOpacity={1} fill="url(#velocity)" dot={{ r: 4, fill: '#3b82f6', strokeWidth: 2, stroke: 'var(--surface)' }} activeDot={{ r: 6, strokeWidth: 0 }} />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* High Risk Radar */}
                <div className="theme-card p-8 rounded-[2.5rem] shadow-sm flex flex-col h-full">
                    <h2 className="text-xl font-black theme-heading tracking-tight mb-6">{t('founder.riskRadar.title')}</h2>
                    <div className="space-y-4 flex-1">
                        {stats.highRiskUsers.length === 0 ? (
                            <p className="text-xs text-green-600 font-bold italic">
                                {t('founder.riskRadar.empty', 'No users currently below the risk review threshold.')}
                            </p>
                        ) : stats.highRiskUsers.map((user) => (
                            <div key={user.user_id} className="flex items-center justify-between p-4 theme-bg-secondary rounded-2xl border border-[var(--surface-border)] hover:border-red-200 transition-all group">
                                <div className="flex items-center gap-3">
                                    <div className="relative">
                                        <div className="w-10 h-10 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center font-black theme-muted text-xs">
                                            {user.profile?.full_name?.charAt(0) || '?'}
                                        </div>
                                        <div className={cn(
                                            "absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-4 border-[var(--surface)]",
                                            user.risk_score < RISK_CRITICAL_THRESHOLD ? "bg-red-500" : "bg-orange-500"
                                        )}></div>
                                    </div>
                                    <div>
                                        <p className="text-sm font-black theme-heading truncate max-w-[120px]">{user.profile?.full_name || t('common.unknown', 'Unknown')}</p>
                                        <p className="text-[0.625rem] font-bold theme-muted">{t('founder.riskRadar.score')}: <span className="text-red-600">{user.risk_score}</span></p>
                                    </div>
                                </div>
                                <button
                                    onClick={() => router.push(`/users/${user.user_id}`)}
                                    className="p-2 bg-[var(--surface)] rounded-xl shadow-sm border border-[var(--surface-border)] hover:bg-red-500/10 text-red-600 transition-colors"
                                    title={t('common.viewDetails', 'View details')}
                                >
                                    <ArrowUpRight className="h-4 w-4" />
                                </button>
                            </div>
                        ))}
                    </div>
                    <button
                        onClick={() => router.push('/moderation')}
                        className="w-full mt-6 py-4 theme-heading bg-blue-600 hover:bg-blue-700 text-white rounded-2xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-lg shadow-blue-600/20 flex items-center justify-center gap-2"
                    >
                        {t('founder.riskRadar.enterEngine')} <ChevronRight className="h-3 w-3" />
                    </button>
                </div>
            </div>
        </div>
    );
}
