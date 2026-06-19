'use client';

import { useEffect, useState, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { MapPin, Search, Plus, Edit2, Trash2, Upload, Download, ToggleLeft, ToggleRight, X, Save, Map } from 'lucide-react';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import { exportToCSV } from '@/lib/utils';
import { useI18n, useT } from '@/lib/i18n';
import { GeographyConfig, isHomeCountryName } from '@/lib/geographyConfig';
import dynamic from 'next/dynamic';

const CoordinatePickerMap = dynamic(() => import('@/components/CoordinatePickerMap'), { ssr: false });

type Location = {
  id: string;
  country_code: string | null;
  country_name_ar: string | null;
  country_name_en: string | null;
  province_name_ar: string | null;
  province_name_en: string | null;
  city_name_ar: string | null;
  city_name_en: string | null;
  town_name_ar: string | null;
  town_name_en: string | null;
  latitude: number | null;
  longitude: number | null;
  is_active: boolean;
  created_at: string;
};

type FormData = Omit<Location, 'id' | 'created_at'>;

const emptyForm: FormData = {
  country_code: '', country_name_ar: '', country_name_en: '', province_name_ar: '', province_name_en: '',
  city_name_ar: '', city_name_en: '', town_name_ar: '', town_name_en: '',
  latitude: null, longitude: null, is_active: true,
};

const requiredFields: Array<keyof FormData> = [
  'country_name_ar',
  'country_name_en',
  'province_name_ar',
  'province_name_en',
  'city_name_ar',
  'city_name_en',
];

function cleanText(value: string | null | undefined): string | null {
  const cleaned = String(value ?? '').trim();
  return cleaned.length > 0 ? cleaned : null;
}

function normalizeCountryCode(form: FormData): string | null {
  const explicit = cleanText(form.country_code)?.toUpperCase() ?? null;
  if (explicit) return explicit;
  return isHomeCountryName(form.country_name_en, form.country_name_ar)
    ? GeographyConfig.homeCountryCode
    : null;
}

function normalizeCoordinate(value: number | null, min: number, max: number): number | null | 'invalid' {
  if (value === null) return null;
  if (!Number.isFinite(value) || value < min || value > max) return 'invalid';
  return value;
}

function parseCoordinateInput(value: string): number | null {
  const cleaned = value.trim();
  if (!cleaned) return null;
  return Number(cleaned);
}

function coordinateInputValue(value: number | null): string {
  return value !== null && Number.isFinite(value) ? String(value) : '';
}

type LocationPayload = Omit<FormData, 'latitude' | 'longitude'> & {
  latitude: number | null;
  longitude: number | null;
};

type ValidationResult =
  | { ok: true; payload: LocationPayload }
  | { ok: false; key: string; fallback: string };

function buildLocationPayload(form: FormData): ValidationResult {
  const payload: LocationPayload = {
    country_code: normalizeCountryCode(form),
    country_name_ar: cleanText(form.country_name_ar),
    country_name_en: cleanText(form.country_name_en),
    province_name_ar: cleanText(form.province_name_ar),
    province_name_en: cleanText(form.province_name_en),
    city_name_ar: cleanText(form.city_name_ar),
    city_name_en: cleanText(form.city_name_en),
    town_name_ar: cleanText(form.town_name_ar),
    town_name_en: cleanText(form.town_name_en),
    latitude: null,
    longitude: null,
    is_active: form.is_active,
  };

  if (requiredFields.some(field => !payload[field])) {
    return {
      ok: false,
      key: 'locations.toast.requiredFields',
      fallback: 'Country, province, and city names are required in English and Arabic.',
    };
  }

  const latitude = normalizeCoordinate(form.latitude, -90, 90);
  if (latitude === 'invalid') {
    return { ok: false, key: 'locations.toast.invalidLatitude', fallback: 'Latitude must be between -90 and 90.' };
  }

  const longitude = normalizeCoordinate(form.longitude, -180, 180);
  if (longitude === 'invalid') {
    return { ok: false, key: 'locations.toast.invalidLongitude', fallback: 'Longitude must be between -180 and 180.' };
  }

  payload.latitude = latitude;
  payload.longitude = longitude;
  return { ok: true, payload };
}

function parseCSVLine(line: string): string[] {
  const values: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    const next = line[i + 1];

    if (char === '"' && inQuotes && next === '"') {
      current += '"';
      i += 1;
      continue;
    }

    if (char === '"') {
      inQuotes = !inQuotes;
      continue;
    }

    if (char === ',' && !inQuotes) {
      values.push(current.trim());
      current = '';
      continue;
    }

    current += char;
  }

  values.push(current.trim());
  return values;
}

function csvValue(row: Record<string, string | null>, ...keys: string[]): string | null {
  for (const key of keys) {
    const value = cleanText(row[key]);
    if (value) return value;
  }
  return null;
}

export default function LocationsPage() {
  const { toast, confirm: confirmDialog } = useToast();
  const t = useT();
  const { dir } = useI18n();
  const isRtl = dir === 'rtl';
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterCountry, setFilterCountry] = useState('');
  const [filterProvince, setFilterProvince] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<FormData>({ ...emptyForm });
  const [saving, setSaving] = useState(false);
  const [importing, setImporting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showMapPicker, setShowMapPicker] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { fetchLocations(); }, []);

  async function fetchLocations() {
    setLoading(true);
    setError(null);
    const { data, error: err } = await supabase.from('locations').select('*').order('province_name_en', { ascending: true }).order('city_name_en', { ascending: true });
    if (err) {
      console.error(err);
      setError(t('locations.errorLoad', 'Failed to load locations.'));
      toast(t('locations.errorLoad', 'Failed to load locations.'), 'error');
    } else {
      setLocations((data as Location[]) || []);
    }
    setLoading(false);
  }

  function openCreate() { setForm({ ...emptyForm }); setEditId(null); setShowForm(true); }
  function openEdit(loc: Location) {
    setForm({
      country_code: loc.country_code,
      country_name_ar: loc.country_name_ar, country_name_en: loc.country_name_en,
      province_name_ar: loc.province_name_ar, province_name_en: loc.province_name_en,
      city_name_ar: loc.city_name_ar, city_name_en: loc.city_name_en,
      town_name_ar: loc.town_name_ar, town_name_en: loc.town_name_en,
      latitude: loc.latitude, longitude: loc.longitude, is_active: loc.is_active,
    });
    setEditId(loc.id); setShowForm(true);
  }

  async function saveLocation() {
    const validation = buildLocationPayload(form);
    if (!validation.ok) {
      toast(t(validation.key, validation.fallback), 'error');
      return;
    }

    setSaving(true);
    const payload = validation.payload;
    if (editId) {
      const { error } = await supabase.from('locations').update(payload).eq('id', editId);
      if (error) { toast(t('locations.toast.updateFailed'), 'error'); setSaving(false); return; }
      toast(t('locations.toast.locationUpdated'), 'success');
    } else {
      const { error } = await supabase.from('locations').insert(payload);
      if (error) { toast(t('locations.toast.createFailed'), 'error'); setSaving(false); return; }
      toast(t('locations.toast.locationCreated'), 'success');
    }
    await logAdminAction(editId ? 'update_location' : 'create_location', 'location', editId, { city: form.city_name_en });
    setSaving(false); setShowForm(false); fetchLocations();
  }

  async function deleteLocation(id: string, name: string) {
    confirmDialog({
      title: t('locations.dialog.deleteTitle'), message: t('locations.dialog.deleteMessage').replace('{name}', name), confirmLabel: t('locations.dialog.deleteLabel'),
      onConfirm: async () => {
        const { count: tripCount, error: tripCountError } = await supabase
          .from('trips')
          .select('id', { count: 'exact', head: true })
          .or(`origin_location_id.eq.${id},dest_location_id.eq.${id}`);

        if (tripCountError) {
          toast(t('locations.toast.referenceCheckFailed', 'Could not verify whether this location is in use.'), 'error');
          return;
        }

        if (tripCount && tripCount > 0) {
          toast(t('locations.toast.cannotDeleteTrips').replace('{count}', String(tripCount)), 'error');
          return;
        }

        const { count: shipmentCount, error: shipmentCountError } = await supabase
          .from('shipments')
          .select('id', { count: 'exact', head: true })
          .or(`pickup_location_id.eq.${id},dropoff_location_id.eq.${id}`);

        if (shipmentCountError) {
          toast(t('locations.toast.referenceCheckFailed', 'Could not verify whether this location is in use.'), 'error');
          return;
        }

        if (shipmentCount && shipmentCount > 0) {
          toast(t('locations.toast.cannotDeleteShipments').replace('{count}', String(shipmentCount)), 'error');
          return;
        }

        const { error } = await supabase.from('locations').delete().eq('id', id);
        if (error) { toast(t('locations.toast.deleteFailed'), 'error'); return; }
        await logAdminAction('delete_location', 'location', id, { name });
        toast(t('locations.toast.locationDeleted'), 'success'); fetchLocations();
      }
    });
  }

  async function toggleActive(loc: Location) {
    const { error } = await supabase.from('locations').update({ is_active: !loc.is_active }).eq('id', loc.id);
    if (error) { toast(t('locations.toast.updateFailed'), 'error'); return; }
    setLocations(prev => prev.map(l => l.id === loc.id ? { ...l, is_active: !l.is_active } : l));
    await logAdminAction('toggle_location', 'location', loc.id, { is_active: !loc.is_active });
  }

  async function handleCSVImport(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setImporting(true);
    const text = await file.text();
    const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/).filter(l => l.trim());
    if (lines.length < 2) {
      toast(t('locations.toast.csvInvalid'), 'error');
      setImporting(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
      return;
    }

    const headers = parseCSVLine(lines[0]).map(h => h.trim().toLowerCase().replace(/"/g, ''));
    const rows: LocationPayload[] = [];

    for (const [index, line] of lines.slice(1).entries()) {
      const vals = parseCSVLine(line);
      const obj: Record<string, string | null> = {};
      headers.forEach((h, i) => { obj[h] = vals[i] || null; });

      const rowForm: FormData = {
        country_code: csvValue(obj, 'country_code', 'countrycode', 'country_iso', 'iso_code'),
        country_name_ar: csvValue(obj, 'country_name_ar', 'country_ar'),
        country_name_en: csvValue(obj, 'country_name_en', 'country_en', 'country'),
        province_name_ar: csvValue(obj, 'province_name_ar', 'province_ar'),
        province_name_en: csvValue(obj, 'province_name_en', 'province_en', 'province'),
        city_name_ar: csvValue(obj, 'city_name_ar', 'city_ar'),
        city_name_en: csvValue(obj, 'city_name_en', 'city_en', 'city'),
        town_name_ar: csvValue(obj, 'town_name_ar', 'town_ar'),
        town_name_en: csvValue(obj, 'town_name_en', 'town_en', 'town'),
        latitude: parseCoordinateInput(csvValue(obj, 'latitude', 'lat') ?? ''),
        longitude: parseCoordinateInput(csvValue(obj, 'longitude', 'lng', 'lon') ?? ''),
        is_active: true,
      };

      const validation = buildLocationPayload(rowForm);
      if (!validation.ok) {
        toast(
          t('locations.toast.csvRowInvalid', 'Row {row}: {message}')
            .replace('{row}', String(index + 2))
            .replace('{message}', t(validation.key, validation.fallback)),
          'error',
        );
        setImporting(false);
        if (fileInputRef.current) fileInputRef.current.value = '';
        return;
      }

      rows.push(validation.payload);
    }

    const { error } = await supabase.from('locations').insert(rows);
    if (error) { toast(t('locations.toast.importFailed').replace('{message}', error.message), 'error'); }
    else { toast(t('locations.toast.importedCount').replace('{count}', String(rows.length)), 'success'); fetchLocations(); }
    setImporting(false);
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  const uniqueCountries = [...new Set(locations.map(l => l.country_name_en).filter(Boolean))].sort() as string[];
  const uniqueProvincesByCountry = locations
    .filter(l => !filterCountry || l.country_name_en === filterCountry)
    .map(l => l.province_name_en)
    .filter(Boolean);
  const uniqueProvinces = [...new Set(uniqueProvincesByCountry)].sort() as string[];

  const filtered = locations.filter(l => {
    const q = search.trim().toLowerCase();
    const matchSearch = !q || [
      l.country_code,
      l.country_name_en,
      l.country_name_ar,
      l.province_name_en,
      l.province_name_ar,
      l.city_name_en,
      l.city_name_ar,
      l.town_name_en,
      l.town_name_ar,
    ].some(value => String(value ?? '').toLowerCase().includes(q));
    const matchCountry = !filterCountry || l.country_name_en === filterCountry;
    const matchProvince = !filterProvince || l.province_name_en === filterProvince;
    return matchSearch && matchCountry && matchProvince;
  });

  if (loading) return <Loading />;
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <p className="theme-muted text-center">{error}</p>
        <button type="button" onClick={() => fetchLocations()} className="px-4 py-2 rounded-lg font-medium" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
          {t('common.retry', 'Retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-3xl font-black theme-heading tracking-tight">{t('locations.title')}</h1>
          <p className="theme-muted text-sm mt-1 font-medium">{t('locations.subtitle')}</p>
        </div>
        <div className="flex items-center gap-2">
          <input type="file" ref={fileInputRef} accept=".csv" className="hidden" onChange={handleCSVImport} />
          <button onClick={() => fileInputRef.current?.click()} disabled={importing} className="flex items-center gap-2 bg-amber-600 text-white px-4 py-2 rounded-lg hover:bg-amber-700 transition shadow-sm font-bold text-xs uppercase disabled:opacity-50">
            <Upload className="h-4 w-4" /> {importing ? t('common.importing') : t('locations.importCsv')}
          </button>
          <button onClick={() => exportToCSV(filtered, 'locations_export', msg => toast(msg, 'error'))} className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition shadow-sm font-bold text-xs uppercase">
            <Download className="h-4 w-4" /> {t('locations.export')}
          </button>
          <button onClick={openCreate} className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition shadow-sm font-bold text-xs uppercase">
            <Plus className="h-4 w-4" /> {t('locations.add')}
          </button>
        </div>
      </div>

      <div className="form-on-light flex flex-wrap items-center gap-3 theme-bg-secondary p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
        <div className="relative flex-1 min-w-[200px]">
          <Search className={`absolute ${isRtl ? 'right-3' : 'left-3'} top-1/2 h-4 w-4 -translate-y-1/2 theme-muted`} />
          <input type="text" placeholder={t('locations.search.placeholder')} className={`w-full rounded-lg border border-[var(--surface-border)] theme-bg-secondary ${isRtl ? 'pr-10 pl-3' : 'pl-10 pr-3'} py-2 theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition`} value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <select
          value={filterCountry}
          onChange={e => { setFilterCountry(e.target.value); setFilterProvince(''); }}
          className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 min-w-[140px] transition"
        >
          <option value="" className="theme-bg-secondary">{t('locations.filter.all')} ({t('locations.filter.country')})</option>
          {uniqueCountries.map(c => (
            <option key={c} value={c} className="theme-bg-secondary">{c}</option>
          ))}
        </select>
        <select
          value={filterProvince}
          onChange={e => setFilterProvince(e.target.value)}
          className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 min-w-[140px] transition"
        >
          <option value="" className="theme-bg-secondary">{t('locations.filter.all')} ({t('locations.filter.province')})</option>
          {uniqueProvinces.map(p => (
            <option key={p} value={p} className="theme-bg-secondary">{p}</option>
          ))}
        </select>
        <span className="theme-bg-secondary border border-[var(--surface-border)] px-3 py-1.5 rounded-lg text-xs font-bold theme-muted">{filtered.length} {t('locations.count')}</span>
      </div>

      <div className="bg-[var(--surface)] rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="theme-bg-secondary border-b border-[var(--surface-border)]">
                <th className="text-start py-3 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.table.city')}</th>
                <th className="text-start py-3 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.table.province')}</th>
                <th className="text-start py-3 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.table.country')}</th>
                <th className="text-start py-3 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.table.coords')}</th>
                <th className="text-center py-3 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.table.active')}</th>
                <th className="text-end py-3 px-4 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.table.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(loc => (
                <tr key={loc.id} className="border-b border-[var(--surface-border)] hover:theme-bg-secondary transition-colors">
                  <td className="py-3 px-4">
                    <p className="font-bold theme-heading">{loc.city_name_en || t('common.na', 'N/A')}</p>
                    <p className="text-xs theme-muted opacity-60" dir="rtl">{loc.city_name_ar || t('common.na', 'N/A')}</p>
                    {loc.town_name_en && <p className="text-[0.625rem] theme-muted">{t('locations.table.town')}: {loc.town_name_en}</p>}
                  </td>
                  <td className="py-3 px-4 theme-muted font-medium">{loc.province_name_en || t('common.na', 'N/A')}</td>
                  <td className="py-3 px-4 theme-muted">
                    <p>{loc.country_name_en || t('common.na', 'N/A')}</p>
                    <p className="text-[0.625rem] font-black uppercase tracking-widest opacity-60">{loc.country_code || t('common.na', 'N/A')}</p>
                  </td>
                  <td className="py-3 px-4 text-xs theme-muted font-mono opacity-80">
                    {loc.latitude !== null && loc.longitude !== null ? `${Number(loc.latitude).toFixed(4)}, ${Number(loc.longitude).toFixed(4)}` : t('common.na', 'N/A')}
                  </td>
                  <td className="py-3 px-4 text-center">
                    <button aria-label={t('locations.action.toggleActive', 'Toggle active')} onClick={() => toggleActive(loc)} className="theme-muted hover:text-blue-600 transition">
                      {loc.is_active ? <ToggleRight className="h-6 w-6 text-green-500" /> : <ToggleLeft className="h-6 w-6 theme-bg-secondary" />}
                    </button>
                  </td>
                  <td className="py-3 px-4 text-end">
                    <div className={`flex gap-1 ${isRtl ? 'justify-start' : 'justify-end'}`}>
                      <button aria-label={t('locations.action.edit', 'Edit location')} onClick={() => openEdit(loc)} className="p-2 theme-muted hover:text-blue-600 hover:bg-blue-500/10 rounded-lg transition"><Edit2 className="h-4 w-4" /></button>
                      <button aria-label={t('locations.action.delete', 'Delete location')} onClick={() => deleteLocation(loc.id, loc.city_name_en || t('common.unknown', 'Unknown'))} className="p-2 theme-muted hover:text-red-600 hover:bg-red-500/10 rounded-lg transition"><Trash2 className="h-4 w-4" /></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filtered.length === 0 && (
          <div className="text-center py-20">
            <MapPin className="h-12 w-12 theme-muted opacity-20 mx-auto mb-3" />
            <p className="theme-muted font-bold uppercase tracking-widest text-sm">{t('locations.empty')}</p>
          </div>
        )}
      </div>

      {/* Create/Edit Modal */}
      {showForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm overflow-y-auto py-8">
          <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-2xl p-8 max-w-lg w-full mx-4 overflow-hidden">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-black theme-heading">{editId ? t('locations.form.editTitle') : t('locations.form.addTitle')}</h3>
              <button onClick={() => setShowForm(false)} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <FormField label={t('locations.form.countryCode', 'Country Code')} value={form.country_code} onChange={v => setForm({ ...form, country_code: v.toUpperCase() })} />
              <FormField label={t('locations.form.countryEn')} value={form.country_name_en} onChange={v => setForm({ ...form, country_name_en: v })} />
              <FormField label={t('locations.form.countryAr')} value={form.country_name_ar} onChange={v => setForm({ ...form, country_name_ar: v })} dir="rtl" />
              <FormField label={t('locations.form.provinceEn')} value={form.province_name_en} onChange={v => setForm({ ...form, province_name_en: v })} />
              <FormField label={t('locations.form.provinceAr')} value={form.province_name_ar} onChange={v => setForm({ ...form, province_name_ar: v })} dir="rtl" />
              <FormField label={t('locations.form.cityEn')} value={form.city_name_en} onChange={v => setForm({ ...form, city_name_en: v })} />
              <FormField label={t('locations.form.cityAr')} value={form.city_name_ar} onChange={v => setForm({ ...form, city_name_ar: v })} dir="rtl" />
              <FormField label={t('locations.form.townEn')} value={form.town_name_en} onChange={v => setForm({ ...form, town_name_en: v })} />
              <FormField label={t('locations.form.townAr')} value={form.town_name_ar} onChange={v => setForm({ ...form, town_name_ar: v })} dir="rtl" />
            </div>
            
            {/* Coordinates Section with Map Picker */}
            <div className="mt-4 space-y-3">
              <div className="flex items-center justify-between">
                <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('locations.form.coordinates', 'Coordinates')}</label>
                <button
                  type="button"
                  onClick={() => setShowMapPicker(true)}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition text-xs font-bold"
                >
                  <Map className="h-3.5 w-3.5" />
                  {t('locations.form.pickOnMap', 'Pick on Map')}
                </button>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <FormField label={t('locations.form.latitude')} value={coordinateInputValue(form.latitude)} onChange={v => setForm({ ...form, latitude: parseCoordinateInput(v) })} type="number" />
                <FormField label={t('locations.form.longitude')} value={coordinateInputValue(form.longitude)} onChange={v => setForm({ ...form, longitude: parseCoordinateInput(v) })} type="number" />
              </div>
            </div>
            <div className="flex items-center gap-3 mt-6">
              <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} className="rounded border-[var(--surface-border)] theme-bg-secondary w-4 h-4 text-blue-600 focus:ring-blue-500/20" />
              <label className="text-sm theme-heading font-medium">{t('locations.form.active')}</label>
            </div>
            <div className="flex gap-3 justify-end mt-8">
              <button onClick={() => setShowForm(false)} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition">{t('locations.form.cancel')}</button>
              <button onClick={saveLocation} disabled={saving} className="flex items-center gap-2 px-8 py-2.5 rounded-xl bg-blue-600 text-white hover:bg-blue-700 font-bold disabled:opacity-50 transition shadow-sm">
                <Save className="h-4 w-4" /> {saving ? t('common.saving') : t('locations.form.save')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Coordinate Picker Map Modal */}
      {showMapPicker && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-2xl w-full max-w-5xl h-[95vh] flex flex-col overflow-hidden">
            <div className="flex items-center justify-between px-6 py-3 border-b border-[var(--surface-border)]">
              <div>
                <h3 className="text-lg font-black theme-heading">{t('locations.mapPicker.title', 'Pick Location on Map')}</h3>
                <p className="text-xs theme-muted">{t('locations.mapPicker.subtitle', 'Click on the map to set coordinates')}</p>
              </div>
              <button onClick={() => setShowMapPicker(false)} className="p-1 theme-muted hover:theme-heading transition">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="flex-1 min-h-0">
              <CoordinatePickerMap
                initialLat={form.latitude}
                initialLng={form.longitude}
                onCoordinateSelect={(lat, lng, locationData) => {
                  // Update coordinates
                  const updatedForm = { ...form, latitude: lat, longitude: lng };
                  
                  // Auto-fill location data if available and fields are empty
                  if (locationData) {
                    if (!form.country_name_en && locationData.country) {
                      updatedForm.country_name_en = locationData.country;
                    }
                    if (!form.country_code && locationData.countryCode) {
                      updatedForm.country_code = locationData.countryCode;
                    }
                    if (!form.province_name_en && locationData.state) {
                      updatedForm.province_name_en = locationData.state;
                    }
                    if (!form.city_name_en && locationData.city) {
                      updatedForm.city_name_en = locationData.city;
                    }
                  }
                  
                  setForm(updatedForm);
                  setShowMapPicker(false);
                  toast(t('locations.mapPicker.success', 'Coordinates set successfully'), 'success');
                }}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function FormField({ label, value, onChange, type = 'text', dir }: { label: string; value: string | null; onChange: (v: string) => void; type?: string; dir?: string }) {
  return (
    <div className="space-y-1">
      <label className="text-[0.625rem] theme-muted font-black uppercase tracking-widest block">{label}</label>
      <input aria-label={label} type={type} dir={dir} value={value || ''} onChange={e => onChange(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition" />
    </div>
  );
}
