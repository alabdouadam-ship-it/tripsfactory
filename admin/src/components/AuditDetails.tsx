'use client';

import { AdminAuditLog } from '@/lib/types';
import { useI18n, useT } from '@/lib/i18n';
import { User, Hash, Clock, FileJson, ShieldCheck, Database, ArrowRight } from 'lucide-react';
import { useState } from 'react';

interface AuditDetailsProps {
    log: AdminAuditLog;
}

function formatLabel(value: string | null | undefined) {
    if (!value) return '';
    return value.replace(/_/g, ' ');
}

function detectChanges(details: Record<string, any> | null): {
    before: Record<string, any>;
    after: Record<string, any>;
    changed: string[];
} | null {
    if (!details) return null;

    const before: Record<string, any> = {};
    const after: Record<string, any> = {};
    const changed: string[] = [];

    // Check for "new" and "old" at root level (your data structure)
    if (details.new && details.old && typeof details.new === 'object' && typeof details.old === 'object') {
        const allKeys = Array.from(new Set([...Object.keys(details.old), ...Object.keys(details.new)]));
        for (const key of allKeys) {
            const oldValue = details.old[key];
            const newValue = details.new[key];
            
            // Only mark as changed if values are actually different
            if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) {
                changed.push(key);
            }
        }
        return {
            before: details.old,
            after: details.new,
            changed: changed, // Only fields that actually changed
        };
    }

    // Check for explicit before/after structure
    if (details.before && details.after && typeof details.before === 'object' && typeof details.after === 'object') {
        const allKeys = Array.from(new Set([...Object.keys(details.before), ...Object.keys(details.after)]));
        for (const key of allKeys) {
            if (JSON.stringify(details.before[key]) !== JSON.stringify(details.after[key])) {
                changed.push(key);
            }
        }
        return {
            before: details.before,
            after: details.after,
            changed: changed,
        };
    }

    // Common patterns for before/after fields
    const patterns = [
        { before: 'old_', after: 'new_' },
        { before: 'previous_', after: 'current_' },
        { before: 'from_', after: 'to_' },
    ];

    // Detect paired fields (old_status/new_status, etc.)
    for (const pattern of patterns) {
        const beforeKeys: string[] = Object.keys(details).filter(k => k.startsWith(pattern.before));
        for (const beforeKey of beforeKeys) {
            const fieldName = beforeKey.substring(pattern.before.length);
            const afterKey = pattern.after + fieldName;
            if (afterKey in details) {
                before[fieldName] = details[beforeKey];
                after[fieldName] = details[afterKey];
                if (JSON.stringify(details[beforeKey]) !== JSON.stringify(details[afterKey])) {
                    changed.push(fieldName);
                }
            }
        }
    }

    if (Object.keys(before).length > 0) {
        return { before, after, changed };
    }

    return null;
}

export function AuditDetails({ log }: AuditDetailsProps) {
    const t = useT();
    const { language, dir } = useI18n();
    const locale = language === 'ar' ? 'ar' : 'en-US';
    const [viewMode, setViewMode] = useState<'diff' | 'json'>('diff');

    const changes = detectChanges(log.details);

    const renderDiffView = () => {
        if (!changes) {
            return (
                <div className="text-center py-8 theme-muted">
                    <p className="text-sm font-medium">
                        {t('audit.diff.noChanges', 'No before/after changes detected in this action.')}
                    </p>
                </div>
            );
        }

        const allKeys = Array.from(new Set([...Object.keys(changes.before), ...Object.keys(changes.after)]));

        return (
            <div className="space-y-4">
                {/* Header Row */}
                <div className="grid grid-cols-2 gap-6">
                    <div className="text-center pb-3 border-b-2 border-red-500/30">
                        <h4 className="text-sm font-black text-red-600 uppercase tracking-widest flex items-center justify-center gap-2">
                            <span className="text-lg">←</span>
                            {t('audit.diff.before', 'OLD / BEFORE')}
                        </h4>
                    </div>
                    <div className="text-center pb-3 border-b-2 border-green-500/30">
                        <h4 className="text-sm font-black text-green-600 uppercase tracking-widest flex items-center justify-center gap-2">
                            {t('audit.diff.after', 'NEW / AFTER')}
                            <span className="text-lg">→</span>
                        </h4>
                    </div>
                </div>

                {/* Comparison Rows */}
                <div className="space-y-3">
                    {allKeys.map((key) => {
                        const oldValue = changes.before[key];
                        const newValue = changes.after[key];
                        const isChanged = changes.changed.includes(key);
                        const oldStr = oldValue !== undefined ? (typeof oldValue === 'string' ? oldValue : JSON.stringify(oldValue)) : '—';
                        const newStr = newValue !== undefined ? (typeof newValue === 'string' ? newValue : JSON.stringify(newValue)) : '—';

                        return (
                            <div key={key} className="grid grid-cols-2 gap-6">
                                {/* Old Value (Left) */}
                                <div className={`p-4 rounded-lg border-2 transition-all ${
                                    isChanged 
                                        ? 'bg-red-100 border-red-400 shadow-md' 
                                        : 'bg-gray-50 border-gray-200'
                                }`}>
                                    <p className="text-[0.625rem] font-black uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                        {isChanged && <span className="text-red-600 text-lg font-black">●</span>}
                                        <span className={isChanged ? 'text-red-700 font-black' : 'text-gray-500'}>
                                            {formatLabel(key)}
                                        </span>
                                    </p>
                                    <div className={`text-sm break-all font-mono ${
                                        isChanged 
                                            ? 'bg-red-200 text-red-900 font-black px-3 py-2 rounded border-2 border-red-500' 
                                            : 'text-gray-700 px-3 py-2'
                                    }`}>
                                        {oldStr}
                                    </div>
                                </div>

                                {/* New Value (Right) */}
                                <div className={`p-4 rounded-lg border-2 transition-all ${
                                    isChanged 
                                        ? 'bg-green-100 border-green-400 shadow-md' 
                                        : 'bg-gray-50 border-gray-200'
                                }`}>
                                    <p className="text-[0.625rem] font-black uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                        {isChanged && <span className="text-green-600 text-lg font-black">●</span>}
                                        <span className={isChanged ? 'text-green-700 font-black' : 'text-gray-500'}>
                                            {formatLabel(key)}
                                        </span>
                                    </p>
                                    <div className={`text-sm break-all font-mono ${
                                        isChanged 
                                            ? 'bg-green-200 text-green-900 font-black px-3 py-2 rounded border-2 border-green-500' 
                                            : 'text-gray-700 px-3 py-2'
                                    }`}>
                                        {newStr}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>

                {/* Changed Fields Summary */}
                {changes.changed.length > 0 && (
                    <div className="mt-6 p-4 bg-blue-500/5 border border-blue-500/20 rounded-xl">
                        <p className="text-[0.625rem] font-black text-blue-600 uppercase tracking-widest mb-2">
                            {t('audit.diff.changedFields', 'Changed Fields')} ({changes.changed.length})
                        </p>
                        <div className="flex flex-wrap gap-2">
                            {changes.changed.map((field) => (
                                <span 
                                    key={field}
                                    className="px-3 py-1.5 bg-blue-500/10 text-blue-600 rounded-lg text-xs font-bold border border-blue-500/20"
                                >
                                    {formatLabel(field)}
                                </span>
                            ))}
                        </div>
                    </div>
                )}

                {/* Additional Details */}
                {log.details && Object.keys(log.details).length > Object.keys(changes.before).length + Object.keys(changes.after).length && (
                    <div className="mt-4 p-4 theme-bg-secondary border border-[var(--surface-border)] rounded-xl">
                        <p className="text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-3 opacity-60">
                            {t('audit.diff.additionalInfo', 'Additional Information')}
                        </p>
                        <div className="space-y-2">
                            {Object.entries(log.details).filter(([key]) => 
                                !key.startsWith('old_') && 
                                !key.startsWith('new_') && 
                                !key.startsWith('previous_') && 
                                !key.startsWith('current_') &&
                                !key.startsWith('from_') &&
                                !key.startsWith('to_') &&
                                key !== 'before' &&
                                key !== 'after'
                            ).map(([key, value]) => (
                                <div key={key} className="flex items-start gap-3 text-sm p-2 rounded hover:theme-bg-secondary transition">
                                    <span className="font-bold theme-muted capitalize min-w-[120px]">
                                        {formatLabel(key)}:
                                    </span>
                                    <span className="theme-heading break-all font-mono">
                                        {typeof value === 'string' ? value : JSON.stringify(value)}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        );
    };

    const renderJson = (data: Record<string, any> | null, title: string) => (
        <div className="flex flex-col h-full">
            <h4 className="text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-3 flex items-center gap-1 opacity-60">
                <FileJson className="h-3 w-3" /> {title}
            </h4>
            <div
                dir="ltr"
                className="bg-gray-900 rounded-xl p-4 overflow-auto max-h-[400px] text-[0.6875rem] font-mono leading-relaxed custom-scrollbar border border-white/5 shadow-inner"
            >
                {data && Object.keys(data).length > 0 ? (
                    <div className="text-blue-300 space-y-1">
                        {Object.entries(data).map(([key, value]) => (
                            <div key={key} className="py-0.5">
                                <span className="text-purple-400 font-bold">"{key}"</span>
                                <span className="text-white/40">: </span>
                                <span className="text-green-400 break-all">{JSON.stringify(value)}</span>
                            </div>
                        ))}
                    </div>
                ) : (
                    <span className="text-white/30 italic">null</span>
                )}
            </div>
        </div>
    );

    return (
        <div className="space-y-8">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 theme-bg-secondary p-5 rounded-2xl border border-[var(--surface-border)] shadow-sm">
                <div className="space-y-1.5">
                    <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest flex items-center gap-1 opacity-60">
                        <Clock className="h-3 w-3" /> {t('audit.details.timestamp', 'Timestamp')}
                    </p>
                    <p className="text-xs font-bold theme-heading leading-tight">
                        {new Date(log.created_at).toLocaleString(locale)}
                    </p>
                </div>
                <div className="space-y-1.5">
                    <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest flex items-center gap-1 opacity-60">
                        <User className="h-3 w-3" /> {t('audit.table.admin', 'Admin')}
                    </p>
                    <p className="text-xs font-bold theme-heading leading-tight truncate">
                        {log.admin?.full_name || t('audit.systemAdmin', 'System/Admin')}
                    </p>
                </div>
                <div className="space-y-1.5">
                    <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest flex items-center gap-1 opacity-60">
                        <Database className="h-3 w-3" /> {t('audit.table.target', 'Target')}
                    </p>
                    <p className="text-xs font-bold theme-heading leading-tight capitalize">
                        {formatLabel(log.target_type) || t('common.na', 'N/A')}
                    </p>
                </div>
                <div className="space-y-1.5 min-w-0">
                    <p className="text-[0.5625rem] theme-muted font-black uppercase tracking-widest flex items-center gap-1 opacity-60">
                        <Hash className="h-3 w-3" /> {t('audit.details.entityId', 'Entity ID')}
                    </p>
                    <p className="text-xs font-mono theme-muted truncate opacity-80" title={log.target_id || undefined}>
                        {log.target_id || t('common.na', 'N/A')}
                    </p>
                </div>
            </div>

            {/* View Mode Toggle */}
            {changes && (
                <div className="flex items-center gap-2 justify-center">
                    <button
                        onClick={() => setViewMode('diff')}
                        className={`px-4 py-2 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all ${
                            viewMode === 'diff'
                                ? 'bg-blue-600 text-white shadow-sm'
                                : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                        }`}
                    >
                        {t('audit.view.diff', 'Diff View')}
                    </button>
                    <button
                        onClick={() => setViewMode('json')}
                        className={`px-4 py-2 rounded-lg text-[0.625rem] font-black uppercase tracking-widest transition-all ${
                            viewMode === 'json'
                                ? 'bg-blue-600 text-white shadow-sm'
                                : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
                        }`}
                    >
                        {t('audit.view.json', 'Raw JSON')}
                    </button>
                </div>
            )}

            {/* Content based on view mode */}
            <div className="relative">
                {viewMode === 'diff' && changes ? renderDiffView() : renderJson(log.details, t('audit.details.details', 'Action Details'))}
            </div>

            <div className="flex items-center gap-4 py-4 px-5 theme-bg-secondary border border-blue-500/20 rounded-2xl shadow-sm">
                <div className="h-10 w-10 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-500 shadow-inner">
                    <ShieldCheck className="h-5 w-5" />
                </div>
                <div className={dir === 'rtl' ? 'text-right' : 'text-left'}>
                    <h5 className="text-xs font-black theme-heading uppercase tracking-widest">
                        {t('audit.details.integrity', 'Audit Trail Status')}
                    </h5>
                    <p className="text-[0.625rem] theme-muted font-medium mt-0.5 opacity-80">
                        {t('audit.details.integrityMsg', 'This entry is stored in the append-only admin audit trail.')}
                    </p>
                </div>
            </div>
        </div>
    );
}
