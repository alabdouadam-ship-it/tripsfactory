import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs))
}

export function exportToCSV(data: any[], filename: string, onNoData?: (message: string) => void) {
    if (!data || !data.length) {
        if (onNoData) onNoData("No data to export");
        else alert("No data to export");
        return;
    }

    // 1. Get headers from the first object
    // We flatten the object roughly or just take top keys.
    // Ideally, we want specific columns. But generic is fine for now.

    // Quick helper to flatten nested objects (like profile.full_name) for cleaner CSV
    const flattenObject = (obj: any, prefix = '', seen = new WeakSet<object>()) => {
        if (!obj || typeof obj !== 'object') return {};
        if (seen.has(obj)) return {};
        seen.add(obj);
        return Object.keys(obj).reduce((acc: any, k) => {
            const pre = prefix.length ? prefix + '.' : '';
            if (typeof obj[k] === 'object' && obj[k] !== null && !Array.isArray(obj[k])) {
                Object.assign(acc, flattenObject(obj[k], pre + k, seen));
            } else {
                acc[pre + k] = Array.isArray(obj[k]) ? JSON.stringify(obj[k]) : obj[k];
            }
            return acc;
        }, {});
    };

    const flatData = data.map(item => flattenObject(item));
    const headers: string[] = Array.from(
        flatData.reduce((set, row) => {
            Object.keys(row).forEach((k) => set.add(k));
            return set;
        }, new Set<string>())
    );
    const toCsvCell = (value: unknown) => {
        if (value === null || value === undefined) return '""';
        const asString = typeof value === 'string' ? value : JSON.stringify(value);
        return `"${asString.replace(/"/g, '""')}"`;
    };

    // 2. Convert to CSV string
    const csvContent = [
        headers.join(','), // Header row
        ...flatData.map((row: Record<string, unknown>) => headers.map((fieldName: string) => toCsvCell(row[fieldName])).join(','))
    ].join('\n');

    // 3. Trigger download
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `${filename}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

export function getCityLabel(loc: { city_name_ar?: string | null; city_name_en?: string | null } | undefined | null) {
    if (!loc) return 'N/A';
    return loc.city_name_en || loc.city_name_ar || 'N/A';
}
