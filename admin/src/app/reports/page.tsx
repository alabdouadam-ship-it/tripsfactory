'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Flag, Search, CheckCircle, AlertTriangle, Eye, Download, Ban, Trash2, Route, User, Star } from 'lucide-react';
import { cn, exportToCSV } from '@/lib/utils';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import Link from 'next/link';
import { useI18n, useT } from '@/lib/i18n';
import { Report, ReportTarget } from '@/lib/types';
import { applyReportAction } from '@/app/actions/moderation-actions';

type FilterStatus = 'open' | 'all' | 'pending' | 'investigating' | 'resolved' | 'dismissed';
type ReportAction = 'warn' | 'delete_target' | 'block_target';

const filterStatuses: FilterStatus[] = ['open', 'all', 'pending', 'investigating', 'resolved', 'dismissed'];
const visibleFilterStatuses: FilterStatus[] = ['open', 'pending', 'investigating', 'resolved', 'dismissed', 'all'];
const reportTargets: Array<'all' | ReportTarget> = ['all', 'user', 'driver', 'rating', 'trip'];
const openReportStatuses = new Set(['open', 'pending', 'investigating']);

function readFilterStatus(value: string | null, fallback: FilterStatus): FilterStatus {
  return filterStatuses.includes(value as FilterStatus) ? value as FilterStatus : fallback;
}

function readTargetFilter(value: string | null): 'all' | ReportTarget {
  return reportTargets.includes(value as 'all' | ReportTarget) ? value as 'all' | ReportTarget : 'all';
}

export default function ReportsPage() {
  const { toast } = useToast();
  const searchParams = useSearchParams();
  const focusedReportId = searchParams.get('focus');
  const [reports, setReports] = useState<Report[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<FilterStatus>(() => readFilterStatus(searchParams.get('status'), focusedReportId ? 'all' : 'open'));
  const [targetFilter, setTargetFilter] = useState<'all' | ReportTarget>(() => readTargetFilter(searchParams.get('target')));
  const [search, setSearch] = useState('');
  const [notesModal, setNotesModal] = useState<{ report: Report; notes: string } | null>(null);
  const [actionModal, setActionModal] = useState<{ report: Report; action: ReportAction; notes: string } | null>(null);
  const [submittingAction, setSubmittingAction] = useState(false);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [error, setError] = useState<string | null>(null);
  const t = useT();
  const { dir, language } = useI18n();
  const isRtl = dir === 'rtl';
  const locale = language === 'ar' ? 'ar' : 'en';

  useEffect(() => { fetchReports(); }, [dateFrom, dateTo]);

  useEffect(() => {
    setFilter(readFilterStatus(searchParams.get('status'), focusedReportId ? 'all' : 'open'));
    setTargetFilter(readTargetFilter(searchParams.get('target')));
  }, [searchParams, focusedReportId]);

  async function fetchReports() {
    setLoading(true);
    setError(null);
    let query = supabase
      .from('reports')
      .select('*, reporter:profiles!reports_reporter_id_fkey(full_name), reported:profiles!reports_reported_id_fkey(full_name)');

    if (dateFrom) query = query.gte('created_at', `${dateFrom}T00:00:00.000Z`);
    if (dateTo) query = query.lte('created_at', `${dateTo}T23:59:59.999Z`);

    const { data, error: err } = await query.order('created_at', { ascending: false });
    if (err) {
      console.error(err);
      setError(t('reports.errorLoad', 'Failed to load reports.'));
      toast(t('reports.errorLoad', 'Failed to load reports.'), 'error');
    } else {
      setReports((data as Report[]) || []);
    }
    setLoading(false);
  }

  async function resolveReport(report: Report, newStatus: 'resolved' | 'dismissed', notes?: string) {
    const { data: { user } } = await supabase.auth.getUser();
    const { error } = await supabase.from('reports').update({
      status: newStatus,
      resolution_action: newStatus === 'resolved' ? 'upheld' : 'no_action',
      resolved_by: user?.id || null,
      resolved_at: new Date().toISOString(),
      admin_notes: notes || null,
    }).eq('id', report.id);
    if (error) { toast(t('reports.toast.updateFailed'), 'error'); return; }
    await logAdminAction(`report_${newStatus}`, 'report', report.id, { reported_id: report.reported_id });
    toast(t('reports.toast.reportResolved').replace('{status}', newStatus), 'success');
    fetchReports();
  }

  function openResolveModal(report: Report, status: 'resolved' | 'dismissed') {
    setNotesModal({ report: { ...report, status }, notes: '' });
  }

  async function applyAction() {
    if (!actionModal || submittingAction) return;
    const { report, action, notes } = actionModal;
    setSubmittingAction(true);
    const res = await applyReportAction(report.id, { action, notes: notes || undefined });
    if (res.success) {
      toast(t('reports.toast.actionApplied', `Report ${action} applied`), 'success');
      setActionModal(null);
      fetchReports();
    } else {
      toast(res.error || t('reports.toast.actionFailed', 'Failed to apply report action'), 'error');
    }
    setSubmittingAction(false);
  }

  const filtered = reports.filter(r => {
    const matchesSearch = r.reporter?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      r.reported?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      r.reason?.toLowerCase().includes(search.toLowerCase());
    const matchesTarget = targetFilter === 'all' || (r.target_type ?? 'user') === targetFilter;
    if (!matchesTarget) return false;
    const normalizedStatus = r.status || 'pending';
    if (filter === 'open') return matchesSearch && openReportStatuses.has(normalizedStatus);
    if (filter === 'all') return matchesSearch;
    return matchesSearch && normalizedStatus === filter;
  });

  function targetIcon(type: string | null | undefined) {
    switch (type) {
      case 'trip': return Route;
      case 'rating': return Star;
      default: return User;
    }
  }

  function targetLink(r: Report): string | null {
    if (r.target_type === 'trip' && r.target_trip_id) return `/trips/${r.target_trip_id}`;
    if (r.target_type === 'rating' && r.target_rating_id) return null;
    if (r.reported_id) return `/users/${r.reported_id}`;
    return null;
  }

  function canDeleteTarget(r: Report) {
    return Boolean(
      (r.target_type === 'trip' && r.target_trip_id) ||
      (r.target_type === 'rating' && r.target_rating_id)
    );
  }

  const openCount = reports.filter(r => openReportStatuses.has(r.status || 'pending')).length;

  const statusBadge = (status: string | null) => {
    const s = status || 'pending';
    const colors: Record<string, string> = {
      open: 'bg-red-100 text-red-700',
      pending: 'bg-amber-100 text-amber-700',
      investigating: 'bg-blue-100 text-blue-700',
      resolved: 'bg-green-100 text-green-700',
      dismissed: 'bg-gray-100 text-gray-500',
    };
    return <span className={`px-2 py-0.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest ${colors[s] || 'bg-gray-100 text-gray-600'}`}>{t(`reports.status.${s}`, s)}</span>;
  };

  if (loading) return <Loading />;
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center">{error}</p>
        <button type="button" onClick={() => fetchReports()} className="px-4 py-2 rounded-lg font-medium" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6" dir={dir}>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">
            {t('reports.title', 'Reports & Disputes')}
          </h1>
          <p className="theme-muted text-sm mt-1 font-medium">
            {t('reports.subtitle', 'Review user reports and take moderation actions')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {openCount > 0 && (
            <span className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest">
              <AlertTriangle className="h-4 w-4" /> {t('reports.openCount', '{count} Open').replace('{count}', String(openCount))}
            </span>
          )}
          <button
            onClick={() => exportToCSV(filtered, 'reports_export', (msg) => toast(msg, 'error'))}
            className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition font-bold text-xs uppercase"
          >
            <Download className="h-4 w-4" /> {t('common.exportCsv', 'Export CSV')}
          </button>
        </div>
      </div>

      <div className="form-on-light flex flex-col gap-4 md:flex-row md:items-center theme-bg-secondary p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-xs font-bold theme-muted uppercase tracking-widest">
            {t('reports.dateRange', 'Date range')}
          </span>
          <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none transition" />
          <span className="theme-muted opacity-40">-</span>
          <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none transition" />
        </div>
        <div className="relative flex-1">
          <Search className={`absolute ${isRtl ? 'right-3' : 'left-3'} top-1/2 h-4 w-4 -translate-y-1/2 theme-muted`} />
          <input
            type="text"
            placeholder={t('reports.search.placeholder', 'Search by user, reason...')}
            className={`w-full rounded-lg border border-[var(--surface-border)] theme-bg-secondary ${isRtl ? 'pr-10 pl-3' : 'pl-10 pr-3'} py-2 theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition`}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div className="flex gap-2">
          {visibleFilterStatuses.map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all ${filter === f ? 'bg-blue-600 text-white shadow-sm' : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'}`}
            >
              {t(`reports.filter.${f}`, f)}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest">{t('reports.target.label', 'Target')}</span>
          <select
            value={targetFilter}
            onChange={e => setTargetFilter(e.target.value as any)}
            className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-1.5 text-xs theme-heading focus:border-blue-500 outline-none"
          >
            <option value="all">{t('reports.target.all', 'All')}</option>
            <option value="user">{t('reports.target.user', 'User')}</option>
            <option value="driver">{t('reports.target.driver', 'Driver')}</option>
            <option value="trip">{t('reports.target.trip', 'Trip')}</option>
            <option value="rating">{t('reports.target.rating', 'Rating')}</option>
          </select>
        </div>
      </div>

      <div className="space-y-4">
        {filtered.map(report => {
          const TIcon = targetIcon(report.target_type);
          const linkHref = targetLink(report);
          const isFocused = focusedReportId === report.id;
          const deletableTarget = canDeleteTarget(report);
          const targetLabel = report.target_type === 'trip'
            ? `${t('reports.target.trip', 'Trip')} ${report.target_trip_id?.slice(0, 8) || ''}`
            : report.target_type === 'rating'
              ? `${t('reports.target.rating', 'Rating')} ${report.target_rating_id?.slice(0, 8) || ''}`
              : (report.reported?.full_name || t('common.unknown', 'Unknown'));
          return (
          <div
            key={report.id}
            data-report-id={report.id}
            className={cn(
              'bg-[var(--surface)] rounded-2xl border shadow-sm p-6 hover:shadow-md transition-all',
              isFocused ? 'border-orange-500/50 bg-orange-500/5 shadow-md' : 'border-[var(--surface-border)]'
            )}
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-xl bg-red-100 flex items-center justify-center">
                  <Flag className="h-5 w-5 text-red-500" />
                </div>
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-sm font-black theme-heading">{report.reason}</span>
                    {statusBadge(report.status)}
                    <span className="px-2 py-0.5 rounded-md text-[0.5625rem] font-black uppercase tracking-widest bg-purple-500/10 text-purple-600 border border-purple-500/20 flex items-center gap-1">
                      <TIcon className="h-3 w-3" /> {t(`reports.target.${report.target_type ?? 'user'}`, report.target_type ?? 'user')}
                    </span>
                  </div>
                  <p className="text-[0.625rem] theme-muted mt-0.5">
                    <Link href={`/users/${report.reporter_id}`} className="text-blue-600 hover:underline">{report.reporter?.full_name || t('common.unknown', 'Unknown')}</Link>
                    {' -> '}
                    {linkHref ? (
                      <Link href={linkHref} className="text-blue-600 hover:underline">{targetLabel}</Link>
                    ) : (
                      <span>{targetLabel}</span>
                    )}
                  </p>
                </div>
              </div>
              <span className="text-[0.625rem] theme-muted font-mono">{new Date(report.created_at).toLocaleString(locale)}</span>
            </div>

            {report.comment && (
              <div className="theme-bg-secondary p-4 rounded-xl border border-[var(--surface-border)] mb-4">
                <p className="text-sm theme-heading leading-relaxed">{report.comment}</p>
              </div>
            )}

            {report.admin_notes && (
              <div className="bg-blue-500/10 p-4 rounded-xl border border-blue-500/20 mb-4">
                <p className="text-[0.625rem] text-blue-500 font-black uppercase mb-1 tracking-widest">{t('reports.adminNotes', 'Admin Notes')}</p>
                <p className="text-sm text-blue-600 font-medium">{report.admin_notes}</p>
              </div>
            )}

            {openReportStatuses.has(report.status || 'pending') && (
              <div className="flex flex-wrap gap-2 pt-4 border-t border-[var(--surface-border)]">
                <button onClick={() => setActionModal({ report, action: 'warn', notes: '' })} className="flex items-center gap-2 px-4 py-2 bg-amber-500 text-white rounded-lg text-xs font-bold hover:bg-amber-600 transition shadow-sm">
                  <AlertTriangle className="h-4 w-4" /> {t('reports.action.warn', 'Warn user')}
                </button>
                {deletableTarget && (
                  <button onClick={() => setActionModal({ report, action: 'delete_target', notes: '' })} className="flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg text-xs font-bold hover:bg-orange-700 transition shadow-sm">
                    <Trash2 className="h-4 w-4" /> {t('reports.action.deleteTarget', 'Delete target')}
                  </button>
                )}
                <button onClick={() => setActionModal({ report, action: 'block_target', notes: '' })} className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg text-xs font-bold hover:bg-red-700 transition shadow-sm">
                  <Ban className="h-4 w-4" /> {t('reports.action.block', 'Block user')}
                </button>
                <button onClick={() => openResolveModal(report, 'resolved')} className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg text-xs font-bold hover:bg-green-700 transition shadow-sm">
                  <CheckCircle className="h-4 w-4" /> {t('reports.action.markUpheld', 'Mark upheld')}
                </button>
                <button onClick={() => openResolveModal(report, 'dismissed')} className="flex items-center gap-2 px-4 py-2 theme-bg-secondary theme-muted rounded-lg text-xs font-bold hover:theme-heading hover:bg-[var(--main-bg)] transition border border-[var(--surface-border)]">
                  {t('reports.action.dismiss', 'Dismiss')}
                </button>
                {linkHref && (
                  <Link href={linkHref} className={`flex items-center gap-2 px-4 py-2 bg-blue-500/10 text-blue-600 rounded-lg text-xs font-bold hover:bg-blue-500/20 transition ${isRtl ? 'mr-auto' : 'ml-auto'}`}>
                    <Eye className="h-4 w-4" /> {t('reports.action.viewTarget', 'View target')}
                  </Link>
                )}
              </div>
            )}
          </div>
        );
        })}
        {filtered.length === 0 && (
          <div className="text-center py-20 bg-[var(--surface)] rounded-2xl border border-dashed border-[var(--surface-border)]">
            <Flag className="h-12 w-12 theme-muted opacity-20 mx-auto mb-3" />
            <p className="theme-muted font-bold uppercase tracking-widest text-sm">
              {t('reports.empty', 'No reports match your criteria.')}
            </p>
          </div>
        )}
      </div>

      {/* Admin Action Modal */}
      {actionModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-2xl p-6 max-w-md w-full mx-4">
            <h3 className="text-xl font-black theme-heading mb-2 flex items-center gap-2">
              {actionModal.action === 'warn' && <AlertTriangle className="h-5 w-5 text-amber-500" />}
              {actionModal.action === 'delete_target' && <Trash2 className="h-5 w-5 text-orange-600" />}
              {actionModal.action === 'block_target' && <Ban className="h-5 w-5 text-red-600" />}
              {t(`reports.actionTitle.${actionModal.action}`, actionModal.action.replace('_', ' ').toUpperCase())}
            </h3>
            <p className="theme-muted text-sm mb-4">
              {actionModal.action === 'warn' && t('reports.action.warn.desc', 'Sends a warning notification to the reported user and increments their strike count.')}
              {actionModal.action === 'delete_target' && t('reports.action.deleteTarget.desc', 'Cancels the reported trip, or rejects the reported review comment.')}
              {actionModal.action === 'block_target' && t('reports.action.block.desc', 'Hard-blocks and disables the reported user account.')}
            </p>
            <textarea
              className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl p-4 text-sm theme-heading focus:border-blue-500 outline-none mb-4 resize-none"
              rows={3}
              placeholder={t('reports.placeholder.adminNotes', 'Admin notes (optional)')}
              value={actionModal.notes}
              onChange={e => setActionModal({ ...actionModal, notes: e.target.value })}
            />
            <div className="flex gap-3 justify-end">
              <button disabled={submittingAction} onClick={() => setActionModal(null)} className="px-4 py-2 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition disabled:opacity-50">
                {t('common.cancel', 'Cancel')}
              </button>
              <button
                onClick={applyAction}
                disabled={submittingAction}
                className={`px-6 py-2 rounded-xl text-white font-bold shadow-sm transition ${
                  actionModal.action === 'warn' ? 'bg-amber-500 hover:bg-amber-600' :
                  actionModal.action === 'delete_target' ? 'bg-orange-600 hover:bg-orange-700' :
                  'bg-red-600 hover:bg-red-700'
                } disabled:opacity-60`}
              >
                {submittingAction ? t('common.saving', 'Saving...') : t('common.confirm', 'Confirm')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Notes Modal */}
      {notesModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-2xl p-6 max-w-md w-full mx-4 overflow-hidden">
            <h3 className="text-xl font-black theme-heading mb-2">
              {notesModal.report.status === 'resolved' ? t('reports.modal.markUpheldTitle', 'Mark Report Upheld') : t('reports.modal.dismissTitle', 'Dismiss Report')}
            </h3>
            <p className="theme-muted text-sm mb-6">
              {notesModal.report.status === 'resolved'
                ? t('reports.modal.markUpheldBody', 'This counts as an upheld report and can affect the reported user risk score.')
                : t('reports.modal.dismissBody', 'Add optional admin notes before dismissing this report without action.')}
            </p>
            <textarea
              className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl p-4 text-sm theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 mb-6 transition resize-none"
              rows={3}
              placeholder={t('reports.placeholder.adminNotes')}
              value={notesModal.notes}
              onChange={e => setNotesModal({ ...notesModal, notes: e.target.value })}
            />
            <div className="flex gap-3 justify-end">
              <button onClick={() => setNotesModal(null)} className="px-4 py-2 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition">{t('common.cancel', 'Cancel')}</button>
              <button onClick={() => {
                resolveReport(notesModal.report, notesModal.report.status as 'resolved' | 'dismissed', notesModal.notes);
                setNotesModal(null);
              }} className="px-6 py-2 rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-bold shadow-sm transition">
                {t('common.confirm', 'Confirm')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
