'use client';

import { useEffect, useState, useCallback } from 'react';
import { useParams, usePathname, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { signedUserDocUrl } from '@/lib/storage';
import { useToast } from '@/lib/toast';
import { Profile, Vehicle } from '@/lib/types';
import {
  ArrowLeft, User, Phone, Calendar, Shield, ShieldCheck, ShieldX, Ban,
  Truck, Route, Star, FileText, Eye, Clock, CheckCircle, XCircle,
  AlertTriangle, MessageSquare, Flag, Send, X, Download, AlertOctagon,
  Lock, Unlock, Trash2, ShieldAlert, History, Gavel, Activity, ShieldOff,
  TrendingUp, TrendingDown, Info, AlertCircle, UserCheck,
  FileCheck2, CalendarClock, UserMinus, ShieldQuestion, CheckCircle2, Upload,
  BarChart3, ArrowRight, Award
} from 'lucide-react';
import Loading from '@/app/loading';
import { useT } from '@/lib/i18n';
import { toggleUserSuspension, updateUserCapabilities, updateUserGovernance, updateVerificationStatus } from '@/app/actions/user-actions';
import { getUserRiskMetrics, issueUserRestriction, liftUserRestriction } from '@/app/actions/governance-actions';
import { sendAdminNotification } from '@/app/actions/notification-actions';
import { getUserRiskData, adjustUserRiskScore } from '@/app/actions/moderation-actions';
import { advanceVerificationStep, flagFraudAccount, manualOverrideExpiry } from '@/app/actions/verification-actions';
import { setUserBlocked, setUserDisabled } from '@/app/actions/user-actions';
import { UserRestriction, RiskScore, RiskHistory } from '@/lib/types';
import { QuickActionStrip } from '@/components/QuickActionStrip';
import { UserEditModal } from '@/components/UserEditModal';
import { TrustBadgeControls } from '@/components/TrustBadgeControls';
import { SendNotificationModal } from '@/components/SendNotificationModal';
import { resolveExportedDynamicRouteId } from '@/lib/export-dynamic-route';
import { UserActivityTab } from '@/components/UserActivityTab';
import { Pencil } from 'lucide-react';



type TabKey = 'overview' | 'documents' | 'vehicles' | 'trips' | 'bookings' | 'ratings' | 'reports' | 'activity';
type BlockTarget = 'account' | 'driver';
type UserDocField = 'identity_doc_url' | 'traveler_license_url' | 'rental_contract_url';
type PendingDocField = 'identity_doc_url_pending' | 'traveler_license_url_pending' | 'rental_contract_url_pending';

export default function UserDetailPage() {
  const params = useParams();
  const pathname = usePathname();
  const router = useRouter();
  const { toast, confirm: confirmDialog } = useToast();
  const t = useT();
  const resolvedId = resolveExportedDynamicRouteId(
    params.id as string | string[] | undefined,
    pathname
  );
  const id = resolvedId ?? '';

  const [user, setUser] = useState<Profile | null>(null);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [trips, setTrips] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [ratings, setRatings] = useState<any[]>([]);
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabKey>('overview');

  // Block dialog state
  const [blockDialog, setBlockDialog] = useState<{ open: boolean; target: BlockTarget }>({ open: false, target: 'account' });
  const [blockReason, setBlockReason] = useState('');
  const [sendNotification, setSendNotification] = useState(true);
  const [blocking, setBlocking] = useState(false);

  // Edit profile modal
  const [editModal, setEditModal] = useState(false);

  // Send notification to this user (modal)
  const [notifModal, setNotifModal] = useState(false);
  // Governance local state
  const [updatingGovernance, setUpdatingGovernance] = useState(false);
  // Signed URLs for user_documents references, keyed by the raw stored value
  // (path or legacy full URL). The bucket is private; admins are authorised
  // via storage RLS (is_admin()).
  const [signedUrls, setSignedUrls] = useState<Record<string, string>>({});
  const [loadError, setLoadError] = useState<string | null>(null);
  const [riskMetrics, setRiskMetrics] = useState<{ total: number; disputed: number; rate: number } | null>(null);
  const [restrictions, setRestrictions] = useState<UserRestriction[]>([]);
  const [riskData, setRiskData] = useState<{ score: RiskScore | null; history: RiskHistory[] }>({ score: null, history: [] });
  const [workflow, setWorkflow] = useState<{ current_step: string; is_fraud_flagged: boolean; fraud_notes?: string } | null>(null);
  const [fetchingGov, setFetchingGov] = useState(false);
  const [uploadingDocField, setUploadingDocField] = useState<UserDocField | null>(null);

  // Resolve a stored user_documents reference (path or legacy full URL) to a
  // short-lived signed URL. user_documents is a private bucket; admins are
  // authorised by the storage RLS policy (is_admin()).
  const resolveDocUrl = useCallback(
    (value: string): Promise<string | null> => signedUserDocUrl(value),
    [],
  );

  const pendingFieldFor: Record<UserDocField, PendingDocField> = {
    identity_doc_url: 'identity_doc_url_pending',
    traveler_license_url: 'traveler_license_url_pending',
    rental_contract_url: 'rental_contract_url_pending',
  };

  async function uploadUserDocument(field: UserDocField, file: File) {
    if (!resolvedId) {
      toast(t('users.detail.invalidId', 'Invalid user URL. Please open the user from the Users list.'), 'error');
      return;
    }
    setUploadingDocField(field);
    try {
      const ext = file.name.split('.').pop() || 'bin';
      const safeExt = ext.toLowerCase().replace(/[^a-z0-9]/g, '') || 'bin';
      const filePath = `${resolvedId}/documents/${field}-${Date.now()}.${safeExt}`;

      const { error: uploadError } = await supabase.storage
        .from('user_documents')
        .upload(filePath, file, { upsert: false });
      if (uploadError) throw uploadError;

      const pendingField = pendingFieldFor[field];
      const patch: Record<string, unknown> = {
        [field]: filePath,
        [pendingField]: null,
      };
      const { error: updateError } = await supabase
        .from('profiles')
        .update(patch)
        .eq('id', resolvedId);
      if (updateError) throw updateError;

      setUser(prev => prev ? ({ ...prev, [field]: filePath, [pendingField]: null } as Profile) : prev);
      const signed = await resolveDocUrl(filePath);
      if (signed) setSignedUrls(prev => ({ ...prev, [filePath]: signed }));
      toast(t('users.detail.documents.uploadSuccess', 'Document updated successfully'), 'success');
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('users.detail.documents.uploadFailed', 'Failed to update document');
      toast(msg, 'error');
    } finally {
      setUploadingDocField(null);
    }
  }

  useEffect(() => {
    if ((activeTab !== 'documents' && activeTab !== 'vehicles') || !user) return;
    // Sign every non-null document reference (path OR legacy full URL),
    // keyed by the raw stored value so the display can look it up directly.
    const values: string[] = [];
    if (user.identity_doc_url) values.push(user.identity_doc_url);
    if (user.traveler_license_url) values.push(user.traveler_license_url);
    if (user.rental_contract_url) values.push(user.rental_contract_url);
    vehicles.forEach(v => {
      if (v.registration_doc_url) values.push(v.registration_doc_url);
      if (v.vehicle_photo_url) values.push(v.vehicle_photo_url);
    });
    const toFetch = values.filter(v => !signedUrls[v]);
    if (toFetch.length === 0) return;
    let cancelled = false;
    (async () => {
      const next: Record<string, string> = {};
      await Promise.all(toFetch.map(async (value) => {
        const url = await resolveDocUrl(value);
        if (url) next[value] = url;
      }));
      if (!cancelled && Object.keys(next).length) {
        setSignedUrls(prev => ({ ...prev, ...next }));
      }
    })();
    return () => { cancelled = true; };
  }, [activeTab, user, vehicles, signedUrls, resolveDocUrl]);

  useEffect(() => {
    if (resolvedId) fetchAll();
    else {
      setLoading(false);
      setLoadError(t('users.detail.invalidId', 'Invalid user URL. Please open the user from the Users list.'));
    }
  }, [resolvedId]);

  async function fetchAll() {
    if (!resolvedId) return;
    setLoading(true);
    setLoadError(null);
    try {
      const [profileRes, vehiclesRes, tripsRes, bookingsRes, ratingsRes, reportsRes] = await Promise.all([
        supabase.from('profiles').select('*').eq('id', id).single(),
        supabase.from('vehicles').select('*').eq('owner_id', id),
        supabase.from('trips').select('*, origin_loc:locations!trips_origin_location_id_fkey(city_name_en, province_name_en), dest_loc:locations!trips_dest_location_id_fkey(city_name_en, province_name_en)').eq('traveler_id', id).order('created_at', { ascending: false }).limit(20),
        supabase.from('bookings').select('*, trips(id, status)').or(`traveler_id.eq.${id},requester_id.eq.${id}`).order('created_at', { ascending: false }).limit(20),
        supabase.from('ratings').select('*, rater:profiles!ratings_rater_id_fkey(full_name)').eq('rated_id', id).order('created_at', { ascending: false }).limit(50),
        supabase.from('reports').select('*, reporter:profiles!reports_reporter_id_fkey(full_name)').eq('reported_id', id).order('created_at', { ascending: false }).limit(50),
      ]);
      if (profileRes.error) {
        setLoadError(profileRes.error.message || t('users.detail.errorLoad', 'Failed to load user.'));
        toast(t('users.detail.errorLoad', 'Failed to load user.'), 'error');
        setUser(null);
      } else {
        setUser(profileRes.data as Profile | null);
      }
      const relatedErrors = [
        { label: t('users.detail.tab.vehicles', 'Vehicles'), error: vehiclesRes.error },
        { label: t('users.detail.tab.trips', 'Trips'), error: tripsRes.error },
        { label: t('users.detail.tab.bookings', 'Bookings'), error: bookingsRes.error },
        { label: t('users.detail.tab.ratings', 'Ratings'), error: ratingsRes.error },
        { label: t('users.detail.tab.reports', 'Reports'), error: reportsRes.error },
      ].filter(item => item.error);
      if (relatedErrors.length > 0) {
        console.warn('[UserDetail] Partial user detail load failed:', relatedErrors.map(item => item.error));
        toast(
          t('users.detail.toast.partialLoadFailed', 'Some user detail sections could not be loaded: {sections}')
            .replace('{sections}', relatedErrors.map(item => item.label).join(', ')),
          'error'
        );
      }
      setVehicles((vehiclesRes.data as Vehicle[]) || []);
      setTrips(tripsRes.data || []);
      setBookings(bookingsRes.data || []);
      setRatings(ratingsRes.data || []);
      setReports(reportsRes.data || []);

      // Fetch Governance Data
      setFetchingGov(true);
      const [riskRes, restRes] = await Promise.all([
        getUserRiskMetrics(id),
        supabase.from('user_restrictions').select('*').eq('user_id', id).order('created_at', { ascending: false })
      ]);
      setRiskMetrics(riskRes.success ? (riskRes.metrics as any) : null);
      setRestrictions(restRes.data || []);

      // Fetch Risk Data (Stage 5)
      const riskDataRes = await getUserRiskData(id);
      if (riskDataRes.success) {
        setRiskData({ score: riskDataRes.score, history: (riskDataRes.history as any) || [] });
      }

      // Fetch Verification Workflow (Stage 2)
      const { data: workflowData, error: workflowError } = await supabase.from('verification_workflow').select('*').eq('entity_id', id).maybeSingle();
      if (workflowError) {
        console.warn('[UserDetail] Failed to load verification workflow:', workflowError.message);
        toast(t('users.detail.toast.workflowLoadFailed', 'Verification workflow could not be loaded'), 'error');
      }
      setWorkflow(workflowData);

      setFetchingGov(false);
    } catch (e) {
      const msg = e instanceof Error ? e.message : t('users.detail.errorLoad', 'Failed to load user.');
      setLoadError(msg);
      toast(msg, 'error');
      setUser(null);
    } finally {
      setFetchingGov(false);
      setLoading(false);
    }
  }

  function openBlockDialog(target: BlockTarget) {
    setBlockDialog({ open: true, target });
    setBlockReason('');
    setSendNotification(true);
  }

  function closeBlockDialog() {
    setBlockDialog({ open: false, target: 'account' });
    setBlockReason('');
    setBlocking(false);
  }

  async function executeBlock() {
    if (!user) return;
    setBlocking(true);
    const { target } = blockDialog;

    try {
      if (target === 'account') {
        const res = await toggleUserSuspension(id, user.is_suspended ?? false, blockReason.trim());
        if (res.success) {
          setUser(prev => prev ? { ...prev, is_suspended: !(prev.is_suspended ?? false) } : null);
          toast(t('users.detail.toast.blockSuccess', 'Success'), 'success');
          closeBlockDialog();
        } else {
          toast(res.error || t('users.detail.toast.blockFailed', 'Failed'), 'error');
        }
        setBlocking(false);
        return;
      }

      const updates: Record<string, any> = {};
      let label = '';

      if (target === 'driver') {
        updates.traveler_status = 'blocked';
        label = t('users.detail.blockLabel.driver');
      }

      // Use server action to enforce role check and audit logging
      const blockRes = await updateVerificationStatus(id, 'driver', 'blocked');
      if (!blockRes.success) { toast(blockRes.error || t('users.detail.toast.blockFailed'), 'error'); setBlocking(false); return; }

      // Send notification via server action if enabled
      if (sendNotification) {
        const reason = blockReason.trim();
        const title = t('users.detail.notifTitle.driver');
        const bodyPart = t('users.detail.notifBody.blocked').replace('{target}', target);
        const body = reason ? bodyPart + t('users.detail.notifBody.reason').replace('{reason}', reason) : bodyPart + t('users.detail.notifBody.byAdmin');
        await sendAdminNotification({ mode: 'single', targetUserId: id, title, body });
      }

      // Update local state
      setUser(prev => prev ? { ...prev, ...updates } : null);
      toast(label, 'success');
      closeBlockDialog();
    } catch (e) {
      toast(t('users.detail.toast.errorOccurred'), 'error');
      setBlocking(false);
    }
  }

  async function unblock(target: BlockTarget) {
    if (!user) return;
    const label = target === 'account' ? 'unsuspend' : `unblock ${target}`;
    const name = user.full_name || t('common.thisUser');
    confirmDialog({
      title: t('users.detail.dialog.unblockTitle'),
      message: t('users.detail.dialog.unblockConfirm').replace('{label}', label).replace('{name}', name),
      confirmLabel: t('users.detail.dialog.unblockLabel'),
      onConfirm: async () => {
        if (target === 'account') {
          const res = await toggleUserSuspension(id, true, 'Unblocked by admin');
          if (res.success) {
            setUser(prev => prev ? { ...prev, is_suspended: false } : null);
            toast(t('users.detail.toast.unblockSuccess').replace('{label}', label), 'success');
          } else {
            toast(res.error || t('users.detail.toast.updateFailed'), 'error');
          }
          return;
        }

        const updates: Record<string, any> = {};
        if (target === 'driver') updates.traveler_status = 'approved';

        // Use server action to enforce role check and audit logging
        const unblockRes = await updateVerificationStatus(id, 'driver', 'approved');
        if (!unblockRes.success) { toast(unblockRes.error || t('users.detail.toast.updateFailed'), 'error'); return; }
        setUser(prev => prev ? { ...prev, ...updates } : null);
        toast(t('users.detail.toast.unblockSuccess').replace('{label}', label), 'success');

        const targetLabel = t('users.detail.dialog.targetDriverAccount');
        await sendAdminNotification({
          mode: 'single',
          targetUserId: id,
          title: t('users.detail.dialog.accountRestored'),
          body: t('users.detail.dialog.accountRestoredBody').replace('{target}', targetLabel),
        });
      }
    });
  }

  async function updateDriverStatus(status: string) {
    if (status === 'blocked') { openBlockDialog('driver'); return; }
    const res = await updateVerificationStatus(id, 'driver', status);
    if (!res.success) { toast(res.error || t('users.detail.toast.updateFailed'), 'error'); return; }
    setUser(prev => prev ? { ...prev, traveler_status: status as any } : null);
    toast(t('users.detail.toast.driverStatusSet').replace('{status}', status), 'success');
  }

  async function applyCapabilityUpdate(updates: Partial<Profile>, successMessage: string) {
    const res = await updateUserCapabilities(id, updates as Parameters<typeof updateUserCapabilities>[1]);
    if (!res.success) {
      toast(res.error || t('users.detail.toast.updateFailed'), 'error');
      return;
    }
    setUser(prev => prev ? { ...prev, ...updates } as Profile : null);
    toast(successMessage, 'success');
  }

  async function enableTraveler() {
    await applyCapabilityUpdate({
      traveler_status: 'approved',
      is_driver: false,
      traveler_type: user?.traveler_type && user.traveler_type !== 'without_vehicle'
        ? user.traveler_type
        : 'no_vehicle',
    }, t('users.detail.toast.travelerEnabled', 'Traveler capability enabled'));
  }

  async function enableDriver() {
    await applyCapabilityUpdate({
      traveler_status: 'approved',
      traveler_type: 'with_vehicle',
      is_driver: true,
    }, t('users.detail.toast.driverEnabled', 'Driver capability enabled'));
  }

  if (loading) return <Loading />;
  if (loadError) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-4">
        <p className="theme-muted text-center">{loadError}</p>
        <div className="flex gap-2">
          <button onClick={() => fetchAll()} className="px-4 py-2 rounded-lg font-medium" style={{ backgroundColor: 'var(--accent)', color: 'var(--accent-foreground)' }}>
            {t('common.retry', 'Retry')}
          </button>
          <button onClick={() => router.push('/users')} className="text-blue-600 hover:underline">
            {t('users.detail.backToUsers', 'Back to Users')}
          </button>
        </div>
      </div>
    );
  }
  if (!user) return (
    <div className="flex flex-col items-center justify-center py-20">
      <p className="theme-muted mb-4 italic opacity-60 uppercase text-[0.625rem] font-black tracking-widest">{t('users.detail.notFound')}</p>
      <button onClick={() => router.push('/users')} className="text-blue-600 hover:underline font-black uppercase text-[0.625rem] tracking-widest">
        {t('users.detail.backToUsers', 'Back to Users')}
      </button>
    </div>
  );

  const tabs: { key: TabKey; label: string; icon: any; count?: number }[] = [
    { key: 'overview', label: t('users.detail.tab.overview', 'Overview'), icon: User },
    { key: 'documents', label: t('users.detail.tab.documents', 'Documents'), icon: FileText },
    { key: 'vehicles', label: t('users.detail.tab.vehicles', 'Vehicles'), icon: Truck, count: vehicles.length },
    { key: 'trips', label: t('users.detail.tab.trips', 'Trips'), icon: Route, count: trips.length },
    { key: 'bookings', label: t('users.detail.tab.bookings', 'Bookings'), icon: MessageSquare, count: bookings.length },
    { key: 'ratings', label: t('users.detail.tab.ratings', 'Ratings'), icon: Star, count: ratings.length },
    { key: 'reports', label: t('users.detail.tab.reports', 'Reports'), icon: Flag, count: reports.length },
    { key: 'activity', label: t('users.detail.tab.activity', 'Activity'), icon: Activity },
  ];

  const statusBadge = (status: string | undefined | null) => {
    const colors: Record<string, string> = {
      approved: 'bg-green-500/10 text-green-600 border border-green-500/20',
      pending: 'bg-amber-500/10 text-amber-600 border border-amber-500/20',
      rejected: 'bg-red-500/10 text-red-600 border border-red-500/20',
      none: 'theme-bg-secondary theme-muted border border-[var(--surface-border)]',
      completed: 'bg-teal-500/10 text-teal-600 border border-teal-500/20',
      cancelled: 'bg-red-500/10 text-red-600 border border-red-500/20',
      in_transit: 'bg-blue-500/10 text-blue-600 border border-blue-500/20',
      available: 'bg-emerald-500/10 text-emerald-600 border border-emerald-500/20',
      accepted: 'bg-indigo-500/10 text-indigo-600 border border-indigo-500/20',
      delivered: 'bg-cyan-500/10 text-cyan-600 border border-cyan-500/20',
      blocked: 'bg-red-600 text-white shadow-lg shadow-red-600/20',
      suspended: 'bg-red-600 text-white shadow-lg shadow-red-600/20',
    };
    const s = status || 'none';
    const label = t(`users.detail.status.${s}` as 'users.detail.status.approved', s.replace(/_/g, ' '));
    return <span className={`px-2.5 py-1 rounded-lg text-[0.625rem] font-black uppercase tracking-widest shadow-sm ${colors[s] || 'theme-bg-secondary theme-muted'}`}>{label}</span>;
  };

  const badgeTierLabel = (tier: string | null | undefined) => {
    const labels: Record<string, string> = {
      trusted_driver: t('badges.tier.trustedDriver', 'Trusted Driver'),
      featured_driver: t('badges.tier.featuredDriver', 'Featured Driver'),
      verified_partner: t('badges.tier.verifiedPartner', 'Verified Partner'),
    };
    if (!tier) return t('badges.tier.none', 'None');
    return labels[tier] || tier.replace(/_/g, ' ');
  };

  const badgeTierBadge = (tier: string | null | undefined) => {
    if (!tier) return null;
    const colors: Record<string, string> = {
      trusted_driver: 'bg-green-500/10 text-green-600 border-green-500/20',
      featured_driver: 'bg-yellow-500/10 text-yellow-700 border-yellow-500/20',
      verified_partner: 'bg-blue-500/10 text-blue-600 border-blue-500/20',
    };
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded bg-green-500/10 text-[0.625rem] font-black uppercase tracking-widest border ${colors[tier] || 'theme-bg-secondary theme-muted border-[var(--surface-border)]'}`}>
        <Award className="h-3.5 w-3.5" />
        {badgeTierLabel(tier)}
      </span>
    );
  };

  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <button onClick={() => router.push('/users')} className="flex items-center gap-2 theme-muted hover:theme-heading text-[0.625rem] font-black uppercase tracking-widest transition-all opacity-60 hover:opacity-100">
          <ArrowLeft className="h-4 w-4" /> {t('users.detail.backToUsers', 'Back to Users')}
        </button>
        <div className="flex gap-2">
          <button
            onClick={() => setEditModal(true)}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-xl bg-orange-600 text-white hover:bg-orange-700 active:scale-95 shadow-orange-600/20"
          >
            <Pencil className="h-4 w-4" /> {t('users.detail.editProfile', 'Edit Profile')}
          </button>
          <button
            onClick={() => setNotifModal(true)}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-xl bg-blue-600 text-white hover:bg-blue-700 active:scale-95 shadow-blue-600/20"
          >
            <Send className="h-4 w-4" /> {t('users.detail.sendNotification', 'Send Notification')}
          </button>
        </div>
      </div>

      {/* Founder Mode: Quick Action Strip */}
      <QuickActionStrip
        actions={[
          {
            label: user.is_suspended ? t('users.actions.unsuspend') : t('users.actions.suspend'),
            icon: user.is_suspended ? ShieldCheck : Ban,
            variant: user.is_suspended ? 'primary' : 'danger',
            shortcut: 'X',
            onClick: () => user.is_suspended ? unblock('account') : openBlockDialog('account')
          },
          {
            label: t('users.detail.action.restrict'),
            icon: ShieldOff,
            variant: 'warning',
            shortcut: 'R',
            onClick: async () => {
              const type = prompt(t('users.detail.prompt.restrictionType'), "no_booking");
              if (!type) return;
              if (!['no_booking', 'no_shipping', 'read_only', 'shadow_ban'].includes(type)) {
                toast(t('users.detail.restrictions.invalidType', 'Invalid restriction type'), 'error');
                return;
              }
              const reason = prompt(t('users.detail.prompt.reason'));
              if (!reason) return;
              const res = await issueUserRestriction(id, type as any, reason);
              if (res.success) {
                toast(t('users.detail.restrictions.issue.success', 'Restriction issued'), 'success');
                fetchAll();
              } else {
                toast(res.error || t('users.detail.restrictions.issue.failed', 'Issue failed'), 'error');
              }
            }
          },
          {
            label: t('users.detail.action.addNote'),
            icon: FileText,
            shortcut: 'N',
            onClick: async () => {
              const note = prompt(t('users.detail.prompt.internalNote'), user.internal_notes || "");
              if (note === null) return;
              const res = await updateUserGovernance(id, { internal_notes: note });
              if (res.success) {
                setUser(prev => prev ? { ...prev, internal_notes: note } : null);
                toast(t('users.detail.toast.noteUpdated', 'Internal note updated'), 'success');
              } else {
                toast(res.error || t('users.detail.toast.updateFailed'), 'error');
              }
            }
          },
          {
            label: t('users.detail.action.auditTrail'),
            icon: History,
            onClick: () => router.push(`/audit-log?entity_id=${id}`)
          },
          {
            label: t('users.detail.action.fraudFlag'),
            icon: AlertOctagon,
            variant: 'danger',
            onClick: async () => {
              const reason = prompt(t('users.detail.prompt.fraudReason'));
              if (!reason) return;
              const res = await flagFraudAccount(id, reason);
              if (res.success) {
                toast(t('users.detail.toast.fraudFlagged', 'Fraud flag saved'), 'success');
                fetchAll();
              } else {
                toast(res.error || t('users.detail.toast.updateFailed'), 'error');
              }
            }
          }
        ]}
      />

      {/* Profile Card */}
      <div className="theme-card rounded-[2rem] shadow-2xl p-10 mb-6 border border-[var(--surface-border)] relative overflow-hidden group">
        <div className="absolute top-0 right-0 -mr-20 -mt-20 w-80 h-80 bg-blue-500/5 rounded-full blur-[100px] pointer-events-none group-hover:bg-blue-500/10 transition-all duration-700"></div>
        <div className="flex items-start gap-8 relative">
          <div className="h-24 w-24 rounded-[1.75rem] bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white text-4xl font-black shadow-2xl shadow-blue-600/30 transform group-hover:rotate-3 transition-transform">
            {user.full_name?.[0]?.toUpperCase() || 'U'}
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-3 mb-1">
              <h1 className="text-3xl font-black theme-heading tracking-tight italic uppercase">{user.full_name || t('users.detail.anonymous')}</h1>
              {user.is_admin && <span className="px-2.5 py-1 rounded bg-purple-500/10 text-purple-600 text-[0.625rem] font-black uppercase tracking-widest border border-purple-500/20">{t('users.detail.badge.admin')}</span>}
              {user.is_suspended && <span className="px-2.5 py-1 rounded bg-red-600 text-white text-[0.625rem] font-black uppercase tracking-widest shadow-lg shadow-red-600/20">{t('users.status.suspendedBadge', 'Suspended')}</span>}
              {user.traveler_status === 'blocked' && <span className="px-2.5 py-1 rounded bg-red-600 text-white text-[0.625rem] font-black uppercase tracking-widest shadow-lg shadow-red-600/20">{t('users.detail.badge.driverBlocked')}</span>}
              {badgeTierBadge(user.trust_badge)}
            </div>
            <p className="text-[0.6875rem] theme-muted font-black uppercase tracking-widest opacity-40 mb-3">{user.id}</p>
            <div className="flex gap-8 mt-4 text-[0.75rem] theme-muted font-bold">
              <span className="flex items-center gap-2"><Phone className="h-4 w-4 opacity-50" /> {user.phone_number || t('common.na')}</span>
              <span className="flex items-center gap-2"><Calendar className="h-4 w-4 opacity-50" /> {t('users.detail.joined')} {new Date(user.created_at).toLocaleDateString()}</span>
            </div>
            <div className="flex gap-3 mt-5">
              {statusBadge(user.traveler_status)}
            </div>
          </div>
          <div className="text-right space-y-3">
            <div className="theme-bg-secondary/50 p-4 rounded-2xl border border-[var(--surface-border)] shadow-sm">
              <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1 opacity-60">{t('users.detail.driverRating')}</p>
              <div className="flex items-end justify-end gap-1.5">
                <p className="text-2xl font-black theme-heading leading-none">{user.traveler_rating_avg ? Number(user.traveler_rating_avg).toFixed(1) : '—'}</p>
                <p className="text-[0.6875rem] font-bold theme-muted opacity-40 pb-0.5">/ {user.traveler_rating_count || 0}</p>
              </div>
            </div>
            <div className="theme-bg-secondary/50 p-4 rounded-2xl border border-[var(--surface-border)] shadow-sm">
              <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-1 opacity-60">{t('users.detail.clientRating')}</p>
              <div className="flex items-end justify-end gap-1.5">
                <p className="text-2xl font-black theme-heading leading-none">{user.client_rating_avg ? Number(user.client_rating_avg).toFixed(1) : '—'}</p>
                <p className="text-[0.6875rem] font-bold theme-muted opacity-40 pb-0.5">/ {user.client_rating_count || 0}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 theme-bg-secondary p-2 rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-x-auto mb-6 scrollbar-none">
        {tabs.map(tab => (
          <button key={tab.key} onClick={() => setActiveTab(tab.key)} className={`flex items-center gap-2 px-6 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest whitespace-nowrap transition-all active:scale-95 ${activeTab === tab.key ? 'bg-blue-600 text-white shadow-xl shadow-blue-600/20' : 'theme-muted hover:theme-heading hover:bg-[var(--surface)] opacity-60 hover:opacity-100'}`}>
            <tab.icon className="h-4 w-4" /> {t(
              `users.detail.tabs.${tab.key}`,
              tab.label,
            )} {tab.count !== undefined && <span className={`px-2 py-0.5 rounded-md text-[0.5625rem] ml-1 ${activeTab === tab.key ? 'bg-white/20' : 'theme-bg-secondary border border-[var(--surface-border)]'}`}>{tab.count}</span>}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="theme-card rounded-2xl shadow-sm p-6 min-h-[300px]">
        {activeTab === 'overview' && (
          <div className="space-y-6">
            <div className="grid md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
                  <User className="h-4 w-4 text-blue-500" />
                  {t('users.detail.section.accountDetails', 'Account Details')}
                </h3>
                <div className="theme-bg-secondary/50 p-4 rounded-xl border border-[var(--surface-border)] space-y-1">
                  <InfoRow label={t('users.detail.field.bio', 'Bio')} value={user.bio} />
                  <InfoRow label={t('users.detail.field.available', 'Available')} value={user.is_available ? t('common.yes') : t('common.no')} />
                  <InfoRow label={t('users.detail.field.travelerType', 'Traveler Type')} value={user.traveler_type ? t(`users.detail.value.${user.traveler_type}` as 'users.detail.value.no_vehicle', user.traveler_type.replace(/_/g, ' ')) : null} />
                  <InfoRow label={t('users.detail.field.identityType', 'Identity Type')} value={user.identity_type ? t(`users.detail.value.${user.identity_type}` as 'users.detail.value.id_card', user.identity_type.replace(/_/g, ' ')) : null} />
                  <InfoRow label={t('badges.tier', 'Badge tier')} value={badgeTierLabel(user.trust_badge)} />
                  <InfoRow label={t('badges.trusted.label', 'Trusted')} value={user.is_trusted ? t('common.yes') : t('common.no')} />
                  <InfoRow label={t('badges.featured.label', 'Featured')} value={user.is_featured ? t('common.yes') : t('common.no')} />
                </div>
              </div>

              <div className="space-y-4">
                <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-green-500" />
                  {t('users.detail.section.driverActions', 'Driver Actions')}
                </h3>
                <div className="theme-bg-secondary/50 p-4 rounded-xl border border-[var(--surface-border)] space-y-4">
                  <div className="flex gap-2 flex-wrap pb-4">
                    <p className="w-full text-[0.625rem] theme-muted font-black uppercase tracking-widest leading-none mb-2 opacity-60">{t('users.detail.driverStatus', 'Traveler / Driver Status')}</p>
                    <div className="w-full mb-3 flex items-center gap-2 flex-wrap">
                      {statusBadge(user.traveler_status)}
                      <span className={`px-2.5 py-1 rounded-lg text-[0.625rem] font-black uppercase tracking-widest border ${user.is_driver ? 'bg-blue-500/10 text-blue-600 border-blue-500/20' : 'theme-bg-secondary theme-muted border-[var(--surface-border)]'}`}>
                        {user.is_driver ? t('users.detail.badge.driverFlag', 'Driver') : t('users.detail.badge.travelerOnly', 'Traveler only')}
                      </span>
                    </div>
                    <div className="flex gap-2 w-full flex-wrap">
                      {user.traveler_status !== 'blocked' && (user.traveler_status !== 'approved' || user.is_driver) && <button onClick={enableTraveler} className="flex-1 min-w-36 py-3 bg-green-600 text-white rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-green-700 shadow-lg shadow-green-600/10 transition-all active:scale-95"><UserCheck className="h-3.5 w-3.5 inline mr-1" />{t('users.detail.action.makeTraveler', 'Make traveler')}</button>}
                      {user.traveler_status !== 'blocked' && !(user.traveler_status === 'approved' && user.is_driver) && <button onClick={enableDriver} className="flex-1 min-w-36 py-3 bg-blue-600 text-white rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-blue-700 shadow-lg shadow-blue-600/10 transition-all active:scale-95"><Truck className="h-3.5 w-3.5 inline mr-1" />{t('users.detail.action.makeDriver', 'Make driver')}</button>}
                      {user.traveler_status && user.traveler_status !== 'none' && user.traveler_status !== 'rejected' && user.traveler_status !== 'blocked' && <button onClick={() => updateDriverStatus('rejected')} className="flex-1 min-w-32 py-3 bg-[var(--surface)] text-orange-600 border border-orange-500/20 rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-orange-500/10 shadow-sm transition-all active:scale-95"><XCircle className="h-3.5 w-3.5 inline mr-1" />{t('users.detail.action.reject', 'Reject')}</button>}
                      {user.traveler_status && user.traveler_status !== 'none' && user.traveler_status !== 'blocked' && <button onClick={() => updateDriverStatus('blocked')} className="flex-1 min-w-32 py-3 bg-red-600 text-white rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-red-700 shadow-lg shadow-red-600/10 transition-all active:scale-95"><Ban className="h-3.5 w-3.5 inline mr-1" />{t('users.detail.action.block', 'Block')}</button>}
                      {user.traveler_status === 'blocked' && <button onClick={() => unblock('driver')} className="w-full py-3 bg-green-600 text-white rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-green-700 shadow-lg shadow-green-600/10 transition-all active:scale-95"><ShieldCheck className="h-3.5 w-3.5 inline mr-1" />{t('users.detail.action.unblock', 'Unblock')}</button>}
                    </div>
                  </div>
                  <div className="pt-2 border-t border-[var(--surface-border)] space-y-1">
                    <InfoRow label={t('users.detail.field.subscriptionExpires', 'Subscription Expires')} value={user.subscription_expires_at ? new Date(user.subscription_expires_at).toLocaleDateString() : null} />
                    <InfoRow label={t('users.detail.field.licenseExpires', 'License Expires')} value={user.license_expires_at ? new Date(user.license_expires_at).toLocaleDateString() : null} />
                  </div>
                </div>
              </div>
            </div>

            {/* Trust badges + Hard block controls */}
            <div className="grid md:grid-cols-2 gap-6">
              <TrustBadgeControls user={user} onChange={(updates) => setUser(prev => prev ? { ...prev, ...updates } as Profile : null)} />
              <div className="space-y-4">
                <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
                  <Lock className="h-4 w-4 text-red-500" />
                  {t('users.detail.section.access', 'Account Access Controls')}
                </h3>
                <div className="theme-bg-secondary/50 p-5 rounded-xl border border-[var(--surface-border)] space-y-3">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="text-sm font-black theme-heading">{t('users.detail.hardBlock', 'Hard block')}</p>
                      <p className="text-[0.625rem] theme-muted">{t('users.detail.hardBlock.help', 'Bans the auth user. They cannot sign in. Requires service-role key.')}</p>
                    </div>
                    <button
                      onClick={async () => {
                        const next = !user.is_blocked;
                        const reason = next ? prompt(t('users.detail.hardBlock.reasonPrompt', 'Reason (optional)')) || undefined : undefined;
                        const res = await setUserBlocked(id, next, reason);
                        if (res.success) {
                          setUser(prev => prev ? { ...prev, is_blocked: next, blocked_reason: reason ?? null } as Profile : null);
                          toast(next ? t('users.detail.hardBlock.toast.on', 'User blocked') : t('users.detail.hardBlock.toast.off', 'User unblocked'), 'success');
                        } else {
                          toast(res.error || 'Failed', 'error');
                        }
                      }}
                      className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition shadow-sm ${user.is_blocked ? 'bg-green-600 text-white hover:bg-green-700' : 'bg-red-600 text-white hover:bg-red-700'}`}
                    >
                      {user.is_blocked ? t('users.unblock', 'Unblock') : t('users.block', 'Block')}
                    </button>
                  </div>
                  <div className="flex items-center justify-between gap-3 pt-3 border-t border-[var(--surface-border)]">
                    <div>
                      <p className="text-sm font-black theme-heading">{t('users.detail.disable', 'Disable account')}</p>
                      <p className="text-[0.625rem] theme-muted">{t('users.detail.disable.help', 'Soft suspension. User can log in but features are restricted.')}</p>
                    </div>
                    <button
                      onClick={async () => {
                        const next = !user.is_suspended;
                        const reason = next ? prompt(t('users.detail.disable.reasonPrompt', 'Reason (optional)')) || undefined : undefined;
                        const res = await setUserDisabled(id, next, reason);
                        if (res.success) {
                          setUser(prev => prev ? { ...prev, is_suspended: next } as Profile : null);
                          toast(next ? t('users.detail.disable.toast.on', 'Account disabled') : t('users.detail.disable.toast.off', 'Account enabled'), 'success');
                        } else {
                          toast(res.error || 'Failed', 'error');
                        }
                      }}
                      className={`px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition shadow-sm ${user.is_suspended ? 'bg-green-600 text-white hover:bg-green-700' : 'bg-orange-600 text-white hover:bg-orange-700'}`}
                    >
                      {user.is_suspended ? t('users.detail.enable', 'Enable') : t('users.detail.disable.btn', 'Disable')}
                    </button>
                  </div>
                  {user.is_blocked && user.blocked_reason && (
                    <div className="text-[0.6875rem] theme-muted bg-red-50 border border-red-200 rounded-lg p-2">
                      <strong className="text-red-700">{t('users.detail.blockReason', 'Block reason')}:</strong> {user.blocked_reason}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Governance & Risk Section */}
            <div className="space-y-4">
              <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
                <Gavel className="h-4 w-4 text-red-600" />
                {t('users.detail.section.governance', 'Governance & Risk Management')}
              </h3>
              <div className="bg-[var(--surface)] rounded-2xl border-2 border-red-500/20 p-6 grid md:grid-cols-3 gap-8 shadow-sm">
                {/* Strikes */}
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('users.detail.field.strikes', 'Behavioral Strikes')}</p>
                    <ShieldAlert className={`h-5 w-5 ${user.strike_count && user.strike_count > 0 ? 'text-red-600 animate-pulse' : 'theme-muted opacity-50'}`} />
                  </div>
                  <div className="flex items-center gap-4">
                    <button
                      disabled={updatingGovernance || (user.strike_count || 0) <= 0}
                      onClick={async () => {
                        setUpdatingGovernance(true);
                        const next = Math.max(0, (user.strike_count || 0) - 1);
                        const res = await updateUserGovernance(id, { strike_count: next });
                        if (res.success) setUser(prev => prev ? { ...prev, strike_count: next } : null);
                        else toast(res.error || t('users.toast.governanceUpdateFailed', 'Failed to update governance settings'), 'error');
                        setUpdatingGovernance(false);
                      }}
                      className="h-10 w-10 rounded-xl border-2 border-[var(--surface-border)] flex items-center justify-center font-black theme-muted hover:theme-bg-secondary active:scale-90 transition-all disabled:opacity-50"
                    >-</button>
                    <span className="text-3xl font-black theme-heading w-8 text-center">{user.strike_count || 0}</span>
                    <button
                      disabled={updatingGovernance}
                      onClick={async () => {
                        setUpdatingGovernance(true);
                        const next = (user.strike_count || 0) + 1;
                        const res = await updateUserGovernance(id, { strike_count: next });
                        if (res.success) setUser(prev => prev ? { ...prev, strike_count: next } : null);
                        else toast(res.error || t('users.toast.governanceUpdateFailed', 'Failed to update governance settings'), 'error');
                        setUpdatingGovernance(false);
                      }}
                      className="h-10 w-10 rounded-xl border-2 border-red-500/20 flex items-center justify-center font-black text-red-600 hover:bg-red-500/10 active:scale-90 transition-all disabled:opacity-50"
                    >+</button>
                  </div>
                  <p className="text-[0.625rem] theme-muted font-medium italic">
                    {t('users.detail.strikeHelp', '3 strikes typically trigger an account freeze evaluation.')}
                  </p>
                </div>

                {/* Freeze/Thaw */}
                <div className="space-y-4 border-l border-[var(--surface-border)] pl-8">
                  <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest">{t('users.detail.field.freeze', 'Account Freeze')}</p>
                  <button
                    disabled={updatingGovernance}
                    onClick={async () => {
                      setUpdatingGovernance(true);
                      const next = !user.is_frozen;
                      const res = await updateUserGovernance(id, { is_frozen: next });
                      if (res.success) setUser(prev => prev ? { ...prev, is_frozen: next } : null);
                      else toast(res.error || t('users.toast.governanceUpdateFailed', 'Failed to update governance settings'), 'error');
                      setUpdatingGovernance(false);
                    }}
                    className={`w-full flex items-center justify-center gap-2 py-3 rounded-xl text-xs font-black uppercase tracking-widest transition-all shadow-sm ${user.is_frozen ? 'bg-green-600 text-white hover:bg-green-700' : 'bg-gray-100 text-gray-600 hover:bg-blue-600 hover:text-white'}`}
                  >
                    {user.is_frozen ? <Unlock className="h-4 w-4" /> : <Lock className="h-4 w-4" />}
                    {user.is_frozen ? t('users.action.thaw', 'Release Freeze') : t('users.action.freeze', 'Freeze Account')}
                  </button>
                  <p className="text-[0.625rem] theme-muted font-medium italic leading-tight">
                    {t('users.detail.freezeHelp', 'Frozen accounts are in read-only mode. Users can log in but cannot book, post, or message.')}
                  </p>
                </div>

                {/* Internal Notes & Soft Delete */}
                <div className="space-y-4 border-l border-[var(--surface-border)] pl-8">
                  <div>
                    <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-2">{t('users.detail.field.notes', 'Admin Intelligence')}</p>
                    <textarea
                      defaultValue={user.internal_notes || ''}
                      onBlur={async (e) => {
                        const next = e.target.value;
                        if (next === user.internal_notes) return;
                        setUpdatingGovernance(true);
                        const res = await updateUserGovernance(id, { internal_notes: next });
                        if (res.success) setUser(prev => prev ? { ...prev, internal_notes: next } : null);
                        else toast(res.error || t('users.toast.governanceUpdateFailed', 'Failed to update governance settings'), 'error');
                        setUpdatingGovernance(false);
                      }}
                      className="w-full h-20 theme-bg-secondary border-none rounded-xl p-3 text-xs theme-heading focus:ring-2 focus:ring-blue-500/20 outline-none resize-none placeholder:italic"
                      placeholder={t('users.detail.notesPlaceholder')}
                    />
                  </div>
                  <button
                    disabled={updatingGovernance || !!user.deleted_at}
                    onClick={async () => {
                      if (confirm(t('users.detail.prompt.deleteConfirm', 'Are you sure you want to terminate this account?'))) {
                        setUpdatingGovernance(true);
                        const next = new Date().toISOString();
                        const res = await updateUserGovernance(id, { deleted_at: next });
                        if (res.success) setUser(prev => prev ? { ...prev, deleted_at: next } : null);
                        else toast(res.error || t('users.toast.governanceUpdateFailed', 'Failed to update governance settings'), 'error');
                        setUpdatingGovernance(false);
                      }
                    }}
                    className="w-full py-2 bg-red-500/10 text-red-600 rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:bg-red-600 hover:text-white transition-all disabled:opacity-50"
                  >
                    {user.deleted_at ? t('users.status.deleted', 'Deleted') : t('users.action.deleteAccount')}
                  </button>
                  <button
                    onClick={() => router.push(`/audit-log?entity_id=${id}`)}
                    className="w-full flex items-center justify-center gap-2 py-2 text-blue-500 hover:text-blue-700 text-[0.625rem] font-black uppercase tracking-widest transition-all mt-2 border border-blue-500/10 rounded-lg hover:bg-blue-500/10"
                  >
                    <History className="h-3 w-3" />
                    {t('users.action.viewHistory')}
                  </button>
                </div>
              </div>
            </div>

            {/* Risk Engine Scorecard (Stage 5) */}
            <div className="bg-[var(--surface)] rounded-2xl border-2 border-red-500/10 p-6 shadow-sm overflow-hidden text-left">
              <div className="flex items-center justify-between mb-4">
                <h4 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-green-600" />
                  {t('users.detail.riskEngine.title')}
                </h4>
                {riskData.score && (
                  <div className={`px-3 py-1 rounded-full text-[0.625rem] font-black uppercase tracking-widest ${riskData.score.risk_score < 50 ? 'theme-badge-danger' :
                    riskData.score.risk_score < 75 ? 'theme-badge-warning' :
                      'theme-badge-success'
                    }`}>
                    {t('users.detail.riskEngine.status') || 'Tier'}: {riskData.score.restriction_tier.replace('_', ' ')}
                  </div>
                )}
              </div>

              <div className="flex items-center gap-8 mb-6">
                <div className="relative h-24 w-24 flex-shrink-0">
                  <svg className="h-full w-full" viewBox="0 0 36 36">
                    <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="var(--surface-border)" strokeWidth="3" />
                    <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke={riskData.score ? (riskData.score.risk_score < 50 ? 'var(--red-600)' : riskData.score.risk_score < 75 ? 'var(--orange-600)' : 'var(--green-600)') : 'var(--muted)'} strokeWidth="3" strokeDasharray={`${riskData.score?.risk_score || 0}, 100`} />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-2xl font-black theme-heading">{riskData.score?.risk_score ?? '—'}</span>
                    <span className="text-[0.5rem] theme-muted font-bold uppercase">{t('users.detail.riskEngine.score')}</span>
                  </div>
                </div>

                <div className="flex-1 space-y-2">
                  <p className="text-xs theme-muted leading-relaxed italic">
                    "{t('users.detail.riskEngine.help')}"
                  </p>
                  <button
                    onClick={async () => {
                      const newScore = prompt(t('users.detail.prompt.riskScore'), riskData.score?.risk_score.toString());
                      if (newScore === null) return;
                      const reason = prompt(t('users.detail.prompt.overrideJustification'));
                      if (!reason) return;
                      const res = await adjustUserRiskScore(id, Number(newScore), reason);
                      if (res.success) {
                        toast(t('users.detail.risk.adjusted', 'Risk score adjusted'), 'success');
                        fetchAll();
                      } else {
                        toast(res.error || t('users.detail.risk.failed', 'Adjustment failed'), 'error');
                      }
                    }}
                    className="text-[0.625rem] font-black uppercase text-blue-600 hover:underline"
                  >
                    {t('users.detail.riskEngine.override')}
                  </button>
                </div>
              </div>

              {/* Quick Analytics */}
              <div className="theme-card rounded-2xl border border-[var(--surface-border)] p-6 space-y-6">
                <div>
                  <h3 className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-4 opacity-60 flex items-center gap-2">
                    <BarChart3 className="h-4 w-4" /> {t('users.detail.quickAnalytics')}
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="theme-bg-secondary/50 p-4 rounded-xl border border-[var(--surface-border)] shadow-sm group hover:scale-[1.02] transition-transform">
                      <p className="text-[0.5625rem] theme-muted font-bold uppercase tracking-widest mb-1 opacity-50">{t('users.detail.riskEngine.score', 'Risk Score')}</p>
                      <p className="text-xl font-black theme-heading">{riskData.score?.risk_score ?? '—'}</p>
                    </div>
                    <div className="theme-bg-secondary/50 p-4 rounded-xl border border-[var(--surface-border)] shadow-sm group hover:scale-[1.02] transition-transform">
                      <p className="text-[0.5625rem] theme-muted font-bold uppercase tracking-widest mb-1 opacity-50">{t('users.detail.riskEngine.tier', 'Restriction Tier')}</p>
                      <p className="text-xl font-black theme-heading">{riskData.score?.restriction_tier ?? '—'}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Score History */}
              <div className="space-y-2 border-t border-[var(--surface-border)] pt-4">
                <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-2 flex items-center gap-1">
                  <History className="h-3 w-3" /> {t('users.detail.riskEngine.history')}
                </p>
                {riskData.history.length === 0 ? (
                  <p className="text-[0.625rem] theme-muted italic opacity-50">No historical score changes recorded.</p>
                ) : (
                  <div className="max-h-32 overflow-y-auto space-y-1 pr-1 custom-scrollbar">
                    {riskData.history.map(entry => (
                      <div key={entry.id} className="flex items-center justify-between p-2 theme-bg-secondary/50 border border-[var(--surface-border)] rounded-lg text-[0.625rem] group hover:theme-bg-secondary transition-colors">
                        <div className="flex items-center gap-2">
                          {entry.new_score > entry.old_score ? <TrendingUp className="h-3 w-3 theme-success" /> : <TrendingDown className="h-3 w-3 theme-danger" />}
                          <span className="font-bold theme-heading">{entry.old_score} → {entry.new_score}</span>
                          <span className="theme-muted truncate max-w-[120px] opacity-70 group-hover:opacity-100 transition-opacity">{entry.reason}</span>
                        </div>
                        <span className="theme-muted font-medium">{new Date(entry.created_at).toLocaleDateString()}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Payment Governance Section */}
            <div className="bg-[var(--surface)] text-left rounded-2xl border-2 border-orange-500/10 p-6 shadow-sm">
              <div className="flex items-center justify-between mb-6">
                <h4 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
                  <Activity className="h-4 w-4 theme-warning" />
                  {t('users.detail.paymentGov.title')}
                </h4>
                {riskMetrics && (
                  <div className="flex gap-4">
                    <div className="text-center">
                      <p className="text-[0.625rem] theme-muted font-bold uppercase">{t('users.detail.paymentGov.disputeRate')}</p>
                      <p className={`text-lg font-black ${riskMetrics.rate > 15 ? 'theme-danger' : 'theme-heading'}`}>{riskMetrics.rate}%</p>
                    </div>
                    <div className="text-center border-l border-[var(--surface-border)] pl-4">
                      <p className="text-[0.625rem] theme-muted font-bold uppercase">{t('users.detail.paymentGov.totalDisputed')}</p>
                      <p className="text-lg font-black theme-heading">{riskMetrics.total} / {riskMetrics.disputed}</p>
                    </div>
                  </div>
                )}
              </div>

              <div className="space-y-4">
                <div>
                  <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest mb-3">{t('users.detail.paymentGov.activeRestrictions')}</p>
                  {restrictions.length === 0 ? (
                    <p className="text-xs theme-muted italic theme-bg-secondary/50 p-6 rounded-[1.5rem] border border-dashed border-[var(--surface-border)] text-center opacity-60">{t('users.detail.paymentGov.noRestrictions')}</p>
                  ) : (
                    <div className="space-y-2">
                      {restrictions.map(res => (
                        <div key={res.id} className="flex items-center justify-between p-4 theme-bg-danger-soft rounded-2xl border border-[var(--red-500)]/10 group">
                          <div className="flex items-center gap-4">
                            <div className="h-10 w-10 rounded-xl theme-bg-danger-soft flex items-center justify-center border border-[var(--red-500)]/20 shadow-sm">
                              <ShieldOff className="h-5 w-5 theme-danger" />
                            </div>
                            <div>
                              <p className="text-xs font-black theme-danger uppercase tracking-widest leading-none mb-1">{res.restriction_type.replace('_', ' ')}</p>
                              <p className="text-[0.625rem] theme-heading font-medium opacity-80">Reason: {res.reason}</p>
                              {res.expires_at && <p className="text-[0.625rem] theme-muted mt-1">Expires: {new Date(res.expires_at).toLocaleDateString()}</p>}
                            </div>
                          </div>
                          <button
                            onClick={async () => {
                              const reason = prompt(t('users.detail.restrictions.lift.prompt', 'Reason for lifting this restriction?'));
                              if (!reason) return;
                              const liftRes = await liftUserRestriction(res.id, id, reason);
                              if (liftRes.success) {
                                toast(t('users.detail.restrictions.lift.success', 'Restriction lifted'), 'success');
                                fetchAll();
                              } else {
                                toast(liftRes.error || t('users.detail.restrictions.lift.failed', 'Failed to lift'), 'error');
                              }
                            }}
                            className="text-[0.625rem] font-black uppercase theme-danger hover:underline tracking-widest px-4 py-2 rounded-lg hover:theme-bg-danger-soft transition-all"
                          >
                            {t('users.detail.restrictions.lift.button', 'Lift')}
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div className="pt-6 border-t border-[var(--surface-border)] grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {(['no_booking', 'no_shipping', 'read_only', 'shadow_ban'] as const).map(type => (
                    <button
                      key={type}
                      onClick={async () => {
                        const reason = prompt(t('users.detail.restrictions.issue.prompt', 'Reason for issuing {type} restriction?').replace('{type}', type.replace('_', ' ')));
                        if (!reason) return;
                        const days = prompt(t('users.detail.restrictions.duration.prompt', 'Duration in days? (0 for permanent)'), '7');
                        const res = await issueUserRestriction(id, type, reason, Number(days) || undefined);
                        if (res.success) {
                          toast(t('users.detail.restrictions.issue.success', 'Restriction issued'), 'success');
                          fetchAll();
                        } else {
                          toast(res.error || t('users.detail.restrictions.issue.failed', 'Issue failed'), 'error');
                        }
                      }}
                      className="py-3 theme-bg-secondary/50 border border-[var(--surface-border)] rounded-xl text-[0.625rem] font-black uppercase tracking-widest theme-muted hover:theme-danger hover:theme-bg-danger-soft hover:border-[var(--red-500)]/30 transition-all shadow-sm active:scale-95"
                    >
                      + {type.replace('_', ' ')}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}


        {activeTab === 'documents' && (
          <div className="space-y-4">
            <h3 className="font-black theme-heading uppercase text-xs tracking-[0.2em] mb-8 pb-4 border-b border-[var(--surface-border)]">{t('users.detail.documents.title')}</h3>
            <div className="space-y-2">
              <DocRow
                t={t}
                label={t('users.detail.documents.identity')}
                url={user.identity_doc_url ? (signedUrls[user.identity_doc_url] ?? null) : null}
                pending={user.identity_doc_url_pending}
                uploading={uploadingDocField === 'identity_doc_url'}
                onUpload={(file) => uploadUserDocument('identity_doc_url', file)}
              />
              <DocRow
                t={t}
                label={t('users.detail.documents.travelerLicense')}
                url={user.traveler_license_url ? (signedUrls[user.traveler_license_url] ?? null) : null}
                pending={user.traveler_license_url_pending}
                uploading={uploadingDocField === 'traveler_license_url'}
                onUpload={(file) => uploadUserDocument('traveler_license_url', file)}
              />
              <DocRow
                t={t}
                label={t('users.detail.documents.rentalContract')}
                url={user.rental_contract_url ? (signedUrls[user.rental_contract_url] ?? null) : null}
                pending={user.rental_contract_url_pending}
                uploading={uploadingDocField === 'rental_contract_url'}
                onUpload={(file) => uploadUserDocument('rental_contract_url', file)}
              />
              {!user.identity_doc_url && !user.traveler_license_url && !user.rental_contract_url && (
                <div className="py-12 text-center">
                  <FileText className="h-12 w-12 theme-muted mx-auto mb-4 opacity-20" />
                  <p className="theme-muted text-sm italic">{t('users.detail.documents.empty')}</p>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'vehicles' && (
          <div className="space-y-6">
            <h3 className="font-black theme-heading uppercase text-xs tracking-[0.2em] mb-4 pb-4 border-b border-[var(--surface-border)]">{t('users.detail.vehicles.title')}</h3>
            {vehicles.length === 0 ? (
              <div className="py-12 text-center">
                <Truck className="h-12 w-12 theme-muted mx-auto mb-4 opacity-20" />
                <p className="theme-muted text-sm italic">{t('users.detail.vehicles.empty')}</p>
              </div>
            ) : vehicles.map(v => (
              <div key={v.id} className="theme-bg-secondary/50 p-6 rounded-[2rem] border border-[var(--surface-border)] flex items-center gap-6 group hover:theme-bg-secondary transition-all">
                <div className="h-16 w-16 rounded-2xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform">
                  <Truck className="h-8 w-8 text-blue-500 shadow-[0_0_15px_rgba(59,130,246,0.5)]" />
                </div>
                <div className="flex-1">
                  <p className="text-lg font-black theme-heading tracking-tight">{v.make} {v.model} <span className="text-sm font-normal theme-muted ml-2">{v.year}</span></p>
                  <p className="text-xs theme-muted font-bold uppercase tracking-widest mt-1">
                    {t('users.detail.vehicles.plate')}: <span className="theme-heading">{v.plate_number}</span> • {v.vehicle_type || t('common.na')}
                  </p>
                </div>
                <div className="flex items-center gap-3">
                  {v.vehicle_photo_url && signedUrls[v.vehicle_photo_url] && (
                    <a href={signedUrls[v.vehicle_photo_url]} target="_blank" rel="noreferrer" className="h-10 w-10 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center hover:theme-heading transition-colors group/link relative overflow-hidden">
                      <Eye className="h-4 w-4 theme-muted group-hover/link:theme-heading transition-colors" />
                    </a>
                  )}
                  {v.registration_doc_url && (() => {
                    const regUrl = signedUrls[v.registration_doc_url] ?? null;
                    return regUrl ? (
                      <>
                        <a href={regUrl} target="_blank" rel="noreferrer" className="px-4 py-2 theme-bg-secondary border border-[var(--surface-border)] rounded-xl text-[0.625rem] font-black uppercase theme-muted hover:theme-heading hover:border-blue-500/50 transition-all flex items-center gap-2">
                          <Eye className="h-3 w-3" /> {t('common.view')}
                        </a>
                        <a href={regUrl} target="_blank" rel="noreferrer" download className="px-4 py-2 bg-green-500/10 border border-green-500/20 rounded-xl text-[0.625rem] font-black uppercase text-green-600 hover:bg-green-500/20 transition-all flex items-center gap-2">
                          <Download className="h-3 w-3" /> {t('users.detail.documents.download')}
                        </a>
                      </>
                    ) : (
                      <span className="text-[0.625rem] theme-muted animate-pulse">{t('users.detail.documents.loading')}</span>
                    );
                  })()}
                </div>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'trips' && <DataTable data={trips} columns={[
          { key: 'status', label: t('users.detail.table.status'), render: (v: any) => statusBadge(v.status) },
          { key: 'origin', label: t('users.detail.table.from'), render: (v: any) => v.origin_loc?.city_name_en || '—' },
          { key: 'dest', label: t('users.detail.table.to'), render: (v: any) => v.dest_loc?.city_name_en || '—' },
          { key: 'departure_time', label: t('users.detail.table.departure'), render: (v: any) => v.departure_time ? new Date(v.departure_time).toLocaleString() : '—' },
          { key: 'created_at', label: t('users.detail.table.created'), render: (v: any) => new Date(v.created_at).toLocaleDateString() },
        ]} emptyText={t('users.detail.trips.empty')} />}

        {activeTab === 'bookings' && <DataTable data={bookings} columns={[
          { key: 'status', label: t('users.detail.table.status'), render: (v: any) => statusBadge(v.status) },
          { key: 'price', label: t('users.detail.table.price'), render: (v: any) => v.price || '—' },
          { key: 'trip', label: t('users.detail.table.trip'), render: (v: any) => v.trip_id ? v.trip_id.slice(0, 8) : '—' },
          { key: 'created_at', label: t('users.detail.table.created'), render: (v: any) => new Date(v.created_at).toLocaleDateString() },
        ]} emptyText={t('users.detail.bookings.empty')} />}

        {activeTab === 'ratings' && <DataTable data={ratings} columns={[
          { key: 'rating', label: t('users.detail.table.score'), render: (v: any) => <span className="font-black text-lg">{v.rating}/5</span> },
          { key: 'role_rated', label: t('users.detail.table.role'), render: (v: any) => statusBadge(v.role_rated) },
          { key: 'rater', label: t('users.detail.table.from'), render: (v: any) => v.rater?.full_name || '—' },
          { key: 'comment', label: t('users.detail.table.comment'), render: (v: any) => v.comment || '—' },
          { key: 'created_at', label: t('users.detail.table.date'), render: (v: any) => new Date(v.created_at).toLocaleDateString() },
        ]} emptyText={t('users.detail.ratings.empty')} />}

        {activeTab === 'reports' && <DataTable data={reports} columns={[
          { key: 'status', label: t('users.detail.table.status'), render: (v: any) => statusBadge(v.status) },
          { key: 'reason', label: t('users.detail.table.reason'), render: (v: any) => v.reason },
          { key: 'reporter', label: t('users.detail.table.reporter'), render: (v: any) => v.reporter?.full_name || '—' },
          { key: 'comment', label: t('users.detail.table.comment'), render: (v: any) => v.comment || '—' },
          { key: 'created_at', label: t('users.detail.table.date'), render: (v: any) => new Date(v.created_at).toLocaleDateString() },
        ]} emptyText={t('users.detail.reports.empty')} />}

        {activeTab === 'activity' && <UserActivityTab user={user} />}
      </div>

      {/* Block Dialog Modal */}
      {
        blockDialog.open && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
            <div className="bg-[var(--surface)] rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden border border-[var(--surface-border)]">
              {/* Header */}
              <div className="theme-bg-danger-soft px-6 py-4 flex items-center justify-between border-b theme-border-danger-soft">
                <div className="flex items-center gap-3">
                  <div className="h-10 w-10 rounded-xl theme-bg-danger-soft flex items-center justify-center">
                    <Ban className="h-5 w-5 theme-danger" />
                  </div>
                  <div>
                    <h3 className="font-black theme-heading text-sm">
                      {blockDialog.target === 'account' ? t('users.detail.notifTitle.account') : t('users.detail.notifTitle.driver')}
                    </h3>
                    <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest">{user.full_name || t('common.unknown')}</p>
                  </div>
                </div>
                <button onClick={closeBlockDialog} className="p-2 hover:theme-bg-danger-soft rounded-xl transition-all active:scale-95">
                  <X className="h-5 w-5 theme-muted" />
                </button>
              </div>

              {/* Body */}
              <div className="px-8 py-8 space-y-6">
                <p className="text-sm theme-muted font-medium leading-relaxed">
                  {blockDialog.target === 'account'
                    ? t('users.detail.dialog.suspendDesc')
                    : t('users.detail.dialog.blockDriverDesc')}
                </p>

                {/* Reason */}
                <div>
                  <label className="block text-xs font-bold theme-muted uppercase tracking-widest mb-1.5">
                    {t('users.detail.dialog.reasonOptional')}
                  </label>
                  <textarea
                    value={blockReason}
                    onChange={(e) => setBlockReason(e.target.value)}
                    placeholder={t('users.detail.placeholder.blockReason')}
                    rows={3}
                    className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-3 text-sm theme-heading focus:ring-2 focus:ring-[var(--red-500)]/20 focus:border-[var(--red-500)]/40 outline-none transition resize-none"
                  />
                </div>

                {/* Notification Toggle */}
                <label className="flex items-center gap-3 cursor-pointer group">
                  <div className="relative">
                    <input
                      type="checkbox"
                      checked={sendNotification}
                      onChange={(e) => setSendNotification(e.target.checked)}
                      className="sr-only peer"
                    />
                    <div className="w-10 h-6 theme-bg-secondary rounded-full peer-checked:bg-red-600 transition" />
                    <div className="absolute top-0.5 left-0.5 w-5 h-5 bg-[var(--surface)] rounded-full shadow-lg peer-checked:translate-x-4 transition-all" />
                  </div>
                  <div>
                    <p className="text-sm font-black theme-heading group-hover:theme-danger transition-colors">{t('users.detail.dialog.sendNotifToUser')}</p>
                    <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest opacity-60">{t('users.detail.dialog.sendNotifDesc')}{blockReason.trim() ? t('users.detail.dialog.sendNotifWithReason') : ''}</p>
                  </div>
                </label>
              </div>

              {/* Footer */}
              <div className="px-6 py-4 theme-bg-secondary border-t border-[var(--surface-border)] flex justify-end gap-3">
                <button
                  onClick={closeBlockDialog}
                  disabled={blocking}
                  className="px-4 py-2 text-sm font-bold theme-muted hover:theme-heading transition"
                >
                  {t('common.cancel')}
                </button>
                <button
                  onClick={executeBlock}
                  disabled={blocking}
                  className="flex items-center gap-2 px-5 py-2.5 bg-red-600 text-white rounded-xl text-sm font-black uppercase tracking-widest hover:bg-red-700 disabled:opacity-50 transition shadow-sm"
                >
                  {blocking ? (
                    <div className="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    <Ban className="h-4 w-4" />
                  )}
                  {blockDialog.target === 'account' ? t('users.detail.suspend') : t('users.detail.action.block')}
                </button>
              </div>
            </div>
          </div>
        )
      }

      {/* Edit Profile Modal */}
      {editModal && user && (
        <UserEditModal
          user={user}
          onClose={() => setEditModal(false)}
          onSaved={(updates) => setUser(prev => prev ? { ...prev, ...updates } as Profile : null)}
        />
      )}

      {/* Send Notification Modal */}
      <SendNotificationModal
        isOpen={notifModal && !!user}
        userId={id}
        userName={user?.full_name || t('common.thisUser')}
        onClose={() => setNotifModal(false)}
      />
    </div >
  );
}

function InfoRow({ label, value }: { label: string; value: string | null | undefined }) {
  return (
    <div className="flex justify-between items-center py-2 border-b border-[var(--surface-border)]">
      <span className="text-xs theme-muted font-bold uppercase tracking-widest">{label}</span>
      <span className="text-sm font-medium theme-heading">{value || '—'}</span>
    </div>
  );
}

function DocRow({
  t,
  label,
  url,
  pending,
  uploading = false,
  onUpload,
}: {
  t: (key: string, fallback?: string) => string;
  label: string;
  url?: string | null;
  pending?: string | null;
  uploading?: boolean;
  onUpload?: (file: File) => void;
}) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-[var(--surface-border)]">
      <div>
        <p className="text-sm font-bold theme-heading">{label}</p>
        {pending && <p className="text-[0.625rem] text-amber-600 font-bold uppercase mt-0.5">{t('users.detail.documents.pendingReupload')}</p>}
      </div>
      <div className="flex gap-2 flex-wrap">
        {onUpload && (
          <label className="flex items-center gap-1 px-3 py-1.5 bg-indigo-500/10 text-indigo-600 rounded-lg text-xs font-bold hover:bg-indigo-500/20 cursor-pointer">
            <Upload className="h-3 w-3" />
            {uploading ? t('common.uploading', 'Uploading...') : t('users.detail.documents.update', 'Update')}
            <input
              type="file"
              className="hidden"
              disabled={uploading}
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) onUpload(file);
                e.currentTarget.value = '';
              }}
            />
          </label>
        )}
        {url && (
          <>
            <a href={url} target="_blank" rel="noreferrer" className="flex items-center gap-1 px-3 py-1.5 bg-blue-500/10 text-blue-600 rounded-lg text-xs font-bold hover:bg-blue-500/20"><Eye className="h-3 w-3" /> {t('common.view')}</a>
            <a href={url} target="_blank" rel="noreferrer" download className="flex items-center gap-1 px-3 py-1.5 bg-green-500/10 text-green-600 rounded-lg text-xs font-bold hover:bg-green-500/20"><Download className="h-3 w-3" /> {t('users.detail.documents.download')}</a>
          </>
        )}
        {pending && <a href={pending} target="_blank" rel="noreferrer" className="flex items-center gap-1 px-3 py-1.5 bg-amber-500/10 text-amber-600 rounded-lg text-xs font-bold hover:bg-amber-500/20"><Eye className="h-3 w-3" /> {t('documents.view.pending')}</a>}
        {!url && !pending && <span className="text-xs theme-muted">{t('users.detail.documents.notUploaded')}</span>}
      </div>
    </div>
  );
}

function DataTable({ data, columns, emptyText }: { data: any[]; columns: { key: string; label: string; render: (row: any) => any }[]; emptyText: string }) {
  if (data.length === 0) return (
    <div className="py-20 text-center">
      <p className="theme-muted text-sm font-bold uppercase tracking-widest opacity-40">{emptyText}</p>
    </div>
  );
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-[var(--surface-border)]">
            {columns.map(c => <th key={c.key} className="text-left py-3 px-2 text-[0.625rem] theme-muted font-black uppercase tracking-widest">{c.label}</th>)}
          </tr>
        </thead>
        <tbody>
          {data.map((row, i) => (
            <tr key={row.id || i} className="border-b border-[var(--surface-border)] hover:theme-bg-secondary/50">
              {columns.map(c => <td key={c.key} className="py-3 px-2 theme-heading">{c.render(row)}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
