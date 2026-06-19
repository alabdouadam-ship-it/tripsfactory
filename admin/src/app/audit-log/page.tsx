'use client';

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { AdminAuditLog } from '@/lib/types';
import {
  Shield,
  Search,
  FileDown,
  Eye,
  Filter,
  User,
  Table as TableIcon,
  Activity,
  X,
  Calendar,
  AlertTriangle,
  RefreshCw,
} from 'lucide-react';
import { exportToCSV } from '@/lib/utils';
import { useI18n, useT } from '@/lib/i18n';
import Loading from '@/app/loading';
import { AuditDetails } from '@/components/AuditDetails';

const DEFAULT_PAGE_SIZE = 50;
const EXPORT_LIMIT = 2000;
const PAGE_SIZE_OPTIONS = [25, 50, 100, 200];

function labelFromValue(value: string | null | undefined) {
  if (!value) return '';
  return value.replace(/_/g, ' ');
}

function actionClass(action: string) {
  const normalized = action.toLowerCase();
  if (/(delete|reject|block|cancel|ignore|dismiss|freeze)/.test(normalized)) {
    return 'bg-red-100 text-red-700';
  }
  if (/(approve|resolve|reopen|create|send)/.test(normalized)) {
    return 'bg-green-100 text-green-700';
  }
  return 'bg-orange-100 text-orange-700';
}

function actionIcon(action: string) {
  const normalized = action.toLowerCase();
  if (/(approve|accept|enable|activate|resolve)/.test(normalized)) return '✅';
  if (/(delete|remove)/.test(normalized)) return '🗑️';
  if (/(reject|block|cancel|freeze|disable)/.test(normalized)) return '❌';
  if (/(update|edit|modify|change)/.test(normalized)) return '🔄';
  if (/(create|add|send)/.test(normalized)) return '➕';
  if (/(flag|report)/.test(normalized)) return '🚩';
  if (/(reopen|restore)/.test(normalized)) return '🔓';
  return '📝';
}

function targetIcon(targetType: string | null) {
  if (!targetType) return '📄';
  const normalized = targetType.toLowerCase();
  if (/(user|profile|admin)/.test(normalized)) return '👤';
  if (/(shipment|package)/.test(normalized)) return '📦';
  if (/(trip|journey)/.test(normalized)) return '🚚';
  if (/(booking|reservation)/.test(normalized)) return '🛒';
  if (/(offer|bid)/.test(normalized)) return '🤝';
  if (/(company|merchant)/.test(normalized)) return '🏢';
  if (/(driver|traveler)/.test(normalized)) return '🚗';
  if (/(notification|message)/.test(normalized)) return '📧';
  return '📄';
}

function formatRelativeTime(dateStr: string, t: any) {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return t('audit.time.justNow', 'Just now');
  if (diffMins < 60) return t('audit.time.minsAgo', '{n}m ago').replace('{n}', String(diffMins));
  if (diffHours < 24) return t('audit.time.hoursAgo', '{n}h ago').replace('{n}', String(diffHours));
  if (diffDays < 7) return t('audit.time.daysAgo', '{n}d ago').replace('{n}', String(diffDays));
  return date.toLocaleDateString();
}

function matchesSearch(log: AdminAuditLog, search: string) {
  if (!search) return true;
  const haystack = [
    log.action,
    log.target_type,
    log.target_id,
    log.admin?.full_name,
    log.details ? JSON.stringify(log.details) : '',
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();
  return haystack.includes(search.toLowerCase());
}

export default function AuditLogPage() {
  const { toast } = useToast();
  const t = useT();
  const { language, dir } = useI18n();
  const locale = language === 'ar' ? 'ar' : 'en-US';
  const searchParams = useSearchParams();
  const deepLinkTargetId =
    searchParams.get('target_id') || searchParams.get('entity_id') || '';
  const deepLinkTargetType =
    searchParams.get('target_type') || searchParams.get('entity_name') || '';

  const [logs, setLogs] = useState<AdminAuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [page, setPage] = useState(0);
  const [pageSize, setPageSize] = useState(DEFAULT_PAGE_SIZE);
  const [selectedLog, setSelectedLog] = useState<AdminAuditLog | null>(null);

  const [search, setSearch] = useState('');
  const [filterTarget, setFilterTarget] = useState('all');
  const [filterAction, setFilterAction] = useState('all');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [quickFilter, setQuickFilter] = useState<string>('all');

  useEffect(() => {
    fetchLogs();
  }, [dateFrom, dateTo]);

  function applyQuickFilter(filter: string) {
    setQuickFilter(filter);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    
    switch (filter) {
      case 'today':
        setDateFrom(today.toISOString().split('T')[0]);
        setDateTo('');
        break;
      case 'week':
        const weekAgo = new Date(today);
        weekAgo.setDate(weekAgo.getDate() - 7);
        setDateFrom(weekAgo.toISOString().split('T')[0]);
        setDateTo('');
        break;
      case 'month':
        const monthAgo = new Date(today);
        monthAgo.setMonth(monthAgo.getMonth() - 1);
        setDateFrom(monthAgo.toISOString().split('T')[0]);
        setDateTo('');
        break;
      case 'critical':
        setFilterAction('all');
        setDateFrom('');
        setDateTo('');
        break;
      case 'all':
      default:
        setDateFrom('');
        setDateTo('');
        setFilterAction('all');
        setFilterTarget('all');
        break;
    }
    setPage(0);
  }

  function clearAllFilters() {
    setSearch('');
    setFilterTarget('all');
    setFilterAction('all');
    setDateFrom('');
    setDateTo('');
    setQuickFilter('all');
    setPage(0);
  }

  async function fetchLogs() {
    setLoading(true);
    setLoadError('');
    try {
      let query = supabase
        .from('admin_audit_log')
        .select('id, admin_id, action, target_type, target_id, details, created_at');

      if (dateFrom) query = query.gte('created_at', `${dateFrom}T00:00:00.000Z`);
      if (dateTo) query = query.lte('created_at', `${dateTo}T23:59:59.999Z`);

      const { data, error } = await query
        .order('created_at', { ascending: false })
        .limit(EXPORT_LIMIT);

      if (error) throw error;

      const auditRows = ((data || []) as unknown as AdminAuditLog[]);
      const adminIds = Array.from(new Set(auditRows.map(row => row.admin_id).filter(Boolean) as string[]));

      if (adminIds.length > 0) {
        const { data: profiles, error: profilesError } = await supabase
          .from('profiles')
          .select('id, full_name')
          .in('id', adminIds);

        if (profilesError) {
          console.warn('Error fetching audit admin profiles:', profilesError);
          toast(t('audit.toast.profileLoadFailed', 'Audit logs loaded, but admin names could not be loaded.'), 'error');
        } else {
          const profileById = new Map((profiles || []).map((profile: any) => [profile.id, profile]));
          auditRows.forEach(row => {
            row.admin = row.admin_id ? profileById.get(row.admin_id) ?? null : null;
          });
        }
      }

      setLogs(auditRows);
      setPage(0);
    } catch (error: any) {
      const message = error?.message || t('audit.errorLoad', 'Failed to load audit logs.');
      console.error('Error fetching audit logs:', error);
      setLoadError(message);
      toast(t('audit.toast.loadFailed', 'Failed to load audit logs'), 'error');
    } finally {
      setLoading(false);
    }
  }

  const targetOptions = useMemo(() => {
    return Array.from(new Set(logs.map(log => log.target_type).filter(Boolean) as string[])).sort();
  }, [logs]);

  const actionOptions = useMemo(() => {
    return Array.from(new Set(logs.map(log => log.action).filter(Boolean))).sort();
  }, [logs]);

  const filteredLogs = useMemo(() => {
    const normalizedSearch = search.trim();
    return logs.filter(log => {
      if (filterTarget !== 'all' && log.target_type !== filterTarget) return false;
      if (filterAction !== 'all' && log.action !== filterAction) return false;
      if (deepLinkTargetId && log.target_id !== deepLinkTargetId) return false;
      if (deepLinkTargetType && log.target_type !== deepLinkTargetType) return false;
      return matchesSearch(log, normalizedSearch);
    });
  }, [logs, search, filterTarget, filterAction, deepLinkTargetId, deepLinkTargetType]);

  const totalPages = Math.max(1, Math.ceil(filteredLogs.length / pageSize));
  const visibleLogs = filteredLogs.slice(page * pageSize, page * pageSize + pageSize);
  const isLimited = logs.length >= EXPORT_LIMIT;

  const activeFilterCount = [
    search.trim() !== '',
    filterTarget !== 'all',
    filterAction !== 'all',
    dateFrom !== '',
    dateTo !== '',
  ].filter(Boolean).length;

  const uniqueAdmins = useMemo(() => {
    return new Set(logs.map(log => log.admin_id).filter(Boolean)).size;
  }, [logs]);

  const lastActionTime = useMemo(() => {
    if (logs.length === 0) return null;
    return logs[0]?.created_at;
  }, [logs]);

  // Keyboard shortcuts
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (selectedLog) {
        if (e.key === 'Escape') {
          setSelectedLog(null);
        }
        return;
      }

      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLSelectElement) {
        return;
      }

      if (e.key === 'ArrowLeft' && page > 0) {
        e.preventDefault();
        setPage(p => p - 1);
      } else if (e.key === 'ArrowRight' && page < totalPages - 1) {
        e.preventDefault();
        setPage(p => p + 1);
      }
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [page, totalPages, selectedLog]);

  function resetPage() {
    setPage(0);
  }

  async function handleExport() {
    if (filteredLogs.length === 0) {
      toast(t('audit.toast.noExportRows', 'No audit logs match the current filters.'), 'error');
      return;
    }

    toast(t('common.exporting', 'Exporting...'), 'success');
    const exportData = filteredLogs.map(l => ({
      id: l.id,
      timestamp: l.created_at,
      admin: l.admin?.full_name || t('audit.systemAdmin', 'System/Admin'),
      action: l.action,
      target_type: l.target_type || '',
      target_id: l.target_id || '',
      details: l.details ? JSON.stringify(l.details) : '',
    }));

    exportToCSV(
      exportData,
      `admin_audit_log_${new Date().toISOString().slice(0, 10)}`,
      (m) => toast(m, 'error'),
    );
  }

  if (loading && logs.length === 0 && !loadError) return <Loading />;

  const searchPadding = dir === 'rtl' ? 'pr-10 pl-3' : 'pl-10 pr-3';
  const searchIconSide = dir === 'rtl' ? 'right-3' : 'left-3';

  return (
    <div className="space-y-6">
      {/* Enhanced Header with Quick Stats */}
      <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div className="flex items-center gap-3">
          <div className="h-12 w-12 rounded-xl bg-gray-900 flex items-center justify-center text-white shadow-lg">
            <Shield className="h-6 w-6" />
          </div>
          <div>
            <h1 className="text-3xl font-black theme-heading tracking-tight">
              {t('audit.title', 'Audit Log')}
            </h1>
            <p className="text-[0.6875rem] theme-muted font-bold">
              {t('audit.subtitle', 'Track explicit admin actions and changes')}
            </p>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="theme-card px-4 py-2 rounded-xl border border-[var(--surface-border)] shadow-sm">
            <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest opacity-60">
              {t('audit.stats.totalEntries', 'Total Entries')}
            </p>
            <p className="text-xl font-black theme-heading">{logs.length.toLocaleString()}</p>
          </div>
          <div className="theme-card px-4 py-2 rounded-xl border border-[var(--surface-border)] shadow-sm">
            <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest opacity-60">
              {t('audit.stats.admins', 'Admins')}
            </p>
            <p className="text-xl font-black theme-heading">{uniqueAdmins}</p>
          </div>
          <div className="theme-card px-4 py-2 rounded-xl border border-[var(--surface-border)] shadow-sm">
            <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest opacity-60">
              {t('audit.stats.lastAction', 'Last Action')}
            </p>
            <p className="text-sm font-black theme-heading">
              {lastActionTime ? formatRelativeTime(lastActionTime, t) : t('common.na', 'N/A')}
            </p>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-wrap items-center gap-2">
        <button
          onClick={fetchLogs}
          disabled={loading}
          className="flex items-center justify-center gap-2 theme-bg-secondary border border-[var(--surface-border)] theme-heading px-4 py-2 rounded-lg hover:theme-card transition shadow-sm font-black text-[0.625rem] uppercase tracking-widest disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          {t('common.refresh', 'Refresh')}
        </button>
        <button
          onClick={handleExport}
          className="flex items-center justify-center gap-2 bg-green-500/10 border border-green-500/20 text-green-600 px-4 py-2 rounded-lg hover:bg-green-500/20 transition shadow-sm font-black text-[0.625rem] uppercase tracking-widest"
        >
          <FileDown className="h-4 w-4" /> {t('common.exportCsv', 'Export CSV')}
        </button>
      </div>

      {/* Smart Filter Bar with Presets */}
      <div className="theme-bg-secondary p-4 rounded-xl border border-[var(--surface-border)] shadow-sm space-y-4">
        {/* Quick Filter Presets */}
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60 mr-2">
            {t('audit.quickFilters', 'Quick Filters')}:
          </span>
          {[
            { id: 'all', label: t('audit.filter.all', 'All'), icon: Activity },
            { id: 'today', label: t('audit.filter.today', 'Today'), icon: Calendar },
            { id: 'week', label: t('audit.filter.thisWeek', 'This Week'), icon: Calendar },
            { id: 'month', label: t('audit.filter.thisMonth', 'This Month'), icon: Calendar },
          ].map((preset) => (
            <button
              key={preset.id}
              onClick={() => applyQuickFilter(preset.id)}
              className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all ${
                quickFilter === preset.id
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
              }`}
            >
              <preset.icon className="h-3.5 w-3.5" />
              {preset.label}
            </button>
          ))}
        </div>

        {/* Main Filters */}
        <div className="flex flex-wrap items-center gap-4">
          <div className="relative flex-1 min-w-[220px]">
            <Search className={`absolute ${searchIconSide} top-1/2 h-4 w-4 -translate-y-1/2 theme-muted opacity-50`} />
            <input
              type="text"
              placeholder={t('audit.search.placeholder', 'Search admin, action, target, or details...')}
              className={`w-full theme-bg-secondary rounded-lg border border-[var(--surface-border)] ${searchPadding} py-2 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all`}
              value={search}
              onChange={e => {
                setSearch(e.target.value);
                resetPage();
              }}
            />
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <Calendar className="h-4 w-4 theme-muted opacity-50" />
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-1.5 text-xs theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all"
              aria-label={t('audit.dateFrom', 'Date from')}
            />
            <span className="theme-muted opacity-30">-</span>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-1.5 text-xs theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all"
              aria-label={t('audit.dateTo', 'Date to')}
            />
          </div>

          <select
            value={filterTarget}
            onChange={e => {
              setFilterTarget(e.target.value);
              resetPage();
            }}
            className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-1.5 text-[0.6875rem] font-black theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none capitalize transition-all"
          >
            <option value="all">{t('audit.filter.allTargets', 'All Targets')}</option>
            {targetOptions.map(target => (
              <option key={target} value={target}>{labelFromValue(target)}</option>
            ))}
          </select>

          <select
            value={filterAction}
            onChange={e => {
              setFilterAction(e.target.value);
              resetPage();
            }}
            className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-1.5 text-[0.6875rem] font-black theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all"
          >
            <option value="all">{t('audit.filter.allActions', 'All Actions')}</option>
            {actionOptions.map(action => (
              <option key={action} value={action}>{labelFromValue(action)}</option>
            ))}
          </select>
        </div>

        {/* Active Filters & Clear */}
        {activeFilterCount > 0 && (
          <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-[var(--surface-border)]">
            <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
              {t('audit.activeFilters', 'Active Filters')} ({activeFilterCount}):
            </span>
            {search.trim() && (
              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-blue-500/10 text-blue-600 text-[0.625rem] font-bold border border-blue-500/20">
                Search: "{search.slice(0, 20)}"
                <button onClick={() => setSearch('')} className="hover:text-blue-700">
                  <X className="h-3 w-3" />
                </button>
              </span>
            )}
            {filterTarget !== 'all' && (
              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-blue-500/10 text-blue-600 text-[0.625rem] font-bold border border-blue-500/20">
                {labelFromValue(filterTarget)}
                <button onClick={() => setFilterTarget('all')} className="hover:text-blue-700">
                  <X className="h-3 w-3" />
                </button>
              </span>
            )}
            {filterAction !== 'all' && (
              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-blue-500/10 text-blue-600 text-[0.625rem] font-bold border border-blue-500/20">
                {labelFromValue(filterAction)}
                <button onClick={() => setFilterAction('all')} className="hover:text-blue-700">
                  <X className="h-3 w-3" />
                </button>
              </span>
            )}
            {dateFrom && (
              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-blue-500/10 text-blue-600 text-[0.625rem] font-bold border border-blue-500/20">
                From: {dateFrom}
                <button onClick={() => setDateFrom('')} className="hover:text-blue-700">
                  <X className="h-3 w-3" />
                </button>
              </span>
            )}
            {dateTo && (
              <span className="inline-flex items-center gap-1 px-2 py-1 rounded-lg bg-blue-500/10 text-blue-600 text-[0.625rem] font-bold border border-blue-500/20">
                To: {dateTo}
                <button onClick={() => setDateTo('')} className="hover:text-blue-700">
                  <X className="h-3 w-3" />
                </button>
              </span>
            )}
            <button
              onClick={clearAllFilters}
              className="inline-flex items-center gap-1 px-3 py-1 rounded-lg bg-red-500/10 text-red-600 text-[0.625rem] font-black uppercase tracking-widest border border-red-500/20 hover:bg-red-500/20 transition"
            >
              <X className="h-3 w-3" /> {t('audit.clearAll', 'Clear All')}
            </button>
          </div>
        )}

        {/* Results Count */}
        <div className="flex flex-col gap-1 text-[0.625rem] theme-muted font-bold uppercase tracking-widest opacity-70 sm:flex-row sm:items-center sm:justify-between pt-2 border-t border-[var(--surface-border)]">
          <span>
            {t('audit.showingResults', 'Showing {count} of {total} entries')
              .replace('{count}', String(filteredLogs.length))
              .replace('{total}', String(logs.length))}
          </span>
          {isLimited && (
            <span className="text-amber-600">
              {t('audit.exportLimitReached', 'Showing latest {limit} rows').replace('{limit}', String(EXPORT_LIMIT))}
            </span>
          )}
        </div>
      </div>

      {loadError && (
        <div className="rounded-xl border border-red-500/20 bg-red-500/10 p-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-3">
            <AlertTriangle className="h-5 w-5 text-red-600 mt-0.5" />
            <div>
              <p className="text-sm font-black text-red-700">{t('audit.errorTitle', 'Audit logs could not be loaded')}</p>
              <p className="text-xs text-red-700/80 mt-1">{loadError}</p>
            </div>
          </div>
          <button
            onClick={fetchLogs}
            className="inline-flex items-center justify-center gap-2 rounded-lg bg-red-600 px-3 py-2 text-[0.625rem] font-black uppercase tracking-widest text-white"
          >
            <RefreshCw className="h-3.5 w-3.5" /> {t('common.retry', 'Retry')}
          </button>
        </div>
      )}

      {/* Enhanced Table with Icons */}
      <div className="bg-[var(--surface)] rounded-xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-start">
            <thead className="theme-bg-secondary border-b border-[var(--surface-border)]">
              <tr>
                <th className="px-6 py-4 text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60 text-start">
                  {t('audit.table.time', 'Time')}
                </th>
                <th className="px-6 py-4 text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60 text-start">
                  {t('audit.table.admin', 'Admin')}
                </th>
                <th className="px-6 py-4 text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60 text-start">
                  {t('audit.table.action', 'Action')}
                </th>
                <th className="px-6 py-4 text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60 text-start">
                  {t('audit.table.target', 'Target')}
                </th>
                <th className="px-6 py-4 text-end"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--surface-border)] opacity-90">
              {visibleLogs.map((log) => {
                const timeStr = new Date(log.created_at).toLocaleTimeString(locale, { 
                  hour: '2-digit', 
                  minute: '2-digit' 
                });
                const relativeTime = formatRelativeTime(log.created_at, t);

                return (
                  <tr key={log.id} className="hover:theme-bg-secondary transition-colors group">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex flex-col gap-0.5">
                        <span className="text-sm font-black theme-heading">
                          {timeStr}
                        </span>
                        <span className="text-[0.625rem] theme-muted font-bold opacity-60">
                          {relativeTime}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <div className="h-7 w-7 rounded-lg theme-bg-secondary flex items-center justify-center theme-muted border border-[var(--surface-border)]">
                          <User className="h-3.5 w-3.5" />
                        </div>
                        <div className="flex flex-col gap-0.5">
                          <span className="text-xs font-black theme-heading whitespace-nowrap">
                            {log.admin?.full_name || t('audit.systemAdmin', 'System')}
                          </span>
                          <span className="text-[0.625rem] theme-muted font-mono opacity-60">
                            @{(log.admin?.full_name || 'system').toLowerCase().replace(/\s+/g, '_')}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <span className="text-base">{actionIcon(log.action)}</span>
                        <div className="flex flex-col gap-0.5">
                          <span className={`px-2 py-0.5 rounded text-[0.625rem] font-black uppercase tracking-tighter whitespace-nowrap ${actionClass(log.action)}`}>
                            {labelFromValue(log.action)}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <span className="text-base">{targetIcon(log.target_type)}</span>
                        <div className="flex flex-col gap-0.5">
                          <p className="text-xs font-black theme-heading capitalize">
                            {labelFromValue(log.target_type) || t('common.na', 'N/A')}
                          </p>
                          <p className="text-[0.625rem] theme-muted font-mono truncate max-w-[120px] opacity-60" title={log.target_id || undefined}>
                            {log.target_id?.slice(0, 8) || t('common.na', 'N/A')}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-end">
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="inline-flex items-center gap-1.5 text-[0.625rem] font-black uppercase theme-muted hover:theme-heading theme-bg-secondary hover:shadow-sm border border-[var(--surface-border)] px-3 py-1.5 rounded-lg transition-all"
                      >
                        <Eye className="h-3.5 w-3.5" /> {t('common.inspect', 'Inspect')}
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {visibleLogs.length === 0 && !loading && !loadError && (
          <div className="text-center py-20 bg-[var(--surface)]">
            <TableIcon className="h-12 w-12 theme-muted mx-auto mb-3 opacity-20" />
            <p className="theme-muted text-[0.625rem] font-black uppercase tracking-widest opacity-60">
              {t('audit.empty', 'No audit log entries found.')}
            </p>
          </div>
        )}
      </div>

      {/* Improved Pagination */}
      {filteredLogs.length > 0 && (
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between py-4 theme-bg-secondary px-6 rounded-xl border border-[var(--surface-border)]">
          {/* Page Size Selector */}
          <div className="flex items-center gap-2">
            <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
              {t('audit.rowsPerPage', 'Rows per page')}:
            </span>
            {PAGE_SIZE_OPTIONS.map((size) => (
              <button
                key={size}
                onClick={() => {
                  setPageSize(size);
                  setPage(0);
                }}
                className={`px-3 py-1.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all ${
                  pageSize === size
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                }`}
              >
                {size}
              </button>
            ))}
          </div>

          {/* Pagination Controls */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage(0)}
              disabled={page === 0 || loading}
              className="flex items-center gap-1 px-3 py-2 rounded-lg border border-[var(--surface-border)] text-[0.625rem] font-black theme-muted uppercase tracking-widest hover:theme-heading hover:theme-bg-secondary transition-all disabled:opacity-30 disabled:cursor-not-allowed shadow-sm theme-bg-secondary"
              title={t('audit.firstPage', 'First page')}
            >
              ⏮️
            </button>
            <button
              onClick={() => setPage(p => Math.max(0, p - 1))}
              disabled={page === 0 || loading}
              className="flex items-center gap-1 px-3 py-2 rounded-lg border border-[var(--surface-border)] text-[0.625rem] font-black theme-muted uppercase tracking-widest hover:theme-heading hover:theme-bg-secondary transition-all disabled:opacity-30 disabled:cursor-not-allowed shadow-sm theme-bg-secondary"
            >
              ◀️ {t('audit.previous', 'Prev')}
            </button>
            
            <div className="flex items-center gap-2 px-4">
              <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
                {t('audit.page', 'Page')}
              </span>
              <select
                value={page}
                onChange={(e) => setPage(Number(e.target.value))}
                className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-2 py-1 text-xs font-black theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none"
              >
                {Array.from({ length: totalPages }, (_, i) => (
                  <option key={i} value={i}>
                    {i + 1}
                  </option>
                ))}
              </select>
              <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
                {t('audit.of', 'of')} {totalPages}
              </span>
            </div>

            <button
              onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
              disabled={page >= totalPages - 1 || loading}
              className="flex items-center gap-1 px-3 py-2 rounded-lg border border-[var(--surface-border)] text-[0.625rem] font-black theme-muted uppercase tracking-widest hover:theme-heading hover:theme-bg-secondary transition-all disabled:opacity-30 disabled:cursor-not-allowed shadow-sm theme-bg-secondary"
            >
              {t('audit.next', 'Next')} ▶️
            </button>
            <button
              onClick={() => setPage(totalPages - 1)}
              disabled={page >= totalPages - 1 || loading}
              className="flex items-center gap-1 px-3 py-2 rounded-lg border border-[var(--surface-border)] text-[0.625rem] font-black theme-muted uppercase tracking-widest hover:theme-heading hover:theme-bg-secondary transition-all disabled:opacity-30 disabled:cursor-not-allowed shadow-sm theme-bg-secondary"
              title={t('audit.lastPage', 'Last page')}
            >
              ⏭️
            </button>
          </div>

          {/* Row Range Display */}
          <div className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
            {t('audit.showingRange', 'Showing {from}-{to} of {total}')
              .replace('{from}', String(page * pageSize + 1))
              .replace('{to}', String(Math.min((page + 1) * pageSize, filteredLogs.length)))
              .replace('{total}', String(filteredLogs.length))}
          </div>
        </div>
      )}

      {/* Enhanced Modal with Better UX */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setSelectedLog(null)}>
          <div className="theme-card rounded-3xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col border border-[var(--surface-border)]" onClick={e => e.stopPropagation()}>
            <div className="p-6 border-b border-[var(--surface-border)] flex items-center justify-between theme-bg-secondary">
              <div className="flex items-center gap-3">
                <div className={`h-10 w-10 rounded-xl flex items-center justify-center text-white shadow-lg ${
                  actionClass(selectedLog.action).includes('red') ? 'bg-red-500' :
                  actionClass(selectedLog.action).includes('green') ? 'bg-green-500' : 'bg-orange-500'
                }`}>
                  <span className="text-xl">{actionIcon(selectedLog.action)}</span>
                </div>
                <div>
                  <h2 className="text-lg font-black theme-heading flex items-center gap-2">
                    {labelFromValue(selectedLog.action) || t('common.na', 'N/A')}
                  </h2>
                  <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">
                    {targetIcon(selectedLog.target_type)} {labelFromValue(selectedLog.target_type) || t('common.na', 'N/A')} • {selectedLog.target_id?.slice(0, 8) || t('common.na', 'N/A')}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                className="p-2 hover:theme-bg-secondary rounded-full transition-colors theme-muted hover:theme-heading"
                aria-label={t('common.cancel', 'Cancel')}
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="p-6 overflow-y-auto custom-scrollbar flex-1">
              <AuditDetails log={selectedLog} />
              
              {/* Quick Actions */}
              <div className="mt-6 flex flex-wrap gap-2">
                <button
                  onClick={() => {
                    navigator.clipboard.writeText(selectedLog.id);
                    toast(t('audit.toast.idCopied', 'Entry ID copied'), 'success');
                  }}
                  className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg theme-bg-secondary border border-[var(--surface-border)] text-[0.625rem] font-black uppercase tracking-widest theme-muted hover:theme-heading transition-all"
                >
                  📋 {t('audit.copyId', 'Copy Entry ID')}
                </button>
                {selectedLog.target_id && (
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(selectedLog.target_id || '');
                      toast(t('audit.toast.targetIdCopied', 'Target ID copied'), 'success');
                    }}
                    className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg theme-bg-secondary border border-[var(--surface-border)] text-[0.625rem] font-black uppercase tracking-widest theme-muted hover:theme-heading transition-all"
                  >
                    🎯 {t('audit.copyTargetId', 'Copy Target ID')}
                  </button>
                )}
                {selectedLog.details && Object.keys(selectedLog.details).length > 0 && (
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(JSON.stringify(selectedLog.details, null, 2));
                      toast(t('audit.toast.jsonCopied', 'JSON copied'), 'success');
                    }}
                    className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg theme-bg-secondary border border-[var(--surface-border)] text-[0.625rem] font-black uppercase tracking-widest theme-muted hover:theme-heading transition-all"
                  >
                    📄 {t('audit.copyJson', 'Copy JSON')}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
