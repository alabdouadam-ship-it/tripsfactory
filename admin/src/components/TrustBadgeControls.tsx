'use client';

import { useState } from 'react';
import { ShieldCheck, Star, Award } from 'lucide-react';
import { Profile } from '@/lib/types';
import { setTrustBadge } from '@/app/actions/user-actions';
import { useToast } from '@/lib/toast';
import { useT } from '@/lib/i18n';

type Badge =
  | 'trusted_driver'
  | 'featured_driver'
  | 'verified_partner'
  | null;

function flagsForTier(tier: Badge) {
  return {
    trust_badge: tier,
    is_trusted: tier === 'trusted_driver' || tier === 'verified_partner',
    is_featured: tier === 'featured_driver',
  };
}

function hasTravelerCapability(user: Profile) {
  return !!(user.traveler_status && user.traveler_status !== 'none');
}

function trustedTierFor(user: Profile): Badge {
  if (hasTravelerCapability(user)) return 'trusted_driver';
  return 'verified_partner';
}

function featuredTierFor(): Badge {
  return 'featured_driver';
}

function isTrustedTier(tier: string | null | undefined) {
  return tier === 'trusted_driver' || tier === 'verified_partner';
}

function isFeaturedTier(tier: string | null | undefined) {
  return tier === 'featured_driver';
}

interface Props {
  user: Profile;
  onChange: (next: Partial<Profile>) => void;
}

export function TrustBadgeControls({ user, onChange }: Props) {
  const { toast } = useToast();
  const t = useT();
  const [busy, setBusy] = useState(false);
  const trustedActive = isTrustedTier(user.trust_badge) || (!user.trust_badge && !!user.is_trusted);
  const featuredActive = isFeaturedTier(user.trust_badge) || (!user.trust_badge && !!user.is_featured);

  async function apply(updates: { is_trusted?: boolean; is_featured?: boolean; trust_badge?: Badge }) {
    setBusy(true);
    const res = await setTrustBadge(user.id, updates);
    setBusy(false);
    if (res.success) {
      onChange(updates);
      toast(t('badges.toast.updated', 'Badge updated'), 'success');
    } else {
      toast(res.error || t('badges.toast.failed', 'Update failed'), 'error');
    }
  }

  return (
    <div className="space-y-4">
      <h3 className="font-black theme-heading uppercase text-xs tracking-widest flex items-center gap-2">
        <Award className="h-4 w-4 text-yellow-500" />
        {t('badges.title', 'Trust & Featured Badges')}
      </h3>
      <div className="theme-bg-secondary/50 p-5 rounded-xl border border-[var(--surface-border)] space-y-4">
        <div className="flex items-center gap-3">
          <button
            disabled={busy}
            onClick={() => apply(flagsForTier(trustedActive ? null : trustedTierFor(user)))}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition ${
              trustedActive ? 'bg-green-600 text-white shadow-md' : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
            }`}
          >
            <ShieldCheck className="h-4 w-4" />
            {trustedActive ? t('badges.trusted.on', 'Trusted') : t('badges.trusted.off', 'Mark trusted')}
          </button>
          <button
            disabled={busy}
            onClick={() => apply(flagsForTier(featuredActive ? null : featuredTierFor()))}
            className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition ${
              featuredActive ? 'bg-yellow-500 text-white shadow-md' : 'theme-bg-secondary theme-muted border border-[var(--surface-border)] hover:theme-heading'
            }`}
          >
            <Star className="h-4 w-4" />
            {featuredActive ? t('badges.featured.on', 'Featured') : t('badges.featured.off', 'Feature')}
          </button>
        </div>

        <div>
          <p className="text-[0.625rem] font-black theme-muted uppercase tracking-widest mb-2">
            {t('badges.tier', 'Badge tier')}
          </p>
          <div className="flex flex-wrap gap-2">
            {([
              { id: null as Badge, label: t('badges.tier.none', 'None') },
              { id: 'trusted_driver' as Badge, label: t('badges.tier.trustedDriver', 'Trusted Driver') },
              { id: 'featured_driver' as Badge, label: t('badges.tier.featuredDriver', 'Featured Driver') },
              { id: 'verified_partner' as Badge, label: t('badges.tier.verifiedPartner', 'Verified Partner') },
            ]).map(b => (
              <button
                key={String(b.id)}
                disabled={busy}
                onClick={() => apply(flagsForTier(b.id))}
                className={`px-3 py-1.5 rounded-lg text-[0.6875rem] font-black uppercase tracking-widest border transition ${
                  user.trust_badge === b.id
                    ? 'bg-purple-600 text-white border-purple-600'
                    : 'theme-bg-secondary theme-muted border-[var(--surface-border)] hover:theme-heading'
                }`}
              >
                {b.label}
              </button>
            ))}
          </div>
        </div>

        <p className="text-[0.625rem] theme-muted italic">
          {t('badges.help', "Selecting a badge tier keeps the database badge and promotion flags in sync. Featured users are surfaced in highlighted lists.")}
        </p>
      </div>
    </div>
  );
}
