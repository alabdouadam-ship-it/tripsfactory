'use client';

import { useState } from 'react';
import { Send, X } from 'lucide-react';
import { useT } from '@/lib/i18n';
import { useToast } from '@/lib/toast';
import { sendAdminNotification } from '@/app/actions/notification-actions';

type SendNotificationModalProps = {
  isOpen: boolean;
  onClose: () => void;
  userId: string;
  userName?: string | null;
  userPhone?: string | null;
};

export function SendNotificationModal({
  isOpen,
  onClose,
  userId,
  userName,
  userPhone,
}: SendNotificationModalProps) {
  const t = useT();
  const { toast } = useToast();
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);

  if (!isOpen) return null;

  const handleSend = async () => {
    if (!title.trim() || !body.trim()) {
      toast(t('users.detail.notif.error.required', 'Title and message are required'), 'error');
      return;
    }

    setSending(true);
    const res = await sendAdminNotification({
      mode: 'single',
      targetUserId: userId,
      title: title.trim(),
      body: body.trim(),
    });
    setSending(false);

    if (res.success) {
      toast(t('users.detail.notif.success', 'Notification sent successfully'), 'success');
      onClose();
      setTitle('');
      setBody('');
    } else {
      toast(res.error || t('users.detail.notif.error.failed', 'Failed to send notification'), 'error');
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="theme-card rounded-2xl shadow-2xl p-8 max-w-lg w-full border border-[var(--surface-border)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-black theme-heading uppercase tracking-tight flex items-center gap-2">
            <Send className="h-5 w-5 text-blue-500" />
            {t('users.detail.sendNotification', 'Send Notification')}
          </h2>
          <button
            onClick={onClose}
            className="theme-muted hover:theme-heading transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-xs font-black theme-heading uppercase tracking-widest mb-2">
              {t('users.detail.notif.recipient', 'Recipient')}
            </label>
            <div className="theme-bg-secondary p-3 rounded-lg border border-[var(--surface-border)]">
              <p className="text-sm font-bold theme-heading">
                {userName || t('common.unknown', 'Unknown')}
              </p>
              <p className="text-xs theme-muted">{userPhone || t('common.na', 'N/A')}</p>
            </div>
          </div>

          <div>
            <label className="block text-xs font-black theme-heading uppercase tracking-widest mb-2">
              {t('users.detail.notif.title', 'Title')} *
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-4 py-3 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 outline-none"
              placeholder={t('users.detail.notif.titlePlaceholder', 'Enter notification title')}
              maxLength={100}
            />
          </div>

          <div>
            <label className="block text-xs font-black theme-heading uppercase tracking-widest mb-2">
              {t('users.detail.notif.message', 'Message')} *
            </label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg px-4 py-3 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 outline-none resize-none"
              placeholder={t('users.detail.notif.messagePlaceholder', 'Enter notification message')}
              rows={4}
              maxLength={500}
            />
            <p className="text-xs theme-muted mt-1 text-right">{body.length}/500</p>
          </div>

          <div className="flex gap-3 pt-4">
            <button
              onClick={onClose}
              className="flex-1 px-4 py-3 rounded-xl text-sm font-black uppercase tracking-widest theme-bg-secondary theme-muted hover:theme-heading transition-all border border-[var(--surface-border)]"
            >
              {t('common.cancel', 'Cancel')}
            </button>
            <button
              onClick={handleSend}
              disabled={sending || !title.trim() || !body.trim()}
              className="flex-1 px-4 py-3 rounded-xl text-sm font-black uppercase tracking-widest bg-blue-600 text-white hover:bg-blue-700 transition-all shadow-lg shadow-blue-600/20 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {sending ? (
                <>
                  <div className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  {t('common.sending', 'Sending...')}
                </>
              ) : (
                <>
                  <Send className="h-4 w-4" />
                  {t('common.send', 'Send')}
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
