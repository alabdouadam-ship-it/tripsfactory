'use client';

import { useEffect, useState, useCallback, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Profile } from '@/lib/types';
import {
  Search, Download, ShieldCheck, Ban, UserPlus, ExternalLink, User, Truck, Building2,
  Star, Award, Lock, Unlock, X, Save, AlertTriangle, Info,
} from 'lucide-react';
import { DataTable, Column } from '@/components/DataTable';
import { getPaginatedUsers, bulkUpdateUserStatus } from '@/app/actions/ux-actions';
import { createUserAccount, setUserBlocked } from '@/app/actions/user-actions';
import { exportToCSV } from '@/lib/utils';
import { useI18n } from '@/lib/i18n';

const PAGE_SIZE = 25;
const QUERY_TIMEOUT_MS = 15000;

type Segment = 'all' | 'individuals' | 'drivers' | 'companies';
type UserCapability = 'company' | 'driver' | 'traveler' | 'individual';

const SEGMENT_FILTERS: Record<Segment, { op: string; field?: string; value?: any }[]> = {
  all: [],
  individuals: [
    { op: 'eq', field: 'account_type', value: 'individual' },
    { op: 'or', value: 'traveler_status.is.null,traveler_status.eq.none' },
  ],
  drivers: [{ op: 'not_is', field: 'traveler_status', value: null }, { op: 'neq', field: 'traveler_status', value: 'none' }],
  companies: [{ op: 'eq', field: 'account_type', value: 'company' }],
};

export default function UsersPage() {
  const router = useRouter();
  const { toast, confirm: confirmDialog } = useToast();
  const { t, dir } = useI18n();
  const isRtl = dir === 'rtl';

  const [segment, setSegment] = useState<Segment>('all');
  const [data, setData] = useState<Profile[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState<{ key: string; direction: 'asc' | 'desc' } | null>(null);
  const [trustFilter, setTrustFilter] = useState<'all' | 'trusted' | 'featured' | 'blocked'>('all');

  // Create modal
  const [showCreate, setShowCreate] = useState(false);
  const [createForm, setCreateForm] = useState({
    full_name: '',
    email: '',
    phone: '',
    password: '',
    account_type: 'individual' as 'individual' | 'company',
    make_driver: false,
    make_company: false,
    send_invitation: false,
  });
  const [creating, setCreating] = useState(false);
  const [showCreateEnvInfo, setShowCreateEnvInfo] = useState(false);

  function closeCreateModal() {
    setShowCreate(false);
    setShowCreateEnvInfo(false);
  }

  const filtersForSegment = useMemo(() => {
    const base = [...SEGMENT_FILTERS[segment]];
    if (trustFilter === 'trusted') base.push({ op: 'eq', field: 'is_trusted', value: true });
    else if (trustFilter === 'featured') base.push({ op: 'eq', field: 'is_featured', value: true });
    else if (trustFilter === 'blocked') base.push({ op: 'eq', field: 'is_blocked', value: true });
    return base;
  }, [segment, trustFilter]);

  const withTimeout = useCallback(<T,>(promise: PromiseLike<T>, timeoutMs = QUERY_TIMEOUT_MS): Promise<T> => {
    return new Promise<T>((resolve, reject) => {
      const timer = window.setTimeout(() => reject(new Error('Query timeout exceeded')), timeoutMs);
      Promise.resolve(promise)
        .then((value) => resolve(value))
        .catch((error) => reject(error))
        .finally(() => window.clearTimeout(timer));
    });
  }, []);

  const fetchUsers = useCallback(async (opts?: { silent?: boolean }) => {
    const silent = opts?.silent === true;
    setLoading(true);
    try {
      const result = await withTimeout(getPaginatedUsers({
        page,
        pageSize: PAGE_SIZE,
        search,
        filters: filtersForSegment,
        orderBy: sort?.key || 'created_at',
        orderDir: sort?.direction || 'desc',
      }));
      if (result.success) {
        setData((result.data ?? []) as Profile[]);
        setTotalCount(result.totalCount || 0);
      } else {
        setData([]);
        setTotalCount(0);
        if (!silent) toast(result.error || 'Failed to fetch users', 'error');
      }
    } catch (error: any) {
      setData([]);
      setTotalCount(0);
      if (!silent) toast(error?.message || 'Failed to fetch users', 'error');
    } finally {
      setLoading(false);
    }
  }, [page, search, sort, filtersForSegment, toast, withTimeout]);

  useEffect(() => { setPage(1); }, [segment, trustFilter]);
  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  async function exportCurrent() {
    try {
      const res = await withTimeout(getPaginatedUsers({
        page: 1, pageSize: 5000, search, filters: filtersForSegment,
        orderBy: sort?.key || 'created_at', orderDir: sort?.direction || 'desc',
      }));
      if (res.success) {
        exportToCSV(res.data || [], `users_${segment}_export`, (m) => toast(m, 'error'));
      } else {
        toast(res.error || 'Export failed', 'error');
      }
    } catch (error: any) {
      toast(error?.message || 'Export failed', 'error');
    }
  }

  function badgeForUser(u: Profile) {
    if (u.is_blocked) return { label: t('users.badge.blocked', 'Blocked'), cls: 'bg-red-100 text-red-700' };
    if (u.is_suspended) return { label: t('users.badge.disabled', 'Disabled'), cls: 'bg-orange-100 text-orange-700' };
    if (u.is_frozen) return { label: t('users.badge.frozen', 'Frozen'), cls: 'bg-purple-100 text-purple-700' };
    return { label: t('users.badge.active', 'Active'), cls: 'bg-green-100 text-green-700' };
  }

  function capabilitiesForUser(u: Profile): UserCapability[] {
    const caps: UserCapability[] = [];
    const hasCompany = u.account_type === 'company' || !!(u.company_status && u.company_status !== 'none');
    const hasTraveler = !!(u.traveler_status && u.traveler_status !== 'none');
    if (hasCompany) caps.push('company');
    if (hasTraveler) caps.push(u.is_driver ? 'driver' : 'traveler');
    return caps.length ? caps : ['individual'];
  }

  function primaryTypeForUser(u: Profile): UserCapability {
    const caps = capabilitiesForUser(u);
    return caps.includes('company') ? 'company' : caps[0];
  }

  function typeLabelForUser(u: Profile) {
    const fallbackLabels: Record<UserCapability, string> = {
      company: 'Company',
      driver: 'Driver',
      traveler: 'Traveler',
      individual: 'Individual',
    };
    return capabilitiesForUser(u)
      .map((cap) => t(`users.type.${cap}`, fallbackLabels[cap]))
      .join(' + ');
  }

  const columns: Column<Profile>[] = [
    {
      header: t('users.col.user', 'User'),
      accessorKey: 'full_name',
      sortable: true,
      cell: (u) => (
        <div className="flex items-center gap-2">
          <div className={cn(
            'h-7 w-7 rounded-lg flex items-center justify-center text-white font-black text-[0.625rem] shadow-sm',
            primaryTypeForUser(u) === 'company' ? 'bg-purple-600' : ['driver', 'traveler'].includes(primaryTypeForUser(u)) ? 'bg-orange-600' : 'bg-blue-600'
          )}>
            {u.full_name?.[0]?.toUpperCase() || 'U'}
          </div>
          <div>
            <p className="text-xs font-bold theme-heading flex items-center gap-1">
              {u.full_name || '—'}
              {u.is_trusted && <span title={t('users.badge.trusted', 'Trusted')}><ShieldCheck className="h-3 w-3 text-green-500" /></span>}
              {u.is_featured && <span title={t('users.badge.featured', 'Featured')}><Star className="h-3 w-3 text-yellow-500" /></span>}
            </p>
            <p className="text-[0.5625rem] theme-muted font-mono opacity-80">{u.id.slice(0, 8)} · {u.phone_number || '—'}</p>
          </div>
        </div>
      ),
    },
    {
      header: t('users.col.type', 'Type'),
      accessorKey: 'account_type',
      sortable: true,
      cell: (u) => {
        const k = primaryTypeForUser(u);
        return (
          <span className={cn(
            'px-2 py-0.5 rounded-lg text-[0.5625rem] font-black uppercase tracking-widest border',
            k === 'company' ? 'bg-purple-50 text-purple-600 border-purple-200' :
              k === 'driver' || k === 'traveler' ? 'bg-orange-50 text-orange-600 border-orange-200' :
                'bg-blue-50 text-blue-600 border-blue-200'
          )}>
            {typeLabelForUser(u)}
          </span>
        );
      },
    },
    {
      header: t('users.col.status', 'Status'),
      accessorKey: 'is_suspended',
      cell: (u) => {
        const b = badgeForUser(u);
        return <span className={`px-2 py-0.5 rounded-lg text-[0.5625rem] font-black uppercase tracking-widest ${b.cls}`}>{b.label}</span>;
      },
    },
    {
      header: t('users.col.rating', 'Rating'),
      accessorKey: 'traveler_rating_avg',
      cell: (u) => {
        const v = (u.traveler_rating_avg ?? 0) || (u.client_rating_avg ?? 0);
        const c = (u.traveler_rating_count ?? 0) + (u.client_rating_count ?? 0);
        return (
          <div className="flex items-center gap-1 text-[0.6875rem] theme-heading">
            <Star className="h-3 w-3 text-yellow-500" /> {v ? Number(v).toFixed(1) : '—'}
            <span className="theme-muted">({c})</span>
          </div>
        );
      },
    },
    {
      header: t('users.col.joined', 'Joined'),
      accessorKey: 'created_at',
      sortable: true,
      cell: (u) => <span className="text-xs">{new Date(u.created_at).toLocaleDateString()}</span>,
    },
    {
      header: '',
      accessorKey: 'actions',
      cell: (u) => (
        <div className="flex items-center gap-1">
          <button
            onClick={() => router.push(`/users/${u.id}`)}
            className="p-1.5 hover:theme-bg-secondary rounded-lg transition"
            title={t('common.viewDetails', 'View')}>
            <ExternalLink className="h-3.5 w-3.5 theme-muted" />
          </button>
          <button
            onClick={() => onToggleBlock(u)}
            className="p-1.5 hover:bg-red-500/10 rounded-lg transition"
            title={u.is_blocked ? t('users.unblock', 'Unblock') : t('users.block', 'Block')}>
            {u.is_blocked ? <Unlock className="h-3.5 w-3.5 text-red-500" /> : <Lock className="h-3.5 w-3.5 theme-muted" />}
          </button>
        </div>
      ),
    },
  ];

  async function onToggleBlock(u: Profile) {
    confirmDialog({
      title: u.is_blocked ? t('users.unblock', 'Unblock user') : t('users.block', 'Block user'),
      message: u.is_blocked
        ? t('users.unblock.confirm', 'Restore access for this user?')
        : t('users.block.confirm', 'Hard-block this user. They will no longer be able to use the app.'),
      confirmLabel: u.is_blocked ? t('users.unblock', 'Unblock') : t('users.block', 'Block'),
      onConfirm: async () => {
        const res = await setUserBlocked(u.id, !u.is_blocked, undefined);
        if (res.success) {
          toast(u.is_blocked ? t('users.toast.unblocked', 'User unblocked') : t('users.toast.blocked', 'User blocked'), 'success');
          fetchUsers();
        } else {
          toast(res.error || 'Action failed', 'error');
        }
      },
    });
  }

  const bulkActions = [
    {
      label: t('users.bulk.disable', 'Disable Selected'),
      icon: Ban,
      variant: 'danger' as const,
      action: async (items: Profile[]) => {
        const res = await bulkUpdateUserStatus(items.map(i => i.id), { is_suspended: true }, 'disable');
        if (res.success) {
          toast(t('users.toast.disabled', 'Users disabled'), 'success');
          fetchUsers();
        } else {
          toast(res.error || 'Failed', 'error');
        }
      },
    },
    {
      label: t('users.bulk.enable', 'Enable Selected'),
      icon: ShieldCheck,
      action: async (items: Profile[]) => {
        const res = await bulkUpdateUserStatus(items.map(i => i.id), { is_suspended: false }, 'enable');
        if (res.success) {
          toast(t('users.toast.enabled', 'Users enabled'), 'success');
          fetchUsers();
        } else {
          toast(res.error || 'Failed', 'error');
        }
      },
    },
  ];

  async function submitCreate() {
    if (!createForm.full_name.trim()) { toast(t('users.create.nameRequired', 'Full name is required'), 'error'); return; }
    if (!createForm.email.trim() && !createForm.phone.trim()) {
      toast(t('users.create.contactRequired', 'Either email or phone is required'), 'error');
      return;
    }
    setCreating(true);
    const res = await createUserAccount({
      email: createForm.email.trim() || undefined,
      phone: createForm.phone.trim() || undefined,
      password: createForm.password.trim() || undefined,
      full_name: createForm.full_name.trim(),
      account_type: createForm.account_type,
      make_driver: createForm.make_driver,
      make_company: createForm.account_type === 'company' || createForm.make_company,
      send_invitation: createForm.send_invitation,
    });
    setCreating(false);

    if (res.success) {
      const passwordMsg = res.generatedPassword
        ? `\n\n${t('users.create.tempPassword', 'Temporary password')}: ${res.generatedPassword}`
        : '';
      toast(t('users.create.success', 'User created') + passwordMsg, 'success');
      closeCreateModal();
      setCreateForm({
        full_name: '', email: '', phone: '', password: '', account_type: 'individual',
        make_driver: false, make_company: false, send_invitation: false,
      });
      fetchUsers({ silent: true });
    } else {
      toast(res.error || t('users.create.failed', 'Create failed'), 'error');
    }
  }

  return (
    <div className="flex flex-col h-full">
      {/* Compact Header */}
      <div className="flex items-center justify-between gap-4 pb-3 flex-shrink-0">
        <div>
          <h1 className="text-2xl font-black theme-heading tracking-tight">
            {t('users.title', 'User Management')}
          </h1>
        </div>
        <div className="flex items-center gap-2">
          <div className="theme-bg-secondary px-3 py-1.5 rounded-lg border border-[var(--surface-border)] text-xs theme-heading">
            <span className="font-bold">{totalCount}</span> {t('users.total', 'users')}
          </div>
          <button onClick={exportCurrent} className="flex items-center gap-1.5 px-3 py-1.5 bg-green-500/10 text-green-600 rounded-lg hover:bg-green-500/20 transition border border-green-500/20 text-xs font-bold">
            <Download className="h-3.5 w-3.5" /> {t('common.exportCsv', 'CSV')}
          </button>
          <button onClick={() => setShowCreate(true)} className="flex items-center gap-1.5 px-3 py-1.5 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition shadow-sm font-bold text-xs">
            <UserPlus className="h-3.5 w-3.5" /> {t('users.create', 'Create')}
          </button>
        </div>
      </div>

      {/* Compact Segment tabs */}
      <div className="flex flex-wrap items-center gap-1.5 pb-3 flex-shrink-0">
        {([
          { id: 'all', label: t('users.segment.all', 'All'), icon: User },
          { id: 'individuals', label: t('users.segment.individuals', 'Individuals'), icon: User },
          { id: 'drivers', label: t('users.segment.drivers', 'Drivers / Travelers'), icon: Truck },
          { id: 'companies', label: t('users.segment.companies', 'Merchants / Companies'), icon: Building2 },
        ] as const).map(s => {
          const Icon = s.icon;
          return (
            <button
              key={s.id}
              onClick={() => setSegment(s.id)}
              className={cn(
                'inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[0.6875rem] font-bold transition',
                segment === s.id
                  ? 'bg-orange-600 text-white shadow-sm'
                  : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
              )}
            >
              <Icon className="h-3.5 w-3.5" />
              {s.label}
            </button>
          );
        })}
      </div>

      {/* Compact Filter Bar */}
      <div className="flex items-center gap-3 pb-3 flex-shrink-0">
        <div className="relative flex-1 max-w-xs">
          <Search className={`absolute ${isRtl ? 'right-2.5' : 'left-2.5'} top-1/2 -translate-y-1/2 h-3.5 w-3.5 theme-muted opacity-50`} />
          <input
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            placeholder={t('users.search.placeholder', 'Search...')}
            className={`w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg ${isRtl ? 'pr-9 pl-3' : 'pl-9 pr-3'} py-1.5 text-sm theme-heading focus:ring-1 focus:ring-blue-500/20 outline-none transition`}
          />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          {(['all', 'trusted', 'featured', 'blocked'] as const).map(f => (
            <button
              key={f}
              onClick={() => setTrustFilter(f)}
              className={`px-2.5 py-1 rounded-lg text-[0.6875rem] font-bold whitespace-nowrap transition-all ${
                trustFilter === f
                  ? f === 'trusted' ? 'bg-green-600 text-white' :
                    f === 'featured' ? 'bg-yellow-500 text-white' :
                    f === 'blocked' ? 'bg-red-600 text-white' :
                    'bg-blue-600 text-white'
                  : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
              }`}
            >
              {t(`users.filter.${f}`, f)}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 min-h-0">
        <DataTable
          data={data}
          columns={columns}
          totalCount={totalCount}
          pageSize={PAGE_SIZE}
          currentPage={page}
          onPageChange={setPage}
          onSort={(key, dir) => setSort({ key, direction: dir })}
          isLoading={loading}
          bulkActions={bulkActions}
          hideColumnSelector={true}
        />
      </div>

      {/* Create user modal */}
      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => !creating && closeCreateModal()}>
          <div className="form-on-light bg-[var(--surface)] rounded-2xl shadow-2xl border border-[var(--surface-border)] max-w-lg w-full max-h-[90vh] overflow-hidden flex flex-col" onClick={e => e.stopPropagation()}>
            <div className="p-6 border-b border-[var(--surface-border)] theme-bg-secondary flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-black theme-heading">{t('users.create.title', 'Create User')}</h2>
                <p className="theme-muted text-sm mt-1 opacity-80">{t('users.create.subtitle', 'Provision a new account from the admin console.')}</p>
              </div>
              <button onClick={closeCreateModal} className="p-1 theme-muted hover:theme-heading transition"><X className="h-5 w-5" /></button>
            </div>

            <div className="p-6 overflow-y-auto flex-1 space-y-4">
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setShowCreateEnvInfo(v => !v)}
                  className="inline-flex items-center gap-1.5 text-[0.625rem] font-black uppercase tracking-widest text-blue-600 hover:text-blue-700"
                >
                  <Info className="h-3.5 w-3.5" />
                  {t('users.create.info', 'Setup info')}
                </button>
                {showCreateEnvInfo && (
                  <div className="mt-2 bg-yellow-50 border border-yellow-200 text-yellow-800 text-xs p-3 rounded-xl flex gap-2 items-start">
                    <AlertTriangle className="h-4 w-4 flex-shrink-0 mt-0.5" />
                    <div>
                      <strong>{t('users.create.requiresEnv', 'Requires SUPABASE_SERVICE_ROLE_KEY')}</strong>
                      {' '}{t('users.create.requiresEnv.body', 'in Supabase Edge Function secrets for admin-action (not admin/.env.local). Otherwise the create call will fail.')}
                    </div>
                  </div>
                )}
              </div>

              <div>
                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">
                  {t('users.create.fullName', 'Full Name')} *
                </label>
                <input value={createForm.full_name} onChange={e => setCreateForm(f => ({ ...f, full_name: e.target.value }))} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 outline-none" />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('users.create.email', 'Email')}</label>
                  <input type="email" value={createForm.email} onChange={e => setCreateForm(f => ({ ...f, email: e.target.value }))} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 outline-none" />
                </div>
                <div>
                  <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('users.create.phone', 'Phone')}</label>
                  <input type="tel" value={createForm.phone} onChange={e => setCreateForm(f => ({ ...f, phone: e.target.value }))} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 outline-none" placeholder="+9665XXXXXXX" />
                </div>
              </div>

              <div>
                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">
                  {t('users.create.password', 'Password')} <span className="text-[0.625rem] opacity-60">({t('users.create.password.optional', 'auto-generate if blank')})</span>
                </label>
                <input type="text" value={createForm.password} onChange={e => setCreateForm(f => ({ ...f, password: e.target.value }))} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 outline-none" placeholder={t('users.create.password.placeholder', 'min 6 chars')} />
              </div>

              <div>
                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-2">{t('users.create.accountType', 'Account Type')}</label>
                <div className="flex gap-2">
                  {(['individual', 'company'] as const).map(type => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => setCreateForm(f => ({ ...f, account_type: type, make_company: type === 'company' }))}
                      className={cn(
                        'flex-1 px-4 py-2.5 rounded-xl text-xs font-black uppercase tracking-widest border transition',
                        createForm.account_type === type
                          ? 'bg-orange-600 text-white border-orange-600'
                          : 'theme-bg-secondary theme-muted border-[var(--surface-border)] hover:theme-heading'
                      )}
                    >
                      {t(`users.type.${type}`, type)}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" checked={createForm.make_driver} onChange={e => setCreateForm(f => ({ ...f, make_driver: e.target.checked }))} className="rounded border-[var(--surface-border)] w-4 h-4 text-orange-600 focus:ring-orange-500/20" />
                  <span className="text-sm theme-heading">{t('users.create.makeDriver', 'Also start driver/traveler review (pending, driver-capable)')}</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" checked={createForm.send_invitation} onChange={e => setCreateForm(f => ({ ...f, send_invitation: e.target.checked }))} className="rounded border-[var(--surface-border)] w-4 h-4 text-orange-600 focus:ring-orange-500/20" />
                  <span className="text-sm theme-heading">{t('users.create.sendInvite', 'Send email invitation (requires email)')}</span>
                </label>
              </div>
            </div>

            <div className="p-6 border-t border-[var(--surface-border)] flex justify-end gap-3 theme-bg-secondary">
              <button type="button" onClick={closeCreateModal} disabled={creating} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition disabled:opacity-50">
                {t('common.cancel', 'Cancel')}
              </button>
              <button type="button" onClick={submitCreate} disabled={creating} className="flex items-center gap-2 px-8 py-2.5 rounded-xl bg-orange-600 text-white hover:bg-orange-700 font-bold disabled:opacity-50 transition shadow-sm">
                <Save className="h-4 w-4" /> {creating ? t('common.saving', 'Saving...') : t('users.create.button', 'Create user')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function cn(...classes: any[]) {
  return classes.filter(Boolean).join(' ');
}
