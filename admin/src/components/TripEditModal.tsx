'use client';

import { useState } from 'react';
import { X, Save, Route as RouteIcon } from 'lucide-react';
import { updateTrip } from '@/app/actions/trip-actions';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';

interface Props {
  trip: any;
  onClose: () => void;
  onSaved: (next: any) => void;
}

export function TripEditModal({ trip, onClose, onSaved }: Props) {
  const { toast } = useToast();
  const t = useT();
  const [saving, setSaving] = useState(false);

  const initialDeparture = trip.departure_time
    ? new Date(trip.departure_time).toISOString().slice(0, 16)
    : '';

  const [form, setForm] = useState({
    departure_time: initialDeparture,
    max_weight_kg: trip.max_weight_kg?.toString() ?? '',
    suggested_price_per_kg: trip.suggested_price_per_kg?.toString() ?? '',
    suggested_flat_price: trip.suggested_flat_price?.toString() ?? '',
    notes: trip.notes ?? '',
    status: trip.status ?? 'available',
  });

  const set = (k: keyof typeof form, v: any) => setForm(f => ({ ...f, [k]: v }));

  async function submit() {
    setSaving(true);
    const updates: any = {
      notes: form.notes || null,
      status: form.status,
    };
    if (form.departure_time) updates.departure_time = new Date(form.departure_time).toISOString();
    if (form.max_weight_kg !== '') updates.max_weight_kg = parseFloat(form.max_weight_kg);
    if (form.suggested_price_per_kg !== '') updates.suggested_price_per_kg = parseFloat(form.suggested_price_per_kg);
    if (form.suggested_flat_price !== '') updates.suggested_flat_price = parseFloat(form.suggested_flat_price);

    const res = await updateTrip(trip.id, updates);
    setSaving(false);

    if (res.success) {
      toast(t('trips.edit.saved', 'Trip updated'), 'success');
      onSaved(updates);
      onClose();
    } else {
      toast(res.error || t('trips.edit.failed', 'Update failed'), 'error');
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => !saving && onClose()}>
      <div className="form-on-light bg-[var(--surface)] rounded-2xl shadow-2xl border border-[var(--surface-border)] max-w-lg w-full max-h-[90vh] overflow-hidden flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="p-6 border-b border-[var(--surface-border)] theme-bg-secondary flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-orange-600 flex items-center justify-center">
              <RouteIcon className="h-5 w-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-black theme-heading">{t('trips.edit.title', 'Edit Trip')}</h2>
              <p className="theme-muted text-xs mt-0.5">#{trip.id?.slice?.(0, 8)}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
        </div>

        <div className="p-6 overflow-y-auto flex-1 space-y-4">
          <Field label={t('trips.edit.departure', 'Departure')}>
            <input type="datetime-local" value={form.departure_time} onChange={e => set('departure_time', e.target.value)} className={inputCls} />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label={t('trips.edit.maxWeight', 'Max weight (kg)')}>
              <input type="number" min="0" step="0.1" value={form.max_weight_kg} onChange={e => set('max_weight_kg', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('trips.edit.status', 'Status')}>
              <select value={form.status} onChange={e => set('status', e.target.value)} className={inputCls}>
                {['pending_approval', 'available', 'in_communication', 'pending_confirmation', 'booked', 'in_transit', 'full', 'completed', 'cancelled'].map(s => (
                  <option key={s} value={s}>{s}</option>
                ))}
              </select>
            </Field>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <Field label={t('trips.edit.pricePerKg', 'Price per kg')}>
              <input type="number" min="0" step="0.01" value={form.suggested_price_per_kg} onChange={e => set('suggested_price_per_kg', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('trips.edit.flatPrice', 'Flat price')}>
              <input type="number" min="0" step="0.01" value={form.suggested_flat_price} onChange={e => set('suggested_flat_price', e.target.value)} className={inputCls} />
            </Field>
          </div>
          <Field label={t('trips.edit.notes', 'Notes')}>
            <textarea rows={3} value={form.notes} onChange={e => set('notes', e.target.value)} className={inputCls + ' resize-none'} />
          </Field>
          <p className="text-[0.625rem] theme-muted italic">
            {t('trips.edit.help', 'Reducing max weight will be blocked if active bookings exceed the new capacity.')}
          </p>
        </div>

        <div className="p-6 border-t border-[var(--surface-border)] flex justify-end gap-3 theme-bg-secondary">
          <button type="button" onClick={onClose} disabled={saving} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition disabled:opacity-50">
            {t('common.cancel', 'Cancel')}
          </button>
          <button type="button" onClick={submit} disabled={saving} className="flex items-center gap-2 px-8 py-2.5 rounded-xl bg-orange-600 text-white hover:bg-orange-700 font-bold disabled:opacity-50 transition shadow-sm">
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

const inputCls = 'w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 outline-none';
