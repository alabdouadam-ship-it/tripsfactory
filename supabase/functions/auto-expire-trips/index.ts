import { createClient } from 'jsr:@supabase/supabase-js@2'

/**
 * auto-expire-trips
 *
 * Cron-triggered Edge Function that auto-completes trips whose departure
 * time has passed, rejects their pending bookings, and notifies affected
 * senders via push notification.
 *
 * Schedule: every 15 minutes via pg_cron + pg_net
 */

interface BookingRow {
    id: string
    status: string
    requester_id: string
}

function requireEnv(name: string): string {
    const v = Deno.env.get(name)
    if (!v || v === '') throw new Error(`Missing or empty env: ${name}`)
    return v
}

Deno.serve(async (req) => {
    try {
        // Verify authorization (service role only). The pg_cron job sends
        // the service-role JWT in the Authorization header; anything else
        // (including valid user/anon JWTs that pass platform verify_jwt)
        // is rejected.
        const authHeader = req.headers.get('Authorization')
        const serviceKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY')
        if (!authHeader || !authHeader.includes(serviceKey)) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { 'Content-Type': 'application/json' },
            })
        }

        const supabaseUrl = requireEnv('SUPABASE_URL')
        const supabase = createClient(supabaseUrl, serviceKey)

        // 1. Find expired trips: active trips whose departure time has passed
        const { data: expiredTrips, error: tripsError } = await supabase
            .from('trips')
            .select('id, traveler_id')
            .in('status', ['available', 'booked'])
            .lt('departure_time', new Date().toISOString())

        if (tripsError) {
            throw new Error(`Failed to query trips: ${tripsError.message}`)
        }

        if (!expiredTrips || expiredTrips.length === 0) {
            return new Response(JSON.stringify({
                message: 'No expired trips found',
                processed: 0,
            }), {
                headers: { 'Content-Type': 'application/json' },
            })
        }

        let completedCount = 0
        let rejectedBookingsCount = 0
        let skippedCount = 0
        const notifiedUserIds: string[] = []

        for (const trip of expiredTrips) {
            // 2. Check if trip has active bookings
            const { data: bookings, error: bookingsError } = await supabase
                .from('bookings')
                .select('id, status, requester_id')
                .eq('trip_id', trip.id)

            if (bookingsError) {
                console.error(`Failed to query bookings for trip ${trip.id}: ${bookingsError.message}`)
                continue
            }

            const activeBookings = (bookings || []).filter((b: BookingRow) =>
                ['accepted', 'in_transit', 'delivered'].includes(b.status)
            )

            if (activeBookings.length > 0) {
                // Trip has active bookings — don't expire, leave as-is
                skippedCount++
                continue
            }

            // 3. Reject all pending/in_communication bookings
            const pendingBookings = (bookings || []).filter((b: BookingRow) =>
                ['pending', 'in_communication'].includes(b.status)
            )

            if (pendingBookings.length > 0) {
                const pendingIds = pendingBookings.map((b: BookingRow) => b.id)
                const { error: rejectError } = await supabase
                    .from('bookings')
                    .update({ status: 'rejected' })
                    .in('id', pendingIds)

                if (rejectError) {
                    console.error(`Failed to reject bookings for trip ${trip.id}: ${rejectError.message}`)
                    continue
                }

                rejectedBookingsCount += pendingIds.length

                // Collect affected sender IDs for notification
                for (const booking of pendingBookings) {
                    if (booking.requester_id && !notifiedUserIds.includes(booking.requester_id)) {
                        notifiedUserIds.push(booking.requester_id)
                    }
                }
            }

            // 4. Mark trip as completed
            const { error: completeError } = await supabase
                .from('trips')
                .update({ status: 'completed' })
                .eq('id', trip.id)

            if (completeError) {
                console.error(`Failed to complete trip ${trip.id}: ${completeError.message}`)
                continue
            }

            completedCount++
        }

        // 5. Send push notifications to affected senders
        for (const userId of notifiedUserIds) {
            try {
                await supabase.functions.invoke('push-notification', {
                    body: {
                        record: {
                            user_id: userId,
                            title: 'تم إلغاء حجزك تلقائياً',
                            body: 'انتهى وقت الرحلة التي حجزت عليها وتم رفض حجزك تلقائياً',
                            data: {
                                type: 'booking_auto_rejected',
                            },
                        },
                    },
                })
            } catch (notifError) {
                console.error(`Failed to notify user ${userId}:`, notifError)
                // Don't fail the whole function for notification errors
            }
        }

        const summary = {
            message: 'Auto-expire completed',
            expired_trips_found: expiredTrips.length,
            trips_completed: completedCount,
            trips_skipped_active: skippedCount,
            bookings_rejected: rejectedBookingsCount,
            senders_notified: notifiedUserIds.length,
        }

        console.log('Auto-expire summary:', summary)

        return new Response(JSON.stringify(summary), {
            headers: { 'Content-Type': 'application/json' },
        })

    } catch (err) {
        console.error('auto-expire-trips error:', err)
        return new Response(JSON.stringify({ error: (err as Error).message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
