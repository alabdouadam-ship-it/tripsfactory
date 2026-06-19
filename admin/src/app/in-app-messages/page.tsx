'use client';

import { useCallback, useEffect, useState } from 'react';
import type { ReactNode } from 'react';
import Image from 'next/image';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';
import { AppSettings } from '@/lib/types';
import { getAppSettings, updateAppSettings, setAppOpen, bumpPopupVersion, publishOccasionalPopup } from '@/app/actions/content-actions';
import {
  Globe, AlertTriangle, Save, Power, MessageSquare, Bell, ImageIcon,
  Lock, Unlock, RefreshCw, Megaphone, Smartphone,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import Loading from '@/app/loading';

type SectionId = 'switch' | 'banner' | 'popup' | 'occasional' | 'version';

export default function ContentPage() {
  const { toast } = useToast();
  const t = useT();
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [section, setSection] = useState<SectionId>('switch');
  const [draft, setDraft] = useState<Partial<AppSettings>>({});

  const fetchSettings = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    const res = await getAppSettings();
    if (res.success) {
      setSettings(res.data);
      setDraft({});
    } else {
      const message = res.error || t('content.error.loadFailed', 'Failed to load app settings.');
      setLoadError(message);
      setSettings(null);
      toast(message, 'error');
    }
    setLoading(false);
  }, [t, toast]);

  useEffect(() => {
    queueMicrotask(() => {
      void fetchSettings();
    });
  }, [fetchSettings]);

  function patch<K extends keyof AppSettings>(key: K, value: AppSettings[K]) {
    setDraft(d => ({ ...d, [key]: value }));
  }

  function get<K extends keyof AppSettings>(key: K): AppSettings[K] | undefined {
    return draft[key] ?? settings?.[key];
  }

  async function save() {
    setSaving(true);
    const res = await updateAppSettings(draft);
    setSaving(false);
    if (res.success) {
      toast(t('content.toast.saved', 'Settings saved'), 'success');
      await fetchSettings();
    } else {
      toast(res.error || 'Save failed', 'error');
    }
  }

  async function toggleAppOpen() {
    const next = !(get('app_open') ?? true);
    const message = next ? null : prompt(t('content.closedMessage.prompt', 'Enter the message users see while the app is closed (optional):')) ?? null;
    setSaving(true);
    const res = await setAppOpen(next, message ?? undefined);
    setSaving(false);
    if (res.success) {
      toast(next ? t('content.app.opened', 'App opened') : t('content.app.closed', 'App closed'), 'success');
      await fetchSettings();
    } else {
      toast(res.error || 'Failed', 'error');
    }
  }

  async function publishPopup() {
    setSaving(true);
    const res = await bumpPopupVersion();
    setSaving(false);
    if (res.success) {
      toast(t('content.popup.published', 'Popup version bumped — clients will re-show on next launch'), 'success');
      await fetchSettings();
    } else {
      toast(res.error || 'Failed', 'error');
    }
  }

  async function publishOccasional() {
    setSaving(true);
    const res = await publishOccasionalPopup();
    setSaving(false);
    if (res.success) {
      toast(t('content.occasional.published', 'Occasional popup published — users will see within 3 hours'), 'success');
      await fetchSettings();
    } else {
      toast(res.error || 'Failed', 'error');
    }
  }

  if (loading) return <Loading />;
  if (!settings) {
    return (
      <div className="p-12 text-center">
        <p className="theme-muted">{loadError || t('content.error.noSettings', 'No app_settings row found. Run migration 00042.')}</p>
      </div>
    );
  }

  const dirty = Object.keys(draft).length > 0;

  const sections: { id: SectionId; label: string; icon: LucideIcon }[] = [
    { id: 'switch', label: t('content.section.switch', 'App Switch'), icon: Power },
    { id: 'banner', label: t('content.section.banner', 'Global Banner'), icon: Megaphone },
    { id: 'popup', label: t('content.section.popup', 'First-launch Popup'), icon: Bell },
    { id: 'occasional', label: t('content.section.occasional', 'Occasional Popup'), icon: MessageSquare },
    { id: 'version', label: t('content.section.version', 'Version Control'), icon: Smartphone },
  ];

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight flex items-center gap-3">
            <Globe className="h-7 w-7 text-orange-500" />
            {t('content.title', 'In-App Messages')}
          </h1>
          <p className="theme-muted text-sm mt-1">
            {t('content.subtitle', 'Manage maintenance messages, popups, and announcements shown to users.')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={save}
            disabled={!dirty || saving}
            className="flex items-center gap-2 bg-orange-600 text-white px-5 py-2 rounded-xl hover:bg-orange-700 transition shadow-sm font-bold text-xs uppercase tracking-widest disabled:opacity-50"
          >
            <Save className="h-4 w-4" /> {saving ? t('common.saving', 'Saving...') : t('common.save', 'Save changes')}
          </button>
        </div>
      </div>

      <div className="flex flex-wrap gap-2">
        {sections.map(s => {
          const Icon = s.icon;
          return (
            <button
              key={s.id}
              onClick={() => setSection(s.id)}
              className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest border transition ${
                section === s.id
                  ? 'bg-orange-600 text-white border-orange-600 shadow-sm'
                  : 'theme-bg-secondary theme-muted border-[var(--surface-border)] hover:theme-heading'
              }`}
            >
              <Icon className="h-4 w-4" />
              {s.label}
            </button>
          );
        })}
      </div>

      {/* Switch */}
      {section === 'switch' && (
        <div className="theme-card rounded-2xl p-6 border border-[var(--surface-border)] shadow-sm space-y-5">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-black theme-heading">{t('content.app.title', 'Global app availability')}</h2>
              <p className="text-sm theme-muted mt-1">{t('content.app.help', 'When closed, the mobile app shows a maintenance screen and blocks all flows.')}</p>
            </div>
            <button
              onClick={toggleAppOpen}
              disabled={saving}
              className={`flex items-center gap-2 px-6 py-3 rounded-xl text-sm font-black uppercase tracking-widest transition shadow-md disabled:opacity-50 ${
                get('app_open') !== false ? 'bg-green-600 text-white hover:bg-green-700' : 'bg-red-600 text-white hover:bg-red-700'
              }`}
            >
              {get('app_open') !== false ? <Unlock className="h-4 w-4" /> : <Lock className="h-4 w-4" />}
              {get('app_open') !== false ? t('content.app.openLabel', 'Open') : t('content.app.closedLabel', 'Closed')}
            </button>
          </div>
          <div className="grid md:grid-cols-2 gap-4">
            <Field label={t('content.closedMessage.en', 'Closed message (English)')}>
              <textarea rows={3} value={get('closed_message') ?? ''} onChange={e => patch('closed_message', e.target.value)} className={inputCls + ' resize-none'} placeholder={t('content.closedMessage.placeholder', 'Optional message shown while the app is closed.')} />
            </Field>
            <Field label={t('content.closedMessage.ar', 'Closed message (Arabic)')}>
              <textarea rows={3} dir="rtl" value={get('closed_message_ar') ?? ''} onChange={e => patch('closed_message_ar', e.target.value)} className={inputCls + ' resize-none'} />
            </Field>
          </div>
        </div>
      )}

      {/* Global Banner */}
      {section === 'banner' && (
        <div className="theme-card rounded-2xl p-6 border border-[var(--surface-border)] shadow-sm space-y-5">
          <div>
            <h2 className="text-xl font-black theme-heading flex items-center gap-2">
              <Megaphone className="h-5 w-5 text-blue-500" />
              {t('content.banner.title', 'Global Banner Message')}
            </h2>
            <p className="text-sm theme-muted mt-1">
              {t('content.banner.help', 'Show a dismissible banner at the top of the home screen. Good for urgent, temporary announcements.')}
            </p>
          </div>

          <label className="flex items-center gap-2">
            <input 
              type="checkbox" 
              checked={!!get('global_message_active')} 
              onChange={e => patch('global_message_active', e.target.checked)} 
              className="rounded border-[var(--surface-border)] w-4 h-4 text-blue-600" 
            />
            <span className="text-sm theme-heading">{t('content.banner.active', 'Active (show banner to users)')}</span>
          </label>

          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-sm text-blue-800">
            <p className="font-bold mb-1">💡 {t('content.banner.howItWorks', 'How it works')}</p>
            <ul className="list-disc list-inside space-y-1 text-xs">
              <li>{t('content.banner.step1', 'Banner appears at top of home screen with megaphone icon')}</li>
              <li>{t('content.banner.step2', 'Users can dismiss it with the X button')}</li>
              <li>{t('content.banner.step3', 'If you change the message, users will see it again')}</li>
              <li>{t('content.banner.step4', 'Changes propagate within 3 hours (app config cache)')}</li>
            </ul>
          </div>

          <Field label={t('content.banner.message', 'Banner Message')}>
            <textarea 
              rows={3} 
              value={get('global_message_content') ?? ''} 
              onChange={e => patch('global_message_content', e.target.value)} 
              className={inputCls + ' resize-none'} 
              placeholder={t('content.banner.placeholder', 'e.g., Service temporarily unavailable in Damascus | الخدمة غير متاحة مؤقتاً في دمشق')}
            />
          </Field>

          <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-3 text-xs text-yellow-800">
            <strong>{t('content.banner.tip', 'Tip')}:</strong> {t('content.banner.tipText', 'Keep it short (1-2 lines). You can write bilingual text in one field separated by | symbol.')}
          </div>
        </div>
      )}

      {/* Popup */}
      {section === 'popup' && (
        <div className="theme-card rounded-2xl p-6 border border-[var(--surface-border)] shadow-sm space-y-5">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-black theme-heading flex items-center gap-2">
                <Bell className="h-5 w-5 text-purple-500" />
                {t('content.popup.title', 'First-launch popup')}
              </h2>
              <p className="text-sm theme-muted mt-1">{t('content.popup.help', 'Shown to users on app launch. Bump the version to re-show after edits.')}</p>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[0.625rem] theme-muted font-bold uppercase">v{get('first_launch_popup_version') ?? 0}</span>
              <button
                onClick={publishPopup}
                disabled={saving}
                className="flex items-center gap-2 px-4 py-2 rounded-xl bg-purple-600 text-white text-xs font-black uppercase tracking-widest hover:bg-purple-700 transition shadow-sm disabled:opacity-50"
              >
                <RefreshCw className="h-4 w-4" /> {t('content.popup.publish', 'Publish version')}
              </button>
            </div>
          </div>
          <label className="flex items-center gap-2">
            <input type="checkbox" checked={!!get('first_launch_popup_active')} onChange={e => patch('first_launch_popup_active', e.target.checked)} className="rounded border-[var(--surface-border)] w-4 h-4 text-purple-600" />
            <span className="text-sm theme-heading">{t('content.popup.active', 'Active (show popup to users)')}</span>
          </label>

          <div className="grid md:grid-cols-2 gap-4">
            <Field label={t('content.popup.titleEn', 'Title (English)')}>
              <input value={get('first_launch_popup_title') ?? ''} onChange={e => patch('first_launch_popup_title', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('content.popup.titleAr', 'Title (Arabic)')}>
              <input dir="rtl" value={get('first_launch_popup_title_ar') ?? ''} onChange={e => patch('first_launch_popup_title_ar', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('content.popup.bodyEn', 'Body (English)')}>
              <textarea rows={4} value={get('first_launch_popup_body') ?? ''} onChange={e => patch('first_launch_popup_body', e.target.value)} className={inputCls + ' resize-none'} />
            </Field>
            <Field label={t('content.popup.bodyAr', 'Body (Arabic)')}>
              <textarea rows={4} dir="rtl" value={get('first_launch_popup_body_ar') ?? ''} onChange={e => patch('first_launch_popup_body_ar', e.target.value)} className={inputCls + ' resize-none'} />
            </Field>
            <Field label={t('content.popup.imageUrl', 'Image URL')}>
              <input value={get('first_launch_popup_image_url') ?? ''} onChange={e => patch('first_launch_popup_image_url', e.target.value)} className={inputCls} placeholder="https://..." />
            </Field>
            <Field label={t('content.popup.actionUrl', 'Action URL (optional)')}>
              <input value={get('first_launch_popup_action_url') ?? ''} onChange={e => patch('first_launch_popup_action_url', e.target.value)} className={inputCls} placeholder="tripship://route or https://..." />
            </Field>
            <Field label={t('content.popup.target', 'Target audience')}>
              <select
                value={get('first_launch_popup_target') ?? 'all'}
                onChange={e => patch('first_launch_popup_target', e.target.value as AppSettings['first_launch_popup_target'])}
                className={inputCls}
              >
                <option value="all">All users</option>
                <option value="individuals">Individuals only</option>
                <option value="drivers">Drivers / Travelers only</option>
                <option value="companies">Merchants / Companies only</option>
                <option value="new_users">New users only</option>
              </select>
            </Field>
          </div>

          {get('first_launch_popup_image_url') && (
            <div className="theme-bg-secondary rounded-xl border border-[var(--surface-border)] p-4 flex items-start gap-3">
              <ImageIcon className="h-5 w-5 theme-muted mt-0.5" />
              <div className="flex-1">
                <p className="text-xs font-bold theme-heading mb-2">{t('content.popup.preview', 'Preview')}</p>
                <Image
                  src={String(get('first_launch_popup_image_url'))}
                  alt="popup"
                  width={320}
                  height={160}
                  unoptimized
                  className="max-h-40 rounded-lg border border-[var(--surface-border)]"
                />
              </div>
            </div>
          )}
        </div>
      )}

      {/* Occasional Popup */}
      {section === 'occasional' && (
        <div className="theme-card rounded-2xl p-6 border border-[var(--surface-border)] shadow-sm space-y-5">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-xl font-black theme-heading flex items-center gap-2">
                <MessageSquare className="h-5 w-5 text-orange-500" />
                {t('content.occasional.title', 'Occasional Popup')}
              </h2>
              <p className="text-sm theme-muted mt-1">{t('content.occasional.help', 'Send announcements anytime. Users see it once within 3 hours of next app launch.')}</p>
            </div>
            <div className="flex items-center gap-2">
              {get('occasional_popup_published_at') && (
                <span className="text-[0.625rem] theme-muted font-bold uppercase">
                  Last: {new Date(get('occasional_popup_published_at')!).toLocaleString()}
                </span>
              )}
              <button
                onClick={publishOccasional}
                disabled={saving || !get('occasional_popup_active')}
                className="flex items-center gap-2 px-4 py-2 rounded-xl bg-orange-600 text-white text-xs font-black uppercase tracking-widest hover:bg-orange-700 transition shadow-sm disabled:opacity-50"
              >
                <RefreshCw className="h-4 w-4" /> {t('content.occasional.publish', 'Publish Now')}
              </button>
            </div>
          </div>
          <label className="flex items-center gap-2">
            <input type="checkbox" checked={!!get('occasional_popup_active')} onChange={e => patch('occasional_popup_active', e.target.checked)} className="rounded border-[var(--surface-border)] w-4 h-4 text-orange-600" />
            <span className="text-sm theme-heading">{t('content.occasional.active', 'Active (enable popup)')}</span>
          </label>

          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-sm text-blue-800">
            <p className="font-bold mb-1">💡 {t('content.occasional.howItWorks', 'How it works')}</p>
            <ul className="list-disc list-inside space-y-1 text-xs">
              <li>{t('content.occasional.step1', 'Edit popup content and save changes')}</li>
              <li>{t('content.occasional.step2', 'Click "Publish Now" to send to users')}</li>
              <li>{t('content.occasional.step3', 'Users see it once within 3 hours of next app launch')}</li>
              <li>{t('content.occasional.step4', 'Each user sees it only once per publish')}</li>
            </ul>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            <Field label={t('content.occasional.titleEn', 'Title (English)')}>
              <input value={get('occasional_popup_title') ?? ''} onChange={e => patch('occasional_popup_title', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('content.occasional.titleAr', 'Title (Arabic)')}>
              <input dir="rtl" value={get('occasional_popup_title_ar') ?? ''} onChange={e => patch('occasional_popup_title_ar', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('content.occasional.bodyEn', 'Body (English)')}>
              <textarea rows={4} value={get('occasional_popup_body') ?? ''} onChange={e => patch('occasional_popup_body', e.target.value)} className={inputCls + ' resize-none'} />
            </Field>
            <Field label={t('content.occasional.bodyAr', 'Body (Arabic)')}>
              <textarea rows={4} dir="rtl" value={get('occasional_popup_body_ar') ?? ''} onChange={e => patch('occasional_popup_body_ar', e.target.value)} className={inputCls + ' resize-none'} />
            </Field>
            <Field label={t('content.occasional.imageUrl', 'Image URL')}>
              <input value={get('occasional_popup_image_url') ?? ''} onChange={e => patch('occasional_popup_image_url', e.target.value)} className={inputCls} placeholder="https://..." />
            </Field>
            <Field label={t('content.occasional.actionUrl', 'Action URL (optional)')}>
              <input value={get('occasional_popup_action_url') ?? ''} onChange={e => patch('occasional_popup_action_url', e.target.value)} className={inputCls} placeholder="tripship://route or https://..." />
            </Field>
            <Field label={t('content.occasional.target', 'Target audience')}>
              <select
                value={get('occasional_popup_target') ?? 'all'}
                onChange={e => patch('occasional_popup_target', e.target.value as AppSettings['occasional_popup_target'])}
                className={inputCls}
              >
                <option value="all">All users</option>
                <option value="individuals">Individuals only</option>
                <option value="drivers">Drivers / Travelers only</option>
                <option value="companies">Merchants / Companies only</option>
                <option value="new_users">New users only</option>
              </select>
            </Field>
          </div>

          {get('occasional_popup_image_url') && (
            <div className="theme-bg-secondary rounded-xl border border-[var(--surface-border)] p-4 flex items-start gap-3">
              <ImageIcon className="h-5 w-5 theme-muted mt-0.5" />
              <div className="flex-1">
                <p className="text-xs font-bold theme-heading mb-2">{t('content.occasional.preview', 'Preview')}</p>
                <Image
                  src={String(get('occasional_popup_image_url'))}
                  alt="occasional popup"
                  width={320}
                  height={160}
                  unoptimized
                  className="max-h-40 rounded-lg border border-[var(--surface-border)]"
                />
              </div>
            </div>
          )}
        </div>
      )}

      {/* Version Control */}
      {section === 'version' && (
        <div className="theme-card rounded-2xl p-6 border border-[var(--surface-border)] shadow-sm space-y-5">
          <div>
            <h2 className="text-xl font-black theme-heading flex items-center gap-2">
              <Smartphone className="h-5 w-5 text-blue-500" />
              {t('content.version.title', 'Version Control')}
            </h2>
            <p className="text-sm theme-muted mt-1">
              {t('content.version.help', 'Control minimum app versions required for Android and iOS users.')}
            </p>
          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-sm text-blue-800">
            <p className="font-bold mb-1">💡 {t('content.version.howItWorks', 'How it works')}</p>
            <ul className="list-disc list-inside space-y-1 text-xs">
              <li>{t('content.version.step1', 'Set minimum version for Android and iOS')}</li>
              <li>{t('content.version.step2', 'Users with older versions will be forced to update')}</li>
              <li>{t('content.version.step3', 'Customize the force update message shown to users')}</li>
              <li>{t('content.version.step4', 'Changes propagate within 3 hours (app config cache)')}</li>
            </ul>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            <Field label={t('content.version.androidMinVersion', 'Android Minimum Version')}>
              <input
                type="text"
                value={get('android_min_version') ?? ''}
                onChange={e => patch('android_min_version', e.target.value)}
                className={inputCls}
                placeholder="e.g., 3.2.1"
              />
            </Field>
            <Field label={t('content.version.iosMinVersion', 'iOS Minimum Version')}>
              <input
                type="text"
                value={get('ios_min_version') ?? ''}
                onChange={e => patch('ios_min_version', e.target.value)}
                className={inputCls}
                placeholder="e.g., 3.2.1"
              />
            </Field>
          </div>

          <Field label={t('content.version.forceUpdateMessage', 'Force Update Message')}>
            <textarea
              rows={3}
              value={get('force_update_message') ?? ''}
              onChange={e => patch('force_update_message', e.target.value)}
              className={inputCls + ' resize-none'}
              placeholder={t('content.version.forceUpdatePlaceholder', 'e.g., Please update to the latest version to continue using TripShip.')}
            />
          </Field>

          <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-3 text-xs text-yellow-800">
            <strong>{t('content.version.note', 'Note')}:</strong> {t('content.version.noteText', 'Users with app versions below the minimum will be forced to update. Changes propagate within 3 hours.')}
          </div>
        </div>
      )}

      {dirty && (
        <div className="fixed bottom-6 right-6 bg-orange-600 text-white px-5 py-3 rounded-xl shadow-2xl flex items-center gap-3 text-sm font-bold">
          <AlertTriangle className="h-4 w-4" />
          {t('content.unsaved', 'Unsaved changes')}
          <button onClick={save} disabled={saving} className="bg-white text-orange-600 px-3 py-1 rounded-lg font-black uppercase text-xs disabled:opacity-50">
            {t('common.save', 'Save')}
          </button>
        </div>
      )}
    </div>
  );
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{label}</label>
      {children}
    </div>
  );
}

const inputCls = 'w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 outline-none';
