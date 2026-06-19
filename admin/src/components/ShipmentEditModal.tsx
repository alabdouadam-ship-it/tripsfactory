'use client';

import { useState } from 'react';
import { X, Save, Package } from 'lucide-react';
import { updateShipment } from '@/app/actions/shipment-actions';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';

interface Props {
  shipment: any;
  onClose: () => void;
  onSaved: (next: any) => void;
}

export function ShipmentEditModal({ shipment, onClose, onSaved }: Props) {
  const { toast } = useToast();
  const t = useT();
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    description: shipment.description ?? '',
    weight_kg: shipment.weight_kg?.toString() ?? '',
    price: (shipment.price ?? shipment.offered_price)?.toString() ?? '',
    pickup_notes: shipment.pickup_notes ?? '',
    dropoff_notes: shipment.dropoff_notes ?? '',
    status: shipment.status ?? 'pending',
  });
  const set = (k: keyof typeof form, v: any) => setForm(f => ({ ...f, [k]: v }));

  async function submit() {
    setSaving(true);
    const parsedWeight = form.weight_kg !== '' ? Number(form.weight_kg) : undefined;
    const parsedPrice = form.price !== '' ? Number(form.price) : undefined;
    if ((parsedWeight !== undefined && Number.isNaN(parsedWeight)) || (parsedPrice !== undefined && Number.isNaN(parsedPrice))) {
      setSaving(false);
      toast(t('shipments.edit.invalidNumber', 'Please enter valid numeric values for weight and price.'), 'error');
      return;
    }
    const updates: any = {
      description: form.description || null,
      pickup_notes: form.pickup_notes || null,
      dropoff_notes: form.dropoff_notes || null,
      status: form.status,
    };
    if (parsedWeight !== undefined) updates.weight_kg = parsedWeight;
    if (parsedPrice !== undefined) updates.price = parsedPrice;

    const res = await updateShipment(shipment.id, updates);
    setSaving(false);
    if (res.success) {
      toast(t('shipments.edit.saved', 'Shipment updated'), 'success');
      onSaved(updates);
      onClose();
    } else {
      toast(res.error || t('shipments.edit.failed', 'Update failed'), 'error');
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => !saving && onClose()}>
      <div className="form-on-light bg-[var(--surface)] rounded-2xl shadow-2xl border border-[var(--surface-border)] max-w-lg w-full max-h-[90vh] overflow-hidden flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="p-6 border-b border-[var(--surface-border)] theme-bg-secondary flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-blue-600 flex items-center justify-center">
              <Package className="h-5 w-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-black theme-heading">{t('shipments.edit.title', 'Edit Shipment')}</h2>
              <p className="theme-muted text-xs mt-0.5">#{shipment.id?.slice?.(0, 8)}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
        </div>

        <div className="p-6 overflow-y-auto flex-1 space-y-4">
          <Field label={t('shipments.edit.description', 'Description')}>
            <textarea rows={3} value={form.description} onChange={e => set('description', e.target.value)} className={inputCls + ' resize-none'} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label={t('shipments.edit.weight', 'Weight (kg)')}>
              <input type="number" min="0" step="0.1" value={form.weight_kg} onChange={e => set('weight_kg', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('shipments.edit.price', 'Price')}>
              <input type="number" min="0" step="0.01" value={form.price} onChange={e => set('price', e.target.value)} className={inputCls} />
            </Field>
          </div>
          <Field label={t('shipments.edit.pickupNotes', 'Pickup notes')}>
            <textarea rows={2} value={form.pickup_notes} onChange={e => set('pickup_notes', e.target.value)} className={inputCls + ' resize-none'} />
          </Field>
          <Field label={t('shipments.edit.dropoffNotes', 'Dropoff notes')}>
            <textarea rows={2} value={form.dropoff_notes} onChange={e => set('dropoff_notes', e.target.value)} className={inputCls + ' resize-none'} />
          </Field>
          <Field label={t('shipments.edit.status', 'Status')}>
            <select value={form.status} onChange={e => set('status', e.target.value)} className={inputCls}>
              {['pending', 'in_communication', 'accepted', 'picked_up', 'in_transit', 'delivered', 'completed', 'cancelled', 'rejected', 'expired', 'frozen', 'disputed'].map(s => (
                <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
              ))}
            </select>
          </Field>
        </div>

        <div className="p-6 border-t border-[var(--surface-border)] flex justify-end gap-3 theme-bg-secondary">
          <button type="button" onClick={onClose} disabled={saving} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition disabled:opacity-50">
            {t('common.cancel', 'Cancel')}
          </button>
          <button type="button" onClick={submit} disabled={saving} className="flex items-center gap-2 px-8 py-2.5 rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-bold disabled:opacity-50 transition shadow-sm">
            <Save className="h-4 w-4" /> {saving ? t('common.saving', 'Saving...') : t('common.save', 'Save')}
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

const inputCls = 'w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-blue-500 outline-none';
