
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

interface Notification {
    title: string
    body: string
    user_id: string
    data: Record<string, any>
}

function requireEnv(name: string): string {
    const v = Deno.env.get(name)
    if (!v || v === '') throw new Error(`Missing or empty env: ${name}`)
    return v
}

/// Reads an optional env var, falling back to [fallback] when unset/empty.
function envOr(name: string, fallback: string): string {
    const v = Deno.env.get(name)
    return v && v !== '' ? v : fallback
}

// Brand-configurable notification identifiers. Defaults equal the current
// values, so behavior is unchanged unless a fork sets these env vars. Keep the
// Android channel id in sync with the client's BrandConfig.notificationChannelId
// (channels are immutable once created on a device).
const NOTIFICATION_CHANNEL_ID = envOr('NOTIFICATION_CHANNEL_ID', 'tripsfactory_notification_v1')
const NOTIFICATION_SOUND_ANDROID = envOr('NOTIFICATION_SOUND_ANDROID', 'tripsfactory_notification')
const NOTIFICATION_SOUND_IOS = envOr('NOTIFICATION_SOUND_IOS', 'tripsfactory_notification.wav')

Deno.serve(async (req) => {
    try {
        // Authenticated by a dedicated shared webhook secret, decoupled from the
        // service-role key (whose injected format — legacy JWT vs sb_secret_ —
        // varies by platform). The notifications DB trigger
        // (handle_new_notification) sends it in the `x-webhook-secret` header; it
        // must equal the PUSH_WEBHOOK_TOKEN env. This function is deployed with
        // verify_jwt=false, so this header is the sole gate — keep the token secret.
        const provided = req.headers.get('x-webhook-secret') ?? ''
        const expected = requireEnv('PUSH_WEBHOOK_TOKEN')
        if (provided.length === 0 || provided !== expected) {
            return new Response(JSON.stringify({ error: 'Unauthorized' }), {
                status: 401,
                headers: { 'Content-Type': 'application/json' },
            })
        }

        let body: unknown
        try {
            body = await req.json()
        } catch {
            return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' },
            })
        }
        const record = body && typeof body === 'object' && 'record' in body ? (body as { record: unknown }).record : null
        if (!record || typeof record !== 'object' || !('user_id' in record) || typeof (record as Notification).user_id !== 'string') {
            return new Response(JSON.stringify({ error: 'Payload must include record.user_id (string)' }), {
                status: 400,
                headers: { 'Content-Type': 'application/json' },
            })
        }
        const notification = record as Notification

        // 1. Setup Service Account & Supabase Client
        const supabaseUrl = requireEnv('SUPABASE_URL')
        const supabaseKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY')
        const serviceAccountStr = requireEnv('FIREBASE_SERVICE_ACCOUNT')

        const serviceAccount = JSON.parse(serviceAccountStr)
        const supabase = createClient(supabaseUrl, supabaseKey)

        // 2. Get User's FCM Tokens (multi-device)
        const { data: tokenRows, error } = await supabase
            .from('notification_tokens')
            .select('token')
            .eq('user_id', notification.user_id)

        const tokens = (tokenRows || [])
            .map((r: { token?: string }) => r.token)
            .filter((t: string | undefined): t is string => Boolean(t))

        if (error || tokens.length === 0) {
            console.log(`No token found for user ${notification.user_id}`)
            return new Response(JSON.stringify({ message: 'No token found' }), {
                headers: { 'Content-Type': 'application/json' },
            })
        }

        // 3. Authenticate with Google (FCM V1)
        const client = new JWT({
            email: serviceAccount.client_email,
            key: serviceAccount.private_key,
            scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
        })

        const accessToken = await client.getAccessToken()
        const projectId = serviceAccount.project_id

        // 4. Send Notification (FCM V1 API)
        // FCM data payload requires all values to be strings
        const rawData = notification.data || {}
        const data: Record<string, string> = {}
        for (const [k, v] of Object.entries(rawData)) {
            data[k] = typeof v === 'string' ? v : JSON.stringify(v)
        }

        const results = []
        const deadTokens: string[] = []

        for (const token of tokens) {
            try {
                const res = await fetch(
                    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
                    {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            Authorization: `Bearer ${accessToken.token}`,
                        },
                        body: JSON.stringify({
                            message: {
                                token,
                                notification: {
                                    title: notification.title,
                                    body: notification.body,
                                },
                                data,
                                android: {
                                    priority: 'high',
                                    notification: {
                                        channel_id: NOTIFICATION_CHANNEL_ID,
                                        sound: NOTIFICATION_SOUND_ANDROID
                                    }
                                },
                                apns: {
                                    payload: {
                                        aps: {
                                            alert: {
                                                title: notification.title,
                                                body: notification.body,
                                            },
                                            sound: NOTIFICATION_SOUND_IOS,
                                            badge: 1,
                                            'content-available': 1
                                        }
                                    }
                                }
                            },
                        }),
                    }
                )

                const result = await res.json()
                results.push({ token, status: res.status, result })

                // Token pruning: if FCM says token is invalid/unregistered, mark for deletion
                if (res.status === 404 || res.status === 410 ||
                    (result?.error?.status === 'UNREGISTERED' || result?.error?.message?.includes('registration token is not a valid'))) {
                    console.log(`Pruning dead token: ${token}`)
                    deadTokens.push(token)
                }
            } catch (err) {
                console.error(`Fetch error for token ${token}:`, err)
                results.push({ token, error: err.message })
            }
        }

        // 5. Cleanup Dead Tokens
        if (deadTokens.length > 0) {
            await supabase
                .from('notification_tokens')
                .delete()
                .in('token', deadTokens)
        }

        console.log(`FCM Delivery for user ${notification.user_id}: ${tokens.length} tokens, ${deadTokens.length} pruned. Results:`, JSON.stringify(results))

        return new Response(JSON.stringify({ sent: tokens.length, pruned: deadTokens.length, results }), {
            headers: { 'Content-Type': 'application/json' },
        })

    } catch (err) {
        console.error(err)
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
