import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AuthGuard } from './AuthGuard';

const { mockPush, mockReplace, mockSignOut, singleMock } = vi.hoisted(() => ({
  mockPush: vi.fn(),
  mockReplace: vi.fn(),
  mockSignOut: vi.fn(),
  singleMock: vi.fn(() => Promise.resolve({ data: { is_admin: true } })),
}));

vi.mock('next/navigation', () => ({
  usePathname: vi.fn(() => '/'),
  useRouter: () => ({ push: mockPush, replace: mockReplace, refresh: vi.fn() }),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn(),
      onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
      signOut: mockSignOut,
    },
    rpc: vi.fn(() => Promise.resolve({ data: true, error: null })),
    from: vi.fn(() => ({
      select: vi.fn(() => ({ eq: vi.fn(() => ({ single: singleMock })) })),
    })),
  },
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({ dir: 'ltr', t: (_k: string, fb?: string) => fb ?? _k }),
}));

vi.mock('@/components/Sidebar', () => ({ Sidebar: () => <div data-testid="sidebar">Sidebar</div> }));
vi.mock('@/app/loading', () => ({ default: () => <div data-testid="loading">Loading</div> }));
vi.mock('@/lib/violation-alerts', () => ({
  ViolationAlertsProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

const { supabase } = await import('@/lib/supabase');
const { usePathname } = await import('next/navigation');

describe('AuthGuard', () => {
  beforeEach(() => {
    mockPush.mockClear();
    mockReplace.mockClear();
    mockSignOut.mockClear();
    singleMock.mockResolvedValue({ data: { is_admin: true } });
    vi.mocked(usePathname).mockReturnValue('/');
    vi.mocked(supabase.auth.getSession).mockResolvedValue({
      data: { session: { user: { id: 'admin-1' } } },
      error: null,
    } as any);
  });

  it('shows loading then content when user is admin', async () => {
    render(
      <AuthGuard>
        <div>Dashboard content</div>
      </AuthGuard>
    );
    await screen.findByText('Dashboard content', undefined, { timeout: 2000 });
    expect(screen.queryByTestId('loading')).not.toBeInTheDocument();
    expect(screen.getByTestId('sidebar')).toBeInTheDocument();
  });

  it('renders children directly on /login', () => {
    vi.mocked(usePathname).mockReturnValue('/login');
    render(
      <AuthGuard>
        <div>Login page</div>
      </AuthGuard>
    );
    expect(screen.getByText('Login page')).toBeInTheDocument();
    expect(screen.queryByTestId('sidebar')).not.toBeInTheDocument();
  });

  it('redirects to login when session is null', async () => {
    vi.mocked(supabase.auth.getSession).mockResolvedValue({
      data: { session: null },
      error: null,
    });
    render(
      <AuthGuard>
        <div>Protected</div>
      </AuthGuard>
    );
    await waitFor(() => {
      expect(mockReplace).toHaveBeenCalledWith('/login');
    }, { timeout: 2000 });
  });

  it('redirects to login when getSession returns error', async () => {
    vi.mocked(supabase.auth.getSession).mockResolvedValue({
      data: { session: null },
      error: { message: 'Session expired', name: 'AuthError', status: 401 },
    } as any);
    render(
      <AuthGuard>
        <div>Protected</div>
      </AuthGuard>
    );
    await waitFor(() => {
      expect(mockReplace).toHaveBeenCalledWith('/login');
    }, { timeout: 2000 });
  });

  it('signs out and redirects when profile is not admin', async () => {
    singleMock.mockResolvedValue({ data: { is_admin: false } });
    render(
      <AuthGuard>
        <div>Protected</div>
      </AuthGuard>
    );
    await waitFor(() => {
      expect(mockSignOut).toHaveBeenCalled();
      expect(mockReplace).toHaveBeenCalledWith('/login');
    }, { timeout: 2000 });
  });

  it('shows loading state before checkAuth resolves', () => {
    vi.mocked(supabase.auth.getSession).mockImplementation(
      () => new Promise(() => {}) // never resolves
    );
    render(
      <AuthGuard>
        <div>Protected</div>
      </AuthGuard>
    );
    expect(screen.getByTestId('loading')).toBeInTheDocument();
  });

  it('keeps access when profile probe returns unknown (non-authoritative)', async () => {
    singleMock.mockResolvedValue({ data: null } as any); // no profile or not admin
    vi.mocked(supabase.auth.getSession).mockResolvedValue({
      data: { session: { user: { id: 'user-1' } } },
      error: null,
    } as any);
    render(
      <AuthGuard>
        <div>Protected</div>
      </AuthGuard>
    );
    await screen.findByText('Protected', undefined, { timeout: 2000 });
  });

  it('shows menu button when authorized and it is clickable', async () => {
    render(
      <AuthGuard>
        <div>Dashboard</div>
      </AuthGuard>
    );
    await screen.findByText('Dashboard', undefined, { timeout: 2000 });
    const menuButton = screen.getByRole('button', { name: /toggle menu/i });
    expect(menuButton).toBeInTheDocument();
    await userEvent.click(menuButton);
    expect(menuButton).toBeInTheDocument();
  });
});
