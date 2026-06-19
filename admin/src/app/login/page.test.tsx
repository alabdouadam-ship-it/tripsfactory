import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import LoginPage from './page';

const mocks = vi.hoisted(() => ({
  mockPush: vi.fn(),
  mockRefresh: vi.fn(),
  mockSignInWithPassword: vi.fn(),
  mockSignOut: vi.fn(),
  mockProfileSingle: vi.fn(),
  mockRpc: vi.fn(),
}));

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mocks.mockPush, refresh: mocks.mockRefresh }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (_key: string, fallback?: string) => fallback ?? _key,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      signInWithPassword: mocks.mockSignInWithPassword,
      signOut: mocks.mockSignOut,
    },
    from: () => ({
      select: () => ({
        eq: () => ({
          single: () => mocks.mockProfileSingle(),
        }),
      }),
    }),
    rpc: mocks.mockRpc,
  },
}));

describe('LoginPage', () => {
  beforeEach(() => {
    window.localStorage.clear();
    mocks.mockPush.mockClear();
    mocks.mockRefresh.mockClear();
    mocks.mockSignInWithPassword.mockResolvedValue({
      data: { session: { user: { id: 'admin-1' } } },
      error: null,
    });
    mocks.mockSignOut.mockResolvedValue({ error: null });
    mocks.mockProfileSingle.mockResolvedValue({
      data: { is_admin: true },
      error: null,
    });
    mocks.mockRpc.mockResolvedValue({ error: null });
  });

  it('records an admin login event after successful admin verification', async () => {
    render(<LoginPage />);

    fireEvent.change(screen.getByPlaceholderText('Email address'), {
      target: { value: 'admin@test.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Password'), {
      target: { value: 'secret123' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Sign in' }));

    await waitFor(() => {
      expect(mocks.mockRpc).toHaveBeenCalledWith('record_admin_login_event');
    });
    expect(window.localStorage.getItem('tripship.admin.lastEmail')).toBe('admin@test.com');
    expect(mocks.mockPush).toHaveBeenCalledWith('/');
  });

  it('prefills the last successful admin email', async () => {
    window.localStorage.setItem('tripship.admin.lastEmail', 'saved@test.com');

    render(<LoginPage />);

    await waitFor(() => {
      expect(screen.getByPlaceholderText('Email address')).toHaveValue('saved@test.com');
    });
  });

  it('does not block admin login when login history recording fails', async () => {
    mocks.mockRpc.mockResolvedValue({ error: { message: 'history unavailable' } });

    render(<LoginPage />);

    fireEvent.change(screen.getByPlaceholderText('Email address'), {
      target: { value: 'admin@test.com' },
    });
    fireEvent.change(screen.getByPlaceholderText('Password'), {
      target: { value: 'secret123' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Sign in' }));

    await waitFor(() => {
      expect(mocks.mockPush).toHaveBeenCalledWith('/');
    });
  });
});
