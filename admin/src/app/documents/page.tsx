'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { signedUserDocUrl } from '@/lib/storage';
import { useToast } from '@/lib/toast';
import { useI18n } from '@/lib/i18n';
import { FileText, CheckCircle, XCircle, Eye, Clock, Search } from 'lucide-react';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import Link from 'next/link';
import { cn } from '@/lib/utils';

type DocEntry = {
  userId: string;
  userName: string;
  phoneNumber: string | null;
  companyName: string | null;
  companyCrNumber: string | null;
  docTypeKey: string;
  currentUrl: string | null;
  pendingUrl: string | null;
  field: string;
  pendingField: string;
};

const DOC_FIELDS = [
  { field: 'identity_doc_url', pendingField: 'identity_doc_url_pending', labelKey: 'documents.type.identity' },
  { field: 'traveler_license_url', pendingField: 'traveler_license_url_pending', labelKey: 'documents.type.travelerLicense' },
  { field: 'rental_contract_url', pendingField: 'rental_contract_url_pending', labelKey: 'documents.type.rentalContract' },
  { field: 'company_cr_url', pendingField: 'company_cr_url_pending', labelKey: 'documents.type.companyCr' },
];

type FilterMode = 'pending' | 'all';
const USER_DOCUMENTS_BUCKET = 'user_documents';

function isHttpUrl(value: string) {
  return /^https?:\/\//i.test(value);
}

function storagePathFromDocumentValue(value: string | null) {
  if (!value) return null;

  if (isHttpUrl(value)) {
    try {
      const url = new URL(value);
      const publicMarker = `/storage/v1/object/public/${USER_DOCUMENTS_BUCKET}/`;
      const signedMarker = `/storage/v1/object/sign/${USER_DOCUMENTS_BUCKET}/`;
      const marker = url.pathname.includes(publicMarker) ? publicMarker : signedMarker;
      const markerIndex = url.pathname.indexOf(marker);
      if (markerIndex === -1) return null;
      return decodeURIComponent(url.pathname.slice(markerIndex + marker.length));
    } catch {
      return null;
    }
  }

  if (value.startsWith('blob:') || value.startsWith('data:')) return null;
  return value.replace(/^\/+/, '');
}

export default function DocumentsPage() {
  const { toast, confirm: confirmDialog } = useToast();
  const { t, dir } = useI18n();
  const [docs, setDocs] = useState<DocEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<FilterMode>('pending');
  const [search, setSearch] = useState('');

  // Resolve to a short-lived signed URL (private user_documents bucket) and
  // open it. Generated on click so URLs never go stale.
  async function openDocument(value: string | null) {
    if (!value) return;
    const url = await signedUserDocUrl(value);
    if (url) {
      window.open(url, '_blank', 'noopener,noreferrer');
    } else {
      toast(t('documents.errorLoad', 'Failed to load documents.'), 'error');
    }
  }

  useEffect(() => {
    fetchDocs();
  }, []);

  async function fetchDocs() {
    setLoading(true);
    setError(null);
    const { data, error: err } = await supabase
      .from('profiles')
      .select('id, full_name, phone_number, company_name, company_cr_number, identity_doc_url, identity_doc_url_pending, traveler_license_url, traveler_license_url_pending, rental_contract_url, rental_contract_url_pending, company_cr_url, company_cr_url_pending')
      .or('identity_doc_url.neq.,traveler_license_url.neq.,rental_contract_url.neq.,company_cr_url.neq.,identity_doc_url_pending.neq.,traveler_license_url_pending.neq.,rental_contract_url_pending.neq.,company_cr_url_pending.neq.');

    if (err) {
      console.error(err);
      setError(t('documents.errorLoad', 'Failed to load documents.'));
      toast(t('documents.errorLoad', 'Failed to load documents.'), 'error');
      setLoading(false);
      return;
    }

    const entries: DocEntry[] = [];
    for (const p of data || []) {
      for (const df of DOC_FIELDS) {
        const currentUrl = (p as any)[df.field];
        const pendingUrl = (p as any)[df.pendingField];
        if (currentUrl || pendingUrl) {
          entries.push({
            userId: p.id,
            userName: p.full_name || 'Anonymous',
            phoneNumber: p.phone_number || null,
            companyName: p.company_name || null,
            companyCrNumber: p.company_cr_number || null,
            docTypeKey: df.labelKey,
            currentUrl,
            pendingUrl,
            field: df.field,
            pendingField: df.pendingField,
          });
        }
      }
    }
    setDocs(entries);
    setLoading(false);
  }

  if (loading) return <Loading />;
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center max-w-xs">{error}</p>
        <button type="button" onClick={() => fetchDocs()} className="px-6 py-2 rounded-xl font-black text-[0.625rem] uppercase tracking-widest transition-all shadow-sm" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  async function approveDoc(doc: DocEntry) {
    const docTypeLabel = t(doc.docTypeKey);
    confirmDialog({
      title: t('documents.confirm.approveTitle'),
      message: t('documents.confirm.approveMessage').replace(/\{docType\}/g, docTypeLabel).replace(/\{userName\}/g, doc.userName),
      confirmLabel: t('documents.confirm.approveLabel'),
      onConfirm: async () => {
        const update: any = {};
        update[doc.field] = doc.pendingUrl;
        update[doc.pendingField] = null;
        const { error } = await supabase.from('profiles').update(update).eq('id', doc.userId);
        if (error) { toast(t('documents.toast.approveFailed'), 'error'); return; }
        await logAdminAction('approve_document', 'document', doc.userId, { docType: docTypeLabel });
        toast(t('documents.toast.approveSuccess'), 'success');
        fetchDocs();
      }
    });
  }

  async function rejectDoc(doc: DocEntry) {
    const docTypeLabel = t(doc.docTypeKey);
    confirmDialog({
      title: t('documents.confirm.rejectTitle'),
      message: t('documents.confirm.rejectMessage').replace(/\{docType\}/g, docTypeLabel).replace(/\{userName\}/g, doc.userName),
      confirmLabel: t('documents.confirm.rejectLabel'),
      onConfirm: async () => {
        const update: any = {};
        update[doc.pendingField] = null;
        const { error } = await supabase.from('profiles').update(update).eq('id', doc.userId);
        if (error) { toast(t('documents.toast.rejectFailed'), 'error'); return; }
        const storagePath = storagePathFromDocumentValue(doc.pendingUrl);
        let storageDeleted = false;
        if (storagePath) {
          const { error: storageError } = await supabase.storage
            .from(USER_DOCUMENTS_BUCKET)
            .remove([storagePath]);
          storageDeleted = !storageError;
          if (storageError) {
            console.warn('Rejected document row was cleared, but storage cleanup failed:', storageError);
            toast(t('documents.toast.storageDeleteFailed', 'Document rejected, but the stored file could not be deleted.'), 'error');
          }
        }
        await logAdminAction('reject_document', 'document', doc.userId, { docType: docTypeLabel, storageDeleted });
        toast(t('documents.toast.rejectSuccess'), 'success');
        fetchDocs();
      }
    });
  }

  const filtered = docs.filter(d => {
    const normalizedSearch = search.trim().toLowerCase();
    if (!normalizedSearch) return filter === 'pending' ? !!d.pendingUrl : true;
    const docTypeLabel = t(d.docTypeKey);
    const searchable = [
      d.userName,
      d.phoneNumber,
      d.userId,
      d.companyName,
      d.companyCrNumber,
      docTypeLabel,
    ].filter(Boolean).join(' ').toLowerCase();
    const matchesSearch = searchable.includes(normalizedSearch);
    if (filter === 'pending') return matchesSearch && !!d.pendingUrl;
    return matchesSearch;
  });

  const pendingCount = docs.filter(d => d.pendingUrl).length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">{t('documents.title')}</h1>
          <p className="theme-muted text-sm mt-1 font-medium">{t('documents.subtitle')}</p>
        </div>
        {pendingCount > 0 && (
          <span className="flex items-center gap-2 bg-amber-500/10 border border-amber-500/20 text-amber-600 px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest shadow-sm">
            <Clock className="h-4 w-4" /> {pendingCount} {t('documents.pendingCount')}
          </span>
        )}
      </div>

      <div className="theme-bg-secondary flex flex-col gap-4 md:flex-row md:items-center p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
        <div className="relative flex-1">
          <Search className={cn('absolute top-1/2 h-4 w-4 -translate-y-1/2 theme-muted opacity-50', dir === 'rtl' ? 'right-3' : 'left-3')} />
          <input
            type="text"
            placeholder={t('documents.search.expandedPlaceholder', 'Search by name, phone, user ID, company, CR, or document type...')}
            className={cn('w-full theme-bg-secondary rounded-lg border border-[var(--surface-border)] py-2.5 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:outline-none transition-all shadow-sm', dir === 'rtl' ? 'pr-10 pl-4' : 'pl-10 pr-4')}
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <div className="flex gap-2">
          {(['pending', 'all'] as FilterMode[]).map(f => (
            <button key={f} onClick={() => setFilter(f)} className={`px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm ${filter === f ? 'bg-blue-600 text-white' : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'}`}>
              {f === 'pending' ? t('documents.filter.pendingOnly') : t('documents.filter.all')}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-[var(--surface)] rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-x-auto">
        <table className="w-full min-w-[760px] text-sm">
          <thead>
            <tr className="theme-bg-secondary border-b border-[var(--surface-border)]">
              <th className={cn('py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60', dir === 'rtl' ? 'text-right' : 'text-left')}>{t('documents.table.user')}</th>
              <th className={cn('py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60', dir === 'rtl' ? 'text-right' : 'text-left')}>{t('documents.table.documentType')}</th>
              <th className={cn('py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60', dir === 'rtl' ? 'text-right' : 'text-left')}>{t('documents.table.status')}</th>
              <th className={cn('py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60', dir === 'rtl' ? 'text-right' : 'text-left')}>{t('documents.table.view')}</th>
              <th className={cn('py-4 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60', dir === 'rtl' ? 'text-left' : 'text-right')}>{t('documents.table.actions')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--surface-border)] opacity-90">
            {filtered.map((d, i) => (
              <tr key={`${d.userId}-${d.field}-${i}`} className="hover:theme-bg-secondary transition-colors group">
                <td className="py-3 px-4">
                  <Link href={`/users/${d.userId}`} className="text-blue-500 hover:underline font-black tracking-tight">{d.userName}</Link>
                  <p className="text-[0.625rem] theme-muted font-mono opacity-60 uppercase tracking-widest">{d.userId.slice(0, 8)}</p>
                  {d.phoneNumber && <p className="text-[0.625rem] theme-muted font-mono opacity-50">{d.phoneNumber}</p>}
                </td>
                <td className="py-3 px-4 font-black theme-heading text-xs uppercase tracking-widest opacity-80">{t(d.docTypeKey)}</td>
                <td className="py-3 px-4">
                  {d.pendingUrl ? (
                    <span className="flex items-center gap-1.5 text-amber-600 text-[0.625rem] font-black uppercase tracking-widest"><Clock className="h-3.5 w-3.5" /> {t('documents.status.pending')}</span>
                  ) : d.currentUrl ? (
                    <span className="flex items-center gap-1.5 text-green-600 text-[0.625rem] font-black uppercase tracking-widest"><CheckCircle className="h-3.5 w-3.5" /> {t('documents.status.approved')}</span>
                  ) : (
                    <span className="theme-muted text-[0.625rem] font-black uppercase tracking-widest opacity-30">{t('documents.status.missing')}</span>
                  )}
                </td>
                <td className="py-3 px-4">
                  <div className="flex gap-2">
                    {d.currentUrl && <button type="button" onClick={() => openDocument(d.currentUrl)} className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-500/10 text-blue-600 rounded-xl text-[0.625rem] font-black uppercase tracking-widest border border-blue-500/20 hover:bg-blue-500/20 transition-all shadow-sm"><Eye className="h-3.5 w-3.5" /> {t('documents.view.current')}</button>}
                    {d.pendingUrl && <button type="button" onClick={() => openDocument(d.pendingUrl)} className="flex items-center gap-1.5 px-3 py-1.5 bg-amber-500/10 text-amber-600 rounded-xl text-[0.625rem] font-black uppercase tracking-widest border border-amber-500/20 hover:bg-amber-500/20 transition-all shadow-sm"><Eye className="h-3.5 w-3.5" /> {t('documents.view.pending')}</button>}
                  </div>
                </td>
                <td className={cn('py-3 px-4', dir === 'rtl' ? 'text-left' : 'text-right')}>
                  {d.pendingUrl && (
                    <div className={cn('flex gap-2', dir === 'rtl' ? 'justify-start' : 'justify-end')}>
                      <button onClick={() => approveDoc(d)} className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-green-700 transition-all shadow-lg shadow-green-600/10"><CheckCircle className="h-3.5 w-3.5" /> {t('documents.actions.approve')}</button>
                      <button onClick={() => rejectDoc(d)} className="flex items-center gap-2 px-4 py-2 theme-bg-secondary text-red-600 border border-red-500/20 rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-red-500/10 transition-all shadow-sm"><XCircle className="h-3.5 w-3.5" /> {t('documents.actions.reject')}</button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="text-center py-20 bg-[var(--surface)]">
            <FileText className="h-12 w-12 theme-muted mx-auto mb-3 opacity-20" />
            <p className="theme-muted text-[0.625rem] font-black uppercase tracking-widest opacity-60">{t('documents.empty')}</p>
          </div>
        )}
      </div>
    </div>
  );
}
