'use client';

import { useEffect, useState } from 'react';
import { useParams, usePathname, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import {
  ArrowLeft, Route, User, Calendar, Weight, MapPin, ArrowRight,
  MessageSquare, Package, Ban, CheckCircle, Clock, ChevronDown, ChevronUp,
  AlertTriangle,
} from 'lucide-react';
import Loading from '@/app/loading';
import Link from 'next/link';

import { StatusBadge } from '@/components/StatusBadge';
import { TimelineStep, TimelineConnector } from '@/components/Timeline';
import InfoCard from '@/components/InfoCard';
import { Message, TripStatus } from '@/lib/types';
import { useT } from '@/lib/i18n';
import { forceTripStatus } from '@/app/actions/operational-actions';
import { Shield, Zap, AlertCircle, Pencil } from 'lucide-react';
import { TripEditModal } from '@/components/TripEditModal';
import { approveTrip, rejectTrip, cancelTripAdmin, reopenTripAdmin } from '@/app/actions/trip-actions';
import { resolveExportedDynamicRouteId } from '@/lib/export-dynamic-route';
import { isHomeCountryLocation } from '@/lib/geographyConfig';

type RouteScope = 'internal' | 'external' | 'invalid' | 'unknown';

function getRouteScope(origin?: any, dest?: any): RouteScope {
  if (!origin || !dest) return 'unknown';
  const originIsHome = isHomeCountryLocation(origin);
  const destIsHome = isHomeCountryLocation(dest);
  if (originIsHome && destIsHome) return 'internal';
  if (originIsHome || destIsHome) return 'external';
  return 'invalid';
}

function scopeBadgeClass(scope: RouteScope): string {
  if (scope === 'internal') return 'bg-emerald-500/10 text-emerald-700 border-emerald-500/20';
  if (scope === 'external') return 'bg-blue-500/10 text-blue-700 border-blue-500/20';
  if (scope === 'invalid') return 'bg-red-500/10 text-red-700 border-red-500/20';
  return 'theme-bg-secondary theme-muted border-[var(--surface-border)]';
}

function travelerRoleClass(isDriver?: boolean | null): string {
  return isDriver
    ? 'bg-indigo-500/10 text-indigo-700 border-indigo-500/20'
    : 'bg-violet-500/10 text-violet-700 border-violet-500/20';
}

export default function TripDetailPage() {
  const params = useParams();
  const pathname = usePathname();
  const router = useRouter();
  const { toast, confirm: confirmDialog } = useToast();
  const t = useT();
  const resolvedId = resolveExportedDynamicRouteId(params.id as string | string[] | undefined, pathname);
  const id = resolvedId ?? '';

  const [trip, setTrip] = useState<any>(null);
  const [bookings, setBookings] = useState<any[]>([]);
  const [bookingsError, setBookingsError] = useState('');
  const [messages, setMessages] = useState<Record<string, Message[]>>({});
  const [loading, setLoading] = useState(true);
  const [expandedBooking, setExpandedBooking] = useState<string | null>(null);
  const [loadingMessages, setLoadingMessages] = useState<string | null>(null);
  const [editOpen, setEditOpen] = useState(false);

  useEffect(() => {
    if (!resolvedId) {
      setLoading(false);
      setTrip(null);
      setBookings([]);
      setBookingsError('');
      return;
    }
    fetchAll();
  }, [resolvedId]);

  async function fetchAll() {
    if (!resolvedId) return;
    setLoading(true);
    setBookingsError('');
    try {
      const { data: tripData, error: tripError } = await supabase
        .from('trips')
        .select(`
          *,
          profile:profiles!traveler_id(id, full_name, avatar_url, phone_number, traveler_status, traveler_type, is_driver, is_suspended),
          origin:locations!origin_location_id(country_code, country_name_ar, country_name_en, city_name_ar, city_name_en, province_name_en),
          dest:locations!dest_location_id(country_code, country_name_ar, country_name_en, city_name_ar, city_name_en, province_name_en)
        `)
        .eq('id', id)
        .single();

      if (tripError) {
        setTrip(null);
        toast(t('tripDetail.toast.loadFailed', 'Failed to load trip.'), 'error');
      } else {
        setTrip(tripData);
      }

      const { data: bookingsData, error: bookingsLoadError } = await supabase
        .from('bookings')
        .select(`
          *,
          requester_profile:profiles!bookings_requester_id_fkey(id, full_name, phone_number, avatar_url),
          driver_profile:profiles!bookings_traveler_id_fkey(id, full_name, phone_number, is_driver, traveler_type)
        `)
        .eq('trip_id', id)
        .order('created_at', { ascending: false });

      if (bookingsLoadError) {
        const message = t('tripDetail.toast.bookingsLoadFailed', 'Failed to load trip bookings.');
        setBookings([]);
        setBookingsError(message);
        toast(message, 'error');
      } else {
        setBookings(bookingsData || []);
      }
    } catch {
      setTrip(null);
      setBookings([]);
      setBookingsError('');
      toast(t('tripDetail.toast.loadFailed', 'Failed to load trip.'), 'error');
    } finally {
      setLoading(false);
    }
  }

  async function loadMessagesForBooking(bookingId: string) {
    if (messages[bookingId]) {
      setExpandedBooking(expandedBooking === bookingId ? null : bookingId);
      return;
    }
    setLoadingMessages(bookingId);
    setExpandedBooking(bookingId);
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*, sender:profiles!messages_sender_id_fkey(full_name)')
        .eq('booking_id', bookingId)
        .order('created_at', { ascending: true });
      if (error) toast(t('tripDetail.toast.messagesLoadFailed', 'Failed to load messages.'), 'error');
      setMessages(prev => ({ ...prev, [bookingId]: (data as Message[]) || [] }));
    } catch {
      toast(t('tripDetail.toast.messagesLoadFailed', 'Failed to load messages.'), 'error');
    } finally {
      setLoadingMessages(null);
    }
  }

  function cancelTrip() {
    confirmDialog({
      title: t('tripDetail.dialog.cancelTrip.title'),
      message: t('tripDetail.dialog.cancelTrip.message'),
      confirmLabel: t('tripDetail.dialog.cancelTrip.confirmLabel'),
      onConfirm: async () => {
        const res = await cancelTripAdmin(id, 'Admin cancelled');
        if (!res.success) { toast(t('tripDetail.toast.cancelFailed'), 'error'); return; }
        const activeBookingIds = bookings
          .filter(b => !['cancelled', 'completed', 'rejected'].includes(b.status))
          .map(b => b.id);
        if (activeBookingIds.length > 0) {
          const { error: bookingsError } = await supabase
            .from('bookings')
            .update({ status: 'cancelled' })
            .in('id', activeBookingIds);
          if (bookingsError) {
            toast(t('tripDetail.toast.relatedBookingsCancelFailed', 'Trip cancelled, but related bookings were not fully cancelled.'), 'error');
            await fetchAll();
            return;
          }
        }
        toast(t('tripDetail.toast.tripCancelled'), 'success');
        await fetchAll();
      }
    });
  }

  function reopenTrip() {
    confirmDialog({
      title: t('tripDetail.dialog.reopenTrip.title'),
      message: t('tripDetail.dialog.reopenTrip.message'),
      confirmLabel: t('tripDetail.dialog.reopenTrip.confirmLabel'),
      onConfirm: async () => {
        const res = await reopenTripAdmin(id, 'Admin reopened');
        if (!res.success) { toast(t('tripDetail.toast.reopenFailed'), 'error'); return; }
        toast(t('tripDetail.toast.tripReopened'), 'success');
        await fetchAll();
      }
    });
  }

  function cancelBooking(bookingId: string) {
    confirmDialog({
      title: t('tripDetail.dialog.cancelBooking.title'),
      message: t('tripDetail.dialog.cancelBooking.message'),
      confirmLabel: t('tripDetail.dialog.cancelBooking.confirmLabel'),
      onConfirm: async () => {
        const { error } = await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', bookingId);
        if (error) { toast(t('bookingDetail.toast.cancelFailed'), 'error'); return; }
        toast(t('tripDetail.toast.bookingCancelled'), 'success');
        await fetchAll();
      }
    });
  }

  if (loading) return <Loading />;
  if (!trip) {
    return (
      <div className="flex flex-col items-center justify-center py-32 theme-card rounded-3xl border border-[var(--surface-border)] shadow-xl">
        <div className="h-20 w-20 rounded-2xl theme-bg-secondary flex items-center justify-center mb-6">
          <Route className="h-10 w-10 theme-muted opacity-20" />
        </div>
        <p className="theme-muted font-bold uppercase tracking-widest text-sm mb-6">{t('tripDetail.notFound')}</p>
        <button
          onClick={() => router.push('/trips')}
          className="px-6 py-3 theme-bg-secondary border border-[var(--surface-border)] rounded-xl theme-heading font-black uppercase tracking-widest hover:scale-105 active:scale-95 transition-all shadow-sm"
        >
          <ArrowLeft className="h-4 w-4 inline mr-2" /> {t('tripDetail.backToList')}
        </button>
      </div>
    );
  }

  const getCityLabel = (loc: any) => loc?.city_name_en || loc?.city_name_ar || 'N/A';
  const isCancelled = trip.status === 'cancelled';
  const isCompleted = trip.status === 'completed';
  const isPendingApproval = trip.status === 'pending_approval';
  const routeScope = getRouteScope(trip.origin, trip.dest);
  const isDriver = !!trip.profile?.is_driver;

  function handleApprove() {
    confirmDialog({
      title: t('tripDetail.approve.title', 'Approve this trip?'),
      message: t('tripDetail.approve.confirm', 'Approving will make it visible to clients.'),
      confirmLabel: t('tripDetail.action.approve', 'Approve'),
      onConfirm: async () => {
        const res = await approveTrip(id);
        if (res.success) {
          toast(t('tripDetail.approved', 'Trip approved'), 'success');
          setTrip((p: any) => ({ ...p, status: 'available' }));
        } else toast(res.error || 'Approve failed', 'error');
      },
    });
  }
  function handleReject() {
    const reason = window.prompt(t('tripDetail.reject.reason', 'Reason for rejecting this trip:'));
    if (!reason) return;
    rejectTrip(id, reason).then(res => {
      if (res.success) {
        toast(t('tripDetail.rejected', 'Trip rejected'), 'success');
        setTrip((p: any) => ({ ...p, status: 'cancelled' }));
      } else toast(res.error || 'Reject failed', 'error');
    });
  }

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      {/* Back button */}
      <button
        onClick={() => router.push('/trips')}
        className="group flex items-center gap-3 theme-muted hover:theme-heading text-[0.625rem] font-black uppercase tracking-[0.2em] transition-all"
      >
        <div className="h-8 w-8 rounded-full theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center group-hover:-translate-x-1 transition-transform">
          <ArrowLeft className="h-4 w-4" />
        </div>
        {t('tripDetail.backToList')}
      </button>

      {/* Trip Header */}
      <div className="theme-card rounded-[2.5rem] shadow-2xl overflow-hidden border border-[var(--surface-border)] relative">
        <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-orange-500 via-yellow-500 to-orange-500 opacity-20"></div>
        <div className="p-10">
          <div className="flex flex-col md:flex-row items-start justify-between gap-8 mb-10">
            <div className="flex items-center gap-6">
              <div className="h-16 w-16 rounded-[1.25rem] theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center text-orange-600 shadow-inner rotate-3 hover:rotate-0 transition-transform">
                <Route className="h-8 w-8 shadow-[0_0_20px_rgba(249,115,22,0.4)]" />
              </div>
              <div>
                <h1 className="text-3xl font-black theme-heading tracking-tight mb-1">Trip <span className="text-orange-600">#{trip.id.slice(0, 8)}</span></h1>
                <div className="flex items-center gap-2">
                  <Clock className="h-3.5 w-3.5 theme-muted" />
                  <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest">Created {new Date(trip.created_at).toLocaleString()}</p>
                </div>
                <div className="mt-3 flex flex-wrap gap-2">
                  <span className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[0.5625rem] font-black uppercase tracking-widest ${travelerRoleClass(isDriver)}`}>
                    <User className="h-3 w-3" />
                    {isDriver ? t('trips.role.driver', 'Driver') : t('trips.role.simpleTraveler', 'Simple traveler')}
                  </span>
                  <span className={`inline-flex rounded-full border px-2 py-0.5 text-[0.5625rem] font-black uppercase tracking-widest ${scopeBadgeClass(routeScope)}`}>
                    {t(`trips.scope.${routeScope}`, routeScope)}
                  </span>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="scale-110">
                <StatusBadge status={trip.status} />
              </div>
              <button onClick={() => setEditOpen(true)} className="flex items-center gap-2 px-5 py-2.5 bg-orange-600 text-white border border-orange-700 hover:bg-orange-700 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                <Pencil className="h-4 w-4" /> {t('tripDetail.action.edit', 'Edit Trip')}
              </button>
              {isPendingApproval && (
                <>
                  <button onClick={handleApprove} className="flex items-center gap-2 px-5 py-2.5 bg-green-600 text-white border border-green-700 hover:bg-green-700 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                    <CheckCircle className="h-4 w-4" /> {t('tripDetail.action.approve', 'Approve')}
                  </button>
                  <button onClick={handleReject} className="flex items-center gap-2 px-5 py-2.5 bg-red-600 text-white border border-red-700 hover:bg-red-700 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                    <Ban className="h-4 w-4" /> {t('tripDetail.action.reject', 'Reject')}
                  </button>
                </>
              )}
              {!isCancelled && !isCompleted && (
                <button onClick={cancelTrip} className="flex items-center gap-2 px-5 py-2.5 theme-bg-danger-soft theme-danger border border-[var(--red-500)]/10 hover:theme-bg-danger-soft rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                  <Ban className="h-4 w-4" /> {t('tripDetail.action.cancel')}
                </button>
              )}
              {isCancelled && (
                <button onClick={reopenTrip} className="flex items-center gap-2 px-5 py-2.5 theme-bg-success-soft theme-success border border-[var(--green-500)]/10 hover:theme-bg-success-soft rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                  <CheckCircle className="h-4 w-4" /> Reopen
                </button>
              )}
            </div>
          </div>

          {/* Route visualization */}
          <div className="theme-bg-secondary/50 rounded-3xl p-8 mb-8 border border-[var(--surface-border)] relative group overflow-hidden">
            <div className="absolute top-0 right-0 h-full w-32 bg-gradient-to-l from-orange-500/5 to-transparent"></div>
            <div className="flex items-center gap-8 relative z-10">
              <div className="flex-1 text-left">
                <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-[0.2em] mb-2 opacity-50">Origin City</p>
                <div className="flex items-center gap-3">
                  <div className="h-3 w-3 rounded-full border-2 border-orange-500"></div>
                  <p className="text-xl font-black theme-heading tracking-tight uppercase">{getCityLabel(trip.origin)}</p>
                </div>
                <p className="text-[0.625rem] theme-muted font-bold mt-1 ml-6">{trip.origin?.province_name_en}</p>
              </div>
              <div className="flex flex-col items-center gap-2">
                <div className="h-1 w-16 bg-gradient-to-r from-orange-500 to-yellow-500 rounded-full shadow-[0_0_10px_rgba(249,115,22,0.3)]"></div>
                <ArrowRight className="h-5 w-5 text-orange-500 group-hover:translate-x-2 transition-transform" />
                <div className="h-1 w-16 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-full shadow-[0_0_10px_rgba(249,115,22,0.3)]"></div>
              </div>
              <div className="flex-1 text-right">
                <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-[0.2em] mb-2 opacity-50">Destination City</p>
                <div className="flex items-center justify-end gap-3">
                  <p className="text-xl font-black theme-heading tracking-tight uppercase">{getCityLabel(trip.dest)}</p>
                  <div className="h-3 w-3 rounded-full bg-orange-500 shadow-[0_0_10px_rgba(249,115,22,0.5)]"></div>
                </div>
                <p className="text-[0.625rem] theme-muted font-bold mt-1 mr-6">{trip.dest?.province_name_en}</p>
              </div>
            </div>
          </div>

          {/* Trip details grid */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <InfoCard icon={<User className="h-4 w-4" />} label="Driver" value={
              trip.profile?.id ? (
                <Link href={`/users/${trip.profile.id}`} className="text-blue-600 hover:underline">
                  {trip.profile?.full_name || 'Unknown'}
                </Link>
              ) : (
                <span className="theme-muted">Unknown</span>
              )
            } />
            <InfoCard icon={<Calendar className="h-4 w-4" />} label="Departure" value={trip.departure_time ? new Date(trip.departure_time).toLocaleString() : '—'} />
            <InfoCard icon={<Weight className="h-4 w-4" />} label="Max Weight" value={`${trip.max_weight_kg ?? '—'} KG`} />
            <InfoCard icon={<MapPin className="h-4 w-4" />} label="Price" value={
              trip.suggested_price_per_kg
                ? `${trip.suggested_price_per_kg} /KG`
                : trip.suggested_flat_price
                  ? `${trip.suggested_flat_price}`
                  : '—'
            } />
          </div>

          {/* Driver warning */}
          {trip.profile?.is_suspended && (
            <div className="mt-8 p-4 theme-bg-danger-soft border border-[var(--red-500)]/10 rounded-2xl flex items-center gap-3 text-xs theme-danger font-bold uppercase tracking-widest shadow-sm">
              <AlertTriangle className="h-5 w-5" /> Driver account is suspended
            </div>
          )}

          {trip.notes && (
            <div className="mt-6 p-6 theme-bg-secondary/30 border border-[var(--surface-border)] rounded-2xl relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-yellow-500"></div>
              <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-[0.2em] mb-2 opacity-50">Operational Notes</p>
              <p className="text-sm theme-heading font-medium leading-relaxed">{trip.notes}</p>
            </div>
          )}
        </div>
      </div>

      {/* Administrative Overrides Panel */}
      {trip && (
        <div className="theme-card rounded-[2rem] border-2 border-orange-500/10 shadow-xl overflow-hidden group">
          <div className="px-8 py-6 border-b border-orange-500/10 bg-orange-500/5 flex items-center justify-between">
            <h2 className="font-black theme-heading uppercase text-xs tracking-[0.2em] flex items-center gap-3">
              <div className="h-8 w-8 rounded-lg bg-orange-500/10 flex items-center justify-center">
                <Shield className="h-4 w-4 text-orange-600" />
              </div>
              Administrative Overrides
            </h2>
            <span className="text-[0.5625rem] theme-bg-secondary theme-muted px-3 py-1 rounded-full font-black uppercase tracking-[0.2em] border border-[var(--surface-border)]">
              Ops Security Level 4
            </span>
          </div>
          <div className="p-8 space-y-8">
            <div className="space-y-6">
              {/* Force Status Section */}
              <div className="space-y-6">
                <div className="flex items-center gap-3 text-[0.625rem] font-black theme-muted uppercase tracking-[0.2em] opacity-60">
                  <Zap className="h-4 w-4 text-orange-500" /> Force Trip Status
                </div>
                <p className="text-xs theme-muted font-medium leading-relaxed">
                  {t('tripDetail.override.warning', 'Direct state injection into the trip lifecycle. Use with caution as this bypasses standard operational guards and state machine validations.')}
                </p>
                <div className="flex flex-wrap gap-2">
                  {(['available', 'in_communication', 'pending_confirmation', 'booked', 'full', 'in_transit', 'completed', 'cancelled'] as TripStatus[]).map(status => (
                    <button
                      key={status}
                      onClick={async () => {
                        const reason = prompt(t('tripDetail.override.forcePrompt', 'Reason for forcing trip status to {status}?').replace('{status}', status.toUpperCase()));
                        if (!reason || reason.length < 5) return;
                        const res = await forceTripStatus(id, status, reason);
                        if (res.success) {
                          toast(t('tripDetail.override.successToast', 'Trip status forced to {status}').replace('{status}', status), 'success');
                          fetchAll();
                        } else {
                          toast(res.error || t('tripDetail.override.failed', 'Override failed'), 'error');
                        }
                      }}
                      className={`px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all border ${trip.status === status
                        ? 'bg-orange-600 text-white border-orange-600 shadow-lg shadow-orange-500/30 -translate-y-1'
                        : 'theme-bg-secondary theme-muted border-[var(--surface-border)] hover:theme-heading hover:border-[var(--muted)]/50'
                        }`}
                    >
                      {status}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex items-start gap-4 p-5 theme-bg-secondary/30 rounded-2xl border border-[var(--surface-border)] shadow-inner">
              <div className="h-8 w-8 rounded-full theme-bg-secondary flex items-center justify-center flex-shrink-0">
                <AlertCircle className="h-4 w-4 theme-info" />
              </div>
              <p className="text-[0.625rem] theme-muted leading-relaxed font-bold uppercase tracking-widest opacity-60">
                Operational Note: All administrative overrides are cryptographically logged in the system audit trail. Force Status bypasses user notifications and payment verification locks.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Bookings Section */}
      <div className="theme-card rounded-[2.5rem] shadow-2xl overflow-hidden border border-[var(--surface-border)]">
        <div className="px-10 py-8 border-b border-[var(--surface-border)] theme-bg-secondary/30 flex items-center justify-between">
          <h2 className="font-black theme-heading uppercase text-sm tracking-[0.2em] flex items-center gap-3">
            <Package className="h-5 w-5 theme-muted" />
            Bookings <span className="text-blue-600 ml-1">({bookings.length})</span>
          </h2>
        </div>

        {bookingsError ? (
          <div className="py-20 text-center">
            <div className="h-20 w-20 rounded-full theme-bg-danger-soft mx-auto mb-6 flex items-center justify-center border border-[var(--red-500)]/10">
              <AlertTriangle className="h-10 w-10 theme-danger opacity-70" />
            </div>
            <p className="theme-danger text-[0.625rem] font-black uppercase tracking-[0.2em] mb-5">{bookingsError}</p>
            <button
              onClick={fetchAll}
              className="px-5 py-2.5 theme-bg-secondary border border-[var(--surface-border)] rounded-xl text-[0.625rem] font-black uppercase tracking-widest theme-heading hover:scale-105 active:scale-95 transition-all shadow-sm"
            >
              {t('common.retry', 'Retry')}
            </button>
          </div>
        ) : bookings.length === 0 ? (
          <div className="py-24 text-center">
            <div className="h-20 w-20 rounded-full theme-bg-secondary mx-auto mb-6 flex items-center justify-center border border-dashed border-[var(--surface-border)]">
              <Package className="h-10 w-10 theme-muted opacity-20" />
            </div>
            <p className="theme-muted text-[0.625rem] font-black uppercase tracking-[0.2em]">{t('tripDetail.bookings.empty', 'No bookings for this trip yet')}</p>
          </div>
        ) : (
          <div className="divide-y divide-[var(--surface-border)]">
            {bookings.map(booking => {
              const isExpanded = expandedBooking === booking.id;
              const bookingMessages = messages[booking.id] || [];
              const isLoadingMsgs = loadingMessages === booking.id;

              return (
                <div key={booking.id} className="border-b last:border-0">
                  {/* Booking row */}
                  <div className="px-8 py-8 flex items-center justify-between gap-8 group/row">
                    <div className="flex items-center gap-6 min-w-0">
                      <div className="h-12 w-12 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center shadow-inner group-hover/row:scale-110 transition-transform">
                        <Package className="h-6 w-6 theme-muted" />
                      </div>
                      <div>
                        <div className="flex items-center gap-3 mb-2">
                          <Link href={`/bookings/${booking.id}`} className="font-black theme-heading text-lg tracking-tighter hover:text-blue-600 transition-colors">
                            #{booking.id.slice(0, 8)}
                          </Link>
                          <StatusBadge status={booking.status} />
                        </div>
                        <div className="flex flex-wrap gap-x-6 gap-y-2 text-[0.625rem] font-bold uppercase tracking-widest theme-muted">
                          <span className="flex items-center gap-2">
                            <User className="h-3 w-3" />
                            {t('tripDetail.booking.requester', 'Requester')}: {booking.requester_profile ? (
                              <Link href={`/users/${booking.requester_profile.id}`} className="theme-heading hover:text-blue-600 transition-colors">
                                {booking.requester_profile.full_name || 'Unknown'}
                              </Link>
                            ) : '—'}
                          </span>
                          <span className="flex items-center gap-2 border-l border-[var(--surface-border)] pl-6">
                            <User className="h-3 w-3" />
                            {t('tripDetail.booking.traveler', 'Traveler')}: {booking.driver_profile ? (
                              <>
                                <Link href={`/users/${booking.driver_profile.id}`} className="theme-heading hover:text-blue-600 transition-colors">
                                  {booking.driver_profile.full_name || 'Unknown'}
                                </Link>
                                <span className={`rounded-full border px-2 py-0.5 text-[0.5rem] font-black uppercase tracking-widest ${travelerRoleClass(!!booking.driver_profile.is_driver)}`}>
                                  {booking.driver_profile.is_driver ? t('trips.role.driver', 'Driver') : t('trips.role.simpleTraveler', 'Simple traveler')}
                                </span>
                              </>
                            ) : 'N/A'}
                          </span>
                          <span className="flex items-center gap-2 border-l border-[var(--surface-border)] pl-6">
                            <span className="text-blue-600 font-black">{booking.price}</span>
                          </span>
                          <span className="flex items-center gap-2 border-l border-[var(--surface-border)] pl-6">
                            <Calendar className="h-3 w-3" />
                            {new Date(booking.created_at).toLocaleDateString()}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 flex-shrink-0">
                      {!['cancelled', 'completed', 'rejected'].includes(booking.status) && (
                        <button onClick={() => cancelBooking(booking.id)} className="px-4 py-2 theme-bg-danger-soft theme-danger border border-[var(--red-500)]/10 rounded-xl text-[0.625rem] font-black uppercase tracking-widest hover:theme-bg-danger transition-all active:scale-95 shadow-sm">
                          {t('common.cancel', 'Cancel')}
                        </button>
                      )}
                      <button
                        onClick={() => loadMessagesForBooking(booking.id)}
                        className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm ${isExpanded
                          ? 'bg-blue-600 text-white shadow-blue-500/20'
                          : 'theme-bg-secondary theme-muted hover:theme-heading hover:border-[var(--muted)]/50'
                          }`}
                      >
                        <MessageSquare className="h-4 w-4" />
                        {t('tripDetail.booking.communications', 'Communications')}
                        {isExpanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
                      </button>
                    </div>
                  </div>

                  {/* Timeline row */}
                  <div className="px-8 pb-8 pt-2">
                    <div className="flex items-center gap-1.5 overflow-x-auto pb-2 scrollbar-hide">
                      <TimelineStep done={!!booking.goods_handed_by_sender_at} label="Handed" ts={booking.goods_handed_by_sender_at} />
                      <TimelineConnector />
                      <TimelineStep done={!!booking.goods_received_by_traveler_at} label="Received" ts={booking.goods_received_by_traveler_at} />
                      <TimelineConnector />
                      <TimelineStep done={!!booking.payment_marked_by_sender_at} label="Paid" ts={booking.payment_marked_by_sender_at} />
                      <TimelineConnector />
                      <TimelineStep done={!!booking.payment_confirmed_by_traveler_at} label="Confirmed" ts={booking.payment_confirmed_by_traveler_at} />
                      <TimelineConnector />
                      <TimelineStep done={!!booking.goods_delivered_by_traveler_at} label="Delivered" ts={booking.goods_delivered_by_traveler_at} />
                      <TimelineConnector />
                      <TimelineStep done={!!booking.goods_received_by_client_at} label="Completed" ts={booking.goods_received_by_client_at} />
                    </div>
                  </div>

                  {/* Expanded messages */}
                  {isExpanded && (
                    <div className="px-8 pb-10">
                      <div className="theme-bg-secondary/50 rounded-3xl border border-[var(--surface-border)] shadow-inner overflow-hidden">
                        <div className="px-6 py-4 border-b border-[var(--surface-border)] theme-bg-secondary/30 flex items-center justify-between">
                          <p className="text-[0.625rem] font-black theme-muted uppercase tracking-[0.2em]">{t('tripDetail.booking.messages', 'Messages')}</p>
                          <div className="flex gap-1">
                            <div className="h-1.5 w-1.5 rounded-full bg-blue-500 animate-pulse"></div>
                            <div className="h-1.5 w-1.5 rounded-full bg-blue-500 animate-pulse delay-75"></div>
                            <div className="h-1.5 w-1.5 rounded-full bg-blue-500 animate-pulse delay-150"></div>
                          </div>
                        </div>
                        <div className="p-6 max-h-[400px] overflow-y-auto space-y-6 custom-scrollbar">
                          {isLoadingMsgs ? (
                            <div className="flex flex-col items-center justify-center py-20 gap-4">
                              <div className="h-12 w-12 border-4 border-blue-500/20 border-t-blue-500 rounded-full animate-spin" />
                              <p className="text-[0.625rem] theme-muted font-black uppercase tracking-[0.2em] animate-pulse">{t('tripDetail.booking.messagesLoading', 'Loading messages...')}</p>
                            </div>
                          ) : bookingMessages.length === 0 ? (
                            <div className="text-center py-20 flex flex-col items-center gap-4 opacity-40">
                              <MessageSquare className="h-12 w-12 theme-muted" />
                              <p className="theme-muted text-[0.625rem] font-black uppercase tracking-[0.2em]">{t('tripDetail.booking.messagesEmpty', 'No messages yet')}</p>
                            </div>
                          ) : (
                            bookingMessages.map((msg) => (
                              <div key={msg.id} className="flex gap-4 group/msg">
                                <div className="h-10 w-10 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center flex-shrink-0 mt-1 shadow-sm group-hover/msg:border-blue-500/30 transition-colors">
                                  <User className="h-5 w-5 theme-muted group-hover/msg:text-blue-500 transition-colors" />
                                </div>
                                <div className="min-w-0 flex-1">
                                  <div className="flex items-center justify-between mb-2">
                                    <div className="flex items-center gap-3">
                                      <span className="text-xs font-black theme-heading uppercase tracking-tight tracking-wider">
                                        {msg.sender?.full_name || 'System Admin'}
                                      </span>
                                      {msg.type !== 'text' && (
                                        <span className="text-[0.5rem] theme-bg-secondary theme-muted px-2 py-0.5 rounded font-black uppercase border border-[var(--surface-border)]">{msg.type}</span>
                                      )}
                                    </div>
                                    <span className="text-[0.625rem] theme-muted font-bold opacity-60">
                                      {new Date(msg.created_at).toLocaleString()}
                                    </span>
                                  </div>
                                  <div className="theme-bg-secondary p-4 rounded-2xl rounded-tl-none border border-[var(--surface-border)] group-hover/msg:shadow-md transition-all">
                                    <p className="text-sm theme-heading font-medium leading-relaxed break-words">{msg.content}</p>
                                  </div>
                                </div>
                              </div>
                            ))
                          )}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>

      {editOpen && trip && (
        <TripEditModal
          trip={trip}
          onClose={() => setEditOpen(false)}
          onSaved={(updates) => setTrip((prev: any) => ({ ...prev, ...updates }))}
        />
      )}
    </div>
  );
}
