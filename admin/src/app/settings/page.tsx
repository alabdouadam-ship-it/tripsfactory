'use client';

import { useState, useEffect, useMemo } from 'react';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';
import { useToast } from '@/lib/toast';
import {
    LogOut,
    User,
    Shield,
    AlertTriangle,
    Key,
    Palette,
    Languages,
    CaseSensitive,
    History,
    Globe2,
    MapPin,
    Monitor,
    Phone,
} from 'lucide-react';
import { useI18n, useT } from '@/lib/i18n';
import { AdminLocalizationConfig } from '@/lib/localizationConfig';
import { useTheme } from '@/lib/theme';
import { getAppSettings, updateAppSettings } from '@/app/actions/content-actions';
import { AppSettings } from '@/lib/types';

type AdminLoginEvent = {
    id: string;
    created_at: string;
    ip_address: string | null;
    country: string | null;
    user_agent: string | null;
    event_type: 'login' | 'logout';
};

export default function SettingsPage() {
    const router = useRouter();
    const { toast } = useToast();
    const { language, setLanguage } = useI18n();
    const { theme, setTheme, themes, fontSize, setFontSize, fontSizes } = useTheme();
    const [loading, setLoading] = useState(false);
    const [showPasswordModal, setShowPasswordModal] = useState(false);
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [email, setEmail] = useState<string | null>(null);
    const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
    const [checkDone, setCheckDone] = useState(false);
    const [loginEvents, setLoginEvents] = useState<AdminLoginEvent[]>([]);
    const [loginEventsLoading, setLoginEventsLoading] = useState(false);
    const [loginEventsError, setLoginEventsError] = useState<string | null>(null);
    const [loginTimeFilter, setLoginTimeFilter] = useState<'24h' | '7d' | '30d'>('24h');
    const [eventTypeFilter, setEventTypeFilter] = useState<'all' | 'login' | 'logout'>('all');
    
    // App settings state for support contact
    const [appSettings, setAppSettings] = useState<AppSettings | null>(null);
    const [appConfigLoading, setAppConfigLoading] = useState(false);
    const [appConfigDraft, setAppConfigDraft] = useState<Partial<AppSettings>>({});
    const [appConfigSaving, setAppConfigSaving] = useState(false);
    
    const t = useT();
    const locale = language === 'ar' ? 'ar' : 'en';
    const dateTimeFormatter = useMemo(() => new Intl.DateTimeFormat(locale, {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
    }), [locale]);
    const regionFormatter = useMemo(() => {
        if (typeof Intl.DisplayNames === 'undefined') return null;
        return new Intl.DisplayNames([locale], { type: 'region' });
    }, [locale]);
    const optionClass = (active: boolean) =>
        `rounded-lg border px-3 py-2 text-sm font-bold transition-colors ${active
            ? 'shadow-sm'
            : 'theme-bg-secondary theme-heading hover:border-blue-400'
        }`;
    const optionStyle = (active: boolean) => active
        ? {
            backgroundColor: 'var(--accent)',
            borderColor: 'var(--accent)',
            color: 'var(--accent-foreground)',
        }
        : undefined;

    useEffect(() => {
        getUser();
        loadAppConfig();
    }, []);

    useEffect(() => {
        if (isAdmin && email) {
            supabase.auth.getUser().then(({ data: { user } }) => {
                if (user) {
                    loadLoginEvents(user.id);
                }
            });
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [loginTimeFilter, eventTypeFilter, isAdmin, email]);

    async function getUser() {
        const { data: { user } } = await supabase.auth.getUser();
        setEmail(user?.email || 'Unknown');

        if (user) {
            const { data, error } = await supabase
                .from('profiles')
                .select('is_admin')
                .eq('id', user.id)
                .single();

            if (error) {
                toast(t('settings.errorLoadProfile', 'Could not load profile.'), 'error');
            } else {
                setIsAdmin(!!data?.is_admin);
                if (data?.is_admin) {
                    loadLoginEvents(user.id);
                }
            }
        }
        setCheckDone(true);
    }

    async function loadLoginEvents(adminId: string) {
        setLoginEventsLoading(true);
        setLoginEventsError(null);
        
        // Calculate the date threshold based on selected filter
        const now = new Date();
        let hoursAgo: number;
        switch (loginTimeFilter) {
            case '24h':
                hoursAgo = 24;
                break;
            case '7d':
                hoursAgo = 24 * 7;
                break;
            case '30d':
                hoursAgo = 24 * 30;
                break;
        }
        
        const threshold = new Date(now.getTime() - hoursAgo * 60 * 60 * 1000);
        
        let query = supabase
            .from('admin_login_events')
            .select('id, created_at, ip_address, country, user_agent, event_type')
            .eq('admin_id', adminId)
            .gte('created_at', threshold.toISOString());
        
        // Apply event type filter
        if (eventTypeFilter !== 'all') {
            query = query.eq('event_type', eventTypeFilter);
        }
        
        const { data, error } = await query
            .order('created_at', { ascending: false })
            .limit(100);

        if (error) {
            console.error('Failed to load admin login history:', error);
            setLoginEvents([]);
            setLoginEventsError(t('settings.loginHistory.error', 'Could not load login history.'));
        } else {
            setLoginEvents((data as AdminLoginEvent[]) || []);
        }
        setLoginEventsLoading(false);
    }

    function formatLoginDate(value: string) {
        return dateTimeFormatter.format(new Date(value));
    }

    function userAgentLabel(userAgent: string | null) {
        if (!userAgent) return t('settings.loginHistory.unknownDevice', 'Unknown device');
        if (userAgent.includes('Edg/')) return 'Microsoft Edge';
        if (userAgent.includes('Chrome/')) return 'Chrome';
        if (userAgent.includes('Firefox/')) return 'Firefox';
        if (userAgent.includes('Safari/')) return 'Safari';
        return userAgent.slice(0, 80);
    }

    function countryLabel(country: string | null) {
        if (!country) return t('settings.loginHistory.unknownCountry', 'Unknown country');
        if (!/^[A-Z]{2}$/.test(country) || !regionFormatter) return country;
        try {
            const countryName = regionFormatter.of(country);
            return countryName ? `${countryName} (${country})` : country;
        } catch {
            return country;
        }
    }

    async function handleSignOut() {
        setLoading(true);
        
        try {
            // Track logout event with IP and country (same as login)
            const { error: logoutHistoryError } = await supabase.rpc('record_admin_logout_event');
            if (logoutHistoryError) {
                console.warn('Failed to record admin logout event:', logoutHistoryError);
            }
        } catch (error) {
            console.error('Failed to track logout:', error);
            // Continue with logout even if tracking fails
        }
        
        await supabase.auth.signOut();
        router.push('/login');
        router.refresh();
    }

    async function handleChangePassword() {
        if (newPassword.length < 6) {
            toast(t('settings.password.tooShort'), 'error');
            return;
        }
        if (newPassword !== confirmPassword) {
            toast(t('settings.password.mismatch'), 'error');
            return;
        }
        setLoading(true);
        const { error } = await supabase.auth.updateUser({ password: newPassword });
        setLoading(false);
        if (error) {
            toast(error.message, 'error');
        } else {
            toast(t('settings.password.updated'), 'success');
            setShowPasswordModal(false);
            setNewPassword('');
            setConfirmPassword('');
        }
    }

    async function loadAppConfig() {
        setAppConfigLoading(true);
        const result = await getAppSettings();
        if (result.success) {
            setAppSettings(result.data);
            setAppConfigDraft({});
        } else {
            toast(t('settings.appConfig.loadError', 'Could not load app settings.'), 'error');
        }
        setAppConfigLoading(false);
    }

    function patchAppConfig<K extends keyof AppSettings>(key: K, value: AppSettings[K]) {
        setAppConfigDraft((prev) => ({ ...prev, [key]: value }));
    }

    function getAppConfig<K extends keyof AppSettings>(key: K): AppSettings[K] | undefined {
        if (key in appConfigDraft) return appConfigDraft[key] as AppSettings[K];
        return appSettings?.[key];
    }

    async function saveAppConfig() {
        if (Object.keys(appConfigDraft).length === 0) return;
        setAppConfigSaving(true);
        const result = await updateAppSettings(appConfigDraft);
        if (result.success) {
            toast(t('settings.appConfig.saved', 'Settings saved successfully.'), 'success');
            await loadAppConfig();
        } else {
            toast(result.error || t('settings.appConfig.saveError', 'Failed to save settings.'), 'error');
        }
        setAppConfigSaving(false);
    }

    const appConfigDirty = Object.keys(appConfigDraft).length > 0;

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-3xl font-bold theme-heading">
                {t('settings.title', 'Settings')}
            </h1>

            <div className="bg-[var(--surface)] rounded-xl shadow-sm border border-[var(--surface-border)] overflow-hidden">
                <div className="p-6 border-b border-[var(--surface-border)]">
                    <h2 className="text-lg font-bold theme-heading flex items-center gap-2">
                        <Palette className="h-5 w-5 text-blue-500" />
                        {t('settings.preferences', 'Language & Appearance')}
                    </h2>
                    <p className="text-sm theme-muted mt-1">
                        {t(
                            'settings.preferences.subtitle',
                            'Adjust the admin console language, theme, and text size.',
                        )}
                    </p>
                </div>
                <div className="p-6 space-y-6">
                    {AdminLocalizationConfig.supported.length > 1 && (
                    <div className="space-y-3">
                        <p className="text-sm font-bold theme-muted uppercase tracking-widest flex items-center gap-2">
                            <Languages className="h-4 w-4" />
                            {t('settings.language', 'Language')}
                        </p>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                            {AdminLocalizationConfig.supported.map((lang) => (
                                <button
                                    key={lang}
                                    type="button"
                                    aria-pressed={language === lang}
                                    onClick={() => setLanguage(lang)}
                                    className={optionClass(language === lang)}
                                    style={optionStyle(language === lang)}
                                >
                                    {lang === 'ar'
                                        ? t('settings.language.arabic', 'Arabic')
                                        : t('settings.language.english', 'English')}
                                </button>
                            ))}
                        </div>
                    </div>
                    )}

                    <div className="space-y-3">
                        <p className="text-sm font-bold theme-muted uppercase tracking-widest flex items-center gap-2">
                            <Palette className="h-4 w-4" />
                            {t('settings.theme', 'Theme')}
                        </p>
                        <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
                            {themes.map((themeOption) => {
                                const active = themeOption.id === theme;
                                return (
                                    <button
                                        key={themeOption.id}
                                        type="button"
                                        aria-pressed={active}
                                        onClick={() => setTheme(themeOption.id)}
                                        className={optionClass(active)}
                                        style={optionStyle(active)}
                                    >
                                        {language === 'ar'
                                            ? (themeOption.labelAr ?? themeOption.label)
                                            : themeOption.label}
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    <div className="space-y-3">
                        <p className="text-sm font-bold theme-muted uppercase tracking-widest flex items-center gap-2">
                            <CaseSensitive className="h-4 w-4" />
                            {t('settings.fontSize', 'Font Size')}
                        </p>
                        <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-2">
                            {fontSizes.map((sizeOption) => {
                                const active = sizeOption.id === fontSize;
                                return (
                                    <button
                                        key={sizeOption.id}
                                        type="button"
                                        aria-pressed={active}
                                        onClick={() => setFontSize(sizeOption.id)}
                                        className={optionClass(active)}
                                        style={optionStyle(active)}
                                    >
                                        {language === 'ar' ? sizeOption.labelAr : sizeOption.label}
                                    </button>
                                );
                            })}
                        </div>
                    </div>
                </div>
            </div>

            <div className="bg-[var(--surface)] rounded-xl shadow-sm border border-[var(--surface-border)] overflow-hidden">
                <div className="p-6 border-b border-[var(--surface-border)]">
                    <h2 className="text-lg font-bold theme-heading flex items-center gap-2">
                        <User className="h-5 w-5 text-blue-500" />
                        {t('settings.account', 'Account')}
                    </h2>
                </div>
                <div className="p-6 space-y-4">
                    <div className="flex items-center justify-between py-2">
                        <div>
                            <p className="text-sm font-bold theme-muted uppercase tracking-widest mb-0.5">
                                {t('settings.emailAddress', 'Email Address')}
                            </p>
                            <p className="theme-heading font-medium">{email}</p>
                        </div>
                        {checkDone && isAdmin !== null && (
                            <span className={`text-xs px-3 py-1 rounded-full font-medium flex items-center gap-1 ${isAdmin ? 'bg-blue-100 text-blue-800' : 'bg-red-100 text-red-800'}`}>
                                {isAdmin ? <Shield className="h-3 w-3" /> : <AlertTriangle className="h-3 w-3" />}
                                {isAdmin
                                    ? t('settings.role.admin', 'Admin')
                                    : t('settings.role.notAdmin', 'Not Admin')}
                            </span>
                        )}
                    </div>
                    {checkDone && isAdmin === false && (
                        <div className="bg-yellow-50 p-4 rounded-lg text-sm text-yellow-800 border border-yellow-200">
                            <p className="font-bold flex items-center gap-2">
                                <AlertTriangle className="h-4 w-4" />
                                {t('settings.accessRestricted', 'Access Restricted')}
                            </p>
                            <p className="mt-1">
                                {t(
                                    'settings.accessRestricted.body',
                                    'You are logged in, but your account is not marked as an Admin in the database. This is why you cannot see any data (Companies, Drivers, etc).',
                                )}
                            </p>
                            <p className="mt-2 font-mono text-xs bg-yellow-100 p-2 rounded">
                                Run the SQL script below in Supabase to fix this.
                            </p>
                        </div>
                    )}
                    <div className="flex items-center justify-between py-2 border-t border-[var(--surface-border)] pt-4">
                        <div>
                            <p className="text-sm font-bold theme-muted uppercase tracking-widest mb-0.5">
                                {t('settings.passwordSecurity', 'Security')}
                            </p>
                            <p className="theme-heading">
                                {t(
                                    'settings.passwordSecurity',
                                    'Password & Authentication',
                                )}
                            </p>
                        </div>
                        <button
                            onClick={() => setShowPasswordModal(true)}
                            className="text-blue-600 hover:text-blue-700 text-sm font-medium flex items-center gap-1"
                        >
                            <Key className="h-4 w-4" />{' '}
                            {t('settings.changePassword', 'Change Password')}
                        </button>
                    </div>
                </div>
            </div>

            {showPasswordModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
                    <div className="bg-[var(--surface)] border border-[var(--surface-border)] rounded-2xl shadow-2xl p-6 max-w-md w-full mx-4 overflow-hidden">
                        <h3 className="text-xl font-black theme-heading mb-4">
                            {t('settings.changePassword.title', 'Change Password')}
                        </h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-xs font-bold theme-muted uppercase tracking-widest mb-1.5">
                                    {t(
                                        'settings.changePassword.new',
                                        'New Password',
                                    )}
                                </label>
                                <input
                                    type="password"
                                    value={newPassword}
                                    onChange={(e) => setNewPassword(e.target.value)}
                                    className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500/50 outline-none transition"
                                    placeholder={t('settings.placeholder.passwordMin')}
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-bold theme-muted uppercase tracking-widest mb-1.5">
                                    {t(
                                        'settings.changePassword.confirm',
                                        'Confirm Password',
                                    )}
                                </label>
                                <input
                                    type="password"
                                    value={confirmPassword}
                                    onChange={(e) => setConfirmPassword(e.target.value)}
                                    className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500/50 outline-none transition"
                                    placeholder={t('settings.placeholder.confirmPassword')}
                                />
                            </div>
                        </div>
                        <div className="flex gap-3 mt-8 justify-end">
                            <button
                                onClick={() => { setShowPasswordModal(false); setNewPassword(''); setConfirmPassword(''); }}
                                className="px-4 py-2 rounded-xl border border-[var(--surface-border)] theme-muted hover:theme-heading font-bold transition"
                            >
                                {t('common.cancel')}
                            </button>
                            <button
                                onClick={handleChangePassword}
                                disabled={loading}
                                className="px-6 py-2.5 rounded-xl bg-blue-600 text-white font-bold hover:bg-blue-700 disabled:opacity-50 shadow-sm transition"
                            >
                                {loading
                                    ? t(
                                        'settings.changePassword.updating',
                                        'Updating...',
                                    )
                                    : t(
                                        'settings.changePassword.update',
                                        'Update Password',
                                    )}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            <div className="bg-[var(--surface)] rounded-xl shadow-sm border border-[var(--surface-border)] overflow-hidden">
                <div className="p-6">
                    <button
                        onClick={handleSignOut}
                        disabled={loading}
                        className="flex items-center justify-center gap-2 w-full sm:w-auto bg-red-50 text-red-700 hover:bg-red-100 px-6 py-3 rounded-lg font-medium transition-colors"
                    >
                        <LogOut className="h-5 w-5" />
                        {loading
                            ? t('settings.signingOut', 'Signing out...')
                            : t('settings.signOut', 'Sign Out')}
                    </button>
                </div>
            </div>

            <div className="bg-[var(--surface)] rounded-xl shadow-sm border border-[var(--surface-border)] overflow-hidden">
                <div className="p-6 border-b border-[var(--surface-border)]">
                    <h2 className="text-lg font-bold theme-heading flex items-center gap-2">
                        <Phone className="h-5 w-5 text-blue-500" />
                        {t('settings.supportContact', 'Support Contact')}
                    </h2>
                    <p className="text-sm theme-muted mt-1">
                        {t(
                            'settings.supportContact.subtitle',
                            'Configure the WhatsApp support number shown to users.',
                        )}
                    </p>
                </div>
                <div className="p-6">
                    {appConfigLoading ? (
                        <p className="text-sm theme-muted">{t('common.loading', 'Loading...')}</p>
                    ) : (
                        <div className="space-y-4">
                            <div>
                                <label className="block text-xs font-bold theme-muted uppercase tracking-widest mb-1.5">
                                    {t('settings.supportContact.whatsapp', 'WhatsApp Number')}
                                </label>
                                <input
                                    type="text"
                                    value={getAppConfig('support_whatsapp') ?? ''}
                                    onChange={(e) => patchAppConfig('support_whatsapp', e.target.value || null)}
                                    className="w-full theme-bg-secondary border border-[var(--surface-border)] rounded-xl px-4 py-2.5 text-sm theme-heading focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500/50 outline-none transition"
                                    placeholder={t('settings.supportContact.whatsappPlaceholder', 'e.g., +1234567890')}
                                />
                                <p className="text-xs theme-muted mt-1.5">
                                    {t(
                                        'settings.supportContact.whatsappHelp',
                                        'Include country code (e.g., +1234567890). This number will be shown to users for support.',
                                    )}
                                </p>
                            </div>
                            {appConfigDirty && (
                                <div className="flex justify-end">
                                    <button
                                        onClick={saveAppConfig}
                                        disabled={appConfigSaving}
                                        className="px-6 py-2.5 rounded-xl bg-blue-600 text-white font-bold hover:bg-blue-700 disabled:opacity-50 shadow-sm transition"
                                    >
                                        {appConfigSaving
                                            ? t('common.saving', 'Saving...')
                                            : t('common.save', 'Save')}
                                    </button>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>

            <div className="bg-[var(--surface)] rounded-xl shadow-sm border border-[var(--surface-border)] overflow-hidden">
                <div className="p-6 border-b border-[var(--surface-border)]">
                    <div className="flex flex-col gap-4">
                        <div>
                            <h2 className="text-lg font-bold theme-heading flex items-center gap-2">
                                <History className="h-5 w-5 text-blue-500" />
                                {t('settings.loginHistory', 'Recent Admin Activity')}
                            </h2>
                            <p className="text-sm theme-muted mt-1">
                                {t(
                                    'settings.loginHistory.subtitle',
                                    'Recent login and logout events for this admin account.',
                                )}
                            </p>
                        </div>
                        <div className="flex flex-col sm:flex-row gap-3">
                            <div className="flex gap-2">
                                <button
                                    type="button"
                                    onClick={() => setLoginTimeFilter('24h')}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest transition ${
                                        loginTimeFilter === '24h'
                                            ? 'bg-blue-600 text-white shadow-sm'
                                            : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                                    }`}
                                >
                                    {t('settings.loginHistory.filter.24h', '24 Hours')}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setLoginTimeFilter('7d')}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest transition ${
                                        loginTimeFilter === '7d'
                                            ? 'bg-blue-600 text-white shadow-sm'
                                            : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                                    }`}
                                >
                                    {t('settings.loginHistory.filter.7d', '7 Days')}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setLoginTimeFilter('30d')}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest transition ${
                                        loginTimeFilter === '30d'
                                            ? 'bg-blue-600 text-white shadow-sm'
                                            : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                                    }`}
                                >
                                    {t('settings.loginHistory.filter.30d', '30 Days')}
                                </button>
                            </div>
                            <div className="flex gap-2">
                                <button
                                    type="button"
                                    onClick={() => setEventTypeFilter('all')}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest transition ${
                                        eventTypeFilter === 'all'
                                            ? 'bg-gray-600 text-white shadow-sm'
                                            : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                                    }`}
                                >
                                    {t('settings.loginHistory.filter.all', 'All')}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setEventTypeFilter('login')}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest transition ${
                                        eventTypeFilter === 'login'
                                            ? 'bg-green-600 text-white shadow-sm'
                                            : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                                    }`}
                                >
                                    {t('settings.loginHistory.filter.logins', 'Logins')}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setEventTypeFilter('logout')}
                                    className={`px-3 py-1.5 rounded-lg text-xs font-black uppercase tracking-widest transition ${
                                        eventTypeFilter === 'logout'
                                            ? 'bg-red-600 text-white shadow-sm'
                                            : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                                    }`}
                                >
                                    {t('settings.loginHistory.filter.logouts', 'Logouts')}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
                <div className="p-6">
                    {loginEventsLoading ? (
                        <p className="text-sm theme-muted">{t('common.loading', 'Loading...')}</p>
                    ) : loginEventsError ? (
                        <div className="rounded-xl border border-red-500/20 bg-red-500/10 p-4 text-sm font-bold text-red-600">
                            {loginEventsError}
                        </div>
                    ) : loginEvents.length === 0 ? (
                        <div className="rounded-xl border border-dashed border-[var(--surface-border)] p-6 text-center">
                            <History className="mx-auto mb-3 h-8 w-8 theme-muted opacity-40" />
                            <p className="text-sm font-bold theme-muted">
                                {t('settings.loginHistory.empty', 'No activity recorded in this time period.')}
                            </p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-black uppercase tracking-widest theme-muted">
                                    {t('settings.loginHistory.showing', 'Showing {count} event(s)')
                                        .replace('{count}', String(loginEvents.length))}
                                </p>
                            </div>
                            <div className="space-y-3">
                            {loginEvents.map((event) => {
                                const isLogin = event.event_type === 'login';
                                return (
                                <div
                                    key={event.id}
                                    className="grid gap-3 rounded-xl border theme-bg-secondary p-4 md:grid-cols-[auto_1.2fr_1fr_1fr_1.2fr]"
                                    style={{
                                        borderColor: isLogin ? 'rgb(34 197 94 / 0.3)' : 'rgb(239 68 68 / 0.3)',
                                    }}
                                >
                                    <div className="flex items-center">
                                        <span
                                            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-black uppercase tracking-widest ${
                                                isLogin
                                                    ? 'bg-green-100 text-green-800 border border-green-300'
                                                    : 'bg-red-100 text-red-800 border border-red-300'
                                            }`}
                                        >
                                            {isLogin ? '✓' : '✕'}
                                            {isLogin
                                                ? t('settings.loginHistory.login', 'Login')
                                                : t('settings.loginHistory.logout', 'Logout')}
                                        </span>
                                    </div>
                                    <div>
                                        <p className="text-[0.625rem] font-black uppercase tracking-widest theme-muted">
                                            {t('settings.loginHistory.time', 'Time')}
                                        </p>
                                        <p className="mt-1 text-sm font-bold theme-heading">{formatLoginDate(event.created_at)}</p>
                                    </div>
                                    <div>
                                        <p className="text-[0.625rem] font-black uppercase tracking-widest theme-muted flex items-center gap-1.5">
                                            <Globe2 className="h-3.5 w-3.5" />
                                            {t('settings.loginHistory.ip', 'IP')}
                                        </p>
                                        <p className="mt-1 font-mono text-sm theme-heading">
                                            {event.ip_address || t('settings.loginHistory.unknownIp', 'Unknown IP')}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-[0.625rem] font-black uppercase tracking-widest theme-muted flex items-center gap-1.5">
                                            <MapPin className="h-3.5 w-3.5" />
                                            {t('settings.loginHistory.country', 'Country')}
                                        </p>
                                        <p className="mt-1 text-sm font-bold theme-heading">
                                            {countryLabel(event.country)}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-[0.625rem] font-black uppercase tracking-widest theme-muted flex items-center gap-1.5">
                                            <Monitor className="h-3.5 w-3.5" />
                                            {t('settings.loginHistory.device', 'Device')}
                                        </p>
                                        <p className="mt-1 truncate text-sm font-medium theme-heading" title={event.user_agent || undefined}>
                                            {userAgentLabel(event.user_agent)}
                                        </p>
                                    </div>
                                </div>
                            )})}
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
