'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import {
    LayoutDashboard,
    Users,
    Truck,
    MessageSquare,
    Settings,
    Map,
    Route,
    Star,
    FileText,
    Flag,
    MapPin,
    Bell,
    ClipboardList,
    ShieldCheck,
    Megaphone,
    HeadphonesIcon,
    UserCheck,
    LogOut,
    Scale,
    ShieldAlert,
    TrendingUp,
    Globe,
    ChevronLeft,
    ChevronRight,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n, useT } from '@/lib/i18n';
import { useViolationAlerts } from '@/lib/violation-alerts';

const navigationSections: Array<{
    key?: string;
    items: { key: string; href: string; icon: any }[];
}> = [
    {
        items: [
            { key: 'nav.dashboard', href: '/', icon: LayoutDashboard },
            { key: 'nav.analytics', href: '/analytics', icon: TrendingUp },
        ],
    },
    {
        key: 'nav.section.trustRisk',
        items: [
            { key: 'nav.founder', href: '/founder', icon: ShieldAlert },
            { key: 'nav.moderation', href: '/moderation', icon: Scale },
            { key: 'nav.reports', href: '/reports', icon: Flag },
        ],
    },
    {
        key: 'nav.section.accounts',
        items: [
            { key: 'nav.users', href: '/users', icon: Users },
            { key: 'nav.drivers', href: '/drivers', icon: Truck },
            { key: 'nav.verification', href: '/verification', icon: UserCheck },
            { key: 'nav.documents', href: '/documents', icon: FileText },
        ],
    },
    {
        key: 'nav.section.operations',
        items: [
            { key: 'nav.trips', href: '/trips', icon: Route },
            { key: 'nav.bookings', href: '/bookings', icon: MessageSquare },
        ],
    },
    {
        key: 'nav.section.supportContent',
        items: [
            { key: 'nav.reviews', href: '/reviews', icon: Star },
            { key: 'nav.support', href: '/support', icon: HeadphonesIcon },
            { key: 'nav.notifications', href: '/notifications', icon: Bell },
            { key: 'nav.ads', href: '/ads', icon: Megaphone },
            { key: 'nav.content', href: '/in-app-messages', icon: Globe },
        ],
    },
    {
        key: 'nav.section.platform',
        items: [
            { key: 'nav.locations', href: '/locations', icon: MapPin },
            { key: 'nav.map', href: '/map', icon: Map },
            { key: 'nav.auditLog', href: '/audit-log', icon: ClipboardList },
            { key: 'nav.settings', href: '/settings', icon: Settings },
        ],
    },
];

export function Sidebar({ isCollapsed = false, onToggleCollapse }: { isCollapsed?: boolean; onToggleCollapse?: () => void }) {
    const pathname = usePathname();
    const router = useRouter();
    const [userEmail, setUserEmail] = useState<string | null>(null);
    const { dir } = useI18n();
    const t = useT();
    const { counts } = useViolationAlerts();

    const badgeFor = (href: string): number => {
        if (href === '/reports') return counts.openReports;
        if (href === '/trips') return counts.pendingTrips;
        return 0;
    };

    useEffect(() => {
        supabase.auth.getUser()
            .then(async ({ data: { user } }) => {
                setUserEmail(user?.email ?? null);
            })
            .catch(() => {
                setUserEmail(null);
            });
    }, []);

    async function handleLogout() {
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

    const filteredNavigationSections = navigationSections;

    return (
        <div
            className={cn(
                "flex h-screen flex-col border-r flex-shrink-0 transition-all duration-300",
                isCollapsed ? "w-16" : "w-64"
            )}
            style={{
                backgroundColor: 'var(--sidebar-bg)',
                color: 'var(--sidebar-text)',
                borderColor: 'var(--sidebar-border)',
            }}
            dir={dir}
        >
            <div className="flex h-16 items-center px-6 flex-shrink-0 justify-between">
                {!isCollapsed && (
                    <h1 className="text-2xl font-bold" style={{ color: 'var(--accent)' }}>
                        {t('sidebar.title', 'TripsFactory Admin')}
                    </h1>
                )}
                {onToggleCollapse && (
                    <button
                        onClick={onToggleCollapse}
                        className="hidden lg:flex items-center justify-center w-8 h-8 rounded-lg hover:bg-opacity-10 hover:bg-white transition-colors"
                        style={{ color: 'var(--sidebar-muted)' }}
                        title={isCollapsed ? t('sidebar.expand', 'Expand sidebar') : t('sidebar.collapse', 'Collapse sidebar')}
                    >
                        {dir === 'rtl' ? (
                            isCollapsed ? <ChevronRight className="h-5 w-5" /> : <ChevronLeft className="h-5 w-5" />
                        ) : (
                            isCollapsed ? <ChevronRight className="h-5 w-5" /> : <ChevronLeft className="h-5 w-5" />
                        )}
                    </button>
                )}
            </div>
            <nav className="flex-1 space-y-0.5 px-2 py-3 overflow-y-auto scrollbar-thin">
                {filteredNavigationSections.map((section, sectionIndex) => (
                    <div
                        key={section.key ?? `section-${sectionIndex}`}
                        className={cn(
                            sectionIndex > 0 && 'mt-3 border-t pt-3'
                        )}
                        style={{ borderColor: 'var(--sidebar-border)' }}
                    >
                        {section.key && !isCollapsed && (
                            <p
                                className="px-2 pb-1 text-[0.625rem] font-black uppercase tracking-widest"
                                style={{ color: 'var(--sidebar-muted)' }}
                            >
                                {t(section.key, section.key)}
                            </p>
                        )}
                        {section.items.map((item) => {
                            const isActive = item.href === '/'
                                ? pathname === '/'
                                : pathname === item.href || pathname.startsWith(`${item.href}/`);
                            const badge = badgeFor(item.href);
                            return (
                                <Link
                                    key={item.key}
                                    href={item.href}
                                    className={cn(
                                        'group flex items-center rounded-md px-2 py-2 text-sm font-medium transition-colors',
                                        isActive ? '' : 'hover:opacity-90',
                                        isCollapsed && 'justify-center'
                                    )}
                                    style={{
                                        backgroundColor: isActive ? 'var(--sidebar-active)' : 'transparent',
                                        color: isActive ? 'var(--sidebar-text)' : 'var(--sidebar-muted)',
                                    }}
                                    title={isCollapsed ? t(item.key, item.key) : undefined}
                                >
                                    <item.icon
                                        className={cn(
                                            'h-5 w-5 group-hover:opacity-100',
                                            !isCollapsed && (dir === 'rtl' ? 'ml-3' : 'mr-3')
                                        )}
                                        style={{ color: isActive ? 'var(--accent)' : 'inherit' }}
                                    />
                                    {!isCollapsed && (
                                        <>
                                            <span className="truncate flex-1">
                                                {t(item.key, item.key)}
                                            </span>
                                            {badge > 0 && (
                                                <span
                                                    className={cn(
                                                        'inline-flex items-center justify-center min-w-[1.25rem] h-5 px-1.5 rounded-full text-[0.625rem] font-black bg-red-600 text-white',
                                                        dir === 'rtl' ? 'mr-2' : 'ml-2'
                                                    )}
                                                    title={t('alerts.pendingItems', 'Pending items')}
                                                >
                                                    {badge > 99 ? '99+' : badge}
                                                </span>
                                            )}
                                        </>
                                    )}
                                    {isCollapsed && badge > 0 && (
                                        <span className="absolute top-1 right-1 w-2 h-2 bg-red-600 rounded-full" />
                                    )}
                                </Link>
                            );
                        })}
                    </div>
                ))}
            </nav>
            <div
                className="border-t p-4 space-y-3"
                style={{ borderColor: 'var(--sidebar-border)' }}
            >
                {!isCollapsed && (
                    <div className="flex items-center justify-between">
                        <div className={cn('min-w-0 flex-1', dir === 'rtl' ? 'mr-3 text-right' : 'ml-3')}>
                            <p className="text-sm font-medium truncate" style={{ color: 'var(--sidebar-text)' }}>
                                {t('sidebar.adminUser', 'Admin User')}
                            </p>
                            <p className="text-xs truncate" style={{ color: 'var(--sidebar-muted)' }}>
                                {userEmail ?? t('common.loading', 'Loading...')}
                            </p>
                        </div>
                    </div>
                )}

                <button
                    onClick={handleLogout}
                    className={cn(
                        "w-full flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition-colors border",
                        isCollapsed && "justify-center"
                    )}
                    style={{
                        color: 'var(--sidebar-muted)',
                        backgroundColor: 'var(--sidebar-hover)',
                        borderColor: 'var(--sidebar-border)',
                    }}
                    title={isCollapsed ? t('sidebar.logout', 'Log out') : undefined}
                >
                    <LogOut className="h-4 w-4" />
                    {!isCollapsed && t('sidebar.logout', 'Log out')}
                </button>
            </div>
        </div>
    );
}
