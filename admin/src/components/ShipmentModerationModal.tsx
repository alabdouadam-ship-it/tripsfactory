'use client';

import { useState } from 'react';
import { X, Flag, AlertTriangle, ShieldAlert } from 'lucide-react';
import { flagShipment, resolveShipmentModeration } from '@/app/actions/shipment-actions';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';

type Mode = 'flag' | 'resolve';

interface Props {
  shipment: any;
  mode: Mode;
  onClose: () => void;
  onDone: (next: any) => void;
}

const FLAG_CATEGORIES = [
  { id: 'illegal', label: 'Illegal goods (drugs, weapons, etc.)' },
  { id: 'fraud', label: 'Fraudulent / scam listing' },
  { id: 'duplicate', label: 'Duplicate / spam' },
  { id: 'inappropriate', label: 'Inappropriate content' },
  { id: 'misleading', label: 'Misleading description' },
  { id: 'other', label: 'Other (see notes)' },
];

export function ShipmentModerationModal({ shipment, mode, onClose, onDone }: Props) {
  const { toast } = useToast();
  const t = useT();
  const [busy, setBusy] = useState(false);
  const [category, setCategory] = useState<string>(shipment.flag_category ?? 'illegal');
  const [reason, setReason] = useState<string>(shipment.flag_reason ?? '');
  const [resolution, setResolution] = useState<'cleared' | 'removed' | 'escalated'>('cleared');
  const [notes, setNotes] = useState<string>('');

  async function submitFlag() {
    setBusy(true);
    const res = await flagShipment(shipment.id, { flag: true, category: category as any, reason });
    setBusy(false);
    if (res.success) {
      toast(t('shipments.mod.flagged', 'Shipment flagged for review'), 'success');
      onDone({ is_flagged: true, flag_category: category, flag_reason: reason, moderation_status: 'pending_review' });
      onClose();
    } else {
      toast(res.error || 'Flag failed', 'error');
    }
  }

  async function submitResolve() {
    setBusy(true);
    const res = await resolveShipmentModeration(shipment.id, { outcome: resolution, notes });
    setBusy(false);
    if (res.success) {
      toast(t('shipments.mod.resolved', 'Moderation resolved'), 'success');
      onDone({
        moderation_status: resolution,
        moderation_notes: notes,
        is_flagged: resolution === 'cleared' ? false : shipment.is_flagged,
        ...(resolution === 'removed' ? { status: 'cancelled' } : {}),
      });
      onClose();
    } else {
      toast(res.error || 'Resolve failed', 'error');
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => !busy && onClose()}>
      <div className="form-on-light bg-[var(--surface)] rounded-2xl shadow-2xl border border-[var(--surface-border)] max-w-lg w-full max-h-[90vh] overflow-hidden flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="p-6 border-b border-[var(--surface-border)] theme-bg-secondary flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`h-10 w-10 rounded-xl flex items-center justify-center ${mode === 'flag' ? 'bg-red-600' : 'bg-purple-600'}`}>
              {mode === 'flag' ? <Flag className="h-5 w-5 text-white" /> : <ShieldAlert className="h-5 w-5 text-white" />}
            </div>
            <div>
              <h2 className="text-xl font-black theme-heading">
                {mode === 'flag' ? t('shipments.mod.flagTitle', 'Flag shipment') : t('shipments.mod.resolveTitle', 'Resolve moderation')}
              </h2>
              <p className="theme-muted text-xs mt-0.5">#{shipment.id?.slice?.(0, 8)}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
        </div>

        <div className="p-6 overflow-y-auto flex-1 space-y-4">
          {mode === 'flag' && (
            <>
              <div className="bg-red-50 border border-red-200 text-red-800 text-xs p-3 rounded-xl flex gap-2 items-start">
                <AlertTriangle className="h-4 w-4 flex-shrink-0 mt-0.5" />
                <span>{t('shipments.mod.flagWarn', 'Flagging will mark this shipment for moderation review. The shipment is not deleted yet.')}</span>
              </div>
              <Field label={t('shipments.mod.category', 'Category')}>
                <div className="space-y-2">
                  {FLAG_CATEGORIES.map(c => (
                    <label key={c.id} className="flex items-center gap-2 cursor-pointer">
                      <input type="radio" name="cat" checked={category === c.id} onChange={() => setCategory(c.id)} className="w-4 h-4 text-red-600 focus:ring-red-500/20" />
                      <span className="text-sm theme-heading">{c.label}</span>
                    </label>
                  ))}
                </div>
              </Field>
              <Field label={t('shipments.mod.reason', 'Reason / details')}>
                <textarea rows={3} value={reason} onChange={e => setReason(e.target.value)} className={inputCls + ' resize-none'} placeholder={t('shipments.mod.reasonPlaceholder', 'Provide context for the moderation queue.')} />
              </Field>
            </>
          )}

          {mode === 'resolve' && (
            <>
              <Field label={t('shipments.mod.resolution', 'Resolution')}>
                <div className="space-y-2">
                  <label className="flex items-start gap-2 cursor-pointer p-3 rounded-xl border border-[var(--surface-border)] hover:bg-green-50/40">
                    <input type="radio" name="res" checked={resolution === 'cleared'} onChange={() => setResolution('cleared')} className="w-4 h-4 mt-0.5 text-green-600" />
                    <div>
                      <p className="text-sm font-bold theme-heading">{t('shipments.mod.cleared', 'Clear flag')}</p>
                      <p className="text-[0.625rem] theme-muted">{t('shipments.mod.cleared.help', 'No issue found. Shipment continues normally.')}</p>
                    </div>
                  </label>
                  <label className="flex items-start gap-2 cursor-pointer p-3 rounded-xl border border-[var(--surface-border)] hover:bg-red-50/40">
                    <input type="radio" name="res" checked={resolution === 'removed'} onChange={() => setResolution('removed')} className="w-4 h-4 mt-0.5 text-red-600" />
                    <div>
                      <p className="text-sm font-bold theme-heading">{t('shipments.mod.removed', 'Remove (cancel) shipment')}</p>
                      <p className="text-[0.625rem] theme-muted">{t('shipments.mod.removed.help', 'Cancels the shipment and locks it from new bookings.')}</p>
                    </div>
                  </label>
                  <label className="flex items-start gap-2 cursor-pointer p-3 rounded-xl border border-[var(--surface-border)] hover:bg-purple-50/40">
                    <input type="radio" name="res" checked={resolution === 'escalated'} onChange={() => setResolution('escalated')} className="w-4 h-4 mt-0.5 text-purple-600" />
                    <div>
                      <p className="text-sm font-bold theme-heading">{t('shipments.mod.escalated', 'Escalate to senior admin')}</p>
                      <p className="text-[0.625rem] theme-muted">{t('shipments.mod.escalated.help', 'Keep the flag, hand off to a super_admin.')}</p>
                    </div>
                  </label>
                </div>
              </Field>
              <Field label={t('shipments.mod.notes', 'Internal notes')}>
                <textarea rows={3} value={notes} onChange={e => setNotes(e.target.value)} className={inputCls + ' resize-none'} />
              </Field>
            </>
          )}
        </div>

        <div className="p-6 border-t border-[var(--surface-border)] flex justify-end gap-3 theme-bg-secondary">
          <button type="button" onClick={onClose} disabled={busy} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition disabled:opacity-50">
            {t('common.cancel', 'Cancel')}
          </button>
          <button
            type="button"
            onClick={mode === 'flag' ? submitFlag : submitResolve}
            disabled={busy}
            className={`flex items-center gap-2 px-8 py-2.5 rounded-xl text-white font-bold disabled:opacity-50 transition shadow-sm ${mode === 'flag' ? 'bg-red-600 hover:bg-red-700' : 'bg-purple-600 hover:bg-purple-700'}`}
          >
            {mode === 'flag' ? <Flag className="h-4 w-4" /> : <ShieldAlert className="h-4 w-4" />}
            {busy ? t('common.saving', 'Saving...') : (mode === 'flag' ? t('shipments.mod.flagBtn', 'Flag') : t('shipments.mod.resolveBtn', 'Resolve'))}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: any }) {
  return (
    <div>
      <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{label}</label>
      {children}
    </div>
  );
}

const inputCls = 'w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-purple-500 outline-none';
