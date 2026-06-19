'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import { useParams, usePathname, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import {
  ArrowLeft, Package, User, Calendar, Weight,
  MessageSquare, Ban, CheckCircle, Clock, ChevronDown, ChevronUp,
  CreditCard, AlertTriangle, Ruler, Image as ImageIcon, ArrowRight, Shield
} from 'lucide-react';
import Loading from '@/app/loading';
import Link from 'next/link';
import { useT } from '@/lib/i18n';
import { StatusBadge } from '@/components/StatusBadge';
import { TimelineStep, TimelineConnector } from '@/components/Timeline';
import InfoCard from '@/components/InfoCard';
import { approveShipment, rejectShipment, cancelShipmentAdmin, reopenShipmentAdmin } from '@/app/actions/shipment-actions';
import { resolveExportedDynamicRouteId } from '@/lib/export-dynamic-route';


type Message = {
  id: string;
  offer_id?: string | null;
  sender_id: string;
  content: string;
  type: string;
  created_at: string;
  is_read: boolean;
  sender?: { full_name: string | null };
};

type LocationLite = {
  city_name_en?: string | null;
  city_name_ar?: string | null;
  province_name_en?: string | null;
};

type ShipmentDetail = {
  id: string;
  status: string;
  created_at: string;
  sender?: { id?: string; full_name?: string | null; avatar_url?: string | null; phone_number?: string | null; is_suspended?: boolean } | null;
  pickup?: LocationLite | null;
  dropoff?: LocationLite | null;
  pickup_date?: string | null;
  weight_kg?: number | null;
  price?: number | null;
  length_cm?: number | null;
  width_cm?: number | null;
  height_cm?: number | null;
  volume_type?: string | null;
  transport_type?: string | null;
  description?: string | null;
  photos?: string[] | null;
  goods_handed_by_sender_at?: string | null;
  goods_received_by_driver_at?: string | null;
  payment_marked_by_sender_at?: string | null;
  payment_confirmed_by_driver_at?: string | null;
  goods_delivered_by_driver_at?: string | null;
  goods_received_by_client_at?: string | null;
};

type OfferStatus = 'sent' | 'accepted' | 'rejected' | 'cancelled' | 'completed';

type OfferRow = {
  id: string;
  shipment_id?: string | null;
  driver_id?: string | null;
  status: OfferStatus;
  price?: number | string | null;
  message?: string | null;
  rejection_reason?: string | null;
  created_at: string;
  updated_at?: string | null;
  driver_profile?: { id: string; full_name?: string | null; is_driver?: boolean | null } | null;
};

function humanize(value: string) {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}

function formatMoney(value: number | string | null | undefined) {
  if (value == null) return 'N/A';
  const amount = typeof value === 'string' ? Number(value) : value;
  if (!Number.isFinite(amount)) return 'N/A';
  return `${amount}`;
}

export default function ShipmentDetailPage() {
  const params = useParams();
  const pathname = usePathname();
  const router = useRouter();
  const { toast, confirm: confirmDialog } = useToast();
  const t = useT();
  const resolvedId = resolveExportedDynamicRouteId(params.id as string | string[] | undefined, pathname);
  const id = resolvedId ?? '';

  const [shipment, setShipment] = useState<ShipmentDetail | null>(null);
  const [offers, setOffers] = useState<OfferRow[]>([]);
  const [offersError, setOffersError] = useState('');
  const [messages, setMessages] = useState<Record<string, Message[]>>({});
  const [loading, setLoading] = useState(true);
  const [expandedOffer, setExpandedOffer] = useState<string | null>(null);
  const [loadingMessages, setLoadingMessages] = useState<string | null>(null);

  useEffect(() => {
    if (!resolvedId) {
      setLoading(false);
      setShipment(null);
      setOffers([]);
      return;
    }
    fetchAll();
  }, [resolvedId]);

  async function fetchAll() {
    if (!resolvedId) return;
    setLoading(true);
    setOffersError('');

    try {
      const { data: shipmentData, error: shipmentError } = await supabase
        .from('shipments')
        .select(`
          *,
          sender:profiles!sender_id(id, full_name, avatar_url, phone_number, is_suspended),
          pickup:locations!pickup_location_id(city_name_ar, city_name_en, province_name_en),
          dropoff:locations!dropoff_location_id(city_name_ar, city_name_en, province_name_en)
        `)
        .eq('id', id)
        .single();

      if (shipmentError) {
        setShipment(null);
        toast(t('shipmentDetail.toast.loadFailed', 'Failed to load shipment.'), 'error');
      } else {
        setShipment(shipmentData);
      }

      const { data: offersData, error: offersLoadError } = await supabase
        .from('offers')
        .select(`
          *,
          driver_profile:profiles!offers_driver_id_fkey(id, full_name, phone_number, is_driver)
        `)
        .eq('shipment_id', id)
        .order('created_at', { ascending: false });

      if (offersLoadError) {
        setOffers([]);
        setOffersError(t('shipmentDetail.toast.offersLoadFailed', 'Failed to load shipment offers.'));
        toast(t('shipmentDetail.toast.offersLoadFailed', 'Failed to load shipment offers.'), 'error');
      } else {
        setOffers((offersData as OfferRow[]) || []);
      }
    } catch {
      setShipment(null);
      setOffers([]);
      setOffersError('');
      toast(t('shipmentDetail.toast.loadFailed', 'Failed to load shipment.'), 'error');
    } finally {
      setLoading(false);
    }
  }

  async function loadMessagesForOffer(offerId: string) {
    if (messages[offerId]) {
      setExpandedOffer(expandedOffer === offerId ? null : offerId);
      return;
    }
    setLoadingMessages(offerId);
    setExpandedOffer(offerId);
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*, sender:profiles!messages_sender_id_fkey(full_name)')
        .eq('offer_id', offerId)
        .order('created_at', { ascending: true });
      if (error) toast(t('shipmentDetail.toast.messagesLoadFailed', 'Failed to load messages.'), 'error');
      setMessages(prev => ({ ...prev, [offerId]: (data as Message[]) || [] }));
    } catch {
      toast(t('shipmentDetail.toast.messagesLoadFailed', 'Failed to load messages.'), 'error');
    } finally {
      setLoadingMessages(null);
    }
  }

  function cancelShipment() {
    confirmDialog({
      title: t('shipmentDetail.dialog.cancelShipment.title'),
      message: t('shipmentDetail.dialog.cancelShipment.message'),
      confirmLabel: t('shipmentDetail.dialog.cancelShipment.confirmLabel'),
      onConfirm: async () => {
        const res = await cancelShipmentAdmin(id, 'Admin cancelled');
        if (!res.success) { toast(t('shipmentDetail.toast.cancelFailed'), 'error'); return; }
        toast(t('shipmentDetail.toast.shipmentCancelled'), 'success');
        await fetchAll();
      }
    });
  }

  function reopenShipment() {
    confirmDialog({
      title: t('shipmentDetail.dialog.reopenShipment.title'),
      message: t('shipmentDetail.dialog.reopenShipment.message'),
      confirmLabel: t('shipmentDetail.dialog.reopenShipment.confirmLabel'),
      onConfirm: async () => {
        const res = await reopenShipmentAdmin(id, 'Admin reopened');
        if (!res.success) { toast(t('shipmentDetail.toast.reopenFailed'), 'error'); return; }
        toast(t('shipmentDetail.toast.shipmentReopened'), 'success');
        await fetchAll();
      }
    });
  }

  if (loading) return <Loading />;
  if (!shipment) {
    return (
      <div className="flex flex-col items-center justify-center py-32 theme-card rounded-[2.5rem] border border-[var(--surface-border)] shadow-xl">
        <div className="h-20 w-20 rounded-2xl theme-bg-secondary flex items-center justify-center mb-6">
          <Package className="h-10 w-10 theme-muted opacity-20" />
        </div>
        <p className="theme-muted font-bold uppercase tracking-widest text-sm mb-6">{t('shipmentDetail.notFound')}</p>
        <button
          onClick={() => router.push('/shipments')}
          className="px-6 py-3 theme-bg-secondary border border-[var(--surface-border)] rounded-xl theme-heading font-black uppercase tracking-widest hover:scale-105 active:scale-95 transition-all shadow-sm"
        >
          <ArrowLeft className="h-4 w-4 inline mr-2" /> {t('shipmentDetail.backToList')}
        </button>
      </div>
    );
  }

  const getCityLabel = (loc?: LocationLite | null) => loc?.city_name_en || loc?.city_name_ar || 'N/A';
  const isCancelled = shipment.status === 'cancelled';
  const isDelivered = shipment.status === 'delivered';
  const isPendingApproval = shipment.status === 'pending_approval';
  const isCompleted = shipment.status === 'completed';
  const acceptedOffer = offers.find((offer) => offer.status === 'accepted' || offer.status === 'completed');
  const shipmentIsAtLeastAccepted = ['accepted', 'picked_up', 'in_transit', 'delivered', 'completed'].includes(shipment.status);
  const shipmentIsInTransit = ['picked_up', 'in_transit', 'delivered', 'completed'].includes(shipment.status);
  const shipmentIsDelivered = ['delivered', 'completed'].includes(shipment.status);

  function offerStatusLabel(offer: OfferRow) {
    if (offer.status === 'rejected' && offer.rejection_reason === 'other_offer_accepted') {
      return t('shipmentDetail.offers.rejectedOtherAccepted', 'Rejected: another offer accepted');
    }
    return t(`offers.status.${offer.status}`, humanize(offer.status));
  }

  function handleApprove() {
    confirmDialog({
      title: t('shipmentDetail.approve.title', 'Approve this shipment?'),
      message: t('shipmentDetail.approve.confirm', 'Approving will publish it for travelers.'),
      confirmLabel: t('shipmentDetail.action.approve', 'Approve'),
      onConfirm: async () => {
        const res = await approveShipment(id);
        if (res.success) {
          toast(t('shipmentDetail.approved', 'Shipment approved'), 'success');
          setShipment((p) => (p ? { ...p, status: 'pending' } : p));
        } else toast(res.error || 'Approve failed', 'error');
      },
    });
  }
  function handleReject() {
    const reason = window.prompt(t('shipmentDetail.reject.reason', 'Reason for rejecting this shipment:'));
    if (!reason) return;
    rejectShipment(id, reason).then(res => {
      if (res.success) {
        toast(t('shipmentDetail.rejected', 'Shipment rejected'), 'success');
        setShipment((p) => (p ? { ...p, status: 'rejected' } : p));
      } else toast(res.error || 'Reject failed', 'error');
    });
  }

  return (
    <div className="max-w-6xl mx-auto space-y-8">
      <button
        onClick={() => router.push('/shipments')}
        className="group flex items-center gap-3 theme-muted hover:theme-heading text-[0.625rem] font-black uppercase tracking-[0.2em] transition-all"
      >
        <div className="h-8 w-8 rounded-full theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center group-hover:-translate-x-1 transition-transform">
          <ArrowLeft className="h-4 w-4" />
        </div>
        {t('shipmentDetail.backToList')}
      </button>

      {/* Shipment Header */}
      <div className="theme-card rounded-[2.5rem] shadow-2xl overflow-hidden border border-[var(--surface-border)] relative">
        <div className="absolute top-0 left-0 w-full h-2 theme-bg-secondary opacity-50"></div>
        <div className="p-10">
          <div className="flex flex-col md:flex-row items-start justify-between gap-8 mb-10">
            <div className="flex items-center gap-6">
              <div className="h-16 w-16 rounded-[1.25rem] theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center theme-heading shadow-inner rotate-3 hover:rotate-0 transition-transform">
                <Package className="h-8 w-8 opacity-80" />
              </div>
              <div>
                <h1 className="text-3xl font-black theme-heading tracking-tight mb-1">{t('shipmentDetail.header.title')} <span className="opacity-50">#{shipment.id.slice(0, 8)}</span></h1>
                <div className="flex items-center gap-2">
                  <Clock className="h-3.5 w-3.5 theme-muted" />
                  <p className="text-[0.625rem] theme-muted font-bold uppercase tracking-widest">{t('shipmentDetail.header.created')} {new Date(shipment.created_at).toLocaleString()}</p>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <div className="scale-110">
                <StatusBadge status={shipment.status} />
              </div>
              {isPendingApproval && (
                <>
                  <button onClick={handleApprove} className="flex items-center gap-2 px-5 py-2.5 bg-green-600 text-white border border-green-700 hover:bg-green-700 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                    <CheckCircle className="h-4 w-4" /> {t('shipmentDetail.action.approve', 'Approve')}
                  </button>
                  <button onClick={handleReject} className="flex items-center gap-2 px-5 py-2.5 bg-red-600 text-white border border-red-700 hover:bg-red-700 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                    <Ban className="h-4 w-4" /> {t('shipmentDetail.action.reject', 'Reject')}
                  </button>
                </>
              )}
              {!isCancelled && !isDelivered && !isCompleted && !isPendingApproval && (
                <button onClick={cancelShipment} className="flex items-center gap-2 px-5 py-2.5 theme-bg-danger-soft theme-danger border border-[var(--red-500)]/10 hover:theme-bg-danger-soft rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                  <Ban className="h-4 w-4" /> {t('shipmentDetail.action.cancel')}
                </button>
              )}
              {isCancelled && (
                <button onClick={reopenShipment} className="flex items-center gap-2 px-5 py-2.5 theme-bg-success-soft theme-success border border-[var(--green-500)]/10 hover:theme-bg-success-soft rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm active:scale-95">
                  <CheckCircle className="h-4 w-4" /> {t('shipmentDetail.header.action.reopen')}
                </button>
              )}
            </div>
          </div>

          {/* Route details */}
          <div className="theme-bg-secondary/50 rounded-3xl p-8 mb-8 border border-[var(--surface-border)] relative group overflow-hidden">
            <div className="absolute top-0 right-0 h-full w-32 bg-gradient-to-l from-[var(--surface-border)] to-transparent opacity-20"></div>
            <div className="flex items-center gap-8 relative z-10">
              <div className="flex-1 text-left">
                <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-[0.2em] mb-2 opacity-50">{t('shipmentDetail.route.pickup')}</p>
                <div className="flex items-center gap-3">
                  <div className="h-3 w-3 rounded-full border-2 border-[var(--surface-border)]"></div>
                  <p className="text-xl font-black theme-heading tracking-tight uppercase">{getCityLabel(shipment.pickup)}</p>
                </div>
                <p className="text-[0.625rem] theme-muted font-bold mt-1 ml-6">{shipment.pickup?.province_name_en}</p>
              </div>
              <div className="flex flex-col items-center gap-2">
                <div className="h-1 w-16 theme-bg-secondary rounded-full shadow-inner opacity-40"></div>
                <ArrowRight className="h-5 w-5 theme-muted group-hover:translate-x-2 transition-transform opacity-50" />
                <div className="h-1 w-16 theme-bg-secondary rounded-full shadow-inner opacity-40"></div>
              </div>
              <div className="flex-1 text-right">
                <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-[0.2em] mb-2 opacity-50">{t('shipmentDetail.route.dropoff')}</p>
                <div className="flex items-center justify-end gap-3">
                  <p className="text-xl font-black theme-heading tracking-tight uppercase">{getCityLabel(shipment.dropoff)}</p>
                  <div className="h-3 w-3 rounded-full theme-bg-secondary border border-[var(--surface-border)] opacity-80"></div>
                </div>
                <p className="text-[0.625rem] theme-muted font-bold mt-1 mr-6">{shipment.dropoff?.province_name_en}</p>
              </div>
            </div>
          </div>

          {/* Shipment details grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <InfoCard icon={<User className="h-3.5 w-3.5" />} label={t('common.client')} value={shipment.sender?.full_name || t('common.unknown')} />
            <InfoCard icon={<Calendar className="h-3.5 w-3.5" />} label={t('trips.addTrip.departureDate')} value={shipment.pickup_date ? new Date(shipment.pickup_date).toLocaleDateString() : t('common.na', 'N/A')} />
            <InfoCard icon={<Weight className="h-3.5 w-3.5" />} label={t('trips.addTrip.maxWeight')} value={`${shipment.weight_kg ?? t('common.na', 'N/A')} KG`} />
            <InfoCard icon={<CreditCard className="h-3.5 w-3.5" />} label={t('trips.addTrip.suggestedPrice')} value={shipment.price ? `${shipment.price}` : t('common.na', 'N/A')} />
          </div>

          {/* Extra details */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
            <InfoCard icon={<Ruler className="h-3.5 w-3.5" />} label={t('shipmentDetail.field.dimensions', 'Dimensions')} value={
              (shipment.length_cm || shipment.width_cm || shipment.height_cm)
                ? `${shipment.length_cm ?? '-'} x ${shipment.width_cm ?? '-'} x ${shipment.height_cm ?? '-'} cm`
                : t('common.na', 'N/A')
            } />
            <InfoCard icon={<Package className="h-3.5 w-3.5" />} label={t('shipmentDetail.field.type', 'Type')} value={shipment.volume_type || t('common.na', 'N/A')} />
            <InfoCard icon={<Shield className="h-3.5 w-3.5" />} label={t('shipmentDetail.field.transportType', 'Transport type')} value={shipment.transport_type || t('common.na', 'N/A')} />
          </div>

          {shipment.description && (
            <div className="mt-8 p-6 theme-bg-secondary/30 border border-[var(--surface-border)] rounded-2xl relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full theme-bg-secondary opacity-50"></div>
              <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-[0.2em] mb-2 opacity-50">{t('shipmentDetail.section.internalDescription')}</p>
              <p className="text-sm theme-heading font-medium leading-relaxed">{shipment.description}</p>
            </div>
          )}

          {shipment.sender?.is_suspended && (
            <div className="mt-6 p-4 theme-bg-danger-soft border border-[var(--red-500)]/10 rounded-2xl flex items-center gap-3 text-xs theme-danger font-black uppercase tracking-widest shadow-sm">
              <AlertTriangle className="h-5 w-5" /> {t('shipmentDetail.warning.suspended')}
            </div>
          )}

          {/* Photos gallery */}
          {shipment.photos && shipment.photos.length > 0 && (
            <div className="mt-8 space-y-4">
              <h3 className="text-[0.625rem] theme-muted font-black uppercase tracking-[0.2em] opacity-60 flex items-center gap-2">
                <ImageIcon className="h-4 w-4" /> {t('shipmentDetail.section.manifestPhotos')}
              </h3>
              <div className="flex gap-4 flex-wrap">
                {shipment.photos.map((url: string, i: number) => (
                  <a key={i} href={url} target="_blank" rel="noopener noreferrer" className="block h-32 w-32 rounded-2xl overflow-hidden border border-[var(--surface-border)] hover:scale-110 hover:shadow-2xl transition-all duration-300 group/photo relative">
                    <Image
                      src={url}
                      alt={`Shipment photo ${i + 1}`}
                      fill
                      unoptimized
                      sizes="128px"
                      className="h-full w-full object-cover"
                    />
                    <div className="absolute inset-0 theme-bg-secondary opacity-0 group-hover/photo:opacity-20 transition-all"></div>
                  </a>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Offers Section */}
      <div className="theme-card rounded-[2.5rem] shadow-2xl overflow-hidden border border-[var(--surface-border)]">
        <div className="px-10 py-8 border-b border-[var(--surface-border)] theme-bg-secondary/30 flex items-center justify-between">
          <h2 className="font-black theme-heading uppercase text-sm tracking-[0.2em] flex items-center gap-3">
            <Package className="h-5 w-5 theme-muted" />
            {t('shipmentDetail.section.offers', 'Offers')} <span className="opacity-50 ml-1">({offers.length})</span>
          </h2>
        </div>

        {offersError ? (
          <div className="p-8">
            <div className="rounded-2xl border border-red-500/20 bg-red-500/10 p-6">
              <p className="text-sm font-bold text-red-700">{offersError}</p>
              <button
                type="button"
                onClick={fetchAll}
                className="mt-4 rounded-xl bg-red-600 px-4 py-2 text-xs font-black uppercase tracking-widest text-white transition hover:bg-red-700"
              >
                {t('common.retry', 'Retry')}
              </button>
            </div>
          </div>
        ) : offers.length === 0 ? (
          <div className="py-24 text-center">
            <div className="h-20 w-20 rounded-full theme-bg-secondary mx-auto mb-6 flex items-center justify-center border border-dashed border-[var(--surface-border)]">
              <Package className="h-10 w-10 theme-muted opacity-20" />
            </div>
            <p className="theme-muted text-[0.625rem] font-black uppercase tracking-[0.2em]">{t('shipmentDetail.empty.noOffers')}</p>
          </div>
        ) : (
          <div className="divide-y divide-[var(--surface-border)]">
            {offers.map(offer => {
              const isExpanded = expandedOffer === offer.id;
              const offerMessages = messages[offer.id] || [];
              const isLoadingMsgs = loadingMessages === offer.id;
              const isAccepted = offer.status === 'accepted' || offer.status === 'completed';
              const driverLabel = offer.driver_profile?.is_driver
                ? t('shipmentDetail.offers.driver', 'Driver')
                : t('shipmentDetail.offers.traveler', 'Traveler');

              return (
                <div key={offer.id} className={isAccepted ? 'bg-blue-500/5' : undefined}>
                  {/* Offer row */}
                  <div className="px-8 py-8 flex items-center justify-between gap-8 group/row">
                    <div className="flex items-center gap-6 min-w-0">
                      <div className="h-12 w-12 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center shadow-inner group-hover/row:scale-110 transition-transform">
                        <Package className="h-6 w-6 theme-muted" />
                      </div>
                      <div>
                        <div className="flex items-center gap-3 mb-2">
                          <span className="font-black theme-heading text-lg tracking-tighter">#{offer.id.slice(0, 8)}</span>
                          <StatusBadge status={offer.status} />
                          {offer.status === 'rejected' && offer.rejection_reason === 'other_offer_accepted' && (
                            <span className="rounded-full border border-amber-500/20 bg-amber-500/10 px-2.5 py-0.5 text-[0.5625rem] font-black uppercase tracking-widest text-amber-700">
                              {t('shipmentDetail.offers.autoRejected', 'Another offer accepted')}
                            </span>
                          )}
                        </div>
                        <div className="flex flex-wrap gap-x-6 gap-y-2 text-[0.625rem] font-bold uppercase tracking-widest theme-muted">
                          <span className="flex items-center gap-2">
                            <User className="h-3 w-3" />
                            {driverLabel}: {offer.driver_profile ? (
                              <Link href={`/users/${offer.driver_profile.id}`} className="theme-heading hover:opacity-70 transition-opacity">
                                {offer.driver_profile.full_name || t('common.unknown')}
                              </Link>
                            ) : t('common.na', 'N/A')}
                          </span>
                          <span className="flex items-center gap-2 border-l border-[var(--surface-border)] pl-6">
                            <span className="theme-heading font-black">{formatMoney(offer.price)}</span>
                          </span>
                          <span className="flex items-center gap-2 border-l border-[var(--surface-border)] pl-6">
                            {offerStatusLabel(offer)}
                          </span>
                          {offer.message && (
                            <span className="flex items-center gap-2 border-l border-[var(--surface-border)] pl-6 italic opacity-60">
                              "{offer.message}"
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 flex-shrink-0">
                      <button
                        onClick={() => loadMessagesForOffer(offer.id)}
                        className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all shadow-sm ${isExpanded
                          ? 'theme-bg-secondary theme-heading shadow-[var(--surface-border)]'
                          : 'theme-bg-secondary theme-muted hover:theme-heading hover:border-[var(--muted)]/50'
                          }`}
                      >
                        <MessageSquare className="h-4 w-4" />
                        {t('shipmentDetail.messages.communications', 'Communications')}
                        {isExpanded ? <ChevronUp className="h-3 w-3" /> : <ChevronDown className="h-3 w-3" />}
                      </button>
                    </div>
                  </div>

                  {isAccepted && (
                    <div className="px-8 pb-8 pt-2">
                      <div className="mb-3 text-[0.625rem] font-black uppercase tracking-[0.2em] theme-muted">
                        {t('shipmentDetail.offers.shipmentProgress', 'Shipment progress')}
                      </div>
                      <div className="flex items-center gap-1.5 overflow-x-auto pb-2 scrollbar-hide">
                        <TimelineStep
                          done={!!acceptedOffer && shipmentIsAtLeastAccepted}
                          label={t('shipmentDetail.timeline.accepted', 'Accepted')}
                          ts={offer.updated_at || offer.created_at}
                        />
                        <TimelineConnector done={shipmentIsInTransit} />
                        <TimelineStep
                          done={shipmentIsInTransit || !!shipment.goods_received_by_driver_at || !!shipment.goods_handed_by_sender_at}
                          label={t('shipmentDetail.timeline.inTransit', 'In transit')}
                          ts={shipment.goods_received_by_driver_at || shipment.goods_handed_by_sender_at}
                        />
                        <TimelineConnector done={shipmentIsDelivered} />
                        <TimelineStep
                          done={shipmentIsDelivered || !!shipment.goods_delivered_by_driver_at}
                          label={t('shipmentDetail.timeline.delivered', 'Delivered')}
                          ts={shipment.goods_delivered_by_driver_at}
                        />
                        <TimelineConnector done={shipment.status === 'completed'} />
                        <TimelineStep
                          done={shipment.status === 'completed' || !!shipment.goods_received_by_client_at}
                          label={t('shipmentDetail.timeline.completed', 'Completed')}
                          ts={shipment.goods_received_by_client_at}
                        />
                      </div>
                    </div>
                  )}

                  {/* Messages */}
                  {isExpanded && (
                    <div className="px-8 pb-10">
                      <div className="theme-bg-secondary/50 rounded-3xl border border-[var(--surface-border)] shadow-inner overflow-hidden">
                        <div className="px-6 py-4 border-b border-[var(--surface-border)] theme-bg-secondary/30 flex items-center justify-between">
                          <p className="text-[0.625rem] font-black theme-muted uppercase tracking-[0.2em]">{t('shipmentDetail.messages.history')}</p>
                          <div className="flex gap-1">
                            <div className="h-1.5 w-1.5 rounded-full theme-bg-secondary animate-pulse"></div>
                            <div className="h-1.5 w-1.5 rounded-full theme-bg-secondary animate-pulse delay-75"></div>
                            <div className="h-1.5 w-1.5 rounded-full theme-bg-secondary animate-pulse delay-150"></div>
                          </div>
                        </div>
                        <div className="p-6 max-h-[400px] overflow-y-auto space-y-6 custom-scrollbar">
                          {isLoadingMsgs ? (
                            <div className="flex flex-col items-center justify-center py-20 gap-4">
                              <div className="h-12 w-12 border-4 border-t-[var(--surface-border)] rounded-full animate-spin" />
                              <p className="text-[0.625rem] theme-muted font-black uppercase tracking-[0.2em] animate-pulse">{t('shipmentDetail.messages.decrypting')}</p>
                            </div>
                          ) : offerMessages.length === 0 ? (
                            <div className="text-center py-20 flex flex-col items-center gap-4 border border-dashed border-[var(--surface-border)] rounded-2xl m-2">
                              <MessageSquare className="h-12 w-12 theme-muted opacity-20" />
                              <p className="theme-muted text-[0.625rem] font-black uppercase tracking-[0.2em]">{t('shipmentDetail.messages.noTraffic')}</p>
                            </div>
                          ) : (
                            offerMessages.map((msg) => (
                              <div key={msg.id} className="flex gap-4 group/msg">
                                <div className="h-10 w-10 rounded-xl theme-bg-secondary border border-[var(--surface-border)] flex items-center justify-center flex-shrink-0 mt-1 shadow-sm group-hover/msg:border-theme-heading transition-colors">
                                  <User className="h-5 w-5 theme-muted group-hover/msg:theme-heading transition-colors" />
                                </div>
                                <div className="min-w-0 flex-1">
                                  <div className="flex items-center justify-between mb-2">
                                    <div className="flex items-center gap-3">
                                      <span className="text-xs font-black theme-heading uppercase tracking-tight tracking-wider">
                                        {msg.sender?.full_name || t('shipmentDetail.messages.systemActor')}
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
    </div>
  );
}
