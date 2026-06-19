'use client';

import { useEffect, useState, useMemo, useRef, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import {
  MessageSquare,
  Search,
  Clock,
  CheckCircle,
  XCircle,
  Send,
  User,
  ShieldCheck,
  ChevronLeft,
} from 'lucide-react';
import Loading from '@/app/loading';
import { logAdminAction } from '@/lib/audit';
import Link from 'next/link';
import { useI18n } from '@/lib/i18n';

type Ticket = {
  id: string;
  user_id: string;
  subject: string;
  status: string;
  created_at: string;
  updated_at: string;
  resolved_by: string | null;
  resolved_at: string | null;
  user?: { full_name: string | null; phone_number: string | null } | null;
};

type Message = {
  id: string;
  ticket_id: string;
  sender_id: string;
  sender_role: string;
  content: string;
  is_read: boolean;
  created_at: string;
};

type ProfileLite = {
  id: string;
  full_name: string | null;
  phone_number: string | null;
};

type StatusFilter = 'all' | 'open' | 'resolved' | 'ignored';

export default function SupportPage() {
  const { toast } = useToast();
  const { t, language } = useI18n();
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [ticketsError, setTicketsError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');

  // Detail pane
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [messagesError, setMessagesError] = useState<string | null>(null);
  const [replyText, setReplyText] = useState('');
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const locale = language === 'ar' ? 'ar' : 'en';
  const dateFormatter = useMemo(() => new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  }), [locale]);
  const dateTimeFormatter = useMemo(() => new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }), [locale]);

  const formatDate = useCallback((value: string) => dateFormatter.format(new Date(value)), [dateFormatter]);
  const formatDateTime = useCallback((value: string) => dateTimeFormatter.format(new Date(value)), [dateTimeFormatter]);

  const fetchTickets = useCallback(async () => {
    setLoading(true);
    setTicketsError(null);
    const { data, error } = await supabase
      .from('support_tickets')
      .select('*')
      .order('updated_at', { ascending: false });
    if (error) {
      setTicketsError(t('support.errorLoad', 'Failed to load tickets.'));
      toast(t('support.errorLoad', 'Failed to load tickets.'), 'error');
      setTickets([]);
      setLoading(false);
      return;
    }

    const list = (data as Ticket[]) || [];
    let merged: Ticket[] = list;
    if (list.length > 0) {
      const ids = [...new Set(list.map(ticket => ticket.user_id))];
      const { data: profilesData, error: profilesError } = await supabase
        .from('profiles')
        .select('id, full_name, phone_number')
        .in('id', ids);
      if (profilesError) {
        console.error(profilesError);
        toast(t('support.errorLoadProfiles', 'Tickets loaded, but user profiles could not be loaded.'), 'error');
      } else {
        const byId = (profilesData || []).reduce((acc: Record<string, { full_name: string | null; phone_number: string | null }>, p) => {
          const profile = p as ProfileLite;
          acc[profile.id] = { full_name: profile.full_name, phone_number: profile.phone_number };
          return acc;
        }, {});
        merged = list.map(ticket => ({ ...ticket, user: byId[ticket.user_id] || null }));
      }
    }
    setTickets(merged);
    setLoading(false);
  }, [t, toast]);

  useEffect(() => {
    queueMicrotask(() => {
      void fetchTickets();
    });
  }, [fetchTickets]);

  // Real-time: new tickets and ticket updates
  useEffect(() => {
    const selectedTicketId = selectedTicket?.id;
    const channel = supabase
      .channel('support-tickets')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'support_tickets' }, () => fetchTickets())
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'support_messages' }, (payload) => {
        const newMessage = payload.new as Partial<Message>;
        if (selectedTicketId && newMessage.ticket_id === selectedTicketId) {
          const normalized = newMessage as Message;
          setMessages(prev => [...prev, normalized].sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()));
        }
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchTickets, selectedTicket?.id]);

  // Auto-scroll to latest message when messages load or change
  useEffect(() => {
    if (!loadingMessages && messages.length > 0) {
      const t = setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 50);
      return () => clearTimeout(t);
    }
  }, [messages, loadingMessages]);

  async function loadMessages(ticket: Ticket) {
    setSelectedTicket(ticket);
    setLoadingMessages(true);
    setMessagesError(null);
    setReplyText('');
    const { data, error } = await supabase
      .from('support_messages')
      .select('*')
      .eq('ticket_id', ticket.id)
      .order('created_at', { ascending: true });
    if (error) {
      console.error(error);
      const message = t('support.errorLoadMessages', 'Failed to load messages.');
      setMessages([]);
      setMessagesError(message);
      setLoadingMessages(false);
      toast(message, 'error');
      return;
    }
    setMessages((data as Message[]) || []);
    setLoadingMessages(false);

    // Mark user messages as read
    const { error: readError } = await supabase
      .from('support_messages')
      .update({ is_read: true })
      .eq('ticket_id', ticket.id)
      .eq('sender_role', 'user')
      .eq('is_read', false);
    if (readError) {
      console.warn('Failed to mark support messages as read:', readError);
    }

    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
  }

  async function sendReply() {
    if (!selectedTicket || selectedTicket.status !== 'open' || !replyText.trim() || sending) return;
    setSending(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { toast(t('support.toast.notAuthenticated', 'Not authenticated'), 'error'); setSending(false); return; }

    const { error } = await supabase.from('support_messages').insert({
      ticket_id: selectedTicket.id,
      sender_id: user.id,
      sender_role: 'admin',
      content: replyText.trim(),
    });

    if (error) {
      toast(t('support.toast.replyFailed', 'Failed to send reply'), 'error');
      console.error(error);
    } else {
      setReplyText('');
      await logAdminAction('support_reply', 'support_ticket', selectedTicket.id, { user_id: selectedTicket.user_id });
      toast(t('support.toast.replySent', 'Reply sent'), 'success');
      const updatedAt = new Date().toISOString();
      const { error: touchError } = await supabase
        .from('support_tickets')
        .update({ updated_at: updatedAt })
        .eq('id', selectedTicket.id);
      if (touchError) {
        console.warn('Failed to update support ticket activity:', touchError);
        toast(t('support.toast.activityUpdateFailed', 'Reply sent, but ticket activity was not updated.'), 'error');
      } else {
        setTickets(prev => prev.map(ticket => ticket.id === selectedTicket.id ? { ...ticket, updated_at: updatedAt } : ticket));
        setSelectedTicket(prev => prev ? { ...prev, updated_at: updatedAt } : null);
      }
      // Reload messages
      const { data, error: reloadError } = await supabase
        .from('support_messages')
        .select('*')
        .eq('ticket_id', selectedTicket.id)
        .order('created_at', { ascending: true });
      if (reloadError) {
        console.warn('Failed to reload support messages:', reloadError);
      } else {
        setMessages((data as Message[]) || []);
      }
      // Also send a push notification to the user
      await sendNotificationToUser(selectedTicket.user_id, selectedTicket.subject, selectedTicket.id);
      setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    }
    setSending(false);
  }

  async function sendNotificationToUser(userId: string, ticketSubject: string, ticketId: string) {
    try {
      const { error } = await supabase.from('notifications').insert({
        user_id: userId,
        title: t('support.notification.title', 'Support Reply'),
        body: t('support.notification.body', 'New reply on your ticket: "{subject}"').replace(/\{subject\}/g, ticketSubject),
        data: { type: 'support_reply', ticket_id: ticketId },
      });
      if (error) {
        console.warn('Failed to send notification:', error);
        toast(t('support.toast.notificationFailed', 'Reply sent, but the user notification was not created.'), 'error');
      }
    } catch (e) {
      console.warn('Failed to send notification:', e);
      toast(t('support.toast.notificationFailed', 'Reply sent, but the user notification was not created.'), 'error');
    }
  }

  async function updateTicketStatus(ticketId: string, status: 'resolved' | 'ignored') {
    const { data: { user } } = await supabase.auth.getUser();
    const updates: Record<string, unknown> = {
      status,
      resolved_by: user?.id,
      resolved_at: new Date().toISOString(),
    };
    const { error } = await supabase
      .from('support_tickets')
      .update(updates)
      .eq('id', ticketId);
    if (error) {
      toast(t('support.toast.updateTicketFailed', 'Failed to update ticket'), 'error');
      return;
    }
    await logAdminAction(`ticket_${status}`, 'support_ticket', ticketId);
    toast(t('support.toast.ticketMarked', 'Ticket marked as {status}').replace('{status}', status), 'success');
    setTickets(prev => prev.map(t => t.id === ticketId ? { ...t, status, ...updates } as Ticket : t));
    if (selectedTicket?.id === ticketId) {
      setSelectedTicket(prev => prev ? { ...prev, status, ...updates } as Ticket : null);
    }
  }

  async function reopenTicket(ticketId: string) {
    const { error } = await supabase
      .from('support_tickets')
      .update({ status: 'open', resolved_by: null, resolved_at: null })
      .eq('id', ticketId);
    if (error) {
      toast(t('support.toast.reopenFailed', 'Failed to reopen ticket'), 'error');
      return;
    }
    await logAdminAction('ticket_reopen', 'support_ticket', ticketId);
    toast(t('support.toast.ticketReopened', 'Ticket reopened'), 'success');
    setTickets(prev => prev.map(t => t.id === ticketId ? { ...t, status: 'open', resolved_by: null, resolved_at: null } : t));
    if (selectedTicket?.id === ticketId) {
      setSelectedTicket(prev => prev ? { ...prev, status: 'open' } : null);
    }
  }

  const filtered = useMemo(() => {
    return tickets.filter(t => {
      const matchesSearch =
        t.subject.toLowerCase().includes(search.toLowerCase()) ||
        t.user?.full_name?.toLowerCase().includes(search.toLowerCase()) ||
        t.user?.phone_number?.includes(search) ||
        t.id.includes(search);
      const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [tickets, search, statusFilter]);

  const openCount = tickets.filter(t => t.status === 'open').length;

  const statusBadge = (status: string) => {
    const colors: Record<string, string> = {
      open: 'bg-amber-100 text-amber-700',
      resolved: 'bg-green-100 text-green-700',
      ignored: 'bg-gray-100 text-gray-500',
    };
    const labels: Record<string, string> = {
      all: t('support.filter.all', 'All'),
      open: t('support.filter.open', 'Open'),
      resolved: t('support.filter.resolved', 'Resolved'),
      ignored: t('support.filter.ignored', 'Ignored'),
    };
    return (
      <span className={`px-2 py-0.5 rounded-lg text-[0.625rem] font-black uppercase tracking-widest ${colors[status] || 'bg-gray-100 text-gray-600'}`}>
        {labels[status] ?? status}
      </span>
    );
  };

  if (loading) return <Loading />;
  if (ticketsError) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center max-w-xs">{ticketsError}</p>
        <button type="button" onClick={() => fetchTickets()} className="px-6 py-2 rounded-xl font-black text-[0.625rem] uppercase tracking-widest transition-all shadow-sm" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-2rem)] gap-4">
      {/* Left: Ticket List */}
      <div className={`flex flex-col ${selectedTicket ? 'hidden lg:flex lg:w-[420px]' : 'w-full'} flex-shrink-0`}>
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-3xl font-black theme-heading tracking-tight">{t('support.title', 'Support Tickets')}</h1>
            <p className="theme-muted text-sm mt-1 font-medium">{t('support.subtitle', 'Manage user support requests')}</p>
          </div>
          {openCount > 0 && (
            <span className="flex items-center gap-2 bg-amber-500/10 border border-amber-500/20 text-amber-600 px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest shadow-sm">
              <Clock className="h-4 w-4" /> {openCount} {t('support.filter.open', 'Open')}
            </span>
          )}
        </div>

        {/* Filters */}
        <div className="flex flex-col gap-3 mb-4">
          <div className="relative">
            <Search className="absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 theme-muted opacity-50" />
            <input
              type="text"
              placeholder={t('support.search.placeholder', 'Search by subject, user, or ID...')}
              className="w-full theme-bg-secondary rounded-xl border border-[var(--surface-border)] ps-10 py-2.5 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all shadow-sm"
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
          </div>
          <div className="flex gap-2">
            {(['all', 'open', 'resolved', 'ignored'] as StatusFilter[]).map(f => (
              <button
                key={f}
                onClick={() => setStatusFilter(f)}
                className={`flex-1 px-3 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm ${statusFilter === f
                  ? 'bg-blue-600 text-white'
                  : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'
                  }`}
              >
                {t(`support.filter.${f}`, f)}
              </button>
            ))}
          </div>
        </div>

        {/* Ticket list */}
        <div className="flex-1 overflow-y-auto space-y-3 custom-scrollbar pe-1">
          {filtered.length === 0 ? (
            <div className="text-center py-20 bg-[var(--surface)] rounded-2xl border border-dashed border-[var(--surface-border)]">
              <MessageSquare className="h-12 w-12 theme-muted mx-auto mb-3 opacity-20" />
              <p className="theme-muted text-[0.625rem] font-black uppercase tracking-widest opacity-60">{t('support.empty.list', 'No tickets found')}</p>
            </div>
          ) : (
            filtered.map(ticket => (
              <button
                key={ticket.id}
                onClick={() => loadMessages(ticket)}
                className={`w-full text-start p-5 rounded-2xl border transition-all ${selectedTicket?.id === ticket.id
                  ? 'bg-blue-600 border-blue-600 shadow-lg'
                  : 'theme-bg-secondary border-[var(--surface-border)] hover:border-gray-400/30 hover:shadow-md'
                  }`}
              >
                <div className="flex items-start justify-between gap-3 mb-2">
                  <h3 className={`font-black text-sm tracking-tight line-clamp-1 ${selectedTicket?.id === ticket.id ? 'text-white' : 'theme-heading'}`}>{ticket.subject}</h3>
                  {statusBadge(ticket.status)}
                </div>
                <div className={`flex items-center gap-2 text-[0.6875rem] font-bold ${selectedTicket?.id === ticket.id ? 'text-blue-100' : 'theme-muted'}`}>
                  <User className="h-3 w-3 opacity-60" />
                  <Link
                    href={`/users/${ticket.user_id}`}
                    className={`hover:underline ${selectedTicket?.id === ticket.id ? 'text-white' : 'text-blue-500'}`}
                    onClick={e => e.stopPropagation()}
                  >
                    {ticket.user?.full_name || t('common.unknown', 'Unknown')}
                  </Link>
                  <span className="opacity-30">|</span>
                  <span className="font-mono opacity-80">{formatDate(ticket.updated_at)}</span>
                </div>
              </button>
            ))
          )}
        </div>
      </div>

      {/* Right: Message Thread */}
      {selectedTicket && (
        <div className="flex-1 flex flex-col theme-card rounded-2xl border border-[var(--surface-border)] shadow-xl overflow-hidden min-w-0">
          {/* Header */}
          <div className="flex items-center gap-4 px-6 py-5 border-b border-[var(--surface-border)] theme-bg-secondary">
            <button
              onClick={() => setSelectedTicket(null)}
              className="lg:hidden p-2 hover:theme-bg-secondary rounded-xl transition theme-muted"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <div className="flex-1 min-w-0">
              <h2 className="text-lg font-black theme-heading tracking-tight truncate">{selectedTicket.subject}</h2>
              <div className="flex items-center gap-2 text-[0.6875rem] font-bold theme-muted mt-1">
                <Link href={`/users/${selectedTicket.user_id}`} className="text-blue-500 hover:underline">
                  {selectedTicket.user?.full_name || t('common.unknown', 'Unknown')}
                </Link>
                <span className="opacity-30">|</span>
                <span className="font-mono opacity-80">{formatDateTime(selectedTicket.created_at)}</span>
                <span className="opacity-30">|</span>
                {statusBadge(selectedTicket.status)}
              </div>
            </div>
            <div className="flex gap-2 flex-shrink-0">
              {selectedTicket.status === 'open' && (
                <>
                  <button
                    onClick={() => updateTicketStatus(selectedTicket.id, 'resolved')}
                    className="flex items-center gap-1.5 px-4 py-2 bg-green-500/10 text-green-600 hover:bg-green-500/20 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm border border-green-500/20"
                    title={t('support.actions.markResolved', 'Mark as resolved')}
                  >
                    <CheckCircle className="h-4 w-4" /> {t('support.actions.resolve', 'Resolve')}
                  </button>
                  <button
                    onClick={() => updateTicketStatus(selectedTicket.id, 'ignored')}
                    className="flex items-center gap-1.5 px-4 py-2 theme-bg-secondary theme-muted hover:theme-heading rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm border border-[var(--surface-border)]"
                    title={t('support.actions.markIgnored', 'Mark as ignored')}
                  >
                    <XCircle className="h-4 w-4" /> {t('support.actions.ignore', 'Ignore')}
                  </button>
                </>
              )}
              {selectedTicket.status !== 'open' && (
                <button
                  onClick={() => reopenTicket(selectedTicket.id)}
                  className="flex items-center gap-1.5 px-4 py-2 bg-amber-500/10 text-amber-600 hover:bg-amber-500/20 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm border border-amber-500/20"
                >
                  <Clock className="h-4 w-4" /> {t('support.actions.reopen', 'Reopen')}
                </button>
              )}
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto px-6 py-6 space-y-6 bg-[var(--surface-bg-alt)]/30 custom-scrollbar">
            {loadingMessages ? (
              <div className="flex items-center justify-center h-full">
                <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
              </div>
            ) : messagesError ? (
              <div className="flex h-full flex-col items-center justify-center gap-4 text-center theme-muted">
                <MessageSquare className="h-12 w-12 opacity-20" />
                <p className="text-sm font-medium">{messagesError}</p>
                <button
                  type="button"
                  onClick={() => selectedTicket && loadMessages(selectedTicket)}
                  className="px-4 py-2 rounded-xl font-black text-[0.625rem] uppercase tracking-widest transition-all shadow-sm"
                  style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}
                >
                  {t('common.retry', 'Retry')}
                </button>
              </div>
            ) : messages.length === 0 ? (
              <div className="text-center py-20 theme-muted">
                <MessageSquare className="h-12 w-12 mx-auto mb-3 opacity-20" />
                <p className="text-[0.625rem] font-black uppercase tracking-widest opacity-60">{t('support.messages.empty', 'No messages in this ticket')}</p>
              </div>
            ) : (
              messages.map(msg => {
                const isAdmin = msg.sender_role === 'admin';
                return (
                  <div
                    key={msg.id}
                    className={`flex ${isAdmin ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-[80%] rounded-2xl px-5 py-4 shadow-sm ${isAdmin
                        ? 'bg-blue-600 text-white rounded-br-none shadow-blue-500/20'
                        : 'theme-bg-secondary border border-[var(--surface-border)] theme-heading rounded-bl-none'
                        }`}
                    >
                      <div className={`flex items-center gap-1.5 mb-2 text-[0.5625rem] font-black uppercase tracking-widest ${isAdmin ? 'text-blue-100/60' : 'theme-muted opacity-60'}`}>
                        {isAdmin ? (
                          <><ShieldCheck className="h-3.5 w-3.5" /> {t('support.role.admin', 'Admin')}</>
                        ) : (
                          <><User className="h-3.5 w-3.5" /> {t('support.role.user', 'User')}</>
                        )}
                      </div>
                      <p className="text-[0.8125rem] leading-relaxed font-medium whitespace-pre-wrap break-words">{msg.content}</p>
                      <p className={`text-[0.5625rem] font-black uppercase font-mono mt-3 ${isAdmin ? 'text-blue-100/40' : 'theme-muted opacity-40'}`}>
                        {formatDateTime(msg.created_at)}
                      </p>
                    </div>
                  </div>
                );
              })
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Reply input */}
          <div className="border-t border-[var(--surface-border)] theme-bg-secondary px-6 py-4">
            {selectedTicket.status !== 'open' ? (
              <div className="flex items-center justify-between gap-4 rounded-2xl border border-[var(--surface-border)] bg-[var(--surface)] px-5 py-4">
                <p className="text-sm font-medium theme-muted">{t('support.reply.closed', 'This ticket is closed. Reopen it before replying.')}</p>
                <button
                  onClick={() => reopenTicket(selectedTicket.id)}
                  className="flex items-center gap-1.5 px-4 py-2 bg-amber-500/10 text-amber-600 hover:bg-amber-500/20 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm border border-amber-500/20"
                >
                  <Clock className="h-4 w-4" /> {t('support.actions.reopen', 'Reopen')}
                </button>
              </div>
            ) : (
            <div className="flex gap-4">
              <textarea
                value={replyText}
                onChange={e => setReplyText(e.target.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    sendReply();
                  }
                }}
                placeholder={t('support.reply.placeholder', 'Type your reply...')}
                className="flex-1 theme-bg-secondary rounded-2xl border border-[var(--surface-border)] px-5 py-3.5 text-sm theme-heading resize-none focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all shadow-inner custom-scrollbar"
                rows={2}
              />
              <button
                onClick={sendReply}
                disabled={sending || !replyText.trim()}
                className="self-end px-6 py-4 bg-blue-600 text-white rounded-2xl hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all flex items-center gap-2 text-[0.625rem] font-black uppercase tracking-widest shadow-lg shadow-blue-500/20"
              >
                {sending ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                ) : (
                  <Send className="h-4 w-4" />
                )}
                {sending ? t('support.reply.sending', 'Sending...') : t('support.reply.send', 'Send')}
              </button>
            </div>
            )}
          </div>
        </div>
      )}

      {/* Empty state when no ticket selected (desktop) */}
      {!selectedTicket && (
        <div className="hidden lg:flex flex-1 items-center justify-center bg-[var(--surface-bg-alt)]/30 rounded-2xl border border-dashed border-[var(--surface-border)]">
          <div className="text-center">
            <MessageSquare className="h-16 w-16 theme-muted mx-auto mb-4 opacity-20" />
            <p className="theme-muted font-black text-xl uppercase tracking-widest opacity-60">{t('support.empty.threadTitle', 'Select a ticket')}</p>
            <p className="theme-muted text-xs mt-2 font-medium opacity-40">{t('support.empty.threadSubtitle', 'Choose a ticket from the list to view the conversation.')}</p>
          </div>
        </div>
      )}
    </div>
  );
}
