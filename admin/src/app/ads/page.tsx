'use client';

import { useEffect, useState, useRef } from 'react';
import Image from 'next/image';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Megaphone, Plus, Edit2, Trash2, ToggleLeft, ToggleRight, X, Save, ExternalLink, Image as ImageIcon, Upload, AlertTriangle, RefreshCw, Info } from 'lucide-react';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import { useT } from '@/lib/i18n';

type Ad = {
  id: string;
  image_url: string | null;
  click_url: string | null;
  is_active: boolean;
  created_at: string;
  updated_at?: string | null;
};

export default function AdsPage() {
  const { toast, confirm: confirmDialog } = useToast();
  const t = useT();
  const [ads, setAds] = useState<Ad[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [imageUrl, setImageUrl] = useState('');
  const [clickUrl, setClickUrl] = useState('');
  const [isActive, setIsActive] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [imagePreviewFailed, setImagePreviewFailed] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { fetchAds(); }, []);

  async function ensureAdminSession() {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
      toast(t('ads.toast.loginRequired', 'Please log in again.'), 'error');
      window.location.href = '/login';
      return false;
    }

    const { data: isAdmin, error } = await supabase.rpc('is_admin');
    if (error || !isAdmin) {
      toast(t('common.unauthorized', 'You are not authorized to perform this action.'), 'error');
      return false;
    }

    return true;
  }

  function formatSupabaseError(error: unknown): string {
    if (!error) return 'Unknown error';
    if (typeof error === 'object' && error !== null) {
      const withMessage = error as { message?: unknown; details?: unknown };
      if (typeof withMessage.message === 'string' && withMessage.message.trim()) return withMessage.message;
      if (typeof withMessage.details === 'string' && withMessage.details.trim()) return withMessage.details;
    }
    return 'Unknown error';
  }

  function isFetchTransportError(error: unknown): boolean {
    const message = formatSupabaseError(error);
    return /failed to fetch/i.test(message) || /networkerror/i.test(message);
  }

  function isHttpUrl(value: string): boolean {
    try {
      const url = new URL(value.trim());
      return url.protocol === 'http:' || url.protocol === 'https:';
    } catch {
      return false;
    }
  }

  function isOptionalHttpUrl(value: string): boolean {
    return !value.trim() || isHttpUrl(value);
  }

  function setImageUrlValue(value: string) {
    setImageUrl(value);
    setImagePreviewFailed(false);
  }

  function getStoredAdImagePath(value: string | null): string | null {
    if (!value) return null;
    try {
      const url = new URL(value);
      const marker = '/storage/v1/object/public/ads/';
      const markerIndex = url.pathname.indexOf(marker);
      if (markerIndex < 0) return null;
      const path = url.pathname.slice(markerIndex + marker.length);
      return path ? decodeURIComponent(path) : null;
    } catch {
      return null;
    }
  }

  async function updateAdWithFallback(
    adId: string,
    payload: { image_url: string; click_url: string | null; is_active: boolean }
  ): Promise<{ error: unknown | null; usedFallback: boolean }> {
    let updateError: unknown = null;

    try {
      const { error } = await supabase.from('ads').update(payload).eq('id', adId);
      updateError = error;
    } catch (error: unknown) {
      updateError = error;
    }

    if (!updateError) return { error: null, usedFallback: false };
    if (!isFetchTransportError(updateError)) return { error: updateError, usedFallback: false };

    try {
      const { error: upsertError } = await supabase
        .from('ads')
        .upsert({ id: adId, ...payload }, { onConflict: 'id' });
      return { error: upsertError, usedFallback: true };
    } catch (fallbackError: unknown) {
      return { error: fallbackError, usedFallback: true };
    }
  }

  async function fetchAds() {
    setLoading(true);
    setLoadError(null);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        toast(t('ads.toast.loginRequired', 'Please log in again.'), 'error');
        window.location.href = '/login';
        return;
      }

      const { data, error } = await supabase.from('ads').select('*').order('updated_at', { ascending: false });
      if (error) throw error;
      setAds((data as Ad[]) || []);
    } catch (error: unknown) {
      const message = formatSupabaseError(error);
      console.error('Ads load error:', error);
      setAds([]);
      setLoadError(message);
      toast(`${t('ads.toast.loadFailed', 'Failed to load ads')}: ${message}`, 'error');
    } finally {
      setLoading(false);
    }
  }

  function openCreate() { setImageUrlValue(''); setClickUrl(''); setIsActive(true); setEditId(null); setShowForm(true); }
  function openEdit(ad: Ad) { setImageUrlValue(ad.image_url || ''); setClickUrl(ad.click_url || ''); setIsActive(ad.is_active); setEditId(ad.id); setShowForm(true); }

  async function handleFileUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploading(true);
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
      const filePath = `${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('ads')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('ads')
        .getPublicUrl(filePath);

      setImageUrlValue(publicUrl);
      toast(t('ads.toast.imageUploaded', 'Image uploaded successfully'), 'success');
    } catch (error: unknown) {
      console.error('Upload error:', error);
      toast(`${t('ads.toast.uploadFailed', 'Failed to upload image')}: ${formatSupabaseError(error)}`, 'error');
    } finally {
      setUploading(false);
      // Reset input so same file can be selected again if needed
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  }

  async function saveAd() {
    if (!imageUrl.trim()) { toast(t('ads.toast.imageRequired'), 'error'); return; }
    if (!isHttpUrl(imageUrl)) { toast(t('ads.toast.invalidImageUrl', 'Image URL must start with http:// or https://'), 'error'); return; }
    if (!isOptionalHttpUrl(clickUrl)) { toast(t('ads.toast.invalidClickUrl', 'Click URL must start with http:// or https://'), 'error'); return; }
    if (!(await ensureAdminSession())) return;
    setSaving(true);
    const payload = { image_url: imageUrl.trim(), click_url: clickUrl.trim() || null, is_active: isActive };
    let auditTargetId = editId;
    if (editId) {
      const { error, usedFallback } = await updateAdWithFallback(editId, payload);
      if (error) {
        console.error('Update Error:', error);
        toast(`${t('ads.toast.updateFailed')}: ${formatSupabaseError(error)}`, 'error');
        setSaving(false);
        return;
      }
      if (usedFallback) {
        toast(t('ads.toast.networkRecovered', 'Network transport recovered with fallback request.'), 'success');
      }
      toast(t('ads.toast.adUpdated'), 'success');
    } else {
      const { data, error } = await supabase.from('ads').insert(payload).select('id').single();
      if (error) {
        console.error('Create Error:', error);
        toast(`${t('ads.toast.createFailed')}: ${formatSupabaseError(error)}`, 'error');
        setSaving(false);
        return;
      }
      auditTargetId = data?.id ?? null;
      toast(t('ads.toast.adCreated'), 'success');
    }
    await logAdminAction(editId ? 'update_ad' : 'create_ad', 'ad', auditTargetId, payload);
    setSaving(false); setShowForm(false); fetchAds();
  }

  async function toggleActive(ad: Ad) {
    if (!(await ensureAdminSession())) return;
    try {
      const { error, usedFallback } = await updateAdWithFallback(ad.id, {
        image_url: ad.image_url ?? '',
        click_url: ad.click_url ?? null,
        is_active: !ad.is_active,
      });
      if (error) {
        console.error('Toggle ad error:', error);
        toast(`${t('ads.toast.updateFailed')}: ${formatSupabaseError(error)}`, 'error');
        return;
      }
      setAds(prev => prev.map(a => a.id === ad.id ? { ...a, is_active: !a.is_active } : a));
      await logAdminAction('toggle_ad', 'ad', ad.id, { is_active: !ad.is_active });
      if (usedFallback) {
        toast(t('ads.toast.networkRecovered', 'Network transport recovered with fallback request.'), 'success');
      }
      toast(t('ads.toast.toggleSuccess', 'Ad status updated'), 'success');
    } catch (error: unknown) {
      console.error('Unexpected toggle error:', error);
      toast(`${t('ads.toast.updateFailed')}: ${formatSupabaseError(error)}`, 'error');
    }
  }

  async function deleteAd(ad: Ad) {
    if (!(await ensureAdminSession())) return;
    confirmDialog({
      title: t('ads.dialog.deleteTitle'), message: t('ads.dialog.deleteMessage'), confirmLabel: t('ads.dialog.deleteLabel'),
      onConfirm: async () => {
        const { error } = await supabase.from('ads').delete().eq('id', ad.id);
        if (error) { toast(`${t('ads.toast.deleteFailed')}: ${formatSupabaseError(error)}`, 'error'); return; }
        await logAdminAction('delete_ad', 'ad', ad.id);
        const storagePath = getStoredAdImagePath(ad.image_url);
        if (storagePath) {
          const { error: storageError } = await supabase.storage.from('ads').remove([storagePath]);
          if (storageError) {
            toast(`${t('ads.toast.imageDeleteFailed', 'Ad deleted, but the stored image could not be removed')}: ${formatSupabaseError(storageError)}`, 'error');
            fetchAds();
            return;
          }
        }
        toast(t('ads.toast.adDeleted'), 'success'); fetchAds();
      }
    });
  }

  if (loading) return <Loading />;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">{t('ads.title')}</h1>
          <p className="theme-muted text-sm mt-1 font-medium">{t('ads.subtitle')}</p>
        </div>
        <button onClick={openCreate} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition shadow-sm font-bold text-xs uppercase">
          <Plus className="h-4 w-4" /> {t('ads.create')}
        </button>
      </div>

      <div className="theme-bg-secondary border border-[var(--surface-border)] rounded-2xl p-4 flex gap-3">
        <Info className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
        <div>
          <p className="text-sm font-black theme-heading">{t('ads.notice.title', 'App display rule')}</p>
          <p className="text-xs theme-muted mt-1 leading-relaxed">{t('ads.notice.body', 'The mobile app shows the last updated active ad. Editing or activating an ad can make it the visible banner.')}</p>
        </div>
      </div>

      {loadError && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-2xl p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex gap-3">
            <AlertTriangle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-black text-red-600">{t('ads.error.loadTitle', 'Ads could not be loaded')}</p>
              <p className="text-xs theme-muted mt-1">{loadError}</p>
            </div>
          </div>
          <button
            onClick={fetchAds}
            className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl bg-red-600 text-white text-[0.625rem] font-black uppercase tracking-widest"
          >
            <RefreshCw className="h-3.5 w-3.5" /> {t('common.retry', 'Retry')}
          </button>
        </div>
      )}

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {ads.map(ad => (
          <div key={ad.id} className={`bg-[var(--surface)] rounded-2xl border ${ad.is_active ? 'border-green-500/30' : 'border-[var(--surface-border)]'} shadow-sm overflow-hidden hover:shadow-lg transition-all group`}>
            <div className="aspect-[16/9] theme-bg-secondary relative overflow-hidden">
              {ad.image_url && isHttpUrl(ad.image_url) ? (
                <Image
                  src={ad.image_url}
                  alt={t('ads.altBanner')}
                  fill
                  unoptimized
                  sizes="(max-width: 768px) 100vw, (max-width: 1280px) 50vw, 33vw"
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="flex items-center justify-center h-full">
                  <div className="text-center">
                    <ImageIcon className="h-12 w-12 theme-muted opacity-20 mx-auto mb-2" />
                    {ad.image_url && <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-50">{t('ads.preview.invalidUrl', 'Invalid image URL')}</p>}
                  </div>
                </div>
              )}
              <div className="absolute top-2 right-2">
                <span className={`px-2 py-1 rounded-lg text-[0.625rem] font-black uppercase tracking-widest shadow ${ad.is_active ? 'bg-green-500 text-white' : 'bg-gray-500 text-white'}`}>
                  {ad.is_active ? t('ads.status.active') : t('ads.status.inactive')}
                </span>
              </div>
            </div>
            <div className="p-4">
              <div className="flex items-center justify-between mb-2">
                <p className="text-[0.625rem] theme-muted font-mono">{ad.id.slice(0, 8)}</p>
                <p className="text-[0.625rem] theme-muted">{t('ads.lastUpdated', 'Updated')}: {new Date(ad.updated_at || ad.created_at).toLocaleDateString()}</p>
              </div>
              {ad.click_url && (
                <a href={ad.click_url} target="_blank" rel="noreferrer" className="text-xs text-blue-600 hover:underline flex items-center gap-1 mb-3 truncate">
                  <ExternalLink className="h-3 w-3 flex-shrink-0" /> {ad.click_url}
                </a>
              )}
              <div className="flex items-center justify-between pt-3 border-t border-[var(--surface-border)]">
                <button onClick={() => toggleActive(ad)} className="theme-muted hover:text-blue-600 transition">
                  {ad.is_active ? <ToggleRight className="h-6 w-6 text-green-500" /> : <ToggleLeft className="h-6 w-6 theme-bg-secondary" />}
                </button>
                <div className="flex gap-1">
                  <button onClick={() => openEdit(ad)} className="p-2 theme-muted hover:text-blue-600 hover:bg-blue-500/10 rounded-lg transition"><Edit2 className="h-4 w-4" /></button>
                  <button onClick={() => deleteAd(ad)} className="p-2 theme-muted hover:text-red-600 hover:bg-red-500/10 rounded-lg transition"><Trash2 className="h-4 w-4" /></button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {ads.length === 0 && !loadError && (
        <div className="text-center py-20 bg-[var(--surface)] rounded-2xl border border-dashed border-[var(--surface-border)]">
          <Megaphone className="h-12 w-12 theme-muted opacity-20 mx-auto mb-3" />
          <p className="theme-muted font-bold uppercase tracking-widest text-sm">{t('ads.empty')}</p>
        </div>
      )}

      {/* Create/Edit Modal */}
      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4 overflow-hidden">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-black theme-heading">{editId ? t('ads.form.editTitle') : t('ads.form.createTitle')}</h3>
              <button onClick={() => setShowForm(false)} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1.5 block">{t('ads.form.imageUrl')}</label>

                {/* File Upload Area */}
                <div className="flex items-center gap-2 mb-3">
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    ref={fileInputRef}
                    onChange={handleFileUpload}
                  />
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploading}
                    className="flex items-center gap-2 px-4 py-2 theme-bg-secondary hover:bg-[var(--main-bg)] theme-heading text-[0.625rem] font-bold uppercase tracking-widest rounded-xl transition border border-[var(--surface-border)] disabled:opacity-50"
                  >
                    {uploading ? (
                      <span>{t('common.uploading')}</span>
                    ) : (
                      <>
                        <Upload className="h-3 w-3" /> {t('ads.form.uploadImage', 'Upload Image')}
                      </>
                    )}
                  </button>
                </div>

                <input type="text" value={imageUrl} onChange={e => setImageUrlValue(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition" placeholder={t('ads.placeholder.imageUrl')} />
                {imageUrl && <p className="mt-1.5 text-[0.625rem] theme-muted font-mono break-all opacity-60">{imageUrl}</p>}
              </div>

              {imageUrl && (
                <div className="aspect-[16/9] bg-gray-100 rounded-lg overflow-hidden relative group">
                  {isHttpUrl(imageUrl) && !imagePreviewFailed ? (
                    <Image
                      src={imageUrl}
                      alt={t('ads.preview.alt', 'Ad preview')}
                      fill
                      unoptimized
                      sizes="(max-width: 768px) 100vw, 448px"
                      className="w-full h-full object-cover"
                      onError={() => setImagePreviewFailed(true)}
                    />
                  ) : (
                    <div className="absolute inset-0 flex items-center justify-center flex-col theme-muted">
                      <ImageIcon className="h-8 w-8 mb-2 opacity-20" />
                      <span className="text-xs font-bold uppercase tracking-widest opacity-40">
                        {isHttpUrl(imageUrl) ? t('ads.preview.loadFailed', 'Failed to load image') : t('ads.preview.invalidUrl', 'Invalid image URL')}
                      </span>
                    </div>
                  )}

                  {/* External Link */}
                  {isHttpUrl(imageUrl) && (
                    <a href={imageUrl} target="_blank" rel="noopener noreferrer" className="absolute top-2 right-2 p-1.5 bg-black/50 hover:bg-black/70 text-white rounded-lg opacity-0 group-hover:opacity-100 transition">
                      <ExternalLink className="h-4 w-4" />
                    </a>
                  )}

                  {uploading && (
                    <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
                    </div>
                  )}
                </div>
              )}

              <div>
                <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1.5 block">{t('ads.form.clickUrl')}</label>
                <input type="text" value={clickUrl} onChange={e => setClickUrl(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition" placeholder={t('ads.placeholder.clickUrl')} />
              </div>

              <div className="flex items-center gap-3">
                <input type="checkbox" checked={isActive} onChange={e => setIsActive(e.target.checked)} className="rounded border-[var(--surface-border)] theme-bg-secondary w-4 h-4 text-blue-600 focus:ring-blue-500/20" />
                <label className="text-sm theme-heading font-medium">{t('ads.form.active')}</label>
              </div>
            </div>

            <div className="flex gap-3 justify-end mt-8">
              <button onClick={() => setShowForm(false)} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition">{t('common.cancel')}</button>
              <button onClick={saveAd} disabled={saving || uploading} className="flex items-center gap-2 px-8 py-2.5 rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-bold disabled:opacity-50 transition shadow-sm">
                <Save className="h-4 w-4" /> {saving ? t('common.saving') : t('ads.form.save')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
