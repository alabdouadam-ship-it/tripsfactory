import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import VerificationCenter from './page';

const {
  mockToast,
  mockFrom,
  mockAdvanceVerificationStep,
  state,
} = vi.hoisted(() => {
  const state = {
    profiles: [] as any[],
    error: null as any,
  };

  const makeProfilesQuery = () => {
    const query: any = {
      eq: vi.fn(() => query),
      order: vi.fn(() => Promise.resolve({
        data: state.profiles,
        error: state.error,
      })),
    };
    return query;
  };

  return {
    mockToast: vi.fn(),
    mockFrom: vi.fn(() => ({
      select: vi.fn(() => makeProfilesQuery()),
    })),
    mockAdvanceVerificationStep: vi.fn(() => Promise.resolve({ success: true })),
    state,
  };
});

vi.mock('next/link', () => ({
  default: ({ children, href, className }: { children: React.ReactNode; href: string; className?: string }) => (
    <a href={href} className={className}>{children}</a>
  ),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => {
  const labels: Record<string, string> = {
    'common.retry': 'Retry',
    'verification.all': 'All',
    'verification.approveTraveler': 'Approve Traveler',
    'verification.docAvailable': 'Document available',
    'verification.docMissing': 'Document missing',
    'verification.driver': 'Driver',
    'verification.emptyQueue': 'Queue is empty. All users are current.',
    'verification.errorLoad': 'Failed to load verification queue.',
    'verification.identityDocs': 'Identity Docs',
    'verification.openProfile': 'Open Profile',
    'verification.pendingApproval': 'Pending Approval',
    'verification.queueSubtitle': 'Review pending traveler approvals.',
    'verification.reviewRiskInProfile': 'Review profile for risk signals, restrictions, and notes.',
    'verification.searchPlaceholder': 'Search by name or phone...',
    'verification.title': 'Verification Center',
    'verification.toast.travelerApproved': '{capability} approved',
    'verification.traveler': 'Traveler',
    'verification.travelerDocs': 'Traveler Documents',
  };

  return {
    useT: () => (key: string, fallback?: string) => labels[key] ?? fallback ?? key,
  };
});

vi.mock('@/app/actions/verification-actions', () => ({
  advanceVerificationStep: mockAdvanceVerificationStep,
}));

describe('VerificationCenter', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockFrom.mockClear();
    mockAdvanceVerificationStep.mockClear();
    state.profiles = [];
    state.error = null;
  });

  it('uses the final approved transition when approving a traveler', async () => {
    state.profiles = [{
      id: 'user-1',
      full_name: 'Traveler User',
      phone_number: '+111',
      traveler_status: 'pending',
      identity_doc_url_pending: 'identity-path',
      traveler_license_url_pending: 'license-path',
      is_driver: false,
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<VerificationCenter />);

    fireEvent.click(await screen.findByRole('button', { name: /Approve Traveler/i }));

    await waitFor(() => {
      expect(mockAdvanceVerificationStep).toHaveBeenCalledWith(
        'user-1',
        'driver',
        'approved',
        'Traveler approved from Verification Center',
      );
    });
  });

  it('shows a retryable error when the verification queue fails to load', async () => {
    state.error = { message: 'permission denied' };

    render(<VerificationCenter />);

    expect(await screen.findByText('Failed to load verification queue.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Retry/i })).toBeInTheDocument();
    expect(mockToast).toHaveBeenCalledWith('Failed to load verification queue.', 'error');
  });

  it('counts pending uploaded documents as available and avoids unsupported fraud claims', async () => {
    state.profiles = [{
      id: 'user-3',
      full_name: 'Pending Docs',
      phone_number: '+333',
      traveler_status: 'pending',
      identity_doc_url_pending: 'identity-path',
      traveler_license_url_pending: 'license-path',
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<VerificationCenter />);

    expect(await screen.findByText('Pending Docs')).toBeInTheDocument();
    expect(screen.getAllByLabelText('Document available')).toHaveLength(2);
    expect(screen.getByText('Review profile for risk signals, restrictions, and notes.')).toBeInTheDocument();
    expect(screen.queryByText(/No fraud flags/i)).not.toBeInTheDocument();
  });

  it('renders polished filter labels instead of raw i18n keys', async () => {
    render(<VerificationCenter />);

    expect(await screen.findByRole('button', { name: /^All$/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /^Traveler$/i })).toBeInTheDocument();
    expect(screen.queryByText('verification.all')).not.toBeInTheDocument();
  });
});
