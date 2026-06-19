'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Loading from '@/app/loading';

export default function AuditPage() {
    const router = useRouter();

    useEffect(() => {
        router.replace('/audit-log');
    }, [router]);

    return <Loading />;
}
