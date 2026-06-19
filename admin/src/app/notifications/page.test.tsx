import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import NotificationsPage from './page';

type QueryRecord = {
  table: string;
  columns?: string;
  filters: Array<{ method: string; args: unknown[] }>;
};

const mocks = vi.hoisted(() => {
  const state = {
    notifications: [] as any[],
    notificationsError: null as any,
    profileSearch: [] as any[],
    profileSearchError: null as any,
    targetUsers: [] as any[],
    targetUsersError: null as any,
    targetProfile: { id: 'user-1', full_name: 'Target User' } as any,
    targetProfileError: null as any,
    insertError: null as any,
    upsertError: null as any,
  };
  const queries: QueryRecord[] = [];
  const insertCalls: Array<{ table: string; payload: any }> = [];
  const upsertCalls: Array<{ table: string; payload: any; options: any }> = [];

  const resultFor = (record: QueryRecord) => {
    if (record.table === 'notifications') {
      return { data: state.notifications, error: state.notificationsError };
    }
    if (record.table === 'profiles' && record.filters.some(filter => filter.method === 'ilike')) {
      return { data: state.profileSearch, error: state.profileSearchError };
    }
    if (record.table === 'profiles' && record.columns?.includes('full_name')) {
      return { data: state.targetProfile, error: state.targetProfileError };
    }
    if (record.table === 'profiles') {
      return { data: state.targetUsers, error: state.targetUsersError };
    }
    return { data: [], error: null };
  };

  const makeQuery = (record: QueryRecord): any => {
    const query: any = {
      order: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'order', args });
        return query;
      }),
      range: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'range', args });
        return Promise.resolve(resultFor(record));
      }),
      ilike: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'ilike', args });
        return query;
      }),
      limit: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'limit', args });
        return Promise.resolve(resultFor(record));
      }),
      is: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'is', args });
        return query;
      }),
      or: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'or', args });
        return query;
      }),
      eq: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'eq', args });
        return query;
      }),
      single: vi.fn(() => Promise.resolve(resultFor(record))),
      then: (onFulfilled: any, onRejected: any) => Promise.resolve(resultFor(record)).then(onFulfilled, onRejected),
    };
    return query;
  };

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns: string) => {
      const record = { table, columns, filters: [] };
      queries.push(record);
      return makeQuery(record);
    }),
    insert: vi.fn((payload: any) => {
      insertCalls.push({ table, payload });
      return Promise.resolve({ error: state.insertError });
    }),
    upsert: vi.fn((payload: any, options: any) => {
      upsertCalls.push({ table, payload, options });
      return Promise.resolve({ error: state.upsertError });
    }),
  }));

  return {
    state,
    queries,
    insertCalls,
    upsertCalls,
    mockFrom,
    mockToast: vi.fn(),
    mockConfirm: vi.fn(),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
    mockChannel: vi.fn(() => ({
      on: vi.fn().mockReturnThis(),
      subscribe: vi.fn(() => ({ channel: 'admin-notifications' })),
    })),
    mockRemoveChannel: vi.fn(),
  };
});

vi.mock('@/app/loading', () => ({
  default: () => <div>Loading</div>,
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({
    language: 'en',
    t: (_key: string, fallback?: string) => fallback ?? _key,
  }),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast, confirm: mocks.mockConfirm }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: mocks.mockLogAdminAction,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mocks.mockFrom,
    channel: mocks.mockChannel,
    removeChannel: mocks.mockRemoveChannel,
  },
}));

describe('NotificationsPage', () => {
  beforeEach(() => {
    mocks.state.notifications = [{
      id: 'notif-1',
      user_id: 'user-1',
      title: 'Route update',
      body: 'Your route changed',
      data: { type: 'admin_notification' },
      is_read: false,
      created_at: '2026-05-07T08:00:00.000Z',
      profile: { full_name: 'Requester One' },
    }];
    mocks.state.notificationsError = null;
    mocks.state.profileSearch = [];
    mocks.state.profileSearchError = null;
    mocks.state.targetUsers = [{ id: 'user-1' }, { id: 'user-2' }];
    mocks.state.targetUsersError = null;
    mocks.state.targetProfile = { id: 'user-1', full_name: 'Target User' };
    mocks.state.targetProfileError = null;
    mocks.state.insertError = null;
    mocks.state.upsertError = null;
    mocks.queries.length = 0;
    mocks.insertCalls.length = 0;
    mocks.upsertCalls.length = 0;
    mocks.mockFrom.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockConfirm.mockClear();
    mocks.mockLogAdminAction.mockClear();
    mocks.mockChannel.mockClear();
    mocks.mockRemoveChannel.mockClear();
  });

  it('loads notifications with profile names and localized unread text', async () => {
    render(<NotificationsPage />);

    await expect(screen.findByText('Route update')).resolves.toBeInTheDocument();
    expect(screen.getByText('Requester One')).toBeInTheDocument();
    expect(screen.getByText('Unread')).toBeInTheDocument();
    expect(mocks.queries).toEqual(expect.arrayContaining([
      expect.objectContaining({
        table: 'notifications',
        columns: '*, profile:profiles!notifications_user_id_fkey(full_name)',
      }),
    ]));
  });

  it('confirms broadcast sends and upserts idempotent notification rows for active users', async () => {
    render(<NotificationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /send notification/i }));
    fireEvent.change(screen.getByPlaceholderText('Notification title...'), { target: { value: 'System notice' } });
    fireEvent.change(screen.getByPlaceholderText('Notification body...'), { target: { value: 'Please check your account.' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send' }));

    await waitFor(() => {
      expect(mocks.mockConfirm).toHaveBeenCalledWith(expect.objectContaining({
        message: 'Send this notification to 2 users? This cannot be undone.',
      }));
    });
    expect(mocks.upsertCalls).toHaveLength(0);

    await act(async () => {
      await mocks.mockConfirm.mock.calls[0][0].onConfirm();
    });

    expect(mocks.upsertCalls).toEqual(expect.arrayContaining([
      expect.objectContaining({
        table: 'notifications',
        options: { onConflict: 'idempotency_key', ignoreDuplicates: true },
      }),
    ]));
    expect(mocks.upsertCalls[0].payload[0]).toEqual(expect.objectContaining({
      user_id: 'user-1',
      title: 'System notice',
      body: 'Please check your account.',
      data: { type: 'admin_broadcast' },
      idempotency_key: expect.stringMatching(/^admin-/),
    }));
    const profilesQuery = mocks.queries.find(query => query.table === 'profiles' && query.columns === 'id');
    expect(profilesQuery?.filters).toEqual(expect.arrayContaining([
      { method: 'is', args: ['deleted_at', null] },
      { method: 'or', args: ['is_suspended.is.null,is_suspended.eq.false'] },
      { method: 'or', args: ['is_admin.is.null,is_admin.eq.false'] },
      { method: 'or', args: ['traveler_status.is.null,traveler_status.not.in.(blocked,suspended)'] },
      { method: 'or', args: ['company_status.is.null,company_status.not.in.(blocked,suspended)'] },
    ]));
  });

  it('uses approved traveler status for the travelers segment', async () => {
    render(<NotificationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /send notification/i }));
    fireEvent.click(screen.getByRole('button', { name: 'Segment' }));
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'travelers' } });
    fireEvent.change(screen.getByPlaceholderText('Notification title...'), { target: { value: 'Traveler notice' } });
    fireEvent.change(screen.getByPlaceholderText('Notification body...'), { target: { value: 'For active travelers.' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send' }));

    await waitFor(() => {
      expect(mocks.mockConfirm).toHaveBeenCalled();
    });
    const targetQuery = mocks.queries.find(query =>
      query.table === 'profiles' &&
      query.columns === 'id' &&
      query.filters.some(filter => filter.method === 'eq' && filter.args[0] === 'traveler_status')
    );
    expect(targetQuery?.filters).toContainEqual({ method: 'eq', args: ['traveler_status', 'approved'] });
  });

  it('validates a single target user before inserting one notification', async () => {
    render(<NotificationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /send notification/i }));
    fireEvent.click(screen.getByRole('button', { name: 'Single User' }));
    fireEvent.change(screen.getByPlaceholderText('Paste user UUID...'), { target: { value: 'user-1' } });
    fireEvent.change(screen.getByPlaceholderText('Notification title...'), { target: { value: 'Direct notice' } });
    fireEvent.change(screen.getByPlaceholderText('Notification body...'), { target: { value: 'Hello.' } });
    fireEvent.click(screen.getByRole('button', { name: 'Send' }));

    await waitFor(() => {
      expect(mocks.insertCalls).toContainEqual({
        table: 'notifications',
        payload: {
          user_id: 'user-1',
          title: 'Direct notice',
          body: 'Hello.',
          data: { type: 'admin_notification' },
        },
      });
    });
    const profileValidationQuery = mocks.queries.find(query =>
      query.table === 'profiles' &&
      query.columns === 'id, full_name'
    );
    expect(profileValidationQuery?.filters).toContainEqual({ method: 'eq', args: ['id', 'user-1'] });
  });

  it('performs server-side search for notification title/body and profile names', async () => {
    mocks.state.profileSearch = [{ id: 'user-1' }];

    render(<NotificationsPage />);
    await screen.findByText('Route update');

    fireEvent.change(screen.getByPlaceholderText('Search notifications...'), { target: { value: 'Requester' } });

    await waitFor(() => {
      expect(mocks.queries.some(query =>
        query.table === 'profiles' &&
        query.filters.some(filter => filter.method === 'ilike' && filter.args[0] === 'full_name')
      )).toBe(true);
    });
    expect(mocks.queries.some(query =>
      query.table === 'notifications' &&
      query.filters.some(filter => filter.method === 'or' && String(filter.args[0]).includes('user_id.in.(user-1)'))
    )).toBe(true);
  });

  it('shows a retryable error when notifications fail to load', async () => {
    mocks.state.notificationsError = { message: 'permission denied' };

    render(<NotificationsPage />);

    await expect(screen.findByText('Failed to load notifications.')).resolves.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Retry' })).toBeInTheDocument();
  });
});
