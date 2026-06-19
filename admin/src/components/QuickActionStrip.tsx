'use client';

import React from 'react';
import {
    ShieldAlert
} from 'lucide-react';
import { useI18n } from '@/lib/i18n';
import { cn } from '@/lib/utils';

interface QuickAction {
    label: string;
    icon: any;
    onClick: () => void;
    variant?: 'danger' | 'warning' | 'primary' | 'ghost';
    shortcut?: string;
}

interface QuickActionStripProps {
    actions: QuickAction[];
}

export function QuickActionStrip({ actions }: QuickActionStripProps) {
    const { t } = useI18n();

    return (
        <div className="flex items-center gap-2 p-2 bg-gray-900 rounded-2xl shadow-xl border border-white/10 mb-6 sticky top-4 z-30 animate-in slide-in-from-top-4 duration-300 text-left">
            <div className="flex items-center px-4 border-r border-white/10 mr-2">
                <ShieldAlert className="h-4 w-4 text-orange-500 mr-2" />
                <span className="text-[0.625rem] font-black text-white uppercase tracking-widest">{t('common.commandBar')}</span>
            </div>

            <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar">
                {actions.map((action, i) => (
                    <button
                        key={i}
                        onClick={action.onClick}
                        title={action.shortcut ? `${t('common.shortcut')}: ${action.shortcut}` : undefined}
                        className={cn(
                            "flex items-center gap-2 px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest transition-all whitespace-nowrap group",
                            action.variant === 'danger' && "bg-red-500/10 text-red-500 hover:bg-red-500 hover:text-white",
                            action.variant === 'warning' && "bg-orange-500/10 text-orange-500 hover:bg-orange-500 hover:text-white",
                            action.variant === 'primary' && "bg-blue-500/10 text-blue-500 hover:bg-blue-500 hover:text-white",
                            (!action.variant || action.variant === 'ghost') && "text-gray-400 hover:bg-white/5 hover:text-white"
                        )}
                    >
                        <action.icon className="h-3.5 w-3.5 group-hover:scale-110 transition-transform" />
                        {action.label}
                        {action.shortcut && (
                            <span className="ml-1 opacity-40 text-[0.5rem] font-medium border border-current px-1 rounded">
                                {action.shortcut}
                            </span>
                        )}
                    </button>
                ))}
            </div>
        </div>
    );
}
