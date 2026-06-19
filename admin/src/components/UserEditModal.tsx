'use client';

import { useState } from 'react';
import { X, Save, User as UserIcon } from 'lucide-react';
import { Profile } from '@/lib/types';
import { updateUserProfile } from '@/app/actions/user-actions';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';

interface Props {
  user: Profile;
  onClose: () => void;
  onSaved: (next: Partial<Profile>) => void;
}

function normalizeTravelerType(value: string | null | undefined): '' | 'with_vehicle' | 'no_vehicle' {
  if (!value) return '';
  if (value === 'with_vehicle' || value === 'no_vehicle') return value;
  if (value === 'without_vehicle') return 'no_vehicle';
  return 'with_vehicle';
}

export function UserEditModal({ user, onClose, onSaved }: Props) {
  const { toast } = useToast();
  const t = useT();
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    full_name: user.full_name || '',
    phone_number: user.phone_number || '',
    bio: user.bio || '',
    company_name: user.company_name || '',
    company_cr_number: user.company_cr_number || '',
    identity_type: user.identity_type || '',
    traveler_type: normalizeTravelerType(user.traveler_type),
    is_available: !!user.is_available,
  });

  const set = (k: keyof typeof form, v: any) => setForm(f => ({ ...f, [k]: v }));
  const nullableText = (value: string) => {
    const next = value.trim();
    return next ? next : null;
  };
  const hasCompanyCapability = user.account_type === 'company' || !!(user.company_status && user.company_status !== 'none');

  async function submit() {
    const fullName = form.full_name.trim();
    if (!fullName) {
      toast(t('users.create.nameRequired', 'Full name is required'), 'error');
      return;
    }
    setSaving(true);
    const updates: Parameters<typeof updateUserProfile>[1] = {
      full_name: fullName,
      phone_number: nullableText(form.phone_number),
      bio: nullableText(form.bio),
      company_name: hasCompanyCapability ? nullableText(form.company_name) : undefined,
      company_cr_number: hasCompanyCapability ? nullableText(form.company_cr_number) : undefined,
      identity_type: form.identity_type || null,
      traveler_type: form.traveler_type || null,
      is_available: form.is_available,
    };
    const res = await updateUserProfile(user.id, updates);
    setSaving(false);

    if (res.success) {
      toast(t('users.edit.saved', 'Profile updated'), 'success');
      onSaved({
        ...updates,
        traveler_type: updates.traveler_type as Profile['traveler_type'],
      });
      onClose();
    } else {
      toast(res.error || t('users.edit.failed', 'Update failed'), 'error');
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => !saving && onClose()}>
      <div className="form-on-light bg-[var(--surface)] rounded-2xl shadow-2xl border border-[var(--surface-border)] max-w-2xl w-full max-h-[90vh] overflow-hidden flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="p-6 border-b border-[var(--surface-border)] theme-bg-secondary flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-blue-600 flex items-center justify-center">
              <UserIcon className="h-5 w-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-black theme-heading">{t('users.edit.title', 'Edit User')}</h2>
              <p className="theme-muted text-xs mt-0.5">{user.full_name}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
        </div>

        <div className="p-6 overflow-y-auto flex-1 space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <Field label={t('users.edit.fullName', 'Full Name')}>
              <input value={form.full_name} onChange={e => set('full_name', e.target.value)} className={inputCls} />
            </Field>
            <Field label={t('users.edit.phone', 'Phone Number')}>
              <input type="tel" value={form.phone_number} onChange={e => set('phone_number', e.target.value)} className={inputCls} />
            </Field>
          </div>

          <Field label={t('users.edit.bio', 'Bio')}>
            <textarea rows={2} value={form.bio} onChange={e => set('bio', e.target.value)} className={inputCls + ' resize-none'} />
          </Field>

          {hasCompanyCapability && (
            <div className="grid grid-cols-2 gap-3">
              <Field label={t('users.edit.companyName', 'Company Name')}>
                <input value={form.company_name} onChange={e => set('company_name', e.target.value)} className={inputCls} />
              </Field>
              <Field label={t('users.edit.crNumber', 'CR Number')}>
                <input value={form.company_cr_number} onChange={e => set('company_cr_number', e.target.value)} className={inputCls} />
              </Field>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3">
            <Field label={t('users.edit.identityType', 'Identity Type')}>
              <select value={form.identity_type} onChange={e => set('identity_type', e.target.value)} className={inputCls}>
                <option value="">-</option>
                <option value="id_card">{t('users.detail.value.id_card', 'ID Card')}</option>
                <option value="passport">{t('users.detail.value.passport', 'Passport')}</option>
                <option value="iqama">{t('users.detail.value.iqama', 'Iqama')}</option>
              </select>
            </Field>
            <Field label={t('users.edit.travelerType', 'Traveler Type')}>
              <select value={form.traveler_type} onChange={e => set('traveler_type', e.target.value)} className={inputCls}>
                <option value="">-</option>
                <option value="no_vehicle">{t('users.detail.value.no_vehicle', 'No vehicle')}</option>
                <option value="with_vehicle">{t('users.detail.value.with_vehicle', 'With vehicle')}</option>
              </select>
            </Field>
          </div>

          <label className="flex items-center gap-2 cursor-pointer pt-2">
            <input type="checkbox" checked={form.is_available} onChange={e => set('is_available', e.target.checked)} className="rounded border-[var(--surface-border)] w-4 h-4 text-blue-600 focus:ring-blue-500/20" />
            <span className="text-sm theme-heading">{t('users.edit.isAvailable', 'Available for trips/deliveries')}</span>
          </label>
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
