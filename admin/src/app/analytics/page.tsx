'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
} from 'recharts';
import {
  AlertCircle,
  TrendingUp,
  MapPin,
  ArrowRight,
  Users,
  Truck,
  User,
  Calendar,
  RefreshCw,
  type LucideIcon,
} from 'lucide-react';
import { useToast } from '@/lib/toast';
import { useT, useI18n } from '@/lib/i18n';
import {
  getTopOriginCities,
  getTopDestinations,
  getUserTypeDistribution,
  getDailyTripCount,
  getTotalUserCount,
  CityCount,
  UserTypeCount,
  DailyTripCount,
} from '@/app/actions/analytics-actions';
import Loading from '@/app/loading';

const DATE_WINDOWS = [7, 30, 90, 180];

const TYPE_COLORS: Record<string, string> = {
  individual: '#3b82f6',
  traveler: '#10b981',
  driver: '#f97316',
};

const TYPE_ICONS: Record<string, LucideIcon> = {
  individual: User,
  traveler: Users,
  driver: Truck,
};

function resultError(error: unknown) {
  return error instanceof Error ? error.message : String(error || 'Analytics failed');
}

export default function AnalyticsPage() {
  const { toast } = useToast();
  const t = useT();
  const { language } = useI18n();
  const [days, setDays] = useState(30);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const requestIdRef = useRef(0);

  const [totalUsers, setTotalUsers] = useState(0);
  const [origins, setOrigins] = useState<CityCount[]>([]);
  const [destinations, setDestinations] = useState<CityCount[]>([]);
  const [userTypes, setUserTypes] = useState<UserTypeCount[]>([]);
  const [daily, setDaily] = useState<DailyTripCount[]>([]);

  const fetchAll = useCallback(async () => {
    const requestId = requestIdRef.current + 1;
    requestIdRef.current = requestId;
    setLoading(true);
    setError(null);

    try {
      const [originResult, destinationResult, userTypeResult, dailyResult, totalUserResult] = await Promise.all([
        getTopOriginCities(days, 10),
        getTopDestinations(days, 10),
        getUserTypeDistribution(),
        getDailyTripCount(days),
        getTotalUserCount(),
      ]);

      if (requestId !== requestIdRef.current) return;

      if (originResult.success) {
        setOrigins(originResult.data || []);
      } else {
        setOrigins([]);
        toast(t('analytics.error.origins', 'Failed to load origin cities.'), 'error');
      }

      if (destinationResult.success) {
        setDestinations(destinationResult.data || []);
      } else {
        setDestinations([]);
        toast(t('analytics.error.destinations', 'Failed to load destinations.'), 'error');
      }

      if (userTypeResult.success) {
        setUserTypes(userTypeResult.data || []);
      } else {
        setUserTypes([]);
        toast(t('analytics.error.userTypes', 'Failed to load user mix.'), 'error');
      }

      if (dailyResult.success) {
        setDaily(dailyResult.data || []);
      } else {
        setDaily([]);
        toast(t('analytics.error.daily', 'Failed to load daily trip count.'), 'error');
      }

      if (totalUserResult.success) {
        setTotalUsers(totalUserResult.data || 0);
      } else {
        const fallbackTotal = (userTypeResult.data || []).reduce((sum, u) => sum + (u.total || 0), 0);
        setTotalUsers(fallbackTotal);
        toast(t('analytics.error.totalUsers', 'Failed to load total users.'), 'error');
      }
    } catch (e) {
      if (requestId !== requestIdRef.current) return;
      console.error('[Analytics] load failed:', e);
      const message = t('analytics.error.load', 'Analytics could not be loaded. Please try again.');
      setError(message);
      toast(`${message} ${resultError(e)}`, 'error');
    } finally {
      if (requestId === requestIdRef.current) {
        setLoading(false);
      }
    }
  }, [days, t, toast]);

  useEffect(() => {
    void fetchAll();
  }, [fetchAll]);

  const totalTrips = daily.reduce((sum, d) => sum + (d.trip_count || 0), 0);
  const cityLabel = (c: CityCount) => (language === 'ar'
    ? (c.city_ar || c.city_en || '-')
    : (c.city_en || c.city_ar || '-'));
  const formatNumber = (value: number) => value.toLocaleString(language === 'ar' ? 'ar' : 'en');
  const userTypeLabel = (type: string) => t(`analytics.userTypes.${type}`, type);
  const userTypeChartData = userTypes.map((u) => ({ ...u, label: userTypeLabel(u.user_type) }));
  const isRtl = language === 'ar';

  if (loading) return <Loading />;

  if (error) {
    return (
      <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 text-center">
        <div className="h-12 w-12 rounded-full bg-red-500/10 flex items-center justify-center">
          <AlertCircle className="h-6 w-6 text-red-600" />
        </div>
        <p className="theme-heading font-bold">{error}</p>
        <button
          type="button"
          onClick={() => void fetchAll()}
          className="px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2"
          style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}
        >
          <RefreshCw className="h-4 w-4" />
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight flex items-center gap-3">
            <TrendingUp className="h-7 w-7 text-orange-500" />
            {t('analytics.title', 'Operational Analytics')}
          </h1>
          <p className="theme-muted text-sm mt-1">
            {t('analytics.subtitle', 'Most active cities, common destinations, user mix, and trip volume.')}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {DATE_WINDOWS.map((windowDays) => (
            <button
              type="button"
              key={windowDays}
              aria-pressed={days === windowDays}
              onClick={() => setDays(windowDays)}
              className={`px-3 py-1.5 rounded-xl text-xs font-black uppercase tracking-widest border transition ${
                days === windowDays
                  ? 'bg-orange-600 text-white border-orange-600 shadow-sm'
                  : 'theme-bg-secondary theme-muted border-[var(--surface-border)] hover:theme-heading'
              }`}
            >
              {windowDays}
              {t('analytics.range.daysSuffix', 'd')}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Stat icon={Users} label={t('analytics.totalUsers', 'Total users')} value={formatNumber(totalUsers)} color="text-blue-600" bg="bg-blue-500/10" />
        <Stat icon={Calendar} label={t('analytics.totalTrips', 'Trips in period')} value={formatNumber(totalTrips)} color="text-orange-600" bg="bg-orange-500/10" />
        <Stat icon={MapPin} label={t('analytics.uniqueOrigins', 'Origin cities')} value={formatNumber(origins.length)} color="text-green-600" bg="bg-green-500/10" />
        <Stat icon={ArrowRight} label={t('analytics.uniqueDest', 'Destination cities')} value={formatNumber(destinations.length)} color="text-purple-600" bg="bg-purple-500/10" />
      </div>

      <div className="grid lg:grid-cols-3 gap-6">
        <div className="theme-card p-6 rounded-2xl border border-[var(--surface-border)] shadow-sm lg:col-span-2">
          <h2 className="font-black theme-heading mb-4 flex items-center gap-2">
            <Calendar className="h-5 w-5 text-orange-500" />
            {t('analytics.daily.title', 'Daily trip count')}
          </h2>
          {daily.length === 0 ? (
            <EmptyState text={t('analytics.daily.empty', 'No trips in the selected window.')} />
          ) : (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={daily}>
                <defs>
                  <linearGradient id="tripGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#f97316" stopOpacity={0.4} />
                    <stop offset="100%" stopColor="#f97316" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
                <XAxis dataKey="day" tickFormatter={(s) => String(s).slice(5)} fontSize={11} />
                <YAxis allowDecimals={false} fontSize={11} />
                <RechartsTooltip />
                <Area type="monotone" dataKey="trip_count" stroke="#f97316" strokeWidth={2} fill="url(#tripGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="theme-card p-6 rounded-2xl border border-[var(--surface-border)] shadow-sm">
          <h2 className="font-black theme-heading mb-4 flex items-center gap-2">
            <Users className="h-5 w-5 text-blue-500" />
            {t('analytics.userTypes.title', 'User mix')}
          </h2>
          {totalUsers === 0 ? (
            <EmptyState text={t('analytics.userTypes.empty', 'No user data.')} />
          ) : (
            <>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie
                    data={userTypeChartData}
                    dataKey="total"
                    nameKey="label"
                    innerRadius={50}
                    outerRadius={80}
                    paddingAngle={2}
                  >
                    {userTypeChartData.map((u) => (
                      <Cell key={u.user_type} fill={TYPE_COLORS[u.user_type] || '#888'} />
                    ))}
                  </Pie>
                  <RechartsTooltip />
                </PieChart>
              </ResponsiveContainer>
              <div className="space-y-2 mt-4">
                {userTypeChartData.map((u) => {
                  const Icon = TYPE_ICONS[u.user_type] || User;
                  const pct = totalUsers ? Math.round((u.total / totalUsers) * 100) : 0;
                  return (
                    <div key={u.user_type} className="flex items-center justify-between gap-3 p-2 rounded-lg theme-bg-secondary">
                      <div className="flex items-center gap-2 min-w-0">
                        <div className="w-2 h-2 rounded-full flex-shrink-0" style={{ background: TYPE_COLORS[u.user_type] || '#888' }} />
                        <Icon className="h-4 w-4 theme-muted flex-shrink-0" />
                        <span className="text-sm font-bold theme-heading truncate">{u.label}</span>
                      </div>
                      <span className="text-xs font-black theme-heading whitespace-nowrap">
                        {formatNumber(u.total)} / {pct}%
                      </span>
                    </div>
                  );
                })}
              </div>
            </>
          )}
        </div>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        <CityChart
          title={t('analytics.origins.title', 'Top origin cities')}
          data={origins}
          cityLabel={cityLabel}
          color="#f97316"
          emptyText={t('analytics.noData', 'No data')}
          rtl={isRtl}
        />
        <CityChart
          title={t('analytics.destinations.title', 'Top destinations')}
          data={destinations}
          cityLabel={cityLabel}
          color="#3b82f6"
          emptyText={t('analytics.noData', 'No data')}
          rtl={isRtl}
        />
      </div>
    </div>
  );
}

function Stat({
  icon: Icon,
  label,
  value,
  color,
  bg,
}: {
  icon: LucideIcon;
  label: string;
  value: string;
  color: string;
  bg: string;
}) {
  return (
    <div className="theme-card rounded-2xl p-5 border border-[var(--surface-border)] shadow-sm flex items-center gap-3 min-w-0">
      <div className={`h-12 w-12 rounded-xl flex items-center justify-center flex-shrink-0 ${bg}`}>
        <Icon className={`h-6 w-6 ${color}`} />
      </div>
      <div className="min-w-0">
        <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest">{label}</p>
        <p className="text-2xl font-black theme-heading truncate">{value}</p>
      </div>
    </div>
  );
}

function EmptyState({ text }: { text: string }) {
  return (
    <div className="py-16 text-center">
      <p className="theme-muted text-sm italic opacity-60">{text}</p>
    </div>
  );
}

function CityChart({
  title,
  data,
  cityLabel,
  color,
  emptyText,
  rtl,
}: {
  title: string;
  data: CityCount[];
  cityLabel: (c: CityCount) => string;
  color: string;
  emptyText: string;
  rtl: boolean;
}) {
  return (
    <div className="theme-card p-6 rounded-2xl border border-[var(--surface-border)] shadow-sm">
      <h2 className="font-black theme-heading mb-4 flex items-center gap-2">
        <MapPin className="h-5 w-5" style={{ color }} />
        {title}
      </h2>
      {data.length === 0 ? (
        <EmptyState text={emptyText} />
      ) : (
        <ResponsiveContainer width="100%" height={350}>
          <BarChart
            data={data.map((d) => ({ city: cityLabel(d), trips: d.total_trips }))}
            layout="vertical"
            margin={{ left: rtl ? 16 : 60, right: rtl ? 60 : 16 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.05)" />
            <XAxis type="number" allowDecimals={false} fontSize={11} />
            <YAxis dataKey="city" type="category" width={100} fontSize={11} orientation={rtl ? 'right' : 'left'} />
            <RechartsTooltip />
            <Bar dataKey="trips" fill={color} radius={[0, 6, 6, 0]} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
