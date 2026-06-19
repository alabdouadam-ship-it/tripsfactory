import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import CompaniesPage from './page';

const {
  mockToast,
  mockFrom,
  mockOr,
  mockAdvanceVerificationStep,
  mockExportToCSV,
  state,
} = vi.hoisted(() => {
  const state = {
    fetchProfiles: [] as any[],
    exportProfiles: [] as any[],
    exportError: null as any,
  };

  const mockOr = vi.fn();

  const makeFetchQuery = () => {
    const query: any = {
      or: vi.fn((value: string) => {
        mockOr(value);
        return query;
      }),
      eq: vi.fn(() => query),
      order: vi.fn(() => query),
      range: vi.fn(() => Promise.resolve({
        data: state.fetchProfiles,
        count: state.fetchProfiles.length,
        error: null,
      })),
    };
    return query;
  };

  const makeExportQuery = () => {
    const query: any = {
      or: vi.fn((value: string) => {
        mockOr(value);
        return query;
      }),
      eq: vi.fn(() => query),
      order: vi.fn(() => Promise.resolve({
        data: state.exportProfiles,
        error: state.exportError,
      })),
    };
    return query;
  };

  return {
    mockToast: vi.fn(),
    mockOr,
    mockFrom: vi.fn(() => ({
      select: vi.fn((_columns: string, options?: { count?: string }) => (
        options?.count ? makeFetchQuery() : makeExportQuery()
      )),
    })),
    mockAdvanceVerificationStep: vi.fn(() => Promise.resolve({ success: true })),
    mockExportToCSV: vi.fn(),
    state,
  };
});

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => {
  const labels: Record<string, string> = {
    'common.na': 'N/A',
    'companies.action.approve': 'Approve',
    'companies.action.reject': 'Reject',
    'companies.action.openProfile': 'Open profile',
    'companies.card.address': 'Address',
    'companies.card.crNumber': 'CR Number',
    'companies.card.noOwner': 'No owner name',
    'companies.card.registered': 'Registered',
    'companies.card.unnamed': 'Unnamed Company',
    'companies.export': 'Export',
    'companies.filter.all': 'All',
    'companies.filter.approved': 'Approved',
    'companies.filter.blocked': 'Blocked',
    'companies.filter.pending': 'Pending',
    'companies.filter.rejected': 'Rejected',
    'companies.filter.suspended': 'Suspended',
    'companies.subtitle': 'Manage company registrations and approvals',
    'companies.title': 'Companies Verification',
    'companies.toast.exporting': 'Exporting...',
    'companies.toast.statusSuccess': 'Company status updated to {status}',
  };

  const t = (key: string, fallback?: string) => labels[key] ?? fallback ?? key;

  return {
    useT: () => t,
    useI18n: () => ({
      t,
      language: 'en',
      dir: 'ltr',
    }),
  };
});

vi.mock('@/app/actions/verification-actions', () => ({
  advanceVerificationStep: mockAdvanceVerificationStep,
}));

vi.mock('@/lib/utils', () => ({
  exportToCSV: mockExportToCSV,
}));

describe('CompaniesPage', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockFrom.mockClear();
    mockOr.mockClear();
    mockAdvanceVerificationStep.mockClear();
    mockExportToCSV.mockClear();
    state.fetchProfiles = [];
    state.exportProfiles = [];
    state.exportError = null;
  });

  it('shows app-submitted pending company applications even before account_type is company', async () => {
    state.fetchProfiles = [{
      id: 'company-1',
      full_name: 'Company Applicant',
      account_type: 'individual',
      company_status: 'pending',
      company_name: 'Applicant LLC',
      company_cr_number: 'CR-123',
      company_address: 'Riyadh',
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<CompaniesPage />);

    expect(await screen.findByText('Applicant LLC')).toBeInTheDocument();
    expect(screen.getByText('Company Applicant')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Open profile/i })).toHaveAttribute('href', '/users/company-1');
    expect(mockOr).toHaveBeenCalledWith('account_type.eq.company,company_status.neq.none');
  });

  it('does not expose approve or reject actions for blocked companies', async () => {
    state.fetchProfiles = [{
      id: 'company-2',
      full_name: 'Blocked Owner',
      account_type: 'company',
      company_status: 'blocked',
      company_name: 'Blocked LLC',
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<CompaniesPage />);

    expect(await screen.findByText('Blocked LLC')).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /^Approve$/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /^Reject$/i })).not.toBeInTheDocument();
    expect(mockAdvanceVerificationStep).not.toHaveBeenCalled();
  });

  it('routes approval through the verification workflow action', async () => {
    state.fetchProfiles = [{
      id: 'company-3',
      full_name: 'Pending Owner',
      account_type: 'individual',
      company_status: 'pending',
      company_name: 'Pending LLC',
      created_at: '2026-01-01T00:00:00.000Z',
    }];

    render(<CompaniesPage />);

    await screen.findByText('Pending LLC');
    fireEvent.click(screen.getByRole('button', { name: /^Approve$/i }));

    await waitFor(() => {
      expect(mockAdvanceVerificationStep).toHaveBeenCalledWith(
        'company-3',
        'company',
        'approved',
        'Companies screen status update',
      );
    });
  });

  it('exports all matching companies, not only the current page', async () => {
    state.fetchProfiles = [{
      id: 'visible-company',
      full_name: 'Visible Owner',
      account_type: 'company',
      company_status: 'approved',
      company_name: 'Visible LLC',
      created_at: '2026-01-01T00:00:00.000Z',
    }];
    state.exportProfiles = [
      { id: 'visible-company', company_name: 'Visible LLC' },
      { id: 'second-company', company_name: 'Second LLC' },
    ];

    render(<CompaniesPage />);

    await screen.findByText('Visible LLC');
    fireEvent.click(screen.getByRole('button', { name: /Export/i }));

    await waitFor(() => {
      expect(mockExportToCSV).toHaveBeenCalledWith(
        state.exportProfiles,
        'companies_export',
        expect.any(Function),
      );
    });
  });
});
