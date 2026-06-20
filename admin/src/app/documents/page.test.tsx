import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import DocumentsPage from './page';

const {
  mockToast,
  mockConfirm,
  mockFrom,
  mockGetPublicUrl,
  mockCreateSignedUrl,
  mockRemove,
  mockLogAdminAction,
  state,
} = vi.hoisted(() => {
  const state = {
    profiles: [] as any[],
    error: null as any,
    updates: [] as Array<{ table: string; patch: any; column: string; value: any }>,
    lastConfirm: null as null | { onConfirm: () => void | Promise<void> },
  };

  const makeSelectQuery = () => ({
    or: vi.fn(() => Promise.resolve({
      data: state.profiles,
      error: state.error,
    })),
  });

  const makeUpdateQuery = (table: string, patch: any) => ({
    eq: vi.fn((column: string, value: any) => {
      state.updates.push({ table, patch, column, value });
      return Promise.resolve({ error: null });
    }),
  });

  return {
    mockToast: vi.fn(),
    mockConfirm: vi.fn((options: any) => {
      state.lastConfirm = options;
    }),
    mockFrom: vi.fn((table: string) => ({
      select: vi.fn(() => makeSelectQuery()),
      update: vi.fn((patch: any) => makeUpdateQuery(table, patch)),
    })),
    mockGetPublicUrl: vi.fn((path: string) => ({
      data: { publicUrl: `https://cdn.test/user_documents/${path}` },
    })),
    mockCreateSignedUrl: vi.fn((path: string) => Promise.resolve({
      data: { signedUrl: `https://cdn.test/signed/${path}` },
      error: null,
    })),
    mockRemove: vi.fn(() => Promise.resolve({ error: null })),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
    state,
  };
});

vi.mock('next/link', () => ({
  default: ({ children, href, className }: { children: React.ReactNode; href: string; className?: string }) => (
    <a href={href} className={className}>{children}</a>
  ),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mockFrom,
    storage: {
      from: vi.fn(() => ({
        getPublicUrl: mockGetPublicUrl,
        createSignedUrl: mockCreateSignedUrl,
        remove: mockRemove,
      })),
    },
  },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast, confirm: mockConfirm }),
}));

vi.mock('@/lib/i18n', () => {
  const labels: Record<string, string> = {
    'common.retry': 'Retry',
    'documents.actions.approve': 'Approve',
    'documents.actions.reject': 'Reject',
    'documents.confirm.approveLabel': 'Approve',
    'documents.confirm.approveMessage': 'Approve {docType} for {userName}?',
    'documents.confirm.approveTitle': 'Approve Document',
    'documents.confirm.rejectLabel': 'Reject',
    'documents.confirm.rejectMessage': 'Reject {docType} for {userName}?',
    'documents.confirm.rejectTitle': 'Reject Document',
    'documents.empty': 'No documents match your criteria.',
    'documents.errorLoad': 'Failed to load documents.',
    'documents.filter.all': 'All Documents',
    'documents.filter.pendingOnly': 'Pending Only',
    'documents.pendingCount': 'Pending',
    'documents.search.expandedPlaceholder': 'Search by name, phone, user ID, or document type...',
    'documents.status.approved': 'Approved',
    'documents.status.pending': 'Pending Review',
    'documents.subtitle': 'Review and approve user document uploads',
    'documents.table.actions': 'Actions',
    'documents.table.documentType': 'Document Type',
    'documents.table.status': 'Status',
    'documents.table.user': 'User',
    'documents.table.view': 'View',
    'documents.title': 'Document Approval',
    'documents.toast.approveSuccess': 'Document approved',
    'documents.toast.rejectSuccess': 'Document rejected',
    'documents.toast.storageDeleteFailed': 'Document rejected, but the stored file could not be deleted.',
    'documents.type.identity': 'Identity Document',
    'documents.view.current': 'Current',
    'documents.view.pending': 'Pending',
  };
  const t = (key: string, fallback?: string) => labels[key] ?? fallback ?? key;

  return {
    useI18n: () => ({ t, dir: 'ltr' as const }),
    useT: () => t,
  };
});

vi.mock('@/lib/audit', () => ({
  logAdminAction: mockLogAdminAction,
}));

describe('DocumentsPage', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockConfirm.mockClear();
    mockFrom.mockClear();
    mockGetPublicUrl.mockClear();
    mockCreateSignedUrl.mockClear();
    mockRemove.mockClear();
    mockLogAdminAction.mockClear();
    state.profiles = [];
    state.error = null;
    state.updates = [];
    state.lastConfirm = null;
  });

  it('approves a pending document by moving it into the current profile field', async () => {
    state.profiles = [{
      id: 'user-1',
      full_name: 'Pending User',
      phone_number: '+111',
      identity_doc_url: null,
      identity_doc_url_pending: 'user-1/documents/identity.pdf',
    }];

    render(<DocumentsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /^Approve$/i }));
    await act(async () => {
      await state.lastConfirm?.onConfirm();
    });

    await waitFor(() => {
      expect(state.updates).toContainEqual({
        table: 'profiles',
        patch: {
          identity_doc_url: 'user-1/documents/identity.pdf',
          identity_doc_url_pending: null,
        },
        column: 'id',
        value: 'user-1',
      });
    });
  });

  it('opens a stored document via a short-lived signed URL', async () => {
    state.profiles = [{
      id: 'user-2',
      full_name: 'Current User',
      phone_number: '+222',
      identity_doc_url: 'user-2/documents/current.pdf',
      identity_doc_url_pending: null,
    }];

    const openSpy = vi.spyOn(window, 'open').mockImplementation(() => null);

    render(<DocumentsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /All Documents/i }));

    // user_documents is a private bucket: the viewer is a button that mints a
    // signed URL on click (no public href).
    fireEvent.click(await screen.findByRole('button', { name: /^Current$/i }));

    await waitFor(() => {
      expect(mockCreateSignedUrl).toHaveBeenCalledWith(
        'user-2/documents/current.pdf',
        expect.any(Number),
      );
      expect(openSpy).toHaveBeenCalledWith(
        'https://cdn.test/signed/user-2/documents/current.pdf',
        '_blank',
        'noopener,noreferrer',
      );
    });

    openSpy.mockRestore();
  });

  it('rejects a pending storage document and removes the stored object', async () => {
    state.profiles = [{
      id: 'user-3',
      full_name: 'Reject User',
      phone_number: '+333',
      identity_doc_url: null,
      identity_doc_url_pending: 'user-3/documents/reject.pdf',
    }];

    render(<DocumentsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /^Reject$/i }));
    await act(async () => {
      await state.lastConfirm?.onConfirm();
    });

    await waitFor(() => {
      expect(state.updates).toContainEqual({
        table: 'profiles',
        patch: { identity_doc_url_pending: null },
        column: 'id',
        value: 'user-3',
      });
      expect(mockRemove).toHaveBeenCalledWith(['user-3/documents/reject.pdf']);
      expect(mockLogAdminAction).toHaveBeenCalledWith(
        'reject_document',
        'document',
        'user-3',
        { docType: 'Identity Document', storageDeleted: true },
      );
    });
  });

  it('shows a retryable error when documents fail to load', async () => {
    state.error = { message: 'permission denied' };

    render(<DocumentsPage />);

    expect(await screen.findByText('Failed to load documents.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Retry/i })).toBeInTheDocument();
  });

  it('searches by user name', async () => {
    state.profiles = [{
      id: 'user-9',
      full_name: 'Owner Name',
      phone_number: '+966555',
      identity_doc_url: null,
      identity_doc_url_pending: 'user-9/documents/identity.pdf',
    }];

    render(<DocumentsPage />);

    const search = await screen.findByPlaceholderText(/Search by name, phone/i);
    fireEvent.change(search, { target: { value: 'Owner' } });

    expect(screen.getByText('Owner Name')).toBeInTheDocument();
  });
});
