'use client';

import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useRef, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { Sidebar } from '@/components/Sidebar';
import Loading from '@/app/loading';
import { useI18n } from '@/lib/i18n';
import { ViolationAlertsProvider } from '@/lib/violation-alerts';

type AuthState = 'checking' | 'allowed' | 'denied';

const BACKEND_VERIFY_TIMEOUT_MS = 12000;

function isAbortError(error: unknown): boolean {
    if (!error) return false;
    const name = (error as any)?.name;
    const message = String((error as any)?.message ?? '');
    return name === 'AbortError' || /aborted/i.test(message);
}

function withTimeout<T>(promise: PromiseLike<T>, timeoutMs: number, label: string): Promise<T> {
    return new Promise<T>((resolve, reject) => {
        const timer = window.setTimeout(() => reject(new Error(`${label} timeout after ${timeoutMs}ms`)), timeoutMs);
        Promise.resolve(promise)
            .then((value) => resolve(value))
            .catch((error) => reject(error))
            .finally(() => window.clearTimeout(timer));
    });
}

export function AuthGuard({ children }: { children: React.ReactNode }) {
    const pathname = usePathname();
    const router = useRouter();
    const { dir, t } = useI18n();
    const [authState, setAuthState] = useState<AuthState>('checking');
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
    const verifiedAdmin = useRef(false);

    /**
     * Background verification. Never sets state to 'denied' on transient errors
     * (network abort, RPC timeout). Only on an authoritative negative result
     * (no profile, profile.is_admin === false, RPC explicitly returns false).
     */
    async function verifyAdminBackground(userId: string): Promise<'admin' | 'not_admin' | 'unknown'> {
        try {
            const profileResult: any = await withTimeout(
                supabase.from('profiles').select('is_admin').eq('id', userId).single(),
                BACKEND_VERIFY_TIMEOUT_MS,
                'profile probe'
            );
            const profileError = profileResult?.error;
            const profile = profileResult?.data;

            if (profileError) {
                console.warn('[AuthGuard] profile probe failed:', profileError.message);
                return 'unknown';
            }
            if (profile && profile.is_admin === false) return 'not_admin';
            if (!profile) return 'unknown';

            const rpcResult: any = await withTimeout(
                supabase.rpc('is_admin'),
                BACKEND_VERIFY_TIMEOUT_MS,
                'is_admin rpc'
            );
            const rpcError = rpcResult?.error;
            const rpcIsAdmin = rpcResult?.data;
            if (rpcError) {
                console.warn('[AuthGuard] is_admin rpc probe failed:', rpcError.message);
                // We have a valid profile.is_admin === true; treat as admin.
                return profile.is_admin ? 'admin' : 'unknown';
            }
            if (rpcIsAdmin === false) return 'not_admin';
            return profile.is_admin ? 'admin' : 'unknown';
        } catch (error) {
            if (isAbortError(error)) {
                console.warn('[AuthGuard] backend verify aborted; treating as unknown.');
                return 'unknown';
            }
            console.warn('[AuthGuard] backend verify error:', (error as any)?.message ?? error);
            return 'unknown';
        }
    }

    /**
     * Session-first bootstrap: render the app immediately when a cached session
     * exists. Run backend verification in the background and only deny on
     * authoritative negatives.
     */
    useEffect(() => {
        let active = true;

        async function bootstrap() {
            if (pathname === '/login') {
                if (active) setAuthState('allowed');
                return;
            }

            try {
                const { data: { session } } = await supabase.auth.getSession();
                if (!active) return;
                if (!session) {
                    setAuthState('denied');
                    return;
                }

                // Optimistically allow render to avoid global loader hangs.
                setAuthState('allowed');

                // Background verify (fire-and-forget). Only flip to denied on
                // authoritative not-admin / no-profile signals.
                void (async () => {
                    const result = await verifyAdminBackground(session.user.id);
                    if (!active) return;
                    if (result === 'not_admin') {
                        await supabase.auth.signOut();
                        setAuthState('denied');
                        return;
                    }
                    if (result === 'admin') {
                        verifiedAdmin.current = true;
                    }
                })();
            } catch (error) {
                console.error('[AuthGuard] bootstrap failed:', error);
                if (!active) return;
                if (verifiedAdmin.current) {
                    setAuthState('allowed');
                    return;
                }
                setAuthState('denied');
            }
        }

        void bootstrap();

        return () => {
            active = false;
        };
    }, [pathname]);

    // Cross-tab / token-revocation sync. Never blocks the UI on a network
    // probe; only reacts to authoritative signOut events.
    useEffect(() => {
        let active = true;
        const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
            try {
                if (pathname === '/login') return;

                if (event === 'SIGNED_OUT' || !session) {
                    if (active) setAuthState('denied');
                    return;
                }

                if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
                    if (active) setAuthState('allowed');
                    void (async () => {
                        const result = await verifyAdminBackground(session.user.id);
                        if (!active) return;
                        if (result === 'not_admin') {
                            await supabase.auth.signOut();
                            setAuthState('denied');
                        } else if (result === 'admin') {
                            verifiedAdmin.current = true;
                        }
                    })();
                }
            } catch (error) {
                console.error('[AuthGuard] auth state listener failed:', error);
            }
        });

        return () => {
            active = false;
            subscription.unsubscribe();
        };
    }, [pathname]);

    // Enforce redirect any time auth enters denied state.
    // Includes a hard fallback for static hosting in case router navigation stalls.
    useEffect(() => {
        if (pathname === '/login' || authState !== 'denied') return;

        router.replace('/login');
        const fallback = window.setTimeout(() => {
            if (window.location.pathname !== '/login') {
                window.location.assign('/login');
            }
        }, 1000);

        return () => window.clearTimeout(fallback);
    }, [authState, pathname, router]);

    // Close sidebar on route change (mobile)
    useEffect(() => {
        setSidebarOpen(false);
    }, [pathname]);

    if (pathname === '/login') {
        return <>{children}</>;
    }

    if (authState === 'checking') {
        return (
            <div className="flex h-screen items-center justify-center" style={{ background: 'var(--main-bg)' }}>
                <Loading />
            </div>
        );
    }

    if (authState !== 'allowed') {
        return (
            <div className="flex h-screen items-center justify-center" style={{ background: 'var(--main-bg)' }}>
                <div className="text-center">
                    <Loading />
                    <p className="mt-4 text-sm" style={{ color: 'var(--foreground)', opacity: 0.8 }}>{t('common.redirecting', 'Redirecting...')}</p>
                </div>
            </div>
        );
    }

    return (
        <ViolationAlertsProvider>
            <div className="flex h-screen overflow-hidden" style={{ background: 'var(--main-bg)' }} dir={dir}>
                {/* Mobile menu button */}
                <button
                    onClick={() => setSidebarOpen(!sidebarOpen)}
                    className={`fixed top-4 z-50 lg:hidden p-2 rounded-lg shadow-lg ${dir === 'rtl' ? 'right-4' : 'left-4'
                        }`}
                    style={{ backgroundColor: 'var(--sidebar-bg)', color: 'var(--sidebar-text)' }}
                    aria-label={t('common.toggleMenu', 'Toggle menu')}
                >
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        {sidebarOpen ? (
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        ) : (
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                        )}
                    </svg>
                </button>

                {/* Backdrop for mobile */}
                {sidebarOpen && (
                    <div
                        className="fixed inset-0 z-30 bg-black/50 lg:hidden"
                        onClick={() => setSidebarOpen(false)}
                    />
                )}

                {/* Sidebar: hidden on mobile unless open */}
                <div className={`fixed inset-y-0 left-0 z-40 transform transition-transform duration-200 ease-in-out lg:relative lg:translate-x-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
                    <Sidebar 
                        isCollapsed={sidebarCollapsed} 
                        onToggleCollapse={() => setSidebarCollapsed(!sidebarCollapsed)} 
                    />
                </div>

                <main className="flex-1 p-4 sm:p-6 lg:p-8 min-w-0 lg:ml-0 overflow-y-auto">
                    {/* Spacer for mobile menu button */}
                    <div className="h-10 lg:hidden" />
                    {children}
                </main>
            </div>
        </ViolationAlertsProvider>
    );
}
