'use client';

import { useEffect, useState } from 'react';
import { useParams, usePathname, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import {
  ArrowLeft, Package, User, Calendar, CreditCard,
  MessageSquare, Ban, CheckCircle, Route, MapPin, AlertTriangle,
} from 'lucide-react';
import Loading from '@/app/loading';
import { logAdminAction } from '@/lib/audit';
import Link from 'next/link';

import { StatusBadge } from '@/components/StatusBadge';
import { Message, BookingStatus } from '@/lib/types';
import { useT } from '@/lib/i18n';
import { forceBookingStatus, toggleBookingFreeze, setBookingEscalation, forcePaymentRelease, forceRefund } from '@/app/actions/operational-actions';
import { resolveBookingDispute } from '@/app/actions/governance-actions';
import { Shield, AlertCircle, Lock, Unlock, Zap, Flag, Banknote, RotateCcw, Scale, Gavel, FileText, CheckCircle2 } from 'lucide-react';
import { QuickActionStrip } from '@/components/QuickActionStrip';
import { resolveExportedDynamicRouteId } from '@/lib/export-dynamic-route';


export default function BookingDetailPage() {
  const params = useParams();
  const pathname = usePathname();
  const router = useRouter();
  const { toast, confirm: confirmDialog } = useToast();
  const t = useT();
  const resolvedId = resolveExportedDynamicRouteId(params.id as string | string[] | undefined, pathname);
  const id = resolvedId ?? '';

  const [booking, setBooking] = useState<any>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(true);

  useEffect(() => {
    if (!resolvedId) {
      setLoading(false);
      setLoadingMessages(false);
      setBooking(null);
      setMessages([]);
      return;
    }
    fetchBooking();
    fetchMessages();
  }, [resolvedId]);

  async function fetchBooking() {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('bookings')
        .select(`
          *,
          trips(*,
            origin:locations!origin_location_id(city_name_en, city_name_ar),
            dest:locations!dest_location_id(city_name_en, city_name_ar),
            driver:profiles!traveler_id(id, full_name)
          ),
          driver_profile:profiles!bookings_traveler_id_fkey(id, full_name, phone_number, is_suspended),
          requester_profile:profiles!bookings_requester_id_profiles_fkey(id, full_name, phone_number, is_suspended)
        `)
        .eq('id', id)
        .single();
      if (error) {
        setBooking(null);
        toast(t('bookingDetail.toast.loadFailed', 'Failed to load booking.'), 'error');
      } else {
        setBooking(data as any);
      }
    } catch {
      setBooking(null);
      toast(t('bookingDetail.toast.loadFailed', 'Failed to load booking.'), 'error');
    } finally {
      setLoading(false);
    }
  }

  async function fetchMessages() {
    setLoadingMessages(true);
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*, sender:profiles!messages_sender_id_fkey(full_name)')
        .eq('booking_id', id)
        .order('created_at', { ascending: true });
      if (error) toast(t('bookingDetail.toast.messagesLoadFailed', 'Failed to load messages.'), 'error');
      setMessages((data as Message[]) || []);
    } catch {
      toast(t('bookingDetail.toast.messagesLoadFailed', 'Failed to load messages.'), 'error');
      setMessages([]);
    } finally {
      setLoadingMessages(false);
    }
  }

  function cancelBooking() {
    confirmDialog({
      title: t('bookingDetail.dialog.cancelBooking.title', 'Cancel Booking'),
      message: t('bookingDetail.dialog.cancelBooking.message', 'Are you sure you want to cancel this booking? This action cannot be undone.'),
      confirmLabel: t('bookingDetail.dialog.cancelBooking.confirmLabel', 'Yes, Cancel'),
      onConfirm: async () => {
        // 1. Cancel the booking
        const { error } = await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', id);
        if (error) { toast(t('bookingDetail.toast.cancelFailed', 'Failed to cancel booking'), 'error'); return; }

        await logAdminAction('cancel_booking', 'booking', id);
        toast(t('bookingDetail.toast.bookingCancelled', 'Booking cancelled successfully'), 'success');

        // 2. Sync Trip Status (if applicable)
        if (booking.trip_id && booking.trips && !['completed', 'cancelled'].includes(booking.trips.status)) {
          try {
            // Count remaining ACTIVE bookings for this trip
            const { count: activeCount, error: activeCountError } = await supabase
              .from('bookings')
              .select('id', { count: 'exact', head: true })
              .eq('trip_id', booking.trip_id)
              .not('status', 'in', '(cancelled,rejected,completed)');

            if (activeCountError) throw activeCountError;

            let newStatus = booking.trips.status;

            // Logic: If no active bookings remain, mark trip as 'available'
            // If there are active bookings, keep as 'booked'
            if (activeCount === 0) {
              newStatus = 'available';
            } else if (booking.trips.status === 'full') {
              // If trip was full and we cancelled a booking, reopen it to 'booked'
              newStatus = 'booked';
            }

            // Only update if status changed and trip isn't already 'in_transit'
            if (booking.trips.status !== 'in_transit' && newStatus !== booking.trips.status) {
              await supabase.from('trips').update({ status: newStatus }).eq('id', booking.trip_id);
              toast(t('bookingDetail.toast.tripStatusUpdated', 'Trip status updated to {status}').replace('{status}', newStatus), 'success');
            }

          } catch (err) {
            console.error('Error syncing trip status:', err);
            toast(t('bookingDetail.toast.syncFailed', 'Failed to sync trip status.'), 'error');
          }
        }

        fetchBooking();
      }
    });
  }

  if (loading) return <Loading />;
  if (!booking) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <p className="text-gray-500 mb-4">{t('bookingDetail.notFound', 'Booking not found')}</p>
        <button onClick={() => router.push('/bookings')} className="text-blue-600 hover:underline">{t('bookingDetail.backToList', 'Back to Bookings')}</button>
      </div>
    );
  }

  const getCityLabel = (loc: any) => loc?.city_name_en || loc?.city_name_ar || 'N/A';
  const isCancellable = !['cancelled', 'completed', 'rejected'].includes(booking.status);

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <button onClick={() => router.push('/bookings')} className="flex items-center gap-2 text-gray-600 hover:text-gray-900 text-sm">
        <ArrowLeft className="h-4 w-4" /> {t('bookingDetail.backToList', 'Back to Bookings')}
      </button>

      {/* Founder Mode: Quick Action Strip */}
      <QuickActionStrip
        actions={[
          {
            label: isCancellable ? t('bookingDetail.action.forceCancel', 'Cancel Booking') : t('bookingDetail.action.cancelled', 'Cancelled'),
            icon: Ban,
            variant: 'danger',
            shortcut: 'X',
            onClick: cancelBooking
          },
          {
            label: booking.status === 'disputed' ? t('bookingDetail.action.resolveDispute', 'Resolve Dispute') : t('bookingDetail.action.openDispute', 'Open Dispute'),
            icon: Gavel,
            variant: 'warning',
            shortcut: 'D',
            onClick: async () => {
              if (booking.status === 'disputed') {
                const outcome = prompt(t('bookingDetail.prompt.disputeOutcome', 'Dispute outcome (favour_requester, favour_traveler, invalid_claim, mutually_resolved)'), "favour_requester");
                if (!outcome) return;
                const notes = prompt(t('bookingDetail.prompt.resolutionNotes', 'Resolution notes'));
                if (!notes) return;
                const allowedOutcomes = ['favour_requester', 'favour_traveler', 'invalid_claim', 'mutually_resolved'] as const;
                if (!allowedOutcomes.includes(outcome as typeof allowedOutcomes[number])) {
                  toast(t('bookingDetail.toast.invalidOutcome', 'Invalid dispute outcome.'), 'error');
                  return;
                }
                const res = await resolveBookingDispute(id, outcome as typeof allowedOutcomes[number], notes);
                if (res.success) {
                  toast(t('bookingDetail.toast.disputeResolved', 'Dispute resolved successfully'), 'success');
                  fetchBooking();
                } else {
                  toast(res.error || t('bookingDetail.toast.resolutionFailed', 'Resolution failed'), 'error');
                }
              } else {
                const reason = prompt(t('bookingDetail.prompt.disputeReason', 'Reason for opening dispute'));
                if (!reason) return;
                const res = await forceBookingStatus(id, 'disputed', reason);
                if (res.success) {
                  toast(t('bookingDetail.toast.statusForced', 'Status forced to {status}').replace('{status}', 'disputed'), 'success');
                  fetchBooking();
                } else {
                  toast(res.error || t('bookingDetail.toast.overrideFailed', 'Override failed'), 'error');
                }
              }
            }
          },
          {
            label: booking.status === 'frozen' ? t('bookingDetail.action.unlock', 'Unlock') : t('bookingDetail.action.freeze', 'Freeze'),
            icon: booking.status === 'frozen' ? Unlock : Lock,
            shortcut: 'L',
            onClick: async () => {
              const reason = prompt(t('bookingDetail.prompt.freezeReason', `Reason for ${booking.status === 'frozen' ? 'unfreezing' : 'freezing'}?`));
              if (!reason) return;
              const res = await toggleBookingFreeze(id, booking.status === 'frozen', reason);
              if (res.success) {
                toast(t(`bookingDetail.toast.${booking.status === 'frozen' ? 'unfrozen' : 'frozen'}`, booking.status === 'frozen' ? 'Booking unfrozen' : 'Booking frozen'), 'success');
                fetchBooking();
              } else {
                toast(res.error || t('bookingDetail.toast.actionFailed', 'Action failed'), 'error');
              }
            }
          },
          {
            label: booking.is_escalated ? t('bookingDetail.action.deEscalate', 'De-escalate') : t('bookingDetail.action.escalate', 'Escalate'),
            icon: Flag,
            variant: booking.is_escalated ? 'primary' : 'ghost',
            onClick: async () => {
              const reason = prompt(t('bookingDetail.prompt.reason', 'Reason'));
              if (!reason) return;
              const res = await setBookingEscalation(id, !booking.is_escalated, reason);
              if (res.success) {
                toast(
                  t('bookingDetail.toast.escalateSuccess', 'Booking {action}').replace(
                    '{action}',
                    !booking.is_escalated ? t('bookingDetail.status.escalated', 'escalated') : t('bookingDetail.status.deescalated', 'de-escalated')
                  ),
                  'success'
                );
                fetchBooking();
              } else {
                toast(res.error || t('bookingDetail.toast.actionFailed', 'Action failed'), 'error');
              }
            }
          },
          {
            label: t('bookingDetail.action.addNote', 'Add Note'),
            icon: FileText,
            shortcut: 'N',
            onClick: async () => {
              const note = prompt(t('bookingDetail.prompt.internalNote', 'Internal note'));
              if (!note) return;
              await logAdminAction('add_booking_note', 'booking', id, { note });
              toast(t('bookingDetail.toast.noteAdded', 'Note added to audit log.'), 'success');
            }
          }
        ]}
      />

      {/* Booking Header */}
      <div className="theme-card rounded-2xl shadow-sm p-6">
        <div className="flex items-start justify-between gap-4 mb-6">
          <div className="flex items-center gap-4">
            <div className="h-12 w-12 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
              <Package className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-gray-900">{t('bookingDetail.header.title', 'Booking #{id}').replace('{id}', booking.id.slice(0, 8))}</h1>
              <p className="text-sm text-gray-500">{t('bookingDetail.header.created', 'Created {date}').replace('{date}', new Date(booking.created_at).toLocaleString())}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <StatusBadge status={booking.status} />
            {isCancellable && (
              <button onClick={cancelBooking} className="flex items-center gap-1.5 px-3 py-1.5 bg-red-50 text-red-600 hover:bg-red-100 rounded-lg text-xs font-bold transition">
                <Ban className="h-3.5 w-3.5" /> {t('bookingDetail.header.cancel', 'Cancel')}
              </button>
            )}
          </div>
        </div>

        {/* Parties */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="theme-bg-secondary p-4 rounded-xl text-left">
            <p className="text-[0.625rem] theme-muted uppercase font-bold mb-2 flex items-center gap-1"><User className="h-3 w-3" /> {t('bookingDetail.travelerDriver', 'Traveler / Driver')}</p>
            {booking.driver_profile ? (
              <>
                <Link href={`/users/${booking.driver_profile.id}`} className="font-bold text-blue-600 hover:underline text-sm">
                  {booking.driver_profile.full_name || t('common.unknown', 'Unknown')}
                </Link>
                <p className="text-xs text-gray-500">{booking.driver_profile.phone_number}</p>
                {booking.driver_profile.is_suspended && (
                  <p className="text-xs text-red-600 mt-1 flex items-center gap-1"><AlertTriangle className="h-3 w-3" /> {t('bookingDetail.parties.suspended', 'Suspended')}</p>
                )}
              </>
            ) : <p className="text-sm text-gray-400">-</p>}
          </div>
          <div className="theme-bg-secondary p-4 rounded-xl text-left">
            <p className="text-[0.625rem] theme-muted uppercase font-bold mb-2 flex items-center gap-1"><User className="h-3 w-3" /> {t('bookingDetail.requester', 'Requester')}</p>
            {booking.requester_profile ? (
              <>
                <Link href={`/users/${booking.requester_profile.id}`} className="font-bold text-blue-600 hover:underline text-sm">
                  {booking.requester_profile.full_name || t('common.unknown', 'Unknown')}
                </Link>
                <p className="text-xs text-gray-500">{booking.requester_profile.phone_number}</p>
              </>
            ) : <p className="text-sm text-gray-400">-</p>}
          </div>
          <div className="theme-bg-secondary p-4 rounded-xl text-left">
            <p className="text-[0.625rem] theme-muted uppercase font-bold mb-2 flex items-center gap-1"><CreditCard className="h-3 w-3" /> {t('bookingDetail.reservationPrice', 'Reservation Price')}</p>
            <p className="font-bold text-lg text-gray-900">{booking.price} <span className="text-xs font-normal text-gray-500">{t('common.currencySar', '')}</span></p>
            {booking.message && <p className="text-xs text-gray-500 mt-1 italic">"{booking.message}"</p>}
          </div>
        </div>

        {/* Dispute Resolution Governance */}
        {(booking.status === 'disputed' || booking.payment_disputed_at) && (
          <div className="bg-[var(--surface)] text-left rounded-2xl border-2 border-orange-500/20 shadow-md overflow-hidden mb-6">
            <div className="px-6 py-4 border-b border-orange-500/10 bg-orange-500/5 flex items-center justify-between">
              <h2 className="font-bold text-orange-600 flex items-center gap-2">
                <Scale className="h-5 w-5" />
                {t('bookingDetail.disputeGov.title', 'Dispute Resolution')}
              </h2>
              <span className="text-[0.625rem] bg-orange-500/20 text-orange-600 px-2 py-0.5 rounded-full font-black uppercase tracking-widest">
                {t('bookingDetail.disputeGov.badge', 'Governance')}
              </span>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <p className="text-[0.625rem] theme-muted uppercase font-black mb-1">{t('bookingDetail.disputeGov.field.reason', 'Dispute Reason')}</p>
                    <div className="p-3 theme-bg-secondary rounded-xl border border-[var(--surface-border)] text-sm theme-heading italic">
                      "{booking.dispute_reason || t('bookingDetail.disputeGov.noReason', 'No reason provided')}"
                    </div>
                  </div>
                  {booking.evidence_urls && booking.evidence_urls.length > 0 && (
                    <div>
                      <p className="text-[0.625rem] text-gray-400 uppercase font-black mb-2">{t('bookingDetail.disputeGov.field.evidence', 'Evidence')}</p>
                      <div className="flex flex-wrap gap-2">
                        {booking.evidence_urls.map((url: string, i: number) => (
                          <a
                            key={i}
                            href={url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 px-3 py-2 bg-[var(--surface)] border border-[var(--surface-border)] rounded-lg text-xs font-bold text-blue-600 hover:border-blue-600 transition shadow-sm"
                          >
                            <FileText className="h-4 w-4" /> {t('bookingDetail.disputeGov.proof', 'Proof')} #{i + 1}
                          </a>
                        ))}
                      </div>
                    </div>
                  )}
                  {booking.dispute_outcome && (
                    <div className="p-3 bg-green-50 rounded-xl border border-green-100">
                      <div className="flex items-center gap-2 text-green-700 font-bold text-sm mb-1">
                        <CheckCircle2 className="h-4 w-4" /> {t('bookingDetail.disputeGov.outcome', 'Outcome')}: {booking.dispute_outcome.replace('_', ' ').toUpperCase()}
                      </div>
                      <p className="text-[0.625rem] text-green-600">
                        {t('bookingDetail.disputeGov.resolvedOn', 'Resolved on')} {new Date(booking.dispute_resolved_at).toLocaleDateString()}
                      </p>
                    </div>
                  )}
                </div>

                {!booking.dispute_outcome && (
                  <div className="space-y-4 theme-bg-secondary/50 p-4 rounded-2xl border border-dashed border-[var(--surface-border)]">
                    <p className="text-[0.625rem] theme-muted uppercase font-black">{t('bookingDetail.disputeGov.finalizeTitle', 'Finalize Resolution')}</p>
                    <div className="grid grid-cols-2 gap-2">
                      {(['favour_requester', 'favour_traveler', 'invalid_claim', 'mutually_resolved'] as const).map(outcome => (
                        <button
                          key={outcome}
                          onClick={async () => {
                            const notes = prompt(`${t('bookingDetail.prompt.resolutionNotesFor', 'Resolution notes for')} ${outcome.replace('_', ' ')}? ${t('common.required', '(Required)')}`);
                            if (!notes || notes.length < 10) {
                              toast(t('bookingDetail.toast.justificationRequired', 'Justification required (min 10 characters)'), "error");
                              return;
                            }
                            const res = await resolveBookingDispute(id, outcome, notes);
                            if (res.success) {
                              toast(t('bookingDetail.toast.disputeResolved', 'Dispute resolved successfully'), "success");
                              fetchBooking();
                            } else {
                              toast(res.error || t('bookingDetail.toast.resolutionFailed', 'Resolution failed'), 'error');
                            }
                          }}
                          className="px-3 py-2.5 bg-[var(--surface)] border border-[var(--surface-border)] rounded-xl text-[0.625rem] font-bold theme-heading hover:border-orange-500 hover:text-orange-600 transition flex items-center justify-center gap-1.5 shadow-sm"
                        >
                          <Gavel className="h-3.5 w-3.5" /> {outcome.replace('_', ' ')}
                        </button>
                      ))}
                    </div>
                    <p className="text-[0.625rem] theme-muted italic">
                      {t('bookingDetail.disputeGov.footer', 'All dispute resolutions are logged and auditable.')}
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Administrative Overrides Panel */}
        <div className="bg-[var(--surface)] text-left rounded-2xl border-2 border-red-500/10 shadow-sm overflow-hidden mb-6">
          <div className="px-6 py-4 border-b border-red-500/10 bg-red-500/5 flex items-center justify-between">
            <h2 className="font-bold text-red-600 flex items-center gap-2">
              <Shield className="h-5 w-5" />
              {t('bookingDetail.overrides.title', 'Administrative Overrides')}
            </h2>
            <span className="text-[0.625rem] bg-red-500/20 text-red-600 px-2 py-0.5 rounded-full font-black uppercase tracking-widest">
              {t('bookingDetail.overrides.badge', 'Admin Only')}
            </span>
          </div>
          <div className="p-6 space-y-6">
            <div className="flex flex-col md:flex-row gap-6">
              <div className="flex-1 space-y-4">
                <div className="flex items-center gap-2 text-sm font-bold text-gray-700">
                  <Zap className="h-4 w-4 text-orange-500" /> {t('bookingDetail.overrides.forceState', 'Force Status')}
                </div>
                <p className="text-xs text-gray-500">
                  {t('bookingDetail.overrides.forceStateDesc', 'Override the booking status regardless of business rules. Use with extreme caution.')}
                </p>
                <div className="flex flex-wrap gap-2">
                  {(['pending', 'in_communication', 'accepted', 'rejected', 'in_transit', 'delivered', 'completed', 'cancelled', 'disputed'] as BookingStatus[]).map(status => (
                    <button
                      key={status}
                      onClick={async () => {
                        const reason = prompt(t('bookingDetail.prompt.forceStatus', `Reason for forcing status to ${status.toUpperCase()}?`).replace('{status}', status.toUpperCase()));
                        if (!reason || reason.length < 5) {
                          toast(t('bookingDetail.toast.reasonRequired', 'Reason required (min 5 characters)'), "error");
                          return;
                        }
                        const res = await forceBookingStatus(id, status, reason);
                        if (res.success) {
                          toast(t('bookingDetail.toast.statusForced', 'Status forced to {status}').replace('{status}', status), "success");
                          fetchBooking();
                        } else {
                          toast(res.error || t('bookingDetail.toast.overrideFailed', 'Override failed'), 'error');
                        }
                      }}
                      className={`px-3 py-1.5 rounded-lg text-[0.625rem] font-black uppercase tracking-tight transition-all border ${booking.status === status
                        ? 'bg-gray-900 text-white border-gray-900 shadow-lg scale-105'
                        : 'bg-[var(--surface)] theme-muted border-[var(--surface-border)] hover:border-[var(--heading)] hover:text-[var(--heading)]'
                        }`}
                    >
                      {status}
                    </button>
                  ))}
                </div>

                {/* Financial Overrides Section - Hidden 
                <div className="pt-4 border-t border-gray-100">
                  <div className="flex items-center gap-2 text-sm font-bold text-gray-700 mb-3">
                    <Banknote className="h-4 w-4 text-green-600" /> {t('bookingDetail.overrides.financial', 'Financial Actions')}
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={async () => {
                        const reason = prompt(t('bookingDetail.prompt.forcePaymentRelease', "Reason for forcing payment release?"));
                        if (!reason) return;
                        const res = await forcePaymentRelease(id, reason);
                        if (res.success) {
                          toast(t('bookingDetail.toast.paymentReleased', 'Payment released successfully'), "success");
                          fetchBooking();
                        } else {
                          toast(res.error || t('bookingDetail.toast.releaseFailed', 'Release failed'), 'error');
                        }
                      }}
                      className="flex-1 bg-green-500/10 text-green-600 hover:bg-green-500/20 border border-green-500/20 px-3 py-2 rounded-lg text-[0.625rem] font-black uppercase transition flex items-center justify-center gap-2"
                    >
                      <Banknote className="h-3.5 w-3.5" /> {t('bookingDetail.action.releasePayment', 'Release Payment')}
                    </button>
                    <button
                      onClick={async () => {
                        const reason = prompt(t('bookingDetail.prompt.forceRefund', "Reason for forcing refund and cancellation?"));
                        if (!reason) return;
                        const res = await forceRefund(id, reason);
                        if (res.success) {
                          toast(t('bookingDetail.toast.bookingRefunded', 'Booking refunded successfully'), "success");
                          fetchBooking();
                        } else {
                          toast(res.error || t('bookingDetail.toast.refundFailed', 'Refund failed'), 'error');
                        }
                      }}
                      className="flex-1 bg-red-500/10 text-red-600 hover:bg-red-500/20 border border-red-500/20 px-3 py-2 rounded-lg text-[0.625rem] font-black uppercase transition flex items-center justify-center gap-2"
                    >
                      <RotateCcw className="h-3.5 w-3.5" /> {t('bookingDetail.action.forceRefund', 'Force Refund')}
                    </button>
                  </div>
                </div>
                */}
              </div>

              <div className="w-full md:w-64 space-y-4 md:border-l md:pl-6 border-gray-100 text-left">
                <div className="flex items-center gap-2 text-sm font-bold text-gray-700">
                  {booking.status === 'frozen' ? <Unlock className="h-4 w-4 text-green-500" /> : <Lock className="h-4 w-4 text-red-500" />}
                  {t('bookingDetail.overrides.lock', 'Freeze / Unfreeze')}
                </div>
                <p className="text-xs text-gray-500">
                  {t('bookingDetail.overrides.lockDesc', 'Freeze a booking to prevent any state changes or actions until unfrozen.')}
                </p>
                <button
                  onClick={async () => {
                    const isFrozen = booking.status === 'frozen';
                    const reason = prompt(t('bookingDetail.prompt.freezeReason', `Reason for ${isFrozen ? 'unfreezing' : 'freezing'} this booking?`));
                    if (!reason) return;
                    const res = await toggleBookingFreeze(id, isFrozen, reason);
                    if (res.success) {
                      toast(t(`bookingDetail.toast.${isFrozen ? 'unfrozen' : 'frozen'}`), "success");
                      fetchBooking();
                    } else {
                      toast(res.error || t('bookingDetail.toast.actionFailed', 'Action failed'), 'error');
                    }
                  }}
                  className={`w-full py-2.5 rounded-xl text-xs font-black uppercase tracking-widest transition-all shadow-md ${booking.status === 'frozen'
                    ? 'bg-green-600 hover:bg-green-700 text-white'
                    : 'bg-red-600 hover:bg-red-700 text-white'
                    }`}
                >
                  {booking.status === 'frozen' ? t('bookingDetail.action.unlock') : t('bookingDetail.action.freeze')}
                </button>

                <div className="pt-4 border-t border-gray-100">
                  <div className="flex items-center gap-2 text-sm font-bold text-gray-700 mb-2">
                    <Flag className={`h-4 w-4 ${booking.is_escalated ? 'text-red-600 fill-red-600' : 'text-gray-400'}`} />
                    {t('bookingDetail.overrides.escalation', 'Escalation')}
                  </div>
                  <button
                    onClick={async () => {
                      const reason = prompt(t('bookingDetail.prompt.escalationReason', `Reason for ${booking.is_escalated ? 'de-escalating' : 'escalating'} this booking?`));
                      if (!reason) return;
                      const res = await setBookingEscalation(id, !booking.is_escalated, reason);
                      if (res.success) {
                        toast(t('bookingDetail.toast.escalateSuccess', 'Booking {action}').replace('{action}', !booking.is_escalated ? t('bookingDetail.status.escalated', 'escalated') : t('bookingDetail.status.deescalated', 'de-escalated')), 'success');
                        fetchBooking();
                      } else {
                        toast(res.error || t('bookingDetail.toast.actionFailed', 'Action failed'), 'error');
                      }
                    }}
                    className={`w-full py-2 rounded-lg text-[0.625rem] font-black uppercase tracking-widest border transition-all ${booking.is_escalated
                      ? 'bg-red-50 text-red-700 border-red-200'
                      : 'bg-gray-50 text-gray-600 border-gray-200'
                      }`}
                  >
                    {booking.is_escalated ? t('bookingDetail.action.deEscalate') : t('bookingDetail.action.escalate')}
                  </button>
                </div>
              </div>
            </div>
            <div className="flex items-start gap-3 p-3 bg-orange-500/10 rounded-xl border border-orange-500/20 italic">
              <AlertCircle className="h-4 w-4 text-orange-600 mt-0.5" />
              <p className="text-[0.625rem] text-orange-600 leading-relaxed font-medium">
                <strong>{t('bookingDetail.overrides.warning', 'Warning')}</strong>: {t('bookingDetail.overrides.warningDesc', 'All administrative overrides are logged and auditable. Use only when necessary and provide clear justification.')}
              </p>
            </div>
          </div>
        </div>

        {/* Linked Trip */}
        <div className="grid grid-cols-1 gap-4 mb-6">
          {booking.trips && (
            <Link href={`/trips/${booking.trips.id}`} className="bg-orange-500/5 p-4 rounded-xl border border-orange-500/10 hover:shadow-sm transition block text-left">
              <p className="text-[0.625rem] text-orange-600 uppercase font-bold mb-2 flex items-center gap-1"><Route className="h-3 w-3" /> {t('bookingDetail.linked.trip', 'Linked Trip')}</p>
              <p className="font-bold text-sm theme-heading">
                {getCityLabel(booking.trips.origin)} -&gt; {getCityLabel(booking.trips.dest)}
              </p>
              <p className="text-xs theme-muted mt-1">{t('bookingDetail.linked.status', 'Status')}: {booking.trips.status} | {t('bookingDetail.linked.traveler', 'Traveler / Driver')}: {booking.trips.driver?.full_name || '-'}</p>
            </Link>
          )}
        </div>

        {/* Full Timeline */}
        <div className="theme-card p-6 mb-6 rounded-2xl shadow-sm text-left">
          <p className="text-xs font-bold theme-muted uppercase mb-3">{t('bookingDetail.timeline.title', 'Booking Timeline')}</p>
          <div className="space-y-3">
            <TimelineRow label={t('bookingDetail.timeline.created', 'Booking Created')} ts={booking.created_at} />
            <TimelineRow label={t('bookingDetail.timeline.handed', 'Goods Handed by Sender')} ts={booking.goods_handed_by_sender_at} />
            <TimelineRow label={t('bookingDetail.timeline.received', 'Goods Received by Traveler')} ts={booking.goods_received_by_traveler_at} />
            <TimelineRow label={t('bookingDetail.timeline.paymentMarked', 'Payment Marked by Sender')} ts={booking.payment_marked_by_sender_at} />
            <TimelineRow label={t('bookingDetail.timeline.paymentConfirmed', 'Payment Confirmed by Traveler')} ts={booking.payment_confirmed_by_traveler_at} />
            <TimelineRow label={t('bookingDetail.timeline.delivered', 'Goods Delivered by Traveler')} ts={booking.goods_delivered_by_traveler_at} />
            <TimelineRow label={t('bookingDetail.timeline.codeVerified', 'Delivery Code Verified')} ts={booking.delivery_code_verified_at} />
            <TimelineRow label={t('bookingDetail.timeline.clientReceived', 'Goods Received by Client')} ts={booking.goods_received_by_client_at} />
            <TimelineRow label={t('bookingDetail.timeline.disputed', 'Payment Disputed')} ts={booking.payment_disputed_at} color="text-red-600" />
            <TimelineRow label={t('bookingDetail.timeline.resolved', 'Dispute Resolved')} ts={booking.dispute_resolved_at} color="text-green-600" />
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="theme-card rounded-2xl shadow-sm overflow-hidden text-left">
        <div className="px-6 py-4 border-b border-[var(--surface-border)] theme-bg-secondary">
          <h2 className="font-bold theme-heading flex items-center gap-2">
            <MessageSquare className="h-5 w-5 theme-muted" />
            {t('bookingDetail.conversation.title', 'Conversation')} ({messages.length} {t('bookingDetail.conversation.messages', 'messages')})
          </h2>
        </div>

        <div className="max-h-[500px] overflow-y-auto">
          {loadingMessages ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
            </div>
          ) : messages.length === 0 ? (
            <div className="py-12 text-center text-gray-400">
              <MessageSquare className="h-10 w-10 mx-auto mb-2 opacity-50" />
              <p className="text-sm font-medium">{t('bookingDetail.conversation.empty', 'No messages yet')}</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-50">
              {messages.map(msg => {
                const isDriver = msg.sender_id === booking.traveler_id;
                return (
                  <div key={msg.id} className="px-6 py-3 hover:bg-gray-50/50 transition">
                    <div className="flex gap-3">
                      <div className={`h-8 w-8 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 ${isDriver ? 'bg-orange-500/10' : 'bg-blue-500/10'
                        }`}>
                        <User className={`h-4 w-4 ${isDriver ? 'text-orange-600' : 'text-blue-600'}`} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2 mb-0.5">
                          <span className="text-xs font-bold theme-heading">{msg.sender?.full_name || t('common.unknown', 'Unknown')}</span>
                          <span className={`text-[0.625rem] px-1.5 py-0.5 rounded font-bold uppercase ${isDriver ? 'bg-orange-500/10 text-orange-600' : 'bg-blue-500/10 text-blue-600'
                            }`}>
                            {isDriver ? t('common.driver', 'Driver') : t('common.client', 'Client')}
                          </span>
                          <span className="text-[0.625rem] text-gray-400">{new Date(msg.created_at).toLocaleString()}</span>
                          {msg.type !== 'text' && (
                            <span className="text-[0.625rem] bg-gray-200 text-gray-600 px-1.5 py-0.5 rounded font-bold uppercase">{msg.type}</span>
                          )}
                        </div>
                        {/* Message Content */}
                        {msg.type === 'text' ? (
                          <p className="text-sm text-gray-700 break-words">{msg.content}</p>
                        ) : msg.type === 'voice' || msg.type === 'audio' ? (
                          <div className="mt-2">
                            <audio controls className="w-full max-w-md">
                              <source src={msg.content} type="audio/mpeg" />
                              <source src={msg.content} type="audio/ogg" />
                              <source src={msg.content} type="audio/wav" />
                              <source src={msg.content} type="audio/mp4" />
                              <source src={msg.content} type="audio/webm" />
                              {t('bookingDetail.conversation.audioNotSupported', 'Your browser does not support the audio element.')}
                            </audio>
                          </div>
                        ) : msg.type === 'image' ? (
                          <div className="mt-2">
                            <a href={msg.content} target="_blank" rel="noopener noreferrer">
                              <img 
                                src={msg.content} 
                                alt={t('bookingDetail.conversation.imageAlt', 'Message image')}
                                className="max-w-sm rounded-lg border border-gray-200 hover:opacity-90 transition cursor-pointer"
                                onError={(e) => {
                                  e.currentTarget.style.display = 'none';
                                  e.currentTarget.nextElementSibling?.classList.remove('hidden');
                                }}
                              />
                              <p className="hidden text-xs text-blue-600 hover:underline">{msg.content}</p>
                            </a>
                          </div>
                        ) : (
                          <a 
                            href={msg.content} 
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="text-sm text-blue-600 hover:underline break-all"
                          >
                            {msg.content}
                          </a>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div >
  );
}



function TimelineRow({ label, ts, color }: { label: string; ts?: string | null; color?: string }) {
  const done = !!ts;
  return (
    <div className="flex items-center gap-3">
      <div className={`h-3 w-3 rounded-full flex-shrink-0 ${done ? (color?.includes('red') ? 'bg-red-500' : color?.includes('green') ? 'bg-green-500' : 'bg-green-500') : 'bg-gray-200'}`} />
      <div className="flex-1 flex items-center justify-between">
        <span className={`text-sm ${done ? (color || 'text-gray-900 font-medium') : 'text-gray-400'}`}>{label}</span>
        <span className="text-xs text-gray-400">{ts ? new Date(ts).toLocaleString() : '—'}</span>
      </div>
    </div>
  );
}
