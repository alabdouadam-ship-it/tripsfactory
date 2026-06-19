'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useToast } from '@/lib/toast';
import { Booking, BookingStatus } from '@/lib/types';
import {
    Search, Download, Package, AlertCircle,
    ExternalLink, RefreshCw, ChevronLeft, ChevronRight,
    ChevronsLeft, ChevronsRight
} from 'lucide-react';
import { DataTable, Column } from '@/components/DataTable';
import { getPaginatedBookings, bulkUpdateBookingStatus } from '@/app/actions/ux-actions';
import { StatusBadge } from '@/components/StatusBadge';
import { useI18n, useT } from '@/lib/i18n';

const PAGE_SIZE = 25;
const BOOKING_STATUSES: BookingStatus[] = [
    'pending',
    'in_communication',
    'accepted',
    'rejected',
    'in_transit',
    'delivered',
    'completed',
    'cancelled',
    'frozen',
    'disputed',
];
const BOOKING_STATUS_FILTERS = ['all', ...BOOKING_STATUSES] as const;
const NON_BULK_CANCELLABLE_STATUSES = new Set<BookingStatus>(['cancelled', 'completed', 'rejected', 'frozen']);

export default function BookingsPage() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const { toast } = useToast();
    const t = useT();
    const { dir, language } = useI18n();
    const locale = language === 'ar' ? 'ar' : 'en';

    const [data, setData] = useState<Booking[]>([]);
    const [totalCount, setTotalCount] = useState(0);
    const [loading, setLoading] = useState(true);
    const [errorMessage, setErrorMessage] = useState<string | null>(null);
    const [page, setPage] = useState(1);
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [sort, setSort] = useState<{ key: string; direction: 'asc' | 'desc' } | null>(null);

    const fetchBookings = useCallback(async () => {
        setLoading(true);
        const filters = [];
        if (statusFilter !== 'all') filters.push({ field: 'status', op: 'eq', value: statusFilter });

        const result = await getPaginatedBookings({
            page,
            pageSize: PAGE_SIZE,
            search,
            filters,
            orderBy: sort?.key || 'created_at',
            orderDir: sort?.direction || 'desc'
        });

        if (result.success) {
            setData(result.data as any[]);
            setTotalCount(result.totalCount ?? 0);
            setErrorMessage(null);
        } else {
            const message = result.error || t('bookings.toast.loadFailed', 'Failed to fetch bookings');
            setData([]);
            setTotalCount(0);
            setErrorMessage(message);
            toast(message, "error");
        }
        setLoading(false);
    }, [page, search, statusFilter, sort, t, toast]);

    useEffect(() => {
        fetchBookings();
    }, [fetchBookings]);

    useEffect(() => {
        const status = searchParams.get('status');
        const allowedStatuses = new Set<string>(BOOKING_STATUS_FILTERS);
        if (!status) return;
        if (!allowedStatuses.has(status)) return;
        setStatusFilter(status);
        setPage(1);
    }, [searchParams]);

    const columns: Column<Booking>[] = [
        {
            header: t('bookings.table.bookingId', 'Booking ID'),
            accessorKey: 'id',
            sortable: true,
            cell: (booking) => (
                <div className="flex items-center gap-2">
                    <Package className="h-4 w-4 text-blue-500" />
                    <span className="font-black theme-heading uppercase">#{booking.id.slice(0, 8)}</span>
                </div>
            )
        },
        {
            header: t('bookings.table.status', 'Status'),
            accessorKey: 'status',
            sortable: true,
            cell: (booking) => <StatusBadge status={booking.status} />
        },
        {
            header: t('bookings.table.trip', 'Trip'),
            accessorKey: 'trip_id',
            cell: (booking) => {
                if (!booking.trips) {
                    return <span className="text-xs theme-muted italic">{t('common.na', 'N/A')}</span>;
                }
                const trip = booking.trips;
                const origin = trip.origin?.city_name_en || trip.origin?.city_name_ar || t('common.unknown', 'Unknown');
                const dest = trip.dest?.city_name_en || trip.dest?.city_name_ar || t('common.unknown', 'Unknown');
                
                return (
                    <button
                        onClick={() => router.push(`/trips/${trip.id}`)}
                        className="text-xs hover:bg-blue-50 dark:hover:bg-blue-900/20 px-2 py-1 rounded-lg transition group"
                    >
                        <div className="flex items-center gap-1.5">
                            <span className="font-bold theme-heading group-hover:text-blue-600 transition">{origin}</span>
                            <span className="theme-muted opacity-50">→</span>
                            <span className="font-bold theme-heading group-hover:text-blue-600 transition">{dest}</span>
                        </div>
                    </button>
                );
            }
        },
        {
            header: t('bookings.table.price', 'Reservation Price'),
            accessorKey: 'offer_price',
            sortable: true,
            cell: (booking) => <span className="font-bold text-blue-600">{booking.offer_price} {t('common.currencySar', '')}</span>
        },
        {
            header: t('bookings.table.participants', 'Participants'),
            accessorKey: 'driver_profile',
            cell: (booking) => (
                <div className="text-xs space-y-1">
                    <div className="flex items-center gap-1">
                        <span className="theme-muted font-bold uppercase text-[0.5625rem] opacity-60">{t('bookings.table.traveler', 'Traveler')}:</span>
                        {booking.driver_profile ? (
                            <button
                                onClick={() => router.push(`/users?user_id=${booking.traveler_id}`)}
                                className="theme-heading hover:text-blue-600 hover:underline font-medium transition"
                            >
                                {booking.driver_profile.full_name}
                            </button>
                        ) : (
                            <span className="theme-muted italic">{t('common.na', 'N/A')}</span>
                        )}
                    </div>
                    <div className="flex items-center gap-1">
                        <span className="theme-muted font-bold uppercase text-[0.5625rem] opacity-60">{t('bookings.table.requester', 'Requester')}:</span>
                        {booking.requester_profile ? (
                            <button
                                onClick={() => router.push(`/users?user_id=${booking.requester_id}`)}
                                className="theme-heading hover:text-blue-600 hover:underline font-medium transition"
                            >
                                {booking.requester_profile.full_name}
                            </button>
                        ) : (
                            <span className="theme-muted italic">{t('common.na', 'N/A')}</span>
                        )}
                    </div>
                </div>
            )
        },
        {
            header: t('bookings.table.createdAt', 'Created At'),
            accessorKey: 'created_at',
            sortable: true,
            cell: (booking) => new Date(booking.created_at).toLocaleString(locale)
        },
        {
            header: '',
            accessorKey: 'actions',
            cell: (booking) => (
                <button onClick={() => router.push(`/bookings/${booking.id}`)} className="p-2 hover:theme-bg-secondary rounded-xl transition">
                    <ExternalLink className="h-4 w-4 theme-muted opacity-50 hover:opacity-100 transition-opacity" />
                </button>
            )
        }
    ];

    const bulkActions = [
        {
            label: t('bookings.bulk.cancelSelected', 'Cancel Selected'),
            icon: AlertCircle,
            variant: 'danger' as const,
            action: async (items: Booking[]) => {
                const cancellableItems = items.filter(item => !NON_BULK_CANCELLABLE_STATUSES.has(item.status));
                if (cancellableItems.length === 0) {
                    toast(t('bookings.bulk.noCancellable', 'No cancellable bookings selected.'), 'error');
                    return;
                }
                const ids = cancellableItems.map(i => i.id);
                const res = await bulkUpdateBookingStatus(ids, { status: 'cancelled' }, 'cancel');
                if (res.success) {
                    toast(t('bookings.bulk.cancelledSuccess', 'Successfully cancelled {count} bookings').replace('{count}', String(cancellableItems.length)), 'success');
                    fetchBookings();
                } else {
                    toast(res.error || t('bookings.bulk.cancelFailed', 'Failed to cancel selected bookings.'), 'error');
                }
            }
        }
    ];

    return (
        <div className="flex flex-col h-full">
            {/* Compact Header */}
            <div className="flex items-center justify-between gap-4 pb-3 flex-shrink-0">
                <div>
                    <h1 className="text-2xl font-black theme-heading tracking-tight">
                        {t('bookings.title', 'Bookings Management')}
                    </h1>
                </div>
                <div className="flex items-center gap-2">
                    <div className="theme-bg-secondary px-3 py-1.5 rounded-lg border border-[var(--surface-border)] text-xs theme-heading">
                        <span className="font-bold">{totalCount}</span> {t('bookings.total', 'bookings')}
                    </div>
                    <button
                        onClick={() => toast(t('bookings.toast.exporting', 'Exporting...'), 'info')}
                        className="flex items-center gap-1.5 px-3 py-1.5 bg-green-500/10 text-green-600 rounded-lg hover:bg-green-500/20 transition border border-green-500/20 text-xs font-bold"
                    >
                        <Download className="h-3.5 w-3.5" /> {t('bookings.export', 'CSV')}
                    </button>
                </div>
            </div>

            {/* Compact Filter Bar */}
            <div className="flex items-center gap-3 pb-3 flex-shrink-0">
                {/* Search */}
                <div className="relative flex-1 max-w-xs">
                    <Search className={`absolute ${dir === 'rtl' ? 'right-2.5' : 'left-2.5'} top-1/2 -translate-y-1/2 h-3.5 w-3.5 theme-muted opacity-50`} />
                    <input
                        value={search}
                        onChange={(e) => {
                            setSearch(e.target.value);
                            setPage(1);
                        }}
                        placeholder={t('bookings.search.placeholder', 'Search...')}
                        className={`w-full theme-bg-secondary border border-[var(--surface-border)] rounded-lg ${dir === 'rtl' ? 'pr-9 pl-3' : 'pl-9 pr-3'} py-1.5 text-sm theme-heading focus:ring-1 focus:ring-blue-500/20 outline-none transition`}
                    />
                </div>

                {/* Compact Status Filters */}
                <div className="flex items-center gap-1.5 overflow-x-auto scrollbar-none">
                    {BOOKING_STATUS_FILTERS.map((status) => (
                        <button
                            key={status}
                            onClick={() => { setStatusFilter(status); setPage(1); }}
                            className={`px-2.5 py-1 rounded-lg text-[0.6875rem] font-bold whitespace-nowrap transition-all ${statusFilter === status ? 'bg-blue-600 text-white' : 'theme-bg-secondary theme-muted hover:theme-heading border border-[var(--surface-border)]'}`}
                        >
                            {t(`bookings.status.${status}`, status.replace('_', ' '))}
                        </button>
                    ))}
                </div>
            </div>

            {/* Error Message */}
            {errorMessage && (
                <div className="mb-3 flex items-center justify-between gap-3 rounded-lg border border-red-500/20 bg-red-500/10 px-3 py-2 text-sm flex-shrink-0">
                    <div className="flex items-center gap-2">
                        <AlertCircle className="h-4 w-4 text-red-600" />
                        <p className="font-bold text-red-700 text-xs">{errorMessage}</p>
                    </div>
                    <button
                        onClick={fetchBookings}
                        className="inline-flex items-center gap-1.5 rounded-lg bg-red-600 px-3 py-1.5 text-xs font-bold text-white transition hover:bg-red-700"
                    >
                        <RefreshCw className="h-3 w-3" />
                        {t('common.retry', 'Retry')}
                    </button>
                </div>
            )}

            {/* Full Height Table - Desktop */}
            <div className="hidden lg:flex flex-col flex-1 min-h-0 theme-card rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
                {/* Compact Table Toolbar */}
                {data.length > 0 && (
                    <div className="px-3 py-2 border-b border-[var(--surface-border)] flex items-center justify-between theme-bg-secondary/30 flex-shrink-0">
                        <div className="flex items-center gap-2">
                            {bulkActions && bulkActions.length > 0 && (
                                <span className="text-xs theme-muted">
                                    {t('table.selectRows', 'Select rows for bulk actions')}
                                </span>
                            )}
                        </div>
                        <div className="text-xs theme-muted">
                            {t('table.showing', 'Showing {count} of {total}')
                                .replace('{count}', String(data.length))
                                .replace('{total}', String(totalCount))}
                        </div>
                    </div>
                )}

                {/* Table Content */}
                <div className="flex-1 overflow-auto scrollbar-thin relative">
                    {loading && (
                        <div className="absolute inset-0 bg-[var(--surface)] opacity-50 backdrop-blur-[1px] z-10 flex items-center justify-center">
                            <div className="h-8 w-8 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
                        </div>
                    )}
                    <table className="w-full text-left border-collapse">
                        <thead className="sticky top-0 theme-bg-secondary z-20 border-b border-[var(--surface-border)]">
                            <tr>
                                <th className="p-3 w-10">
                                    <input
                                        type="checkbox"
                                        className="rounded text-blue-600 focus:ring-blue-500 h-4 w-4"
                                    />
                                </th>
                                {columns.map(col => (
                                    <th
                                        key={col.accessorKey as string}
                                        className="p-3 text-[0.6875rem] font-bold theme-muted uppercase"
                                    >
                                        {col.header}
                                    </th>
                                ))}
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-[var(--surface-border)] text-sm">
                            {data.map(item => (
                                <tr
                                    key={item.id}
                                    className="hover:theme-bg-secondary transition-colors"
                                >
                                    <td className="p-3">
                                        <input
                                            type="checkbox"
                                            className="rounded text-blue-600 focus:ring-blue-500 h-4 w-4"
                                        />
                                    </td>
                                    {columns.map((col) => (
                                        <td key={col.accessorKey as string} className="p-3 theme-heading">
                                            {col.cell ? col.cell(item) : (item[col.accessorKey as keyof Booking] as any)}
                                        </td>
                                    ))}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {data.length === 0 && !loading && (
                        <div className="flex flex-col items-center justify-center py-20 theme-muted">
                            <Package className="h-10 w-10 mb-4 opacity-10" />
                            <p className="font-bold text-xs uppercase opacity-40">{t('bookings.empty', 'No bookings found')}</p>
                        </div>
                    )}
                </div>

                {/* Compact Pagination */}
                <div className="px-3 py-2 border-t border-[var(--surface-border)] theme-bg-secondary/30 flex items-center justify-between flex-shrink-0">
                    <p className="text-xs theme-muted">
                        {t('table.page', 'Page {current} of {total}')
                            .replace('{current}', String(page))
                            .replace('{total}', String(Math.ceil(totalCount / PAGE_SIZE) || 1))}
                    </p>
                    <div className="flex items-center gap-1">
                        <button
                            disabled={page === 1 || loading}
                            onClick={() => setPage(1)}
                            className="p-1.5 hover:bg-blue-600 hover:text-white rounded-lg disabled:opacity-30 transition border border-[var(--surface-border)]"
                        >
                            <ChevronsLeft className="h-3.5 w-3.5" />
                        </button>
                        <button
                            disabled={page === 1 || loading}
                            onClick={() => setPage(page - 1)}
                            className="p-1.5 hover:bg-blue-600 hover:text-white rounded-lg disabled:opacity-30 transition border border-[var(--surface-border)]"
                        >
                            <ChevronLeft className="h-3.5 w-3.5" />
                        </button>
                        <div className="px-3 py-1 bg-[var(--surface)] border border-[var(--surface-border)] rounded-lg">
                            <span className="text-xs font-bold theme-heading">{page} / {Math.ceil(totalCount / PAGE_SIZE) || 1}</span>
                        </div>
                        <button
                            disabled={page >= Math.ceil(totalCount / PAGE_SIZE) || loading}
                            onClick={() => setPage(page + 1)}
                            className="p-1.5 hover:bg-blue-600 hover:text-white rounded-lg disabled:opacity-30 transition border border-[var(--surface-border)]"
                        >
                            <ChevronRight className="h-3.5 w-3.5" />
                        </button>
                        <button
                            disabled={page >= Math.ceil(totalCount / PAGE_SIZE) || loading}
                            onClick={() => setPage(Math.ceil(totalCount / PAGE_SIZE))}
                            className="p-1.5 hover:bg-blue-600 hover:text-white rounded-lg disabled:opacity-30 transition border border-[var(--surface-border)]"
                        >
                            <ChevronsRight className="h-3.5 w-3.5" />
                        </button>
                    </div>
                </div>
            </div>

            {/* Mobile Card View */}
            <div className="lg:hidden space-y-3">
                {loading && (
                    <div className="flex items-center justify-center py-20">
                        <div className="h-10 w-10 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
                    </div>
                )}
                
                {!loading && data.length === 0 && (
                    <div className="flex flex-col items-center justify-center py-20 theme-muted">
                        <Package className="h-10 w-10 mb-4 opacity-10" />
                        <p className="font-black text-xs uppercase tracking-widest opacity-40">{t('bookings.empty', 'No bookings found')}</p>
                    </div>
                )}

                {!loading && data.map((booking) => (
                    <div
                        key={booking.id}
                        className="theme-card rounded-2xl border border-[var(--surface-border)] p-4 space-y-3 shadow-sm hover:shadow-md transition-shadow"
                    >
                        {/* Header: ID + Status */}
                        <div className="flex items-center justify-between gap-2">
                            <div className="flex items-center gap-2">
                                <Package className="h-4 w-4 text-blue-500 flex-shrink-0" />
                                <span className="font-black theme-heading text-sm">#{booking.id.slice(0, 8)}</span>
                            </div>
                            <StatusBadge status={booking.status} />
                        </div>

                        {/* Trip Info */}
                        {booking.trips && (
                            <button
                                onClick={() => router.push(`/trips/${booking.trips!.id}`)}
                                className="w-full text-left p-3 rounded-xl theme-bg-secondary hover:bg-blue-50 dark:hover:bg-blue-900/20 transition group"
                            >
                                <p className="text-[0.625rem] font-black uppercase theme-muted opacity-60 mb-1">{t('bookings.table.trip', 'Trip')}</p>
                                <div className="flex items-center gap-2">
                                    <span className="font-bold theme-heading group-hover:text-blue-600 transition text-sm">
                                        {booking.trips.origin?.city_name_en || booking.trips.origin?.city_name_ar || t('common.unknown', 'Unknown')}
                                    </span>
                                    <span className="theme-muted opacity-50">→</span>
                                    <span className="font-bold theme-heading group-hover:text-blue-600 transition text-sm">
                                        {booking.trips.dest?.city_name_en || booking.trips.dest?.city_name_ar || t('common.unknown', 'Unknown')}
                                    </span>
                                </div>
                            </button>
                        )}

                        {/* Participants */}
                        <div className="space-y-2">
                            <div className="flex items-center justify-between gap-2">
                                <span className="text-[0.625rem] font-black uppercase theme-muted opacity-60">{t('bookings.table.traveler', 'Traveler')}</span>
                                {booking.driver_profile ? (
                                    <button
                                        onClick={() => router.push(`/users?user_id=${booking.traveler_id}`)}
                                        className="theme-heading hover:text-blue-600 hover:underline font-bold text-sm transition"
                                    >
                                        {booking.driver_profile.full_name}
                                    </button>
                                ) : (
                                    <span className="theme-muted italic text-sm">{t('common.na', 'N/A')}</span>
                                )}
                            </div>
                            <div className="flex items-center justify-between gap-2">
                                <span className="text-[0.625rem] font-black uppercase theme-muted opacity-60">{t('bookings.table.requester', 'Requester')}</span>
                                {booking.requester_profile ? (
                                    <button
                                        onClick={() => router.push(`/users?user_id=${booking.requester_id}`)}
                                        className="theme-heading hover:text-blue-600 hover:underline font-bold text-sm transition"
                                    >
                                        {booking.requester_profile.full_name}
                                    </button>
                                ) : (
                                    <span className="theme-muted italic text-sm">{t('common.na', 'N/A')}</span>
                                )}
                            </div>
                        </div>

                        {/* Price + Date */}
                        <div className="flex items-center justify-between gap-2 pt-2 border-t border-[var(--surface-border)]">
                            <div>
                                <p className="text-[0.625rem] font-black uppercase theme-muted opacity-60 mb-0.5">{t('bookings.table.price', 'Price')}</p>
                                <p className="font-bold text-blue-600 text-sm">{booking.offer_price} {t('common.currencySar', 'SAR')}</p>
                            </div>
                            <div className="text-right">
                                <p className="text-[0.625rem] font-black uppercase theme-muted opacity-60 mb-0.5">{t('bookings.table.createdAt', 'Created')}</p>
                                <p className="text-xs theme-heading font-medium">{new Date(booking.created_at).toLocaleDateString(locale)}</p>
                            </div>
                        </div>

                        {/* View Details Button */}
                        <button
                            onClick={() => router.push(`/bookings/${booking.id}`)}
                            className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 text-white hover:bg-blue-700 transition font-bold text-sm"
                        >
                            <ExternalLink className="h-4 w-4" />
                            {t('common.viewDetails', 'View Details')}
                        </button>
                    </div>
                ))}

                {/* Mobile Pagination */}
                {!loading && data.length > 0 && (
                    <div className="flex flex-col gap-3 pt-4">
                        <p className="text-center text-xs theme-muted font-bold">
                            {t('table.page', 'Page {current} of {total}').replace('{current}', String(page)).replace('{total}', String(Math.ceil(totalCount / PAGE_SIZE)))}
                        </p>
                        <div className="flex items-center justify-center gap-2">
                            <button
                                disabled={page === 1}
                                onClick={() => setPage(1)}
                                className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] theme-bg-secondary"
                            >
                                <ChevronsLeft className="h-4 w-4" />
                            </button>
                            <button
                                disabled={page === 1}
                                onClick={() => setPage(page - 1)}
                                className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] theme-bg-secondary"
                            >
                                <ChevronLeft className="h-4 w-4" />
                            </button>
                            <div className="px-4 py-2 theme-bg-secondary border border-[var(--surface-border)] rounded-xl">
                                <span className="text-xs font-black theme-heading">{page} / {Math.ceil(totalCount / PAGE_SIZE)}</span>
                            </div>
                            <button
                                disabled={page >= Math.ceil(totalCount / PAGE_SIZE)}
                                onClick={() => setPage(page + 1)}
                                className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] theme-bg-secondary"
                            >
                                <ChevronRight className="h-4 w-4" />
                            </button>
                            <button
                                disabled={page >= Math.ceil(totalCount / PAGE_SIZE)}
                                onClick={() => setPage(Math.ceil(totalCount / PAGE_SIZE))}
                                className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] theme-bg-secondary"
                            >
                                <ChevronsRight className="h-4 w-4" />
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
