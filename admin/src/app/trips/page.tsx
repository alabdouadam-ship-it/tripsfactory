'use client';

import { useEffect, useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/lib/toast';
import { Trip, Profile } from '@/lib/types';
import { Route, Calendar, Trash2, ArrowRight, Download, Search, User, Weight, Eye, Ban, ChevronLeft, ChevronRight, Plus, X, Repeat, ChevronDown } from 'lucide-react';
import { exportToCSV, getCityLabel } from '@/lib/utils';
import { StatusBadge } from '@/components/StatusBadge';
import { logAdminAction } from '@/lib/audit';
import Loading from '@/app/loading';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useT, useI18n } from '@/lib/i18n';
import { isHomeCountryLocation, homeCountryName } from '@/lib/geographyConfig';
import { cancelTripAdmin } from '@/app/actions/trip-actions';

const PAGE_SIZE = 24;
const QUERY_TIMEOUT_MS = 15000;

type LocationRow = {
    id: string;
    country_code?: string | null;
    country_name_ar: string | null;
    country_name_en: string | null;
    province_name_ar: string | null;
    province_name_en: string | null;
    city_name_ar: string | null;
    city_name_en: string | null;
    town_name_ar: string | null;
    town_name_en: string | null;
};

type RouteScope = 'internal' | 'external' | 'invalid' | 'unknown';

function locationLabel(loc: LocationRow, useEn = true): string {
    const country = useEn ? (loc.country_name_en || loc.country_name_ar) : (loc.country_name_ar || loc.country_name_en);
    const city = useEn ? (loc.city_name_en || loc.city_name_ar) : (loc.city_name_ar || loc.city_name_en);
    const town = useEn ? (loc.town_name_en || loc.town_name_ar) : (loc.town_name_ar || loc.town_name_en);
    const province = useEn ? (loc.province_name_en || loc.province_name_ar) : (loc.province_name_ar || loc.province_name_en);
    const parts = [city, town].filter(Boolean);
    return `${country || ''} - ${parts.join(', ')} (${province || ''})`;
}

function filterLocationsBySearch(locations: LocationRow[], search: string, useEn: boolean): LocationRow[] {
    if (!search.trim()) return locations;
    const q = search.trim().toLowerCase();
    return locations.filter(loc => {
        const label = locationLabel(loc, useEn).toLowerCase();
        return label.includes(q);
    });
}

function getRouteScope(origin?: Partial<LocationRow> | null, dest?: Partial<LocationRow> | null): RouteScope {
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

function applyTripClassificationFilter(query: any, classificationFilter: string) {
    if (classificationFilter === 'fully_completed_clean') {
        return query.eq('status', 'completed').is('cancellation_reason', null);
    }
    if (classificationFilter === 'completed_with_problems') {
        return query.eq('status', 'completed').not('cancellation_reason', 'is', null);
    }
    if (classificationFilter === 'cancelled_trips') {
        return query.eq('status', 'cancelled');
    }
    if (classificationFilter === 'in_flight') {
        return query.in('status', ['booked', 'in_transit']);
    }
    if (classificationFilter === 'open_listings') {
        return query.in('status', ['available', 'full']);
    }
    if (classificationFilter === 'delayed') {
        return query
            .lt('departure_time', new Date().toISOString())
            .in('status', ['available', 'booked', 'in_transit', 'full', 'pending_confirmation', 'in_communication']);
    }
    if (classificationFilter === 'pending_approval') {
        return query.eq('status', 'pending_approval');
    }
    return query;
}

export default function TripsPage() {
    const router = useRouter();
    const { toast, confirm: confirmDialog } = useToast();
    const t = useT();
    const { language } = useI18n();
    const [trips, setTrips] = useState<Trip[]>([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [classificationFilter, setClassificationFilter] = useState<string>('all');
    const [page, setPage] = useState(0);
    const [totalCount, setTotalCount] = useState(0);
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');

    // Add trip modal
    const [showAddTripModal, setShowAddTripModal] = useState(false);
    const [addTripTravelerSearch, setAddTripTravelerSearch] = useState('');
    const [addTripTravelerResults, setAddTripTravelerResults] = useState<Profile[]>([]);
    const [selectedTraveler, setSelectedTraveler] = useState<Profile | null>(null);
    const [locations, setLocations] = useState<LocationRow[]>([]);
    const [originLocationId, setOriginLocationId] = useState('');
    const [destLocationId, setDestLocationId] = useState('');
    const [departureDate, setDepartureDate] = useState('');
    const [departureTime, setDepartureTime] = useState('12:00');
    const [maxWeight, setMaxWeight] = useState('');
    const [suggestedFlatPrice, setSuggestedFlatPrice] = useState('');
    const [notes, setNotes] = useState('');
    const [repeatDates, setRepeatDates] = useState<string[]>([]);
    const [addTripRepeatDate, setAddTripRepeatDate] = useState('');
    const [addTripSaving, setAddTripSaving] = useState(false);
    const [travelerDropdownOpen, setTravelerDropdownOpen] = useState(false);
    const [originLocationSearch, setOriginLocationSearch] = useState('');
    const [destLocationSearch, setDestLocationSearch] = useState('');
    const [originLocOpen, setOriginLocOpen] = useState(false);
    const [destLocOpen, setDestLocOpen] = useState(false);

    useEffect(() => {
        setPage(0);
    }, [statusFilter, classificationFilter, dateFrom, dateTo]);

    useEffect(() => {
        fetchTrips();
    }, [page, statusFilter, classificationFilter, dateFrom, dateTo]);

    function withTimeout<T>(promise: PromiseLike<T>, timeoutMs = QUERY_TIMEOUT_MS): Promise<T> {
        return new Promise<T>((resolve, reject) => {
            const timer = window.setTimeout(() => reject(new Error('Query timeout exceeded')), timeoutMs);
            Promise.resolve(promise)
                .then((value) => resolve(value))
                .catch((error) => reject(error))
                .finally(() => window.clearTimeout(timer));
        });
    }

    async function fetchLocationsForAddTrip() {
        const { data, error } = await supabase.from('locations').select('*').eq('is_active', true).order('country_name_en').order('province_name_en').order('city_name_en');
        if (error) {
            toast(t('trips.addTrip.locationsLoadFailed', 'Failed to load locations.'), 'error');
            setLocations([]);
            return;
        }
        setLocations((data as LocationRow[]) || []);
    }

    const searchTravelersForAddTrip = useCallback(async (q: string) => {
        setAddTripTravelerSearch(q);
        if (q.trim().length < 2) { setAddTripTravelerResults([]); return; }
        const term = q.trim().replace(/%/g, '\\%').replace(/_/g, '\\_');
        const { data } = await supabase
            .from('profiles')
            .select('id, full_name, phone_number, traveler_status, traveler_type, is_driver, is_suspended, is_blocked')
            .eq('traveler_status', 'approved')
            .or(`full_name.ilike.%${term}%,phone_number.ilike.%${term}%`)
            .limit(20);
        setAddTripTravelerResults(((data as Profile[]) || []).filter((profile) => !profile.is_suspended && !profile.is_blocked));
    }, []);

    function openAddTripModal() {
        setShowAddTripModal(true);
        setSelectedTraveler(null);
        setAddTripTravelerSearch('');
        setAddTripTravelerResults([]);
        setOriginLocationId('');
        setDestLocationId('');
        setDepartureDate('');
        setDepartureTime('12:00');
        setMaxWeight('');
        setSuggestedFlatPrice('');
        setNotes('');
        setRepeatDates([]);
        setAddTripRepeatDate('');
        setOriginLocationSearch('');
        setDestLocationSearch('');
        setOriginLocOpen(false);
        setDestLocOpen(false);
        fetchLocationsForAddTrip();
    }

    async function saveAddTrip() {
        if (!selectedTraveler) {
            toast(t('trips.addTrip.selectTravelerFirst'), 'error');
            return;
        }
        if (!originLocationId || !destLocationId) {
            toast(t('trips.addTrip.selectOriginDest'), 'error');
            return;
        }
        if (!departureDate) {
            toast(t('trips.addTrip.selectDate'), 'error');
            return;
        }
        const originLoc = locations.find((loc) => loc.id === originLocationId);
        const destLoc = locations.find((loc) => loc.id === destLocationId);
        const detectedScope = getRouteScope(originLoc, destLoc);
        if (detectedScope === 'unknown') {
            toast(t('trips.addTrip.selectOriginDest'), 'error');
            return;
        }
        if (detectedScope === 'invalid') {
            toast(t('trips.addTrip.invalidRoute', `Trip must start or end in ${homeCountryName('en')}.`), 'error');
            return;
        }
        setAddTripSaving(true);
        try {
            const [hours, mins] = departureTime.split(':').map(Number);
            const mainDeparture = new Date(departureDate);
            mainDeparture.setHours(hours, mins || 0, 0, 0);
            const createdTripIds: string[] = [];


            const createOneTrip = async (departureTime: Date) => {
                const { data: tripRow, error: tripErr } = await supabase
                    .from('trips')
                    .insert({
                        traveler_id: selectedTraveler.id,
                        origin_location_id: originLocationId,
                        dest_location_id: destLocationId,
                        departure_time: departureTime.toISOString(),
                        max_weight_kg: maxWeight ? parseFloat(maxWeight) : null,
                        suggested_flat_price: suggestedFlatPrice ? parseFloat(suggestedFlatPrice) : null,
                        notes: notes || null,
                        trip_type: 'scheduled',
                        status: 'available',
                    })
                    .select('id')
                    .single();
                if (tripErr) throw tripErr;
                const tripId = tripRow.id;
                createdTripIds.push(tripId);
                return tripId;
            };

            await createOneTrip(mainDeparture);

            for (const dateStr of repeatDates) {
                const [y, m, d] = dateStr.split('-').map(Number);
                const repDeparture = new Date(y, m - 1, d, hours, mins || 0, 0, 0);
                await createOneTrip(repDeparture);
            }

            await logAdminAction('admin_add_trip', 'trip', createdTripIds[0] || null, {
                originLocationId,
                destLocationId,
                repeatCount: repeatDates.length,
                createdTripIds,
                travelerId: selectedTraveler.id,
                detectedScope,
            });
            toast(t('trips.addTrip.toastSuccess'), 'success');
            setShowAddTripModal(false);
            fetchTrips();
        } catch (e) {
            console.error(e);
            toast(t('trips.addTrip.toastFailed'), 'error');
        } finally {
            setAddTripSaving(false);
        }
    }

    async function fetchTrips() {
        setLoading(true);
        try {
            let query: any = supabase
                .from('trips')
                .select(`
                    *,
                    profile:profiles!traveler_id(id, full_name, avatar_url, traveler_status, traveler_type, is_driver),
                    origin:locations!origin_location_id(country_code, country_name_ar, country_name_en, city_name_ar, city_name_en),
                    dest:locations!dest_location_id(country_code, country_name_ar, country_name_en, city_name_ar, city_name_en)
                `, { count: 'exact' });

            if (statusFilter !== 'all') query = query.eq('status', statusFilter);
            query = applyTripClassificationFilter(query, classificationFilter);
            if (dateFrom) query = query.gte('departure_time', `${dateFrom}T00:00:00.000Z`);
            if (dateTo) query = query.lte('departure_time', `${dateTo}T23:59:59.999Z`);

            const from = page * PAGE_SIZE;
            const to = from + PAGE_SIZE - 1;

            const result: any = await withTimeout(
                query
                    .order('created_at', { ascending: false })
                    .range(from, to)
            );
            const { data, count, error } = result;

            if (error) throw error;

            setTrips((data as any[]) || []);
            setTotalCount(count || 0);

        } catch (error) {
            console.error('Error fetching trips:', error);
            setTrips([]);
            setTotalCount(0);
            toast(t('trips.toast.loadFailed'), 'error');
        } finally {
            setLoading(false);
        }
    }

    function cancelTrip(tripId: string) {
        confirmDialog({
            title: t('trips.dialog.cancelTrip.title'),
            message: t('trips.dialog.cancelTrip.message'),
            confirmLabel: t('trips.dialog.cancelTrip.confirmLabel'),
            onConfirm: async () => {
                const { data: activeBookings, error: bookingsLoadError } = await supabase
                    .from('bookings')
                    .select('id')
                    .eq('trip_id', tripId)
                    .not('status', 'in', '(cancelled,completed,rejected)');

                if (bookingsLoadError) {
                    toast(t('trips.toast.bookingGuardFailed', 'Could not verify related bookings.'), 'error');
                    return;
                }

                const res = await cancelTripAdmin(tripId, 'Admin cancelled from trips list');
                if (!res.success) {
                    toast(t('trips.toast.cancelFailed'), 'error');
                    return;
                }

                const activeBookingIds = ((activeBookings as Array<{ id: string }>) || []).map((booking) => booking.id);
                if (activeBookingIds.length > 0) {
                    const { error: bookingsError } = await supabase
                        .from('bookings')
                        .update({ status: 'cancelled' })
                        .in('id', activeBookingIds);
                    if (bookingsError) {
                        toast(t('trips.toast.relatedBookingsCancelFailed', 'Trip cancelled, but related bookings were not fully cancelled.'), 'error');
                        fetchTrips();
                        return;
                    }
                }

                setTrips(trips.map(t => t.id === tripId ? { ...t, status: 'cancelled' } : t));
                toast(t('trips.toast.tripCancelled'), 'success');
            },
        });
    }

    function deleteTrip(id: string) {
        confirmDialog({
            title: t('trips.dialog.deleteTrip.title'),
            message: t('trips.dialog.deleteTrip.message'),
            confirmLabel: t('trips.dialog.deleteTrip.confirmLabel'),
            onConfirm: async () => {
                // Check active bookings
                const { count, error: guardError } = await supabase
                    .from('bookings')
                    .select('*', { count: 'exact', head: true })
                    .eq('trip_id', id)
                    .not('status', 'in', '(cancelled,rejected,completed)');

                if (guardError) {
                    toast(t('trips.toast.bookingGuardFailed', 'Could not verify related bookings.'), 'error');
                    return;
                }

                if (count && count > 0) {
                    toast(t('trips.toast.cannotDeleteBookings').replace('{count}', String(count)), 'error');
                    return;
                }

                const { error } = await supabase.from('trips').delete().eq('id', id);
                if (error) {
                    toast(t('trips.toast.deleteFailed'), 'error');
                    console.error(error);
                } else {
                    setTrips(trips.filter(t => t.id !== id));
                    await logAdminAction('delete_trip', 'trip', id);
                    toast(t('trips.toast.tripDeleted'), 'success');
                }
            },
        });
    }



    // Export function needs to fetch all matching current filters
    async function handleExport() {
        toast(t('trips.toast.exporting'), 'success');
        let query = supabase
            .from('trips')
            .select(`
                *,
                profile:profiles!traveler_id(id, full_name, avatar_url, traveler_status, traveler_type, is_driver),
                origin:locations!origin_location_id(country_code, country_name_ar, country_name_en, city_name_ar, city_name_en),
                dest:locations!dest_location_id(country_code, country_name_ar, country_name_en, city_name_ar, city_name_en)
            `);

        if (statusFilter !== 'all') query = query.eq('status', statusFilter);
        query = applyTripClassificationFilter(query, classificationFilter);
        if (dateFrom) query = query.gte('departure_time', `${dateFrom}T00:00:00.000Z`);
        if (dateTo) query = query.lte('departure_time', `${dateTo}T23:59:59.999Z`);

        const { data, error } = await query.order('created_at', { ascending: false });
        if (error) {
            toast(error.message || t('trips.toast.exportFailed', 'Export failed'), 'error');
            return;
        }
        if (data) {
            exportToCSV(data, 'trips_export', (msg) => toast(msg, 'error'));
        }
    }

    const totalPages = Math.ceil(totalCount / PAGE_SIZE);

    if (loading) return <Loading />;

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold theme-heading">
                    {t('trips.title', 'Trips & Routes')}
                </h1>
                <div className="flex items-center gap-2">
                    <button
                        onClick={openAddTripModal}
                        className="flex items-center gap-2 bg-orange-600 text-white px-4 py-2 rounded-lg hover:bg-orange-700 transition"
                    >
                        <Plus className="h-4 w-4" /> {t('trips.addTrip.title')}
                    </button>
                    <button
                        onClick={handleExport}
                        className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition"
                    >
                        <Download className="h-4 w-4" /> {t('trips.export', 'Export')}
                    </button>
                    <div className="theme-bg-secondary px-4 py-2 rounded-lg border border-[var(--surface-border)] font-medium theme-heading">
                        {t('common.total', 'Total')}: {totalCount}
                    </div>
                </div>
            </div>

            {/* Filters */}
            <div className="form-on-light flex flex-col gap-4 md:flex-row md:items-center theme-bg-secondary p-4 rounded-xl shadow-sm border border-[var(--surface-border)]">
                <div className="flex flex-wrap items-center gap-2">
                    <span className="text-xs font-bold theme-muted uppercase">
                        {t('trips.departureDateRange', 'Departure date')}
                    </span>
                    <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-orange-500 focus:outline-none transition" />
                    <span className="theme-muted opacity-40">-</span>
                    <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-orange-500 focus:outline-none transition" />
                </div>
                <div className="flex gap-2 flex-wrap">
                    {['all', 'pending_approval', 'available', 'in_communication', 'pending_confirmation', 'booked', 'in_transit', 'full', 'completed', 'cancelled'].map((status) => (
                        <button
                            key={status}
                            onClick={() => {
                                setStatusFilter(status);
                                if (status !== 'all' && classificationFilter !== 'all') setClassificationFilter('all');
                            }}
                            className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition-all ${statusFilter === status
                                ? 'bg-orange-600 text-white shadow-sm'
                                : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'
                                }`}
                        >
                            {t(`trips.status.${status}`, status)}
                        </button>
                    ))}
                </div>
                <div className="flex flex-wrap items-center gap-2 md:ml-auto">
                    <span className="text-xs font-bold theme-muted uppercase">{t('trips.classification', 'Classification')}</span>
                    <select
                        value={classificationFilter}
                        onChange={e => {
                            const next = e.target.value;
                            setClassificationFilter(next);
                            if (next !== 'all' && statusFilter !== 'all') setStatusFilter('all');
                        }}
                        className="rounded-lg border border-[var(--surface-border)] theme-bg-secondary px-3 py-2 text-sm theme-heading focus:border-orange-500 focus:outline-none transition"
                    >
                        <option value="all">{t('trips.classification.all', 'All')}</option>
                        <option value="open_listings">{t('trips.classification.open_listings', 'Open listings')}</option>
                        <option value="in_flight">{t('trips.classification.in_flight', 'In-flight')}</option>
                        <option value="fully_completed_clean">{t('trips.classification.clean', 'Completed (clean)')}</option>
                        <option value="completed_with_problems">{t('trips.classification.problems', 'Completed (with problems)')}</option>
                        <option value="cancelled_trips">{t('trips.classification.cancelled', 'Cancelled trips')}</option>
                        <option value="delayed">{t('trips.classification.delayed', 'Delayed')}</option>
                        <option value="pending_approval">{t('trips.classification.pending_approval', 'Pending approval')}</option>
                    </select>
                </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
                {trips.map((trip) => {
                    const routeScope = getRouteScope(trip.origin as any, trip.dest as any);
                    const isDriver = !!trip.profile?.is_driver;
                    const maxWeight = Number(trip.max_weight_kg);
                    const currentLoad = Number(trip.current_load_kg ?? 0);
                    const capacityLabel = Number.isFinite(maxWeight) && maxWeight > 0
                        ? `${currentLoad || 0} / ${maxWeight} KG`
                        : t('common.na', 'N/A');
                    const priceLabel = trip.suggested_price_per_kg != null
                        ? `${trip.suggested_price_per_kg} /KG`
                        : trip.suggested_flat_price != null
                            ? `${trip.suggested_flat_price}`
                            : t('common.na', 'N/A');

                    return (
                    <div key={trip.id} className="bg-[var(--surface)] rounded-xl border border-[var(--surface-border)] shadow-sm overflow-hidden hover:shadow-lg transition-all flex flex-col group">
                        <div className="p-6 flex-1">
                            <div className="flex justify-between items-start mb-6 gap-4">
                                <div className="flex items-center gap-3 min-w-0">
                                    <div className="h-10 w-10 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-600 group-hover:bg-orange-500/20 transition-colors flex-shrink-0">
                                        <Route className="h-5 w-5" />
                                    </div>
                                    <div className="min-w-0">
                                        {trip.profile?.id ? (
                                            <Link href={`/users/${trip.profile.id}`} className="block truncate text-sm font-bold theme-heading leading-tight hover:text-blue-600 hover:underline">
                                                {trip.profile?.full_name || t('trips.unknownTraveler', 'Unknown traveler')}
                                            </Link>
                                        ) : (
                                            <h3 className="truncate text-sm font-bold theme-heading leading-tight">{trip.profile?.full_name || t('trips.unknownTraveler', 'Unknown traveler')}</h3>
                                        )}
                                        <span className={`mt-1 inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-[0.5625rem] font-black uppercase tracking-widest ${travelerRoleClass(isDriver)}`}>
                                            <User className="h-3 w-3" />
                                            {isDriver ? t('trips.role.driver', 'Driver') : t('trips.role.simpleTraveler', 'Simple traveler')}
                                        </span>
                                    </div>
                                </div>
                                <div className="flex flex-col items-end gap-2">
                                    <StatusBadge status={trip.status} />
                                    <span className={`inline-flex rounded-full border px-2 py-0.5 text-[0.5625rem] font-black uppercase tracking-widest ${scopeBadgeClass(routeScope)}`}>
                                        {t(`trips.scope.${routeScope}`, routeScope)}
                                    </span>
                                </div>
                            </div>

                            <div className="flex items-center gap-2 mb-8 theme-bg-secondary p-3 rounded-lg border border-[var(--surface-border)]">
                                <div className="flex-1 text-center min-w-0">
                                    <p className="text-[0.625rem] theme-muted uppercase font-bold tracking-wider opacity-60">{t('common.from', 'From')}</p>
                                    <p className="font-bold theme-heading truncate">{getCityLabel(trip.origin)}</p>
                                </div>
                                <ArrowRight className="h-4 w-4 text-orange-400 flex-shrink-0" />
                                <div className="flex-1 text-center min-w-0">
                                    <p className="text-[0.625rem] theme-muted uppercase font-bold tracking-wider opacity-60">{t('common.to', 'To')}</p>
                                    <p className="font-bold theme-heading truncate">{getCityLabel(trip.dest)}</p>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div className="bg-orange-500/5 p-3 rounded-lg border border-orange-500/10">
                                    <p className="text-[0.625rem] text-orange-600 uppercase font-bold mb-1 flex items-center gap-1">
                                        <Weight className="h-3 w-3" /> {t('trips.capacity', 'Capacity')}
                                    </p>
                                    <p className="text-lg font-black theme-heading">{capacityLabel}</p>
                                </div>
                                <div className="bg-orange-500/5 p-3 rounded-lg border border-orange-500/10">
                                    <p className="text-[0.625rem] text-orange-600 uppercase font-bold mb-1 flex items-center gap-1">
                                        {t('trips.price', 'Price')}
                                    </p>
                                    <p className="text-lg font-black theme-heading">{priceLabel}</p>
                                </div>
                            </div>
                        </div>

                        <div className="theme-bg-secondary px-6 py-3 flex justify-between items-center border-t border-[var(--surface-border)]">
                            <div className="flex items-center gap-1.5 text-[0.625rem] theme-muted font-bold uppercase">
                                <Calendar className="h-3.5 w-3.5" />
                                {trip.departure_time ? new Date(trip.departure_time).toLocaleDateString() : t('common.na', 'N/A')}
                            </div>
                            <div className="flex items-center gap-1">
                                <button
                                    onClick={() => router.push(`/trips/${trip.id}`)}
                                    className="theme-muted hover:text-blue-500 p-1.5 hover:bg-blue-500/10 rounded-lg transition-all"
                                    title={t('common.viewDetails')}
                                >
                                    <Eye className="h-4 w-4" />
                                </button>
                                {!['cancelled', 'completed'].includes(trip.status) && (
                                    <button
                                        onClick={() => cancelTrip(trip.id)}
                                        className="theme-muted hover:text-orange-500 p-1.5 hover:bg-orange-500/10 rounded-lg transition-all"
                                        title={t('trips.dialog.cancelTrip.title')}
                                    >
                                        <Ban className="h-4 w-4" />
                                    </button>
                                )}
                                <button
                                    onClick={() => deleteTrip(trip.id)}
                                    className="theme-muted hover:text-red-500 p-1.5 hover:bg-red-500/10 rounded-lg transition-all"
                                    title={t('trips.dialog.deleteTrip.title')}
                                >
                                    <Trash2 className="h-4 w-4" />
                                </button>
                            </div>
                        </div>
                    </div>
                    );
                })}
            </div>

            {trips.length === 0 && !loading && (
                <div className="text-center py-20 bg-[var(--surface)] rounded-xl border border-[var(--surface-border)]">
                    <p className="theme-muted font-medium">
                        {t('trips.empty', 'No trips match your search.')}
                    </p>
                </div>
            )}

            {/* Pagination Controls */}
            {totalPages > 1 && (
                <div className="flex items-center justify-center gap-4 py-4">
                    <button onClick={() => setPage(Math.max(0, page - 1))} disabled={page === 0} className="flex items-center gap-1 px-4 py-2 rounded-lg border border-[var(--surface-border)] text-sm font-bold theme-muted hover:theme-heading hover:theme-bg-secondary disabled:opacity-30 disabled:cursor-not-allowed transition-all">
                        <ChevronLeft className="h-4 w-4" /> {t('common.previous', 'Previous')}
                    </button>
                    <div className="flex items-center gap-1">
                        <span className="text-sm font-bold theme-muted">
                            {t(
                                'common.pageOf',
                                `Page ${page + 1} of {total}`,
                            ).replace('{current}', String(page + 1)).replace('{total}', String(totalPages))}
                        </span>
                    </div>
                    <button onClick={() => setPage(Math.min(totalPages - 1, page + 1))} disabled={page === totalPages - 1} className="flex items-center gap-1 px-4 py-2 rounded-lg border border-[var(--surface-border)] text-sm font-bold theme-muted hover:theme-heading hover:theme-bg-secondary disabled:opacity-30 disabled:cursor-not-allowed transition-all">
                        {t('common.next', 'Next')} <ChevronRight className="h-4 w-4" />
                    </button>
                </div>
            )}

            {/* Add Trip Modal */}
            {showAddTripModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" onClick={() => !addTripSaving && setShowAddTripModal(false)}>
                    <div className="form-on-light bg-[var(--surface)] rounded-2xl shadow-2xl border border-[var(--surface-border)] max-w-2xl w-full max-h-[90vh] overflow-hidden flex flex-col" onClick={e => e.stopPropagation()}>
                        <div className="p-8 border-b border-[var(--surface-border)] theme-bg-secondary">
                            <h2 className="text-2xl font-black theme-heading">{t('trips.addTrip.title')}</h2>
                            <p className="theme-muted text-sm mt-1 opacity-80">{t('trips.addTrip.subtitle')}</p>
                        </div>
                        <div className="p-8 overflow-y-auto flex-1 space-y-6">
                            {/* Traveler - searchable dropdown */}
                            <div className="relative">
                                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.traveler')}</label>
                                <div
                                    className="flex items-center rounded-xl border border-[var(--surface-border)] theme-bg-secondary focus-within:ring-2 focus-within:ring-orange-500/20 focus-within:border-orange-500 transition-all shadow-sm"
                                    onBlur={() => setTimeout(() => setTravelerDropdownOpen(false), 150)}
                                >
                                    <input
                                        type="text"
                                        placeholder={selectedTraveler ? '' : t('trips.addTrip.travelerPlaceholder')}
                                        className="flex-1 min-w-0 rounded-l-xl pl-4 py-3 pr-2 text-sm border-0 focus:ring-0 focus:outline-none bg-transparent theme-heading"
                                        value={selectedTraveler ? (selectedTraveler.full_name || selectedTraveler.phone_number || selectedTraveler.id) : addTripTravelerSearch}
                                        onChange={e => { setAddTripTravelerSearch(e.target.value); if (!e.target.value) setSelectedTraveler(null); searchTravelersForAddTrip(e.target.value); setTravelerDropdownOpen(true); }}
                                        onFocus={() => { setTravelerDropdownOpen(true); if (addTripTravelerSearch.length >= 2) searchTravelersForAddTrip(addTripTravelerSearch); }}
                                        readOnly={!!selectedTraveler}
                                    />
                                    {selectedTraveler ? (
                                        <button type="button" onClick={() => { setSelectedTraveler(null); setAddTripTravelerSearch(''); }} className="p-2 theme-muted hover:text-red-500 transition rounded-r-xl" aria-label={t('common.clear', 'Clear')}>
                                            <X className="h-5 w-5" />
                                        </button>
                                    ) : (
                                        <button type="button" onClick={() => { setTravelerDropdownOpen(!travelerDropdownOpen); if (!travelerDropdownOpen && addTripTravelerSearch.length >= 2) searchTravelersForAddTrip(addTripTravelerSearch); }} className="p-2 theme-muted hover:theme-heading transition rounded-r-xl" aria-label={t('common.openList', 'Open list')}>
                                            <ChevronDown className="h-5 w-5" />
                                        </button>
                                    )}
                                </div>
                                {travelerDropdownOpen && (addTripTravelerSearch.length >= 2 || addTripTravelerResults.length > 0) && (
                                    <ul className="absolute z-10 mt-2 w-full border border-[var(--surface-border)] rounded-xl theme-bg-secondary shadow-2xl divide-y divide-[var(--surface-border)] max-h-48 overflow-y-auto">
                                        {(() => {
                                            const q = addTripTravelerSearch.trim().toLowerCase();
                                            const filtered = q ? addTripTravelerResults.filter(u => {
                                                const name = (u.full_name || '').toLowerCase();
                                                const phone = (u.phone_number || '').toLowerCase();
                                                const id = (u.id || '').toLowerCase();
                                                return name.includes(q) || phone.includes(q) || id.includes(q);
                                            }) : addTripTravelerResults;
                                            if (filtered.length === 0) return <li className="px-4 py-4 text-sm theme-muted">{t('trips.addTrip.noTravelersFound')}</li>;
                                            return filtered.map(u => (
                                                <li
                                                    key={u.id}
                                                    className="px-4 py-3 hover:bg-orange-500/10 cursor-pointer flex items-center justify-between theme-heading transition-colors"
                                                    onMouseDown={e => { e.preventDefault(); setSelectedTraveler(u); setAddTripTravelerSearch(u.full_name || u.phone_number || ''); setTravelerDropdownOpen(false); }}
                                                >
                                                    <span className="font-bold">{u.full_name || u.phone_number || '—'}</span>
                                                    <span className={`rounded-full border px-2 py-0.5 text-[0.625rem] font-black uppercase tracking-widest ${travelerRoleClass(!!u.is_driver)}`}>{u.is_driver ? t('trips.role.driver', 'Driver') : t('trips.role.simpleTraveler', 'Simple traveler')}</span>
                                                </li>
                                            ));
                                        })()}
                                    </ul>
                                )}
                            </div>

                            {/* Origin - searchable dropdown with country */}
                            <div className="relative">
                                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.origin')}</label>
                                <div className="flex items-center rounded-xl border border-[var(--surface-border)] theme-bg-secondary focus-within:ring-2 focus-within:ring-orange-500/20 focus-within:border-orange-500 transition-all shadow-sm">
                                    <input
                                        type="text"
                                        placeholder={t('trips.addTrip.searchLocation')}
                                        className="flex-1 min-w-0 rounded-l-xl pl-4 py-3 pr-2 text-sm border-0 focus:ring-0 focus:outline-none bg-transparent theme-heading"
                                        value={originLocationId ? (() => { const loc = locations.find(l => l.id === originLocationId); return loc ? locationLabel(loc, language === 'en') : ''; })() : originLocationSearch}
                                        onChange={e => { setOriginLocationSearch(e.target.value); if (!e.target.value) setOriginLocationId(''); setOriginLocOpen(true); }}
                                        onFocus={() => setOriginLocOpen(true)}
                                        onBlur={() => setTimeout(() => setOriginLocOpen(false), 180)}
                                    />
                                    {originLocationId ? (
                                        <button type="button" onClick={() => { setOriginLocationId(''); setOriginLocationSearch(''); }} className="p-2 theme-muted hover:text-red-500 transition rounded-r-xl"><X className="h-5 w-5" /></button>
                                    ) : (
                                        <span className="p-2 theme-muted rounded-r-xl"><ChevronDown className="h-5 w-5" /></span>
                                    )}
                                </div>
                                {originLocOpen && (
                                    <ul className="absolute z-10 mt-2 w-full border border-[var(--surface-border)] rounded-xl theme-bg-secondary shadow-2xl divide-y divide-[var(--surface-border)] max-h-48 overflow-y-auto">
                                        {filterLocationsBySearch(locations, originLocationSearch, language === 'en').slice(0, 100).map(loc => (
                                            <li key={loc.id} className="px-4 py-3 hover:bg-orange-500/10 cursor-pointer text-sm theme-heading transition-colors" onMouseDown={e => { e.preventDefault(); setOriginLocationId(loc.id); setOriginLocationSearch(''); setOriginLocOpen(false); }}>
                                                {locationLabel(loc, language === 'en')}
                                            </li>
                                        ))}
                                        {filterLocationsBySearch(locations, originLocationSearch, language === 'en').length === 0 && (
                                            <li className="px-4 py-4 text-sm theme-muted">{t('trips.addTrip.noLocationFound')}</li>
                                        )}
                                    </ul>
                                )}
                            </div>

                            {/* Destination - searchable dropdown with country */}
                            <div className="relative">
                                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.dest')}</label>
                                <div className="flex items-center rounded-xl border border-[var(--surface-border)] theme-bg-secondary focus-within:ring-2 focus-within:ring-orange-500/20 focus-within:border-orange-500 transition-all shadow-sm">
                                    <input
                                        type="text"
                                        placeholder={t('trips.addTrip.searchLocation')}
                                        className="flex-1 min-w-0 rounded-l-xl pl-4 py-3 pr-2 text-sm border-0 focus:ring-0 focus:outline-none bg-transparent theme-heading"
                                        value={destLocationId ? (() => { const loc = locations.find(l => l.id === destLocationId); return loc ? locationLabel(loc, language === 'en') : ''; })() : destLocationSearch}
                                        onChange={e => { setDestLocationSearch(e.target.value); if (!e.target.value) setDestLocationId(''); setDestLocOpen(true); }}
                                        onFocus={() => setDestLocOpen(true)}
                                        onBlur={() => setTimeout(() => setDestLocOpen(false), 180)}
                                    />
                                    {destLocationId ? (
                                        <button type="button" onClick={() => { setDestLocationId(''); setDestLocationSearch(''); }} className="p-2 theme-muted hover:text-red-500 transition rounded-r-xl"><X className="h-5 w-5" /></button>
                                    ) : (
                                        <span className="p-2 theme-muted rounded-r-xl"><ChevronDown className="h-5 w-5" /></span>
                                    )}
                                </div>
                                {destLocOpen && (
                                    <ul className="absolute z-10 mt-2 w-full border border-[var(--surface-border)] rounded-xl theme-bg-secondary shadow-2xl divide-y divide-[var(--surface-border)] max-h-48 overflow-y-auto">
                                        {filterLocationsBySearch(locations, destLocationSearch, language === 'en').slice(0, 100).map(loc => (
                                            <li key={loc.id} className="px-4 py-3 hover:bg-orange-500/10 cursor-pointer text-sm theme-heading transition-colors" onMouseDown={e => { e.preventDefault(); setDestLocationId(loc.id); setDestLocationSearch(''); setDestLocOpen(false); }}>
                                                {locationLabel(loc, language === 'en')}
                                            </li>
                                        ))}
                                        {filterLocationsBySearch(locations, destLocationSearch, language === 'en').length === 0 && (
                                            <li className="px-4 py-4 text-sm theme-muted">{t('trips.addTrip.noLocationFound')}</li>
                                        )}
                                    </ul>
                                )}
                            </div>

                            {originLocationId && destLocationId && (() => {
                                const scope = getRouteScope(
                                    locations.find((loc) => loc.id === originLocationId),
                                    locations.find((loc) => loc.id === destLocationId)
                                );
                                return (
                                    <div className={`rounded-xl border p-4 ${scopeBadgeClass(scope)}`}>
                                        <p className="text-[0.625rem] font-black uppercase tracking-widest opacity-70">
                                            {t('trips.addTrip.detectedRoute', 'Detected route')}
                                        </p>
                                        <p className="mt-1 text-sm font-black">
                                            {t(`trips.scope.${scope}`, scope)}
                                        </p>
                                        {scope === 'invalid' && (
                                            <p className="mt-1 text-xs font-bold">
                                                {t('trips.addTrip.invalidRoute', `Trip must start or end in ${homeCountryName('en')}.`)}
                                            </p>
                                        )}
                                    </div>
                                );
                            })()}

                            {/* Date & Time */}
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.departureDate')}</label>
                                    <input type="date" value={departureDate} onChange={e => setDepartureDate(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 focus:outline-none transition" />
                                </div>
                                <div>
                                    <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.departureTime')}</label>
                                    <input type="time" value={departureTime} onChange={e => setDepartureTime(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 focus:outline-none transition" />
                                </div>
                            </div>

                            {/* Weight & Notes (suggested price hidden for now) */}
                            <div className="flex flex-wrap items-end gap-6">
                                <div className="w-32">
                                    <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.maxWeight')}</label>
                                    <input type="number" step="0.1" min="0" placeholder="kg" value={maxWeight} onChange={e => setMaxWeight(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 focus:outline-none transition" />
                                </div>
                                <div className="flex-1 min-w-[200px]">
                                    <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-1.5">{t('trips.addTrip.notes')}</label>
                                    <textarea rows={2} value={notes} onChange={e => setNotes(e.target.value)} className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 focus:outline-none transition resize-none" placeholder={t('trips.addTrip.notesPlaceholder')} />
                                </div>
                            </div>

                            {/* Repeat dates */}
                            <div>
                                <label className="block text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-3 flex items-center gap-1.5">
                                    <Repeat className="h-4 w-4" /> {t('trips.addTrip.repeatOn')}
                                </label>
                                <div className="flex flex-wrap gap-2 mb-3">
                                    {repeatDates.map(d => (
                                        <span key={d} className="inline-flex items-center gap-1.5 theme-bg-secondary border border-[var(--surface-border)] px-3 py-1.5 rounded-xl text-xs font-bold theme-heading shadow-sm group">
                                            {d}
                                            <button type="button" onClick={() => setRepeatDates(r => r.filter(x => x !== d))} className="theme-muted hover:text-red-500 transition-colors"><X className="h-3.5 w-3.5" /></button>
                                        </span>
                                    ))}
                                </div>
                                <div className="flex gap-3">
                                    <input type="date" value={addTripRepeatDate} onChange={e => setAddTripRepeatDate(e.target.value)} className="theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:border-orange-500 transition" />
                                    <button type="button" onClick={() => { if (addTripRepeatDate && !repeatDates.includes(addTripRepeatDate)) setRepeatDates(r => [...r, addTripRepeatDate].sort()); setAddTripRepeatDate(''); }} className="flex items-center gap-2 px-6 py-2.5 rounded-xl theme-bg-secondary border border-orange-500/20 text-orange-600 text-xs font-black uppercase tracking-widest hover:bg-orange-500/10 transition shadow-sm">
                                        <Plus className="h-4 w-4" /> {t('trips.addTrip.addRepeatDate')}
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div className="p-8 border-t border-[var(--surface-border)] flex justify-end gap-3 theme-bg-secondary">
                            <button type="button" onClick={() => setShowAddTripModal(false)} disabled={addTripSaving} className="px-6 py-2.5 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition disabled:opacity-50">
                                {t('common.cancel')}
                            </button>
                            <button type="button" onClick={saveAddTrip} disabled={addTripSaving} className="px-8 py-2.5 rounded-xl bg-orange-600 text-white hover:bg-orange-700 font-bold disabled:opacity-50 transition shadow-sm">
                                {addTripSaving ? t('common.saving') : t('trips.addTrip.save')}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
