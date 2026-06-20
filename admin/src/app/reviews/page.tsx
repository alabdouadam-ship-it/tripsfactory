'use client';

import { useEffect, useState, useMemo } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Star, Trash2, Search, CheckCircle, XCircle, Clock, Download } from 'lucide-react';
import { exportToCSV } from '@/lib/utils';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import Link from 'next/link';
import { useI18n } from '@/lib/i18n';
import { Rating } from '@/lib/types';

type CommentFilter = 'all' | 'pending' | 'approved' | 'rejected';

type ReviewRating = Rating & {
  booking?: { id?: string | null; trip_id?: string | null } | null;
};

function hasReviewComment(rating: Rating) {
  return Boolean(rating.comment?.trim());
}

function shortId(id: string | null | undefined) {
  if (!id) return 'N/A';
  return `#${id.slice(0, 8)}`;
}

function localDateBoundaryIso(value: string, endOfDay = false) {
  const time = endOfDay ? 'T23:59:59.999' : 'T00:00:00.000';
  return new Date(`${value}${time}`).toISOString();
}

function humanize(value: string) {
  return value
    .split('_')
    .map(part => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

export default function ReviewsPage() {
  const { toast, confirm: confirmDialog } = useToast();
  const [ratings, setRatings] = useState<ReviewRating[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [commentFilter, setCommentFilter] = useState<CommentFilter>('all');
  const [ratingFilter, setRatingFilter] = useState<number>(0);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [error, setError] = useState<string | null>(null);
  const { t, language } = useI18n();

  useEffect(() => { fetchRatings(); }, [dateFrom, dateTo]);

  async function fetchRatings() {
    setLoading(true);
    setError(null);
    let query = supabase
      .from('ratings')
      .select(`
        *,
        rater:profiles!ratings_rater_id_fkey(full_name),
        rated:profiles!ratings_rated_id_fkey(full_name),
        booking:bookings!ratings_booking_id_fkey(id, trip_id)
      `);

    if (dateFrom) query = query.gte('created_at', localDateBoundaryIso(dateFrom));
    if (dateTo) query = query.lte('created_at', localDateBoundaryIso(dateTo, true));

    const { data, error: err } = await query.order('created_at', { ascending: false });
    if (err) {
      console.error(err);
      setError(t('reviews.errorLoad', 'Failed to load reviews.'));
      toast(t('reviews.errorLoad', 'Failed to load reviews.'), 'error');
    } else {
      setRatings((data as ReviewRating[]) || []);
    }
    setLoading(false);
  }

  async function updateCommentStatus(id: string, status: 'approved' | 'rejected') {
    const { error } = await supabase.from('ratings').update({ comment_status: status }).eq('id', id);
    if (error) { toast(t('reviews.toast.updateFailed'), 'error'); return; }
    setRatings(prev => prev.map(r => r.id === id ? { ...r, comment_status: status } : r));
    await logAdminAction(status === 'approved' ? 'approve_comment' : 'reject_comment', 'rating', id);
    toast(status === 'approved' ? t('reviews.toast.commentApproved') : t('reviews.toast.commentRejected'), 'success');
  }

  function deleteRatingComment(id: string) {
    confirmDialog({
      title: t('reviews.dialog.deleteCommentTitle'), message: t('reviews.dialog.deleteCommentMessage'), confirmLabel: t('reviews.dialog.deleteCommentLabel'),
      onConfirm: async () => {
        const { error } = await supabase.from('ratings').update({ comment: null, comment_status: 'rejected' }).eq('id', id);
        if (error) { toast(t('reviews.toast.deleteFailed'), 'error'); return; }
        setRatings(prev => prev.map(r => r.id === id ? { ...r, comment: null, comment_status: 'rejected' } : r));
        await logAdminAction('delete_rating_comment', 'rating', id);
        toast(t('reviews.toast.commentDeleted', 'Comment deleted'), 'success');
      }
    });
  }

  function roleLabel(role: string) {
    switch (role) {
      case 'driver':
        return t('reviews.role.driver', 'Traveler / Driver');
      case 'traveler':
        return t('reviews.role.traveler', 'Traveler');
      case 'client':
        return t('reviews.role.client', 'Sender');
      case 'sender':
        return t('reviews.role.sender', 'Sender');
      default:
        return humanize(role || t('common.unknown', 'Unknown'));
    }
  }

  function roleClass(role: string) {
    return role === 'driver' || role === 'traveler'
      ? 'bg-orange-100 text-orange-700'
      : 'bg-blue-100 text-blue-700';
  }

  function renderContext(rating: ReviewRating) {
    if (rating.booking_id) {
      return (
        <Link href={`/bookings/${rating.booking_id}`} className="text-blue-600 hover:underline text-xs font-bold">
          {t('reviews.context.booking', 'Trip booking')} {shortId(rating.booking_id)}
        </Link>
      );
    }

    return <span className="text-xs theme-muted opacity-50">{t('reviews.context.none', 'No linked trip')}</span>;
  }

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase();
    return ratings.filter(r => {
      const contextText = [
        r.booking_id,
        roleLabel(r.role_rated),
      ].filter(Boolean).join(' ');
      const matchesSearch = !query || [
        r.rater?.full_name,
        r.rated?.full_name,
        r.comment,
        contextText,
      ].some(value => value?.toLowerCase().includes(query));
      const matchesComment = commentFilter === 'all' || (hasReviewComment(r) && (r.comment_status || 'pending') === commentFilter);
      const matchesRating = ratingFilter === 0 || r.rating === ratingFilter;
      return matchesSearch && matchesComment && matchesRating;
    });
  }, [ratings, search, commentFilter, ratingFilter, language, t]);

  const pendingCount = ratings.filter(r => hasReviewComment(r) && (!r.comment_status || r.comment_status === 'pending')).length;
  const dateFormatter = useMemo(() => new Intl.DateTimeFormat(language === 'ar' ? 'ar' : 'en', {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  }), [language]);

  const statusBadge = (status: string | null) => {
    const s = status || 'pending';
    const colors: Record<string, string> = {
      pending: 'bg-amber-100 text-amber-700', approved: 'bg-green-100 text-green-700', rejected: 'bg-red-100 text-red-700',
    };
    const label = t(`reviews.status.${s}`, humanize(s));
    return <span className={`px-2 py-0.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest ${colors[s] || 'bg-gray-100 text-gray-600'}`}>{label}</span>;
  };

  if (loading) return <Loading />;
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center">{error}</p>
        <button type="button" onClick={() => fetchRatings()} className="px-4 py-2 rounded-lg font-medium" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">
            {t('reviews.title', 'Reviews & Ratings')}
          </h1>
          <p className="theme-muted text-sm mt-1 font-medium">
            {t('reviews.subtitle', 'Moderate ratings and review comments')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {pendingCount > 0 && (
            <span className="flex items-center gap-2 bg-amber-500/10 border border-amber-500/20 text-amber-600 px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest shadow-sm">
              <Clock className="h-4 w-4" /> {pendingCount} {t('reviews.commentsPending', 'Comments Pending')}
            </span>
          )}
          <button
            onClick={() => exportToCSV(filtered, 'reviews_export', (msg) => toast(msg, 'error'))}
            className="flex items-center gap-2 bg-green-500/10 border border-green-500/20 text-green-600 px-4 py-2 rounded-xl hover:bg-green-500/20 transition shadow-sm font-black text-[0.625rem] uppercase tracking-widest"
          >
            <Download className="h-4 w-4" /> {t('common.exportCsv', 'Export CSV')}
          </button>
          <div className="theme-bg-secondary px-4 py-2 rounded-xl border border-[var(--surface-border)] shadow-sm font-black text-[0.625rem] theme-heading uppercase tracking-widest">
            {t('common.total', 'Total')}: {filtered.length}
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="theme-bg-secondary flex flex-col gap-4 md:flex-row md:items-center p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
            {t('reviews.dateRange', 'Date range')}
          </span>
          <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-2 text-xs theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all" />
          <span className="theme-muted opacity-30">-</span>
          <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-2 text-xs theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all" />
        </div>
        <div className="relative flex-1">
          <Search className="absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 theme-muted opacity-50" />
          <input
            type="text"
            placeholder={t('reviews.search.placeholder', 'Search by user, comment, or context...')}
            className="w-full theme-bg-secondary rounded-lg border border-[var(--surface-border)] ps-10 py-2 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div className="flex gap-2 flex-wrap">
          {(['all', 'pending', 'approved', 'rejected'] as CommentFilter[]).map(f => (
            <button
              key={f}
              onClick={() => setCommentFilter(f)}
              className={`px-3 py-1.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm ${commentFilter === f ? 'bg-blue-600 text-white' : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'}`}
            >
              {t(`reviews.filter.comment.${f}`, humanize(f))}
            </button>
          ))}
          <span className="w-px bg-[var(--surface-border)] mx-1" />
          {[0, 1, 2, 3, 4, 5].map(r => (
            <button key={r} onClick={() => setRatingFilter(r)} className={`px-2 py-1.5 rounded-lg text-[0.625rem] font-black transition-all shadow-sm ${ratingFilter === r ? 'bg-yellow-500 text-white' : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'}`}>
              {r === 0 ? t('reviews.filter.rating.all', 'All') : (
                <span className="inline-flex items-center gap-1">
                  {r}
                  <Star className="h-3 w-3 fill-current" />
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Ratings Table */}
      <div className="bg-[var(--surface)] rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
        <table className="w-full min-w-[1040px] text-sm">
          <thead>
            <tr className="theme-bg-secondary border-b border-[var(--surface-border)]">
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.score')}</th>
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.from')}</th>
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.to')}</th>
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.role')}</th>
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.context', 'Context')}</th>
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.comment')}</th>
              <th className="text-center py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.status')}</th>
              <th className="text-start py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.date')}</th>
              <th className="text-end py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">{t('reviews.table.actions')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--surface-border)] opacity-90">
            {filtered.map(r => (
              <tr key={r.id} className="hover:theme-bg-secondary transition-colors group">
                <td className="py-3 px-4">
                  <div className="flex items-center gap-0.5">
                    {[1, 2, 3, 4, 5].map(s => (
                      <Star key={s} className={`h-3 w-3 ${s <= r.rating ? 'fill-yellow-400 text-yellow-400' : 'theme-muted opacity-20'}`} />
                    ))}
                  </div>
                </td>
                <td className="py-3 px-4">
                  <Link href={`/users/${r.rater_id}`} className="text-blue-600 hover:underline text-xs font-bold">{r.rater?.full_name || t('common.unknown')}</Link>
                </td>
                <td className="py-3 px-4">
                  <Link href={`/users/${r.rated_id}`} className="text-blue-600 hover:underline text-xs font-bold">{r.rated?.full_name || t('common.unknown')}</Link>
                </td>
                <td className="py-3 px-4">
                  <span className={`px-2 py-0.5 rounded text-[0.625rem] font-black uppercase ${roleClass(r.role_rated)}`}>{roleLabel(r.role_rated)}</span>
                </td>
                <td className="py-3 px-4 max-w-[220px]">
                  {renderContext(r)}
                </td>
                <td className="py-3 px-4 max-w-xs">
                  {hasReviewComment(r) ? (
                    <p className="text-xs theme-heading font-medium line-clamp-2">{r.comment}</p>
                  ) : (
                    <span className="text-xs theme-muted italic opacity-30">{t('reviews.noComment', 'No comment')}</span>
                  )}
                </td>
                <td className="py-3 px-4 text-center">
                  {hasReviewComment(r) ? statusBadge(r.comment_status) : <span className="theme-muted opacity-30">-</span>}
                </td>
                <td className="py-3 px-4 text-[0.6875rem] font-black theme-muted font-mono uppercase tracking-widest opacity-60">{dateFormatter.format(new Date(r.created_at))}</td>
                <td className="py-3 px-4 text-end">
                  <div className="flex gap-1 justify-end">
                    {hasReviewComment(r) && (!r.comment_status || r.comment_status === 'pending') && (
                      <>
                        <button onClick={() => updateCommentStatus(r.id, 'approved')} className="p-2 text-green-600 hover:bg-green-500/10 rounded-lg transition-all" title={t('reviews.title.approveComment', 'Approve comment')}>
                          <CheckCircle className="h-4 w-4" />
                        </button>
                        <button onClick={() => updateCommentStatus(r.id, 'rejected')} className="p-2 text-red-500 hover:bg-red-500/10 rounded-lg transition-all" title={t('reviews.title.rejectComment', 'Reject comment')}>
                          <XCircle className="h-4 w-4" />
                        </button>
                      </>
                    )}
                    {hasReviewComment(r) && (
                      <button onClick={() => deleteRatingComment(r.id)} className="p-2 theme-muted hover:text-red-500 hover:bg-red-500/10 rounded-lg transition-all" title={t('reviews.title.deleteComment', 'Delete comment')}>
                        <Trash2 className="h-4 w-4" />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        </div>
        {filtered.length === 0 && (
          <div className="text-center py-20 bg-[var(--surface)]">
            <Star className="h-12 w-12 theme-muted mx-auto mb-3 opacity-20" />
            <p className="theme-muted text-[0.625rem] font-black uppercase tracking-widest opacity-60">
              {t('reviews.empty', 'No ratings match your criteria.')}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
