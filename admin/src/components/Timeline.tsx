'use client';

import React from 'react';
import { useT } from '@/lib/i18n';

export function TimelineStep({ done, label, ts }: { done: boolean; label: string; ts?: string | null }) {
    const t = useT();
    return (
        <div className="flex flex-col items-center group cursor-help min-w-[30px]" title={ts ? new Date(ts).toLocaleString() : t('common.notYet', 'Not yet')}>
            <div className={`h-2.5 w-2.5 rounded-full ring-4 ring-[var(--surface)] ${done ? 'bg-blue-600' : 'theme-bg-secondary'}`} />
            <span className={`text-[0.5rem] mt-1 font-black uppercase tracking-widest ${done ? 'text-blue-600' : 'theme-muted opacity-30'}`}>{label}</span>
            {ts && <span className="text-[0.4375rem] font-bold theme-muted opacity-0 group-hover:opacity-100 transition-opacity absolute mt-6 theme-card shadow-xl border border-[var(--surface-border)] px-1.5 py-0.5 rounded pointer-events-none z-10">{new Date(ts).toLocaleDateString()}</span>}
        </div>
    );
}

export function TimelineConnector({ done }: { done?: boolean }) {
    return <div className={`flex-1 h-0.5 mx-1 rounded-full ${done ? 'bg-blue-500/30' : 'theme-bg-secondary opacity-50'}`} />;
}
