import React from 'react';

type InfoCardProps = {
    icon: React.ReactNode;
    label: string;
    value: React.ReactNode;
    className?: string;
};

export default function InfoCard({ icon, label, value, className = '' }: InfoCardProps) {
    return (
        <div className={`theme-bg-secondary/50 p-4 rounded-xl border border-[var(--surface-border)] ${className}`}>
            <div className="flex items-center gap-1.5 text-[0.625rem] theme-muted uppercase font-black tracking-widest mb-1 opacity-60">
                {icon} {label}
            </div>
            <div className="font-black theme-heading text-sm tracking-tight">{value}</div>
        </div>
    );
}
