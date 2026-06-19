'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import {
  AlertCircle,
  Building2,
  CheckCircle2,
  Handshake,
  Package,
  Plane,
  RefreshCw,
  ShoppingCart,
  TrendingUp,
  Truck,
  Users,
} from 'lucide-react';
import {
  Area,
  AreaChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip as RechartsTooltip,
  XAxis,
  YAxis,
} from 'recharts';
import Loading from '@/app/loading';
import { useT } from '@/lib/i18n';
import { useToast } from '@/lib/toast';

const SHIPMENT_STATUSES = [
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
] as const;

const TRIP_STATUSES = [
  'pending_approval',
  'available',
  'in_communication',
  'pending_confirmation',
  'booked',
  'full',
  'in_transit',
  'completed',
  'cancelled',
] as const;

const ACTIVE_TRIP_STATUSES = ['available', 'booked', 'in_transit', 'pending_confirmation'];
const ACTIVE_SHIPMENT_STATUSES = [
  'pending',
  'in_communication',
  'accepted',
  'picked_up',
  'in_transit',
  'frozen',
  'disputed',
];

const STATUS_COLORS: Record<string, string> = {
  pending_approval: '#f59e0b',
  pending: '#f59e0b',
  available: '#10b981',
  in_communication: '#7c3aed',
  pending_confirmation: '#f59e0b',
  accepted: '#3b82f6',
  booked: '#3b82f6',
  picked_up: '#6366f1',
  in_transit: '#f97316',
  full: '#8b5cf6',
  delivered: '#14b8a6',
  completed: '#10b981',
  cancelled: '#ef4444',
  rejected: '#ef4444',
  expired: '#64748b',
  frozen: '#06b6d4',
  disputed: '#e11d48',
};

const TRIP_STATUS_COLORS: Record<string, string> = {
  ...STATUS_COLORS,
  available: '#22c55e',
  completed: '#0f766e',
};

type DashboardStats = {
  totalUsers: number;
  totalDrivers: number;
  totalCompanies: number;
  activeTrips: number;
  totalTrips: number;
  activeShipments: number;
  bookings: number;
  offers: number;
  shipments: number;
  disputes: number;
  pendingDrivers: number;
  shipmentReviews: number;
  pendingCompanies: number;
  growthData: Array<{ name: string; users: number; drivers: number; trips: number }>;
};

type RecentActivity = {
  id: string;
  type: 'user' | 'booking' | 'shipment' | 'driver';
  labelKey: string;
  name?: string | null;
  createdAt: string;
  icon: typeof Users;
  color: string;
  href: string;
};

type StatusDistributionItem = {
  status: string;
  name: string;
  value: number;
  color: string;
};

const initialStats: DashboardStats = {
  totalUsers: 0,
  totalDrivers: 0,
  totalCompanies: 0,
  activeTrips: 0,
  totalTrips: 0,
  activeShipments: 0,
  bookings: 0,
  offers: 0,
  shipments: 0,
  disputes: 0,
  pendingDrivers: 0,
  shipmentReviews: 0,
  pendingCompanies: 0,
  growthData: [],
};

function formatStatusLabel(status: string) {
  return status.replace(/_/g, ' ');
}

export default function Home() {
  const router = useRouter();
  const t = useT();
  const { toast } = useToast();
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState<DashboardStats>(initialStats);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [statusDistribution, setStatusDistribution] = useState<StatusDistributionItem[]>([]);
  const [tripStatusDistribution, setTripStatusDistribution] = useState<StatusDistributionItem[]>([]);
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);

  useEffect(() => {
    fetchStats();
  }, []);

  async function fetchStats() {
    if (lastUpdated) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }
    setError(null);

    try {
      const [
        companiesReq,
        tripsReq,
        activeTripsReq,
        shipmentsReq,
        activeShipmentsReq,
        bookingsReq,
        offersReq,
        disputesReq,
        pendingDriversReq,
        shipmentReviewsReq,
        pendingCompaniesReq,
      ] = await Promise.all([
        supabase
          .from('profiles')
          .select('*', { count: 'exact', head: true })
          .eq('account_type', 'company')
          .neq('company_status', 'none'),
        supabase.from('trips').select('*', { count: 'exact', head: true }),
        supabase.from('trips').select('*', { count: 'exact', head: true }).in('status', ACTIVE_TRIP_STATUSES),
        supabase.from('shipments').select('*', { count: 'exact', head: true }),
        supabase.from('shipments').select('*', { count: 'exact', head: true }).in('status', ACTIVE_SHIPMENT_STATUSES),
        supabase.from('bookings').select('*', { count: 'exact', head: true }),
        supabase.from('offers').select('*', { count: 'exact', head: true }),
        supabase.from('bookings').select('*', { count: 'exact', head: true }).eq('status', 'disputed'),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('traveler_status', 'pending'),
        supabase.from('shipments').select('*', { count: 'exact', head: true }).eq('moderation_status', 'pending_review'),
        supabase
          .from('profiles')
          .select('*', { count: 'exact', head: true })
          .eq('account_type', 'company')
          .eq('company_status', 'pending'),
      ]);

      const countError =
        companiesReq.error ||
        tripsReq.error ||
        activeTripsReq.error ||
        shipmentsReq.error ||
        activeShipmentsReq.error ||
        bookingsReq.error ||
        offersReq.error ||
        disputesReq.error ||
        pendingDriversReq.error ||
        shipmentReviewsReq.error ||
        pendingCompaniesReq.error;
      if (countError) {
        throw countError;
      }

      const { data: rpcStats, error: rpcError } = await supabase.rpc('get_dashboard_stats');

      let totalUsers = 0;
      let totalDrivers = 0;
      let growthData: DashboardStats['growthData'] = [];

      if (!rpcError && rpcStats) {
        totalUsers = rpcStats.total_users || 0;
        totalDrivers = rpcStats.total_drivers || 0;
        growthData = (rpcStats.monthly_growth || []).slice(0, 7).reverse().map((g: any) => ({
          name: g.month,
          users: g.users || 0,
          drivers: g.drivers || 0,
          trips: g.trips || 0,
        }));
      } else {
        const rpcReason = rpcError?.message || 'Empty RPC response';
        console.warn('[Dashboard] get_dashboard_stats unavailable, using fallback mode:', rpcReason);
        toast(
          t(
            'dashboard.rpcFallback',
            'Dashboard metrics are in fallback mode because RPC stats are unavailable.',
          ),
          'info',
        );

        const [usersReq, driversReq] = await Promise.all([
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('profiles').select('*', { count: 'exact', head: true }).neq('traveler_status', 'none'),
        ]);
        if (usersReq.error || driversReq.error) {
          throw usersReq.error || driversReq.error;
        }
        totalUsers = usersReq.count || 0;
        totalDrivers = driversReq.count || 0;

        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        for (let i = 6; i >= 0; i--) {
          const d = new Date();
          d.setMonth(d.getMonth() - i);
          growthData.push({
            name: monthNames[d.getMonth()],
            users: 0,
            drivers: 0,
            trips: 0,
          });
        }
      }

      setStats({
        totalUsers,
        totalDrivers,
        totalCompanies: companiesReq.count || 0,
        activeTrips: activeTripsReq.count || 0,
        totalTrips: tripsReq.count || 0,
        activeShipments: activeShipmentsReq.count || 0,
        bookings: bookingsReq.count || 0,
        offers: offersReq.count || 0,
        shipments: shipmentsReq.count || 0,
        disputes: disputesReq.count || 0,
        pendingDrivers: pendingDriversReq.count || 0,
        shipmentReviews: shipmentReviewsReq.count || 0,
        pendingCompanies: pendingCompaniesReq.count || 0,
        growthData,
      });

      const [profilesRes, bookingsRes, shipmentsRes, pendingDriversRes] = await Promise.all([
        supabase.from('profiles').select('id, full_name, created_at').order('created_at', { ascending: false }).limit(3),
        supabase.from('bookings').select('id, status, created_at').order('created_at', { ascending: false }).limit(5),
        supabase.from('shipments').select('id, created_at').order('created_at', { ascending: false }).limit(3),
        supabase
          .from('profiles')
          .select('id, traveler_status, created_at')
          .eq('traveler_status', 'pending')
          .order('created_at', { ascending: false })
          .limit(3),
      ]);

      if (profilesRes.error || bookingsRes.error || shipmentsRes.error || pendingDriversRes.error) {
        console.warn(
          '[Dashboard] recent activity partially unavailable:',
          profilesRes.error || bookingsRes.error || shipmentsRes.error || pendingDriversRes.error,
        );
      }

      const activities: Array<RecentActivity & { sortAt: string }> = [];

      (profilesRes.data || []).forEach((p: any) => {
        activities.push({
          id: `user-${p.id}`,
          type: 'user',
          labelKey: 'dashboard.activity.newUser',
          name: p.full_name,
          createdAt: p.created_at,
          icon: Users,
          color: 'text-blue-500',
          href: `/users/${p.id}`,
          sortAt: p.created_at,
        });
      });
      (bookingsRes.data || []).forEach((b: any) => {
        activities.push({
          id: `booking-${b.id}`,
          type: 'booking',
          labelKey: 'dashboard.activity.booking',
          name: `#${String(b.id).slice(0, 8)} ${b.status ?? ''}`,
          createdAt: b.created_at,
          icon: ShoppingCart,
          color: 'text-green-500',
          href: `/bookings/${b.id}`,
          sortAt: b.created_at,
        });
      });
      (shipmentsRes.data || []).forEach((s: any) => {
        activities.push({
          id: `shipment-${s.id}`,
          type: 'shipment',
          labelKey: 'dashboard.activity.newShipment',
          createdAt: s.created_at,
          icon: Package,
          color: 'text-orange-500',
          href: `/shipments/${s.id}`,
          sortAt: s.created_at,
        });
      });
      (pendingDriversRes.data || []).forEach((driver: any) => {
        activities.push({
          id: `driver-${driver.id}`,
          type: 'driver',
          labelKey: 'dashboard.activity.driverPending',
          createdAt: driver.created_at,
          icon: Truck,
          color: 'text-purple-500',
          href: `/users/${driver.id}`,
          sortAt: driver.created_at,
        });
      });

      activities.sort((a, b) => new Date(b.sortAt).getTime() - new Date(a.sortAt).getTime());
      setRecentActivity(activities.slice(0, 8).map(({ sortAt, ...rest }) => rest));

      const statusResults = await Promise.all(
        SHIPMENT_STATUSES.map(async (shipmentStatus) => {
          const result = await supabase.from('shipments').select('*', { count: 'exact', head: true }).eq('status', shipmentStatus);
          return { shipmentStatus, ...result };
        }),
      );
      const failedStatus = statusResults.find((result) => result.error);
      if (failedStatus) {
        console.warn('[Dashboard] shipment status distribution partially unavailable:', failedStatus.error);
        toast(
          t('dashboard.statusDistributionUnavailable', 'Shipment status chart is partially unavailable.'),
          'info',
        );
      }

      const distribution = statusResults
        .filter((result) => !result.error && (result.count || 0) > 0)
        .map((result) => ({
          status: result.shipmentStatus,
          name: formatStatusLabel(result.shipmentStatus),
          value: result.count || 0,
          color: STATUS_COLORS[result.shipmentStatus] || '#94a3b8',
        }));

      setStatusDistribution(
        distribution.length === 0
          ? [{ status: 'none', name: t('dashboard.noData'), value: 1, color: '#e2e8f0' }]
          : distribution,
      );

      const tripStatusResults = await Promise.all(
        TRIP_STATUSES.map(async (tripStatus) => {
          const result = await supabase.from('trips').select('*', { count: 'exact', head: true }).eq('status', tripStatus);
          return { tripStatus, ...result };
        }),
      );
      const failedTripStatus = tripStatusResults.find((result) => result.error);
      if (failedTripStatus) {
        console.warn('[Dashboard] trip status distribution partially unavailable:', failedTripStatus.error);
        toast(
          t('dashboard.tripStatusDistributionUnavailable', 'Trip status chart is partially unavailable.'),
          'info',
        );
      }

      const tripDistribution = tripStatusResults
        .filter((result) => !result.error && (result.count || 0) > 0)
        .map((result) => ({
          status: result.tripStatus,
          name: formatStatusLabel(result.tripStatus),
          value: result.count || 0,
          color: TRIP_STATUS_COLORS[result.tripStatus] || '#94a3b8',
        }));

      setTripStatusDistribution(
        tripDistribution.length === 0
          ? [{ status: 'none', name: t('dashboard.noData'), value: 1, color: '#e2e8f0' }]
          : tripDistribution,
      );
      setLastUpdated(new Date());
    } catch (e) {
      console.error('Error fetching stats', e);
      setError(t('dashboard.errorLoad', 'Failed to load dashboard. Please try again.'));
      toast(t('dashboard.errorLoad', 'Failed to load dashboard. Please try again.'), 'error');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  const statCards = [
    { key: 'dashboard.totalUsers', label: 'Total Users', value: stats.totalUsers, icon: Users, color: 'bg-blue-500' },
    { key: 'dashboard.drivers', label: 'Drivers', value: stats.totalDrivers, icon: Truck, color: 'bg-orange-500' },
    { key: 'dashboard.companies', label: 'Companies', value: stats.totalCompanies, icon: Building2, color: 'bg-cyan-500' },
    {
      key: 'dashboard.trips',
      label: 'Trips',
      value: `${stats.activeTrips}/${stats.totalTrips}`,
      detailKey: 'dashboard.activeTotal',
      detail: 'Active / total',
      icon: Plane,
      color: 'bg-purple-500',
    },
    { key: 'dashboard.bookings', label: 'Bookings', value: stats.bookings, icon: ShoppingCart, color: 'bg-green-500' },
    {
      key: 'dashboard.shipments',
      label: 'Shipments',
      value: `${stats.activeShipments}/${stats.shipments}`,
      detailKey: 'dashboard.activeTotal',
      detail: 'Active / total',
      icon: Package,
      color: 'bg-indigo-500',
    },
    { key: 'dashboard.offers', label: 'Offers', value: stats.offers, icon: Handshake, color: 'bg-emerald-500' },
  ];

  const actionQueue = [
    {
      key: 'dashboard.travelerApprovals',
      label: 'Traveler Approvals',
      detailKey: 'dashboard.pendingTravelers',
      detail: 'Travelers / drivers pending approval',
      value: stats.pendingDrivers,
      href: '/users',
      icon: Users,
      color: 'text-blue-500',
    },
    {
      key: 'dashboard.disputes',
      label: 'Disputes',
      detailKey: 'dashboard.openDisputes',
      detail: 'Open disputes',
      value: stats.disputes,
      href: '/bookings?status=disputed',
      icon: AlertCircle,
      color: 'text-red-500',
    },
    {
      key: 'dashboard.shipmentReviews',
      label: 'Shipment Reviews',
      detailKey: 'dashboard.pendingReview',
      detail: 'Pending review',
      value: stats.shipmentReviews,
      href: '/shipments?moderation=pending_review',
      icon: Package,
      color: 'text-amber-500',
    },
    {
      key: 'dashboard.pendingCompanies',
      label: 'Pending Companies',
      detailKey: 'dashboard.awaitingApproval',
      detail: 'Awaiting approval',
      value: stats.pendingCompanies,
      href: '/companies',
      icon: Building2,
      color: 'text-cyan-500',
    },
  ];

  if (loading) return <Loading />;
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center">{error}</p>
        <button
          type="button"
          onClick={() => fetchStats()}
          className="px-4 py-2 rounded-lg font-medium"
          style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}
        >
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  function formatTimeAgo(date: string) {
    const d = new Date(date);
    if (Number.isNaN(d.getTime())) return '';

    const now = new Date();
    const diffMs = Math.max(0, now.getTime() - d.getTime());
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    if (diffMins < 1) {
      return t('dashboard.time.justNow', 'Just now');
    }
    if (diffMins < 60) {
      return t('dashboard.time.minutesAgo', `${diffMins} mins ago`).replace('{count}', String(diffMins));
    }
    if (diffHours < 24) {
      return t('dashboard.time.hoursAgo', `${diffHours} hour(s) ago`).replace('{count}', String(diffHours));
    }
    if (diffDays < 7) {
      return t('dashboard.time.daysAgo', `${diffDays} day(s) ago`).replace('{count}', String(diffDays));
    }
    return d.toLocaleDateString();
  }

  function activityText(activity: RecentActivity) {
    if (activity.type === 'user') {
      return `${activity.name ?? t('dashboard.activity.user', 'User')} : ${t(activity.labelKey, 'New user registered')}`;
    }
    if (activity.type === 'booking') {
      return `${t(activity.labelKey, 'Booking')} ${activity.name ?? ''}`;
    }
    return t(activity.labelKey, activity.labelKey);
  }

  return (
    <div className="space-y-8 pb-10">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">
            {t('dashboard.title', 'System Overview')}
          </h1>
          <p className="theme-muted text-sm mt-1 font-medium">
            {t('dashboard.subtitle', 'Monitoring TripShip Network')}
          </p>
        </div>
        <button
          type="button"
          onClick={() => fetchStats()}
          disabled={refreshing}
          className="theme-card px-4 py-2 rounded-xl shadow-sm flex items-center gap-3 border border-[var(--surface-border)] text-left hover:shadow-md transition disabled:opacity-60"
          aria-label={t('dashboard.refresh', 'Refresh dashboard')}
        >
          <RefreshCw className={`h-4 w-4 text-blue-500 ${refreshing ? 'animate-spin' : ''}`} />
          <span className="flex flex-col">
            <span className="text-xs font-black theme-heading uppercase tracking-widest">
              {t('dashboard.refresh', 'Refresh')}
            </span>
            <span className="text-[0.625rem] font-bold theme-muted uppercase tracking-widest">
              {lastUpdated
                ? `${t('dashboard.lastUpdated', 'Last updated')}: ${lastUpdated.toLocaleTimeString(undefined, {
                  hour: '2-digit',
                  minute: '2-digit',
                })}`
                : t('dashboard.notUpdatedYet', 'Not updated yet')}
            </span>
          </span>
        </button>
      </div>

      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4 2xl:grid-cols-7">
        {statCards.map((stat) => (
          <div key={stat.key} className="theme-card p-4 rounded-2xl shadow-sm flex items-center transition-all hover:shadow-md group border border-[var(--surface-border)] min-w-0">
            <div className={`p-2.5 rounded-xl ${stat.color} bg-opacity-10 mr-3 group-hover:scale-105 transition-transform flex-shrink-0`}>
              <stat.icon className={`h-4 w-4 ${stat.color.replace('bg-', 'text-')}`} />
            </div>
            <div className="min-w-0">
              <p className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
                {t(stat.key, stat.label)}
              </p>
              <p className="text-xl font-black theme-heading leading-tight">{stat.value}</p>
              {stat.detailKey && (
                <p className="text-[0.625rem] font-bold theme-muted uppercase tracking-widest mt-1">
                  {t(stat.detailKey, stat.detail ?? '')}
                </p>
              )}
            </div>
          </div>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2 theme-card p-8 rounded-2xl shadow-sm flex flex-col">
          <div className="mb-8 flex items-center justify-between">
            <div>
              <h2 className="text-xl font-black theme-heading tracking-tight">
                {t('dashboard.networkGrowth', 'Network Growth')}
              </h2>
              <p className="text-xs theme-muted font-bold uppercase mt-1">
                {t('dashboard.networkGrowth.subtitle', 'Users, Drivers & Trips Tracking')}
              </p>
            </div>
            <div className="bg-green-500/10 p-2 rounded-lg">
              <TrendingUp className="h-5 w-5 text-green-500" />
            </div>
          </div>
          <div className="h-80 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={stats.growthData}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="colorDrivers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.1} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="colorTrips" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.1} />
                    <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--surface-border)" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 900, fill: 'var(--text-secondary)', textAnchor: 'middle' }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 10, fontWeight: 900, fill: 'var(--text-secondary)' }} />
                <RechartsTooltip
                  contentStyle={{
                    borderRadius: '16px',
                    border: '1px solid var(--surface-border)',
                    boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)',
                    backgroundColor: 'var(--surface)',
                    color: 'var(--text-primary)',
                    fontSize: '12px',
                    fontWeight: 'bold',
                  }}
                  itemStyle={{ color: 'var(--text-primary)' }}
                />
                <Area type="monotone" dataKey="users" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorUsers)" />
                <Area type="monotone" dataKey="drivers" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorDrivers)" />
                <Area type="monotone" dataKey="trips" stroke="#f59e0b" strokeWidth={3} fillOpacity={1} fill="url(#colorTrips)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="theme-card p-8 rounded-2xl shadow-sm border border-[var(--surface-border)]">
          <h2 className="text-xl font-black theme-heading tracking-tight mb-8">
            {t('dashboard.recentActivity', 'Recent Activity')}
          </h2>
          <div className="space-y-4">
            {recentActivity.length === 0 && (
              <p className="text-sm theme-muted font-medium">
                {t('dashboard.noRecentActivity', 'No recent activity yet.')}
              </p>
            )}
            {recentActivity.map((activity) => (
              <button
                type="button"
                key={activity.id}
                onClick={() => router.push(activity.href)}
                className="w-full flex gap-4 group text-left rounded-xl transition hover:theme-bg-secondary p-2 -m-2"
              >
                <div className="flex flex-col items-center">
                  <div className={`p-2 rounded-lg theme-bg-secondary ${activity.color} group-hover:scale-105 transition-transform border border-[var(--surface-border)]`}>
                    <activity.icon className="h-4 w-4" />
                  </div>
                  <div className="w-0.5 h-full theme-bg-secondary mt-2 opacity-50"></div>
                </div>
                <div className="pb-4">
                  <p className="text-sm font-bold theme-heading tracking-tight">
                    {activityText(activity)}
                  </p>
                  <p className="text-[0.625rem] theme-muted font-black uppercase mt-1 tracking-widest opacity-60">
                    {formatTimeAgo(activity.createdAt)}
                  </p>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="theme-card p-8 rounded-2xl shadow-sm border border-[var(--surface-border)]">
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-xl font-black theme-heading tracking-tight">
              {t('dashboard.shipmentStatus', 'Shipment Status')}
            </h2>
            <CheckCircle2 className="h-5 w-5 text-blue-500" />
          </div>
          <div className="h-64 flex flex-col md:flex-row items-center gap-8">
            <div className="h-full flex-1 w-full md:w-auto">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={statusDistribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={90}
                    paddingAngle={8}
                    dataKey="value"
                    stroke="none"
                  >
                    {statusDistribution.map((entry, index) => (
                      <Cell key={`${entry.status}-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip
                    contentStyle={{
                      borderRadius: '16px',
                      border: '1px solid var(--surface-border)',
                      backgroundColor: 'var(--surface)',
                      color: 'var(--text-primary)',
                      fontSize: '12px',
                      fontWeight: 'bold',
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="grid grid-cols-2 gap-4 w-full md:w-auto">
              {statusDistribution.map((entry) => (
                <div
                  key={entry.status}
                  className="flex items-center gap-3 theme-bg-secondary p-3 rounded-xl border border-[var(--surface-border)]"
                >
                  <div className="w-3 h-3 rounded-full shadow-sm" style={{ backgroundColor: entry.color }}></div>
                  <div className="flex flex-col">
                    <span className="text-[0.625rem] theme-muted font-black uppercase tracking-widest leading-none mb-1">{entry.name}</span>
                    <span className="text-sm font-black theme-heading leading-none">{entry.value}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="theme-card p-8 rounded-2xl shadow-sm border border-[var(--surface-border)]">
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-xl font-black theme-heading tracking-tight">
              {t('dashboard.tripStatus', 'Trip Status')}
            </h2>
            <CheckCircle2 className="h-5 w-5 text-purple-500" />
          </div>
          <div className="h-64 flex flex-col md:flex-row items-center gap-8">
            <div className="h-full flex-1 w-full md:w-auto">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={tripStatusDistribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={90}
                    paddingAngle={8}
                    dataKey="value"
                    stroke="none"
                  >
                    {tripStatusDistribution.map((entry, index) => (
                      <Cell key={`trip-${entry.status}-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip
                    contentStyle={{
                      borderRadius: '16px',
                      border: '1px solid var(--surface-border)',
                      backgroundColor: 'var(--surface)',
                      color: 'var(--text-primary)',
                      fontSize: '12px',
                      fontWeight: 'bold',
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="grid grid-cols-2 gap-4 w-full md:w-auto">
              {tripStatusDistribution.map((entry) => (
                <div
                  key={entry.status}
                  className="flex items-center gap-3 theme-bg-secondary p-3 rounded-xl border border-[var(--surface-border)]"
                >
                  <div className="w-3 h-3 rounded-full shadow-sm" style={{ backgroundColor: entry.color }}></div>
                  <div className="flex flex-col">
                    <span className="text-[0.625rem] theme-muted font-black uppercase tracking-widest leading-none mb-1">{entry.name}</span>
                    <span className="text-sm font-black theme-heading leading-none">{entry.value}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="theme-card p-8 rounded-2xl shadow-sm border border-[var(--surface-border)] lg:col-span-2">
          <div className="mb-6">
            <h2 className="text-xl font-black theme-heading tracking-tight">
              {t('dashboard.actionQueue', 'Action Queue')}
            </h2>
            <p className="text-xs theme-muted font-bold uppercase mt-1">
              {t('dashboard.actionQueue.subtitle', 'Open the queues that usually need admin attention.')}
            </p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {actionQueue.map((action) => (
              <button
                type="button"
                key={action.href}
                onClick={() => router.push(action.href)}
                className="theme-bg-secondary hover:shadow-md transition-all p-4 rounded-xl text-left border border-[var(--surface-border)] flex items-start gap-4"
              >
                <div className={`p-2 rounded-lg bg-[var(--surface)] border border-[var(--surface-border)] ${action.color}`}>
                  <action.icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-sm font-black theme-heading uppercase tracking-widest">
                    {t(action.key, action.label)}
                  </p>
                  <p className="text-2xl font-black theme-heading mt-1">{action.value}</p>
                  <p className="text-[0.625rem] font-bold theme-muted uppercase tracking-widest mt-1">
                    {t(action.detailKey, action.detail)}
                  </p>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
