'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Bell, Send, User, Search, Clock } from 'lucide-react';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import { useI18n } from '@/lib/i18n';

type NotificationEntry = {
  id: string;
  user_id: string;
  title: string;
  body: string;
  data: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;
  profile?: { full_name: string | null };
};

type SendMode = 'single' | 'segment' | 'broadcast';
type NotificationSegment = 'all' | 'travelers' | 'individuals';

export default function NotificationsPage() {
  const { toast: showToast, confirm: confirmDialog } = useToast();
  const { t, language } = useI18n();
  const [notifications, setNotifications] = useState<NotificationEntry[]>([]);
  const [initialLoading, setInitialLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [search, setSearch] = useState('');
  const [showSend, setShowSend] = useState(false);
  const [sendMode, setSendMode] = useState<SendMode>('broadcast');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [targetUserId, setTargetUserId] = useState('');
  const [segment, setSegment] = useState<NotificationSegment>('all');
  const [sending, setSending] = useState(false);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const PAGE_SIZE = 50;
  const locale = language === 'ar' ? 'ar' : 'en';
  const dateTimeFormatter = useMemo(() => new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }), [locale]);

  const formatDateTime = useCallback((value: string) => {
    return dateTimeFormatter.format(new Date(value));
  }, [dateTimeFormatter]);

  function escapeSearchTerm(value: string) {
    return value.trim().replace(/[%,()]/g, ' ').replace(/\s+/g, ' ');
  }

  function stableHash(value: string) {
    let hash = 0;
    for (let i = 0; i < value.length; i += 1) {
      hash = ((hash << 5) - hash + value.charCodeAt(i)) | 0;
    }
    return Math.abs(hash).toString(36);
  }

  function campaignKey(target: string, notificationTitle: string, notificationBody: string) {
    const day = new Date().toISOString().slice(0, 10);
    return stableHash(`${target}|${notificationTitle}|${notificationBody}|${day}`);
  }

  function activeProfilesQuery(columns = 'id'): any {
    return supabase
      .from('profiles')
      .select(columns)
      .is('deleted_at', null)
      .or('is_suspended.is.null,is_suspended.eq.false')
      .or('is_admin.is.null,is_admin.eq.false')
      .or('traveler_status.is.null,traveler_status.not.in.(blocked,suspended)');
  }

  function applySegmentFilter(query: any) {
    if (sendMode !== 'segment' || segment === 'all') return query;
    if (segment === 'travelers') return query.eq('traveler_status', 'approved');
    if (segment === 'individuals') {
      return query
        .or('traveler_status.is.null,traveler_status.eq.none');
    }
    return query;
  }

  const fetchNotificationsPage = useCallback(async (pageToFetch: number, reset = false) => {
    if (reset) {
      setNotifications([]);
      setHasMore(true);
      setError(null);
      setInitialLoading(true);
    } else {
      setLoadingMore(true);
    }

    const from = pageToFetch * PAGE_SIZE;
    const to = from + PAGE_SIZE - 1;
    const searchTerm = escapeSearchTerm(search);
    let profileIds: string[] = [];
    if (searchTerm) {
      const { data: profiles, error: profilesError } = await supabase
        .from('profiles')
        .select('id')
        .ilike('full_name', `%${searchTerm}%`)
        .limit(50);
      if (profilesError) {
        console.warn('Failed to search notification profiles:', profilesError);
      } else {
        profileIds = ((profiles as Array<{ id: string }> | null) || []).map(profile => profile.id);
      }
    }

    let query = supabase
      .from('notifications')
      .select('*, profile:profiles!notifications_user_id_fkey(full_name)')
      .order('created_at', { ascending: false });

    if (searchTerm) {
      const filters = [
        `title.ilike.%${searchTerm}%`,
        `body.ilike.%${searchTerm}%`,
      ];
      if (/^[0-9a-f]{8}-[0-9a-f-]{27,36}$/i.test(searchTerm)) {
        filters.push(`user_id.eq.${searchTerm}`);
      }
      if (profileIds.length > 0) {
        filters.push(`user_id.in.(${profileIds.join(',')})`);
      }
      query = query.or(filters.join(','));
    }

    const { data, error: err } = await query.range(from, to);
    if (err) {
      console.error(err);
      if (reset) {
        setError(t('notifications.errorLoad', 'Failed to load notifications.'));
        showToast(t('notifications.errorLoad', 'Failed to load notifications.'), 'error');
      } else {
        showToast(t('notifications.errorLoadMore', 'Failed to load more notifications.'), 'error');
      }
      setInitialLoading(false);
      setLoadingMore(false);
      return;
    }

    const list = (data as NotificationEntry[]) || [];
    if (reset) {
      setNotifications(list);
      setPage(1);
    } else {
      setNotifications(prev => [...prev, ...list]);
      setPage(p => p + 1);
    }
    setHasMore(list.length === PAGE_SIZE);
    setInitialLoading(false);
    setLoadingMore(false);
  }, [PAGE_SIZE, search, showToast, t]);

  const fetchNotifications = useCallback(async (reset = false) => {
    const pageToFetch = reset ? 0 : page;
    await fetchNotificationsPage(pageToFetch, reset);
  }, [fetchNotificationsPage, page]);

  useEffect(() => {
    queueMicrotask(() => {
      void fetchNotificationsPage(0, true);
    });
  }, [fetchNotificationsPage]);

  // Real-time: new notifications (refetch so new items appear)
  useEffect(() => {
    const channel = supabase
      .channel('admin-notifications')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, () => {
        void fetchNotificationsPage(0, true);
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchNotificationsPage]);

  async function sendNotification() {
    const notificationTitle = title.trim();
    const notificationBody = body.trim();
    if (!notificationTitle || !notificationBody) {
      showToast(t('notifications.toast.titleBodyRequired', 'Title and body are required'), 'error');
      return;
    }

    if (sendMode === 'single') {
      await sendSingleNotification(notificationTitle, notificationBody);
      return;
    }

    setSending(true);
    const query = applySegmentFilter(activeProfilesQuery('id'));
    const { data: users, error: usersError } = await query;
    setSending(false);
    if (usersError || !users?.length) {
      showToast(t('notifications.toast.noUsersInSegment', 'No users found for segment'), 'error');
      return;
    }

    const targetUsers = (users || []) as Array<{ id: string }>;
    const targetLabel = sendMode === 'broadcast' ? 'broadcast' : segment;
    confirmDialog({
      title: t('notifications.confirm.title', 'Confirm notification send'),
      message: t(
        'notifications.confirm.message',
        'Send this notification to {count} users? This cannot be undone.',
      ).replace('{count}', String(users.length)),
      confirmLabel: t('notifications.send.button', 'Send'),
      cancelLabel: t('common.cancel', 'Cancel'),
      onConfirm: async () => {
        await sendNotificationsToUsers(
          targetUsers,
          targetLabel,
          notificationTitle,
          notificationBody,
        );
      },
    });
  }

  async function sendSingleNotification(notificationTitle: string, notificationBody: string) {
    const trimmedUserId = targetUserId.trim();
    if (!trimmedUserId) {
      showToast(t('notifications.toast.userIdRequired', 'User ID is required'), 'error');
      return;
    }

    setSending(true);
    const { data: targetProfile, error: targetError } = await activeProfilesQuery('id, full_name')
      .eq('id', trimmedUserId)
      .single();
    if (targetError || !targetProfile) {
      showToast(t('notifications.toast.userNotFound', 'No active user found for this ID'), 'error');
      setSending(false);
      return;
    }

    const { error } = await supabase.from('notifications').insert({
      user_id: trimmedUserId,
      title: notificationTitle,
      body: notificationBody,
      data: { type: 'admin_notification' },
    });
    if (error) {
      showToast(t('notifications.toast.sendFailed', 'Failed to send'), 'error');
      setSending(false);
      return;
    }

    await logAdminAction('send_notification', 'notification', null, {
      sendMode: 'single',
      targetUserId: trimmedUserId,
      title: notificationTitle,
    });
    showToast(t('notifications.toast.sentToUser', 'Notification sent to user'), 'success');
    setSending(false);
    setShowSend(false);
    setTitle('');
    setBody('');
    setTargetUserId('');
    void fetchNotifications(true);
  }

  async function sendNotificationsToUsers(
    users: Array<{ id: string }>,
    targetLabel: string,
    notificationTitle: string,
    notificationBody: string,
  ) {
    setSending(true);
    const key = campaignKey(targetLabel, notificationTitle, notificationBody);
    const inserts = users.map(user => ({
      user_id: user.id,
      title: notificationTitle,
      body: notificationBody,
      data: { type: 'admin_broadcast' },
      idempotency_key: `admin-${key}-${user.id}`,
    }));

    const batchSize = 500;
    for (let i = 0; i < inserts.length; i += batchSize) {
      const batch = inserts.slice(i, i + batchSize);
      const { error } = await supabase
        .from('notifications')
        .upsert(batch, { onConflict: 'idempotency_key', ignoreDuplicates: true });
      if (error) {
        showToast(t('notifications.toast.failedAtBatch', 'Failed at batch {n}').replace('{n}', String(Math.floor(i / batchSize) + 1)), 'error');
        setSending(false);
        return;
      }
    }

    await logAdminAction('send_notification', 'notification', null, {
      sendMode,
      segment: sendMode === 'segment' ? segment : undefined,
      targetCount: users.length,
      title: notificationTitle,
    });
    showToast(t('notifications.toast.sentToManyUsers', 'Notification sent to {count} users').replace('{count}', String(users.length)), 'success');
    setSending(false);
    setShowSend(false);
    setTitle('');
    setBody('');
    setTargetUserId('');
    void fetchNotifications(true);
  }

  const filtered = notifications.filter(n =>
    n.title?.toLowerCase().includes(search.toLowerCase()) ||
    n.body?.toLowerCase().includes(search.toLowerCase()) ||
    n.user_id?.toLowerCase().includes(search.toLowerCase()) ||
    n.profile?.full_name?.toLowerCase().includes(search.toLowerCase())
  );

  if (initialLoading) return <Loading />;
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center">{error}</p>
        <button type="button" onClick={() => fetchNotifications(true)} className="px-4 py-2 rounded-lg font-medium" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">{t('notifications.title', 'Notifications')}</h1>
          <p className="theme-muted text-sm mt-1 font-medium">{t('notifications.subtitle', 'Send and view notifications to users')}</p>
        </div>
        <button onClick={() => setShowSend(true)} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition shadow-sm font-bold text-xs uppercase">
          <Send className="h-4 w-4" /> {t('notifications.send', 'Send Notification')}
        </button>
      </div>

      <div className="form-on-light flex items-center theme-bg-secondary p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
        <div className="relative flex-1">
          <Search className="absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 theme-muted" />
          <input type="text" placeholder={t('notifications.search.placeholder', 'Search notifications...')} className="w-full rounded-lg border border-[var(--surface-border)] theme-bg-secondary ps-10 py-2 theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition" value={search} onChange={e => setSearch(e.target.value)} />
        </div>
      </div>

      <div className="space-y-3">
        {filtered.map(n => (
          <div key={n.id} className="bg-[var(--surface)] rounded-xl border border-[var(--surface-border)] shadow-sm p-4 hover:shadow-md transition-all flex items-start gap-4 group">
            <div className={`h-10 w-10 rounded-xl flex items-center justify-center ${n.is_read ? 'theme-bg-secondary' : 'bg-blue-500/10'}`}>
              <Bell className={`h-5 w-5 ${n.is_read ? 'theme-muted opacity-40' : 'text-blue-500'}`} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <p className="text-sm font-bold theme-heading truncate">{n.title}</p>
                {!n.is_read && <span className="px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-500 text-[0.625rem] font-black uppercase">{t('notifications.status.unread', 'Unread')}</span>}
              </div>
              <p className="text-sm theme-muted opacity-80 line-clamp-2">{n.body}</p>
              <div className="flex items-center gap-3 mt-2 text-[0.625rem] theme-muted font-bold">
                <span className="flex items-center gap-1"><User className="h-3 w-3" /> {n.profile?.full_name || n.user_id.slice(0, 8)}</span>
                <span className="flex items-center gap-1"><Clock className="h-3 w-3" /> {formatDateTime(n.created_at)}</span>
              </div>
            </div>
          </div>
        ))}
        {filtered.length === 0 && !initialLoading && (
          <div className="text-center py-20 theme-bg-secondary rounded-2xl border border-dashed border-[var(--surface-border)]">
            <Bell className="h-12 w-12 theme-muted opacity-20 mx-auto mb-3" />
            <p className="theme-muted font-bold uppercase tracking-widest text-sm">{t('notifications.empty')}</p>
          </div>
        )}
        {hasMore && (
          <div className="flex justify-center pt-4">
            <button
              onClick={() => fetchNotifications(false)}
              disabled={loadingMore}
              className="px-8 py-2.5 rounded-xl border border-[var(--surface-border)] text-sm font-bold theme-muted hover:theme-heading hover:theme-bg-secondary transition disabled:opacity-50"
            >
              {loadingMore ? t('common.loading') : t('notifications.loadMore')}
            </button>
          </div>
        )}
      </div>

      {/* Send Modal */}
      {showSend && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-xl p-6 max-w-md w-full mx-4 overflow-hidden">
            <h3 className="text-lg font-black theme-heading mb-4">{t('notifications.send', 'Send Notification')}</h3>
            <div className="flex gap-2 mb-4">
              {(['broadcast', 'segment', 'single'] as SendMode[]).map(m => (
                <button key={m} onClick={() => setSendMode(m)} className={`px-3 py-1.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all ${sendMode === m ? 'bg-blue-600 text-white' : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'}`}>
                  {m === 'broadcast' ? t('notifications.mode.broadcast', 'All Users') : m === 'segment' ? t('notifications.mode.segment', 'Segment') : t('notifications.mode.single', 'Single User')}
                </button>
              ))}
            </div>

            {sendMode === 'single' && (
              <div className="mb-3">
                <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1 block">{t('notifications.single.userId', 'User ID')}</label>
                <input type="text" value={targetUserId} onChange={e => setTargetUserId(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none" placeholder={t('notifications.placeholder.pasteUserId', 'Paste user UUID...')} />
              </div>
            )}

            {sendMode === 'segment' && (
              <div className="mb-3">
                <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1 block">{t('notifications.segment.label', 'Target Segment')}</label>
                <select value={segment} onChange={e => setSegment(e.target.value as typeof segment)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none">
                  <option value="all">{t('notifications.segment.all', 'All Users')}</option>
                  <option value="travelers">{t('notifications.segment.travelers', 'Travelers / Drivers')}</option>
                  <option value="individuals">{t('notifications.segment.individuals', 'Individuals')}</option>
                </select>
              </div>
            )}

            <div className="mb-3">
              <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1 block">{t('notifications.field.title', 'Title')}</label>
              <input type="text" value={title} onChange={e => setTitle(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none" placeholder={t('notifications.placeholder.title', 'Notification title...')} />
            </div>
            <div className="mb-4">
              <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1 block">{t('notifications.field.body', 'Body')}</label>
              <textarea value={body} onChange={e => setBody(e.target.value)} rows={3} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none resize-none" placeholder={t('notifications.placeholder.body', 'Notification body...')} />
            </div>

            <div className="flex gap-3 justify-end">
              <button onClick={() => setShowSend(false)} className="px-4 py-2 rounded-lg border border-[var(--surface-border)] theme-muted hover:theme-heading font-medium transition-colors">{t('common.cancel', 'Cancel')}</button>
              <button onClick={sendNotification} disabled={sending} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 font-medium disabled:opacity-50 shadow-sm transition-colors">
                <Send className="h-4 w-4" /> {sending ? t('notifications.send.sending', 'Sending...') : t('notifications.send.button', 'Send')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
