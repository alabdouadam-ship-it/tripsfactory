'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
    Search, Terminal, User,
    Package, Shield, HelpCircle,
    ArrowRight
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import { cn } from '@/lib/utils';
import { useT } from '@/lib/i18n';

interface Command {
    id: string;
    label: string;
    icon: any;
    action: () => void;
    category: 'navigation' | 'actions' | 'support';
}

export function CommandPalette() {
    const [isOpen, setIsOpen] = useState(false);
    const [query, setQuery] = useState('');
    const [selectedIndex, setSelectedIndex] = useState(0);
    const router = useRouter();
    const inputRef = useRef<HTMLInputElement>(null);
    const t = useT();

    const commands: Command[] = [
        { id: 'nav-users', label: t('commandPalette.cmd.users', 'Go to Users'), icon: User, action: () => router.push('/users'), category: 'navigation' },
        { id: 'nav-bookings', label: t('commandPalette.cmd.bookings', 'Go to Bookings'), icon: Package, action: () => router.push('/bookings'), category: 'navigation' },
        { id: 'nav-verification', label: t('commandPalette.cmd.verification', 'Go to Verification Center'), icon: Shield, action: () => router.push('/verification'), category: 'navigation' },
        { id: 'action-search', label: t('commandPalette.cmd.search', 'Quick Search'), icon: Search, action: () => { setIsOpen(false); /* Focus global search logic */ }, category: 'actions' },
        { id: 'help', label: t('commandPalette.cmd.help', 'Admin Documentation'), icon: HelpCircle, action: () => window.open('https://docs.tripship.app', '_blank'), category: 'support' },
    ];

    const filteredCommands = commands.filter(cmd =>
        cmd.label.toLowerCase().includes(query.toLowerCase())
    );

    useEffect(() => {
        setSelectedIndex(prev => {
            if (filteredCommands.length === 0) return 0;
            return Math.min(prev, filteredCommands.length - 1);
        });
    }, [filteredCommands.length]);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
                e.preventDefault();
                setIsOpen(prev => !prev);
            }
            if (e.key === 'Escape') setIsOpen(false);
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, []);

    useEffect(() => {
        if (isOpen) {
            setTimeout(() => inputRef.current?.focus(), 10);
            setSelectedIndex(0);
        }
    }, [isOpen]);

    const handleSelect = (cmd?: Command) => {
        if (!cmd) return;
        cmd.action();
        setIsOpen(false);
        setQuery('');
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-start justify-center pt-[15vh] px-4 backdrop-blur-sm bg-black/40 animate-in fade-in duration-200">
            <div className="w-full max-w-2xl bg-gray-900 border border-white/10 rounded-3xl shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
                <div className="flex items-center gap-3 px-6 py-5 border-b border-white/10">
                    <Terminal className="h-5 w-5 text-orange-500" />
                    <input
                        ref={inputRef}
                        type="text"
                        placeholder={t('commandPalette.placeholder', 'Type a command or search...')}
                        className="flex-1 bg-transparent border-none text-white focus:ring-0 placeholder-gray-500 text-sm font-medium"
                        value={query}
                        onChange={(e) => setQuery(e.target.value)}
                        onKeyDown={(e) => {
                            if (e.key === 'ArrowDown') {
                                e.preventDefault();
                                if (filteredCommands.length === 0) return;
                                setSelectedIndex(prev => (prev + 1) % filteredCommands.length);
                            }
                            if (e.key === 'ArrowUp') {
                                e.preventDefault();
                                if (filteredCommands.length === 0) return;
                                setSelectedIndex(prev => (prev - 1 + filteredCommands.length) % filteredCommands.length);
                            }
                            if (e.key === 'Enter') {
                                e.preventDefault();
                                handleSelect(filteredCommands[selectedIndex]);
                            }
                        }}
                    />
                    <kbd className="hidden sm:block px-2 py-0.5 rounded-lg bg-white/5 border border-white/10 text-[0.625rem] text-gray-400 font-bold tracking-widest">
                        ESC
                    </kbd>
                </div>

                <div className="max-h-[60vh] overflow-y-auto py-2 scrollbar-thin">
                    {filteredCommands.length > 0 ? (
                        filteredCommands.map((cmd, i) => (
                            <button
                                key={cmd.id}
                                className={cn(
                                    "w-full flex items-center justify-between px-6 py-4 text-left transition-colors group",
                                    i === selectedIndex ? "bg-white/5" : "hover:bg-white/5"
                                )}
                                onClick={() => handleSelect(cmd)}
                            >
                                <div className="flex items-center gap-4">
                                    <div className={cn(
                                        "p-2 rounded-xl transition-colors",
                                        i === selectedIndex ? "bg-orange-500 text-white" : "bg-white/5 text-gray-400"
                                    )}>
                                        <cmd.icon className="h-4 w-4" />
                                    </div>
                                    <div>
                                        <p className="text-sm font-bold text-white tracking-tight">{cmd.label}</p>
                                        <p className="text-[0.625rem] font-black text-gray-500 uppercase tracking-widest mt-0.5">{t(`commandPalette.cat.${cmd.category}`, cmd.category)}</p>
                                    </div>
                                </div>
                                <ArrowRight className={cn(
                                    "h-4 w-4 text-orange-500 transition-opacity",
                                    i === selectedIndex ? "opacity-100" : "opacity-0"
                                )} />
                            </button>
                        ))
                    ) : (
                        <div className="py-12 text-center">
                            <p className="text-sm text-gray-500 font-medium tracking-tight">{t('commandPalette.empty', 'No commands found for "{query}"').replace('{query}', query)}</p>
                        </div>
                    )}
                </div>

                <div className="px-6 py-4 border-t border-white/10 bg-black/20 flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <div className="flex items-center gap-1">
                            <kbd className="px-1.5 py-0.5 rounded-md bg-white/5 border border-white/10 text-[0.5rem] text-gray-400 font-bold">↵</kbd>
                            <span className="text-[0.625rem] text-gray-500 font-medium">{t('commandPalette.action.select', 'Select')}</span>
                        </div>
                        <div className="flex items-center gap-1">
                            <kbd className="px-1.5 py-0.5 rounded-md bg-white/5 border border-white/10 text-[0.5rem] text-gray-400 font-bold">↑↓</kbd>
                            <span className="text-[0.625rem] text-gray-500 font-medium">{t('commandPalette.action.navigate', 'Navigate')}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
