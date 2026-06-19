'use client';

import dynamic from 'next/dynamic';
import { useMemo } from 'react';
import { useT } from '@/lib/i18n';

export default function MapPage() {
    const t = useT();
    const Map = useMemo(() => dynamic(
        () => import('./MapComponent'),
        {
            loading: () => <div className="h-full w-full flex items-center justify-center theme-bg-secondary rounded-xl font-black text-[0.625rem] theme-muted uppercase tracking-widest opacity-60">{t('map.loadingEngine', 'Loading Map Engine...')}</div>,
            ssr: false
        }
    ), [t]);

    return (
        <div className="h-[calc(100vh-120px)] min-h-[520px] w-full rounded-2xl overflow-hidden shadow-xl border border-[var(--surface-border)]">
            <Map />
        </div>
    );
}
