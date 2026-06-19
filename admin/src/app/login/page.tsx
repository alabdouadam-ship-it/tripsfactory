'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';
import { useT } from '@/lib/i18n';
import { Eye, EyeOff } from 'lucide-react';

const LAST_ADMIN_EMAIL_KEY = 'tripship.admin.lastEmail';

export default function LoginPage() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const router = useRouter();
    const t = useT();
    const passwordToggleLabel = showPassword
        ? t('login.hidePassword', 'Hide password')
        : t('login.showPassword', 'Show password');

    useEffect(() => {
        try {
            const lastEmail = window.localStorage.getItem(LAST_ADMIN_EMAIL_KEY);
            if (lastEmail) setEmail(lastEmail);
        } catch {
            // Local storage can be unavailable in private or restricted browser modes.
        }
    }, []);

    async function handleLogin(e: React.FormEvent) {
        e.preventDefault();
        setLoading(true);
        setError(null);

        try {
            // 1. Sign in
            const { data: { session }, error: authError } = await supabase.auth.signInWithPassword({
                email,
                password,
            });

            if (authError) throw authError;
            if (!session) throw new Error('No session');

            // 2. Check is_admin
            const { data: profile, error: profileError } = await supabase
                .from('profiles')
                .select('is_admin')
                .eq('id', session.user.id)
                .single();

            if (profileError) throw profileError;

            if (!profile?.is_admin) {
                await supabase.auth.signOut();
                throw new Error('Access denied. Admins only.');
            }

            const { error: loginHistoryError } = await supabase.rpc('record_admin_login_event');
            if (loginHistoryError) {
                console.warn('Failed to record admin login event:', loginHistoryError);
            }

            try {
                window.localStorage.setItem(LAST_ADMIN_EMAIL_KEY, email.trim());
            } catch {
                // This preference is convenience-only; login should not depend on it.
            }

            // 3. Redirect
            router.push('/');
            router.refresh();

        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : String(err ?? 'Unknown error'));
        } finally {
            setLoading(false);
        }
    }

    return (
        <div className="flex min-h-screen items-center justify-center bg-[var(--surface)]">
            <div className="w-full max-w-md space-y-8 rounded-3xl theme-card p-10 shadow-2xl border border-[var(--surface-border)]">
                <div className="text-center">
                    <h2 className="text-4xl font-black theme-heading tracking-tight italic uppercase">
                        {t('login.title', 'TripShip Admin')}
                    </h2>
                    <p className="mt-2 text-[0.625rem] font-black theme-muted uppercase tracking-widest opacity-60">
                        {t('login.subtitle', 'Sign in to access dashboard')}
                    </p>
                </div>

                <form className="mt-8 space-y-6" onSubmit={handleLogin}>
                    {error && (
                        <div className="bg-red-500/10 text-red-600 border border-red-500/20 p-4 rounded-xl text-[0.625rem] font-black uppercase tracking-widest shadow-sm">
                            {error}
                        </div>
                    )}

                    <div className="space-y-4 rounded-xl overflow-hidden">
                        <div>
                            <input
                                type="email"
                                required
                                className="relative block w-full theme-bg-secondary border border-[var(--surface-border)] py-3 px-4 theme-heading font-medium text-sm focus:ring-2 focus:ring-blue-600/20 focus:outline-none transition-all placeholder:opacity-30"
                                placeholder={t('login.email', 'Email address')}
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                            />
                        </div>
                        <div className="relative">
                            <input
                                type={showPassword ? 'text' : 'password'}
                                required
                                className="relative block w-full theme-bg-secondary border border-[var(--surface-border)] py-3 px-4 theme-heading font-medium text-sm focus:ring-2 focus:ring-blue-600/20 focus:outline-none transition-all placeholder:opacity-30"
                                placeholder={t('login.password', 'Password')}
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                autoComplete="current-password"
                                style={{ paddingInlineEnd: '3rem' }}
                            />
                            <button
                                type="button"
                                aria-label={passwordToggleLabel}
                                title={passwordToggleLabel}
                                aria-pressed={showPassword}
                                className="absolute top-1/2 -translate-y-1/2 rounded-lg p-1.5 theme-muted transition-all hover:theme-heading hover:theme-bg-secondary focus:outline-none focus:ring-2 focus:ring-blue-600/20"
                                style={{ insetInlineEnd: '0.75rem' }}
                                onClick={() => setShowPassword((current) => !current)}
                            >
                                {showPassword ? (
                                    <EyeOff className="h-4 w-4" aria-hidden="true" />
                                ) : (
                                    <Eye className="h-4 w-4" aria-hidden="true" />
                                )}
                            </button>
                        </div>
                    </div>

                    <div>
                        <button
                            type="submit"
                            disabled={loading}
                            className="group relative flex w-full justify-center rounded-2xl bg-blue-600 hover:bg-blue-700 px-4 py-4 text-[0.625rem] font-black text-white uppercase tracking-widest transition-all shadow-xl shadow-blue-600/20 active:scale-95 disabled:opacity-50"
                        >
                            {loading
                                ? t('login.submitting', 'Signing in...')
                                : t('login.submit', 'Sign in')}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
