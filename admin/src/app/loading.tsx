'use client';

import { useT } from '@/lib/i18n';

export default function Loading({ message }: { message?: string }) {
    const t = useT();
    const text = message ?? t('common.loadingData', 'Loading data...');
    return (
        <div className="flex flex-col items-center justify-center min-h-[50vh]">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent"></div>
            <p className="mt-4 text-gray-500 font-medium">{text}</p>
        </div>
    );
}
