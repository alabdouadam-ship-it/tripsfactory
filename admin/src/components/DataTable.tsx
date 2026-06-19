'use client';

import React, { useState, useEffect } from 'react';
import {
    ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight,
    Settings2, Download, Filter, Search, MoreHorizontal,
    CheckCircle2, AlertCircle, Trash2, ArrowUpDown
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useT } from '@/lib/i18n';

export interface Column<T> {
    header: string;
    accessorKey: keyof T | string;
    cell?: (item: T) => React.ReactNode;
    sortable?: boolean;
}

interface DataTableProps<T> {
    data: T[];
    columns: Column<T>[];
    totalCount: number;
    pageSize: number;
    currentPage: number;
    onPageChange: (page: number) => void;
    onSort?: (key: string, direction: 'asc' | 'desc') => void;
    onBulkAction?: (items: T[]) => void;
    isLoading?: boolean;
    bulkActions?: { label: string; action: (items: T[]) => void; icon?: any; variant?: 'danger' | 'primary' }[];
    hideColumnSelector?: boolean;
}

export function DataTable<T extends { id: string | number }>({
    data,
    columns,
    totalCount,
    pageSize,
    currentPage,
    onPageChange,
    onSort,
    isLoading,
    bulkActions,
    hideColumnSelector = false
}: DataTableProps<T>) {
    const t = useT();
    const [selectedIds, setSelectedIds] = useState<Set<string | number>>(new Set());
    const [visibleColumns, setVisibleColumns] = useState<Set<string>>(new Set(columns.map(c => c.accessorKey as string)));
    const [showColumnToggle, setShowColumnToggle] = useState(false);
    const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'asc' | 'desc' } | null>(null);
    const dataIdsKey = data.map((d) => String(d.id)).join('|');

    const totalPages = Math.ceil(totalCount / pageSize);
    const selectedItemsOnPage = data.filter(d => selectedIds.has(d.id));
    const allCurrentPageSelected = data.length > 0 && selectedItemsOnPage.length === data.length;

    useEffect(() => {
        // Keep bulk selection page-scoped to avoid cross-page mismatch.
        setSelectedIds(new Set());
    }, [currentPage, dataIdsKey]);

    const toggleSelectAll = () => {
        if (allCurrentPageSelected) {
            setSelectedIds(new Set());
        } else {
            setSelectedIds(new Set(data.map(d => d.id)));
        }
    };

    const toggleSelect = (id: string | number) => {
        const next = new Set(selectedIds);
        if (next.has(id)) next.delete(id);
        else next.add(id);
        setSelectedIds(next);
    };

    const handleSort = (key: string) => {
        const direction = sortConfig?.key === key && sortConfig.direction === 'asc' ? 'desc' : 'asc';
        setSortConfig({ key, direction });
        onSort?.(key, direction);
    };

    return (
        <div className="flex flex-col h-full theme-card rounded-2xl border border-[var(--surface-border)] shadow-sm overflow-hidden">
            {/* Table Header / Toolbar */}
            {(!hideColumnSelector || (selectedItemsOnPage.length > 0 && bulkActions && bulkActions.length > 0)) && (
                <div className="px-3 py-2 border-b border-[var(--surface-border)] flex items-center justify-between gap-4 theme-bg-secondary/30">
                    <div className="flex items-center gap-3">
                        {selectedItemsOnPage.length > 0 && (
                            <div className="flex items-center gap-3 animate-in slide-in-from-left-2 duration-200">
                                <span className="text-[0.75rem] font-black text-blue-600 bg-blue-500/10 px-4 py-1.5 rounded-full border border-blue-500/20">
                                    {t('common.selectedOnPage', '{count} selected on this page').replace('{count}', String(selectedItemsOnPage.length))}
                                </span>
                                <div className="h-4 w-px bg-[var(--surface-border)]" />
                                {bulkActions?.map((act, i) => (
                                    <button
                                        key={i}
                                        onClick={() => act.action(selectedItemsOnPage)}
                                        className={cn(
                                            "px-4 py-2 rounded-xl text-[0.625rem] font-black uppercase tracking-widest flex items-center gap-2 transition-all shadow-sm active:scale-95",
                                            act.variant === 'danger' ? "bg-red-500/10 text-red-600 hover:bg-red-600 hover:text-white" : "bg-blue-600 text-white hover:bg-blue-700"
                                        )}
                                    >
                                        {act.icon && <act.icon className="h-3 w-3" />}
                                        {act.label}
                                    </button>
                                ))}
                            </div>
                        )}
                    </div>

                    {!hideColumnSelector && (
                        <div className="flex items-center gap-2">
                            <button
                                onClick={() => setShowColumnToggle(!showColumnToggle)}
                                className="p-2 hover:theme-bg-secondary rounded-xl transition theme-muted relative border border-[var(--surface-border)]"
                            >
                                <Settings2 className="h-4 w-4" />
                                {showColumnToggle && (
                                    <div className="absolute right-0 top-full mt-2 w-56 theme-card border border-[var(--surface-border)] rounded-2xl shadow-2xl z-50 p-4 animate-in fade-in zoom-in-95 duration-100">
                                        <p className="text-[0.625rem] font-black uppercase theme-muted mb-3 px-1 tracking-widest opacity-60">{t('table.visibleColumns', 'Visible Columns')}</p>
                                        <div className="space-y-1">
                                            {columns.map(col => (
                                                <label key={col.accessorKey as string} className="flex items-center gap-3 p-2 hover:theme-bg-secondary rounded-xl cursor-pointer transition-colors">
                                                    <input
                                                        type="checkbox"
                                                        checked={visibleColumns.has(col.accessorKey as string)}
                                                        onChange={() => {
                                                            const next = new Set(visibleColumns);
                                                            if (next.has(col.accessorKey as string)) next.delete(col.accessorKey as string);
                                                            else next.add(col.accessorKey as string);
                                                            setVisibleColumns(next);
                                                        }}
                                                        className="rounded-md text-blue-600 focus:ring-blue-500 h-4 w-4 theme-bg-secondary border-[var(--surface-border)]"
                                                    />
                                                    <span className="text-xs font-black theme-heading uppercase tracking-tight">{col.header}</span>
                                                </label>
                                            ))}
                                        </div>
                                    </div>
                                )}
                            </button>
                        </div>
                    )}
                </div>
            )}

            {/* Table Body */}
            <div className="flex-1 overflow-auto scrollbar-thin relative">
                {isLoading && (
                    <div className="absolute inset-0 bg-[var(--surface)] opacity-50 backdrop-blur-[1px] z-10 flex items-center justify-center">
                        <div className="h-10 w-10 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
                    </div>
                )}
                <table className="w-full text-left border-collapse min-w-[800px]">
                    <thead className="sticky top-0 theme-bg-secondary z-20 shadow-sm border-b border-[var(--surface-border)]">
                        <tr>
                            <th className="p-3 w-12">
                                <input
                                    type="checkbox"
                                    checked={allCurrentPageSelected}
                                    onChange={toggleSelectAll}
                                    className="rounded-md text-blue-600 focus:ring-blue-500 h-4 w-4 theme-bg-secondary border-[var(--surface-border)]"
                                />
                            </th>
                            {columns.filter(c => visibleColumns.has(c.accessorKey as string)).map(col => (
                                <th
                                    key={col.accessorKey as string}
                                    className="p-3 text-[0.625rem] font-black theme-muted uppercase tracking-widest group opacity-60"
                                >
                                    <button
                                        disabled={!col.sortable}
                                        onClick={() => handleSort(col.accessorKey as string)}
                                        className={cn(
                                            "flex items-center gap-2",
                                            col.sortable ? "hover:theme-heading transition-colors" : "cursor-default"
                                        )}
                                    >
                                        {col.header}
                                        {col.sortable && (
                                            <ArrowUpDown className={cn(
                                                "h-3 w-3 opacity-0 group-hover:opacity-100 transition-opacity",
                                                sortConfig?.key === col.accessorKey && "opacity-100 text-blue-600"
                                            )} />
                                        )}
                                    </button>
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-[var(--surface-border)] text-sm">
                        {data.map(item => (
                            <tr
                                key={item.id}
                                className={cn(
                                    "hover:theme-bg-secondary transition-colors",
                                    selectedIds.has(item.id) && "bg-blue-500/5"
                                )}
                            >
                                <td className="p-3">
                                    <input
                                        type="checkbox"
                                        checked={selectedIds.has(item.id)}
                                        onChange={() => toggleSelect(item.id)}
                                        className="rounded-md text-blue-600 focus:ring-blue-500 h-4 w-4 theme-bg-secondary border-[var(--surface-border)]"
                                    />
                                </td>
                                {columns.filter(c => visibleColumns.has(c.accessorKey as string)).map((col, colIdx) => (
                                    <td key={col.accessorKey as string} className="p-3 theme-heading font-black tracking-tight">
                                        <div className="flex items-center gap-2">
                                            {/* Heat Signal: Risk Dot (only on first column if data has risk_score) */}
                                            {colIdx === 0 && (item as any).risk_score !== undefined && (
                                                <div className={cn(
                                                    "w-2 h-2 rounded-full flex-shrink-0 animate-pulse",
                                                    (item as any).risk_score > 75 ? "bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.5)]" :
                                                        (item as any).risk_score > 40 ? "bg-orange-500" : "bg-green-500"
                                                )} title={t('table.riskScore', 'Risk Score: {score}').replace('{score}', String((item as any).risk_score))} />
                                            )}
                                            {col.cell ? col.cell(item) : (item[col.accessorKey as keyof T] as any)}
                                        </div>
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
                {data.length === 0 && !isLoading && (
                    <div className="flex flex-col items-center justify-center py-20 theme-muted">
                        <Search className="h-10 w-10 mb-4 opacity-10" />
                        <p className="font-black text-[0.625rem] uppercase tracking-widest opacity-40">{t('table.empty', 'Zero registries discovered.')}</p>
                    </div>
                )}
            </div>

            {/* Pagination Footer */}
            <div className="px-3 py-2 border-t border-[var(--surface-border)] theme-bg-secondary/30 flex items-center justify-between gap-4">
                <p className="text-[0.625rem] theme-muted font-black uppercase tracking-widest opacity-60">
                    {t('table.registrySegment', 'Registry Segment')}: <span className="theme-heading">{Math.min(data.length, pageSize)}</span> / <span className="theme-heading">{totalCount}</span>
                </p>
                <div className="flex items-center gap-2">
                    <button
                        disabled={currentPage === 1 || isLoading}
                        onClick={() => onPageChange(1)}
                        className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] shadow-sm bg-[var(--surface)]"
                    >
                        <ChevronsLeft className="h-4 w-4" />
                    </button>
                    <button
                        disabled={currentPage === 1 || isLoading}
                        onClick={() => onPageChange(currentPage - 1)}
                        className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] shadow-sm bg-[var(--surface)]"
                    >
                        <ChevronLeft className="h-4 w-4" />
                    </button>
                    <div className="flex items-center px-6 py-2 bg-[var(--surface)] border border-[var(--surface-border)] rounded-xl shadow-sm">
                        <span className="text-[0.625rem] font-black theme-heading uppercase tracking-widest">{t('table.shard', 'Shard {current} / {total}').replace('{current}', String(currentPage)).replace('{total}', String(totalPages || 1))}</span>
                    </div>
                    <button
                        disabled={currentPage === totalPages || totalPages === 0 || isLoading}
                        onClick={() => onPageChange(currentPage + 1)}
                        className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] shadow-sm bg-[var(--surface)]"
                    >
                        <ChevronRight className="h-4 w-4" />
                    </button>
                    <button
                        disabled={currentPage === totalPages || totalPages === 0 || isLoading}
                        onClick={() => onPageChange(totalPages)}
                        className="p-2 hover:bg-blue-600 hover:text-white rounded-xl disabled:opacity-30 transition border border-[var(--surface-border)] shadow-sm bg-[var(--surface)]"
                    >
                        <ChevronsRight className="h-4 w-4" />
                    </button>
                </div>
            </div>
        </div>
    );
}
