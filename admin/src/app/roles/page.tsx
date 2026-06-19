'use client';

import Link from 'next/link';
import { ShieldCheck } from 'lucide-react';
import { useT } from '@/lib/i18n';

export default function RolesPage() {
  const t = useT();

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-black theme-heading tracking-tight">
          {t('roles.title', 'Admin Access')}
        </h1>
        <p className="theme-muted text-sm mt-1 font-medium">
          {t('roles.subtitle', 'Access is unified. All admins have the same permissions.')}
        </p>
      </div>

      <div className="bg-[var(--surface)] rounded-2xl border border-[var(--surface-border)] shadow-sm p-8">
        <div className="flex items-start gap-4">
          <div className="h-11 w-11 rounded-xl bg-green-500/10 text-green-600 flex items-center justify-center">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div className="space-y-2">
            <p className="font-bold theme-heading">
              {t('roles.unified.title', 'Role tiers are disabled in this admin panel.')}
            </p>
            <p className="text-sm theme-muted">
              {t('roles.unified.body', 'Authorization is based only on profiles.is_admin.')}
            </p>
            <p className="text-sm theme-muted">
              {t('roles.unified.hint', 'Use Users to grant/revoke admin access with the is_admin flag.')}
            </p>
            <div className="pt-2">
              <Link
                href="/users"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 text-xs font-bold uppercase tracking-widest transition"
              >
                {t('roles.unified.cta', 'Go to Users')}
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
