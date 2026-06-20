import { cn } from "@/lib/utils";

interface StatusBadgeProps {
    status?: string | null;
    className?: string;
}

const statusStyles: Record<string, string> = {
    // Common
    pending: 'bg-amber-500/10 text-amber-600 border-amber-500/20',
    pending_approval: 'bg-amber-500/10 text-amber-600 border-amber-500/20',
    pending_confirmation: 'bg-amber-500/10 text-amber-600 border-amber-500/20',
    cancelled: 'bg-red-500/10 text-red-600 border-red-500/20',
    rejected: 'bg-red-500/10 text-red-600 border-red-500/20',
    completed: 'bg-green-500/10 text-green-600 border-green-500/20',
    disputed: 'bg-rose-500/10 text-rose-600 border-rose-500/20',
    frozen: 'bg-cyan-500/10 text-cyan-600 border-cyan-500/20',
    expired: 'bg-slate-500/10 text-slate-600 border-slate-500/20',

    // Trip specific
    available: 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20',
    booked: 'bg-blue-500/10 text-blue-600 border-blue-500/20',
    in_transit: 'bg-orange-500/10 text-orange-600 border-orange-500/20',
    full: 'bg-purple-500/10 text-purple-600 border-purple-500/20',

    // Delivery specific
    in_communication: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
    accepted: 'bg-blue-500/10 text-blue-600 border-blue-500/20',
    picked_up: 'bg-indigo-500/10 text-indigo-600 border-indigo-500/20',
    delivered: 'bg-teal-500/10 text-teal-600 border-teal-500/20',
};

export function StatusBadge({ status, className }: StatusBadgeProps) {
    const safeStatus = typeof status === 'string' ? status : '';
    const normalizedStatus = safeStatus.trim().toLowerCase();
    const style = statusStyles[normalizedStatus] || 'theme-bg-secondary theme-muted border-[var(--surface-border)]';
    const label = safeStatus ? safeStatus.replace(/_/g, ' ') : 'unknown';

    return (
        <span className={cn(
            "px-2.5 py-0.5 rounded-full text-[0.625rem] font-black uppercase border-2 shadow-sm",
            style,
            className
        )}>
            {label}
        </span>
    );
}
