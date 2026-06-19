import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import SupportPage from './page';

const mocks = vi.hoisted(() => {
  const state = {
    tickets: [] as any[],
    profiles: [] as any[],
    messages: [] as any[],
    ticketsError: null as any,
    profilesError: null as any,
    messagesError: null as any,
    insertError: null as any,
    notificationInsertError: null as any,
    updateError: null as any,
    user: { id: 'admin-user-id' } as any,
  };
  const selectCalls: Array<{ table: string; columns: string }> = [];
  const insertCalls: Array<{ table: string; payload: any }> = [];
  const updateCalls: Array<{ table: string; payload: any; eqs: Array<{ field: string; value: any }> }> = [];

  const makeSelectQuery = (table: string) => {
    const query: any = {
      eq: vi.fn(() => query),
      order: vi.fn(() => {
        if (table === 'support_tickets') {
          return Promise.resolve({ data: state.tickets, error: state.ticketsError });
        }
        if (table === 'support_messages') {
          return Promise.resolve({ data: state.messages, error: state.messagesError });
        }
        return Promise.resolve({ data: [], error: null });
      }),
      in: vi.fn(() => Promise.resolve({ data: state.profiles, error: state.profilesError })),
    };
    return query;
  };

  const makeUpdateQuery = (table: string, payload: any) => {
    const record = { table, payload, eqs: [] as Array<{ field: string; value: any }> };
    const query: any = {
      error: state.updateError,
      eq: vi.fn((field: string, value: any) => {
        record.eqs.push({ field, value });
        return query;
      }),
    };
    updateCalls.push(record);
    return query;
  };

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns: string) => {
      selectCalls.push({ table, columns });
      return makeSelectQuery(table);
    }),
    insert: vi.fn((payload: any) => {
      insertCalls.push({ table, payload });
      return Promise.resolve({ error: table === 'notifications' ? state.notificationInsertError : state.insertError });
    }),
    update: vi.fn((payload: any) => makeUpdateQuery(table, payload)),
  }));

  return {
    state,
    selectCalls,
    insertCalls,
    updateCalls,
    mockFrom,
    mockToast: vi.fn(),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
    mockChannel: vi.fn(() => ({
      on: vi.fn().mockReturnThis(),
      subscribe: vi.fn(() => ({ channel: 'support-tickets' })),
    })),
    mockRemoveChannel: vi.fn(),
    t: vi.fn((key: string, fallback?: string) => fallback ?? key),
  };
});

vi.mock('next/link', () => ({
  default: ({ children, href, className, onClick }: { children: React.ReactNode; href: string; className?: string; onClick?: React.MouseEventHandler<HTMLAnchorElement> }) => (
    <a href={href} className={className} onClick={onClick}>{children}</a>
  ),
}));

vi.mock('@/app/loading', () => ({
  default: () => <div>Loading</div>,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mocks.mockFrom,
    auth: { getUser: vi.fn(() => Promise.resolve({ data: { user: mocks.state.user } })) },
    channel: mocks.mockChannel,
    removeChannel: mocks.mockRemoveChannel,
  },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast }),
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: mocks.mockLogAdminAction,
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({
    t: mocks.t,
    language: 'en' as const,
    dir: 'ltr' as const,
  }),
}));

describe('SupportPage', () => {
  beforeEach(() => {
    Element.prototype.scrollIntoView = vi.fn();
    mocks.state.tickets = [];
    mocks.state.profiles = [];
    mocks.state.messages = [];
    mocks.state.ticketsError = null;
    mocks.state.profilesError = null;
    mocks.state.messagesError = null;
    mocks.state.insertError = null;
    mocks.state.notificationInsertError = null;
    mocks.state.updateError = null;
    mocks.state.user = { id: 'admin-user-id' };
    mocks.selectCalls.length = 0;
    mocks.insertCalls.length = 0;
    mocks.updateCalls.length = 0;
    mocks.mockFrom.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockLogAdminAction.mockClear();
    mocks.mockChannel.mockClear();
    mocks.mockRemoveChannel.mockClear();
    mocks.t.mockClear();
  });

  function seedTicket(status = 'open') {
    mocks.state.tickets = [{
      id: 'ticket-12345678',
      user_id: 'user-123',
      subject: 'Payment issue',
      status,
      created_at: '2026-05-01T10:00:00.000Z',
      updated_at: '2026-05-02T10:00:00.000Z',
      resolved_by: null,
      resolved_at: null,
    }];
    mocks.state.profiles = [{
      id: 'user-123',
      full_name: 'Requester One',
      phone_number: '+963900000000',
    }];
  }

  it('loads tickets and profiles without using the invalid support_tickets profiles FK join', async () => {
    seedTicket();

    render(<SupportPage />);

    await expect(screen.findByText('Payment issue', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Requester One' })).toHaveAttribute('href', '/users/user-123');
    expect(mocks.selectCalls).toContainEqual({ table: 'support_tickets', columns: '*' });
    expect(mocks.selectCalls.find(call => call.table === 'support_tickets')?.columns).not.toContain('profiles');
    expect(mocks.selectCalls).toContainEqual({ table: 'profiles', columns: 'id, full_name, phone_number' });
  });

  it('shows a retryable message error instead of an empty thread', async () => {
    seedTicket();
    mocks.state.messagesError = { message: 'permission denied' };

    render(<SupportPage />);

    fireEvent.click(await screen.findByText('Payment issue', {}, { timeout: 3000 }));

    await expect(screen.findByText('Failed to load messages.', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    expect(mocks.mockToast).toHaveBeenCalledWith('Failed to load messages.', 'error');
  });

  it('sends admin replies, touches ticket activity, and includes ticket_id in the notification', async () => {
    seedTicket();
    mocks.state.messages = [{
      id: 'message-1',
      ticket_id: 'ticket-12345678',
      sender_id: 'user-123',
      sender_role: 'user',
      content: 'Please help',
      is_read: false,
      created_at: '2026-05-02T10:00:00.000Z',
    }];

    render(<SupportPage />);

    fireEvent.click(await screen.findByText('Payment issue', {}, { timeout: 3000 }));
    await screen.findByText('Please help');
    fireEvent.change(screen.getByPlaceholderText('Type your reply...'), {
      target: { value: 'We are checking this now.' },
    });
    fireEvent.click(screen.getByRole('button', { name: /send/i }));

    await waitFor(() => {
      expect(mocks.insertCalls).toContainEqual({
        table: 'support_messages',
        payload: {
          ticket_id: 'ticket-12345678',
          sender_id: 'admin-user-id',
          sender_role: 'admin',
          content: 'We are checking this now.',
        },
      });
    });
    expect(mocks.updateCalls).toEqual(expect.arrayContaining([
      expect.objectContaining({
        table: 'support_tickets',
        payload: expect.objectContaining({ updated_at: expect.any(String) }),
        eqs: [{ field: 'id', value: 'ticket-12345678' }],
      }),
    ]));
    expect(mocks.insertCalls).toEqual(expect.arrayContaining([
      {
        table: 'notifications',
        payload: {
          user_id: 'user-123',
          title: 'Support Reply',
          body: 'New reply on your ticket: "Payment issue"',
          data: { type: 'support_reply', ticket_id: 'ticket-12345678' },
        },
      },
    ]));
    expect(mocks.mockLogAdminAction).toHaveBeenCalledWith('support_reply', 'support_ticket', 'ticket-12345678', { user_id: 'user-123' });
  });

  it('shows a visible error when a support reply notification cannot be created', async () => {
    seedTicket();
    mocks.state.notificationInsertError = { message: 'notifications denied' };
    mocks.state.messages = [{
      id: 'message-1',
      ticket_id: 'ticket-12345678',
      sender_id: 'user-123',
      sender_role: 'user',
      content: 'Please help',
      is_read: false,
      created_at: '2026-05-02T10:00:00.000Z',
    }];

    render(<SupportPage />);

    fireEvent.click(await screen.findByText('Payment issue', {}, { timeout: 3000 }));
    await screen.findByText('Please help');
    fireEvent.change(screen.getByPlaceholderText('Type your reply...'), {
      target: { value: 'We are checking this now.' },
    });
    fireEvent.click(screen.getByRole('button', { name: /send/i }));

    await waitFor(() => {
      expect(mocks.mockToast).toHaveBeenCalledWith(
        'Reply sent, but the user notification was not created.',
        'error',
      );
    });
  });

  it('keeps resolved tickets read-only until reopened', async () => {
    seedTicket('resolved');

    render(<SupportPage />);

    fireEvent.click(await screen.findByText('Payment issue', {}, { timeout: 3000 }));

    expect(await screen.findByText('This ticket is closed. Reopen it before replying.')).toBeInTheDocument();
    expect(screen.queryByPlaceholderText('Type your reply...')).not.toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: /reopen/i }).length).toBeGreaterThan(0);
  });

  it('marks open tickets resolved through the admin status action', async () => {
    seedTicket('open');

    render(<SupportPage />);

    fireEvent.click(await screen.findByText('Payment issue', {}, { timeout: 3000 }));
    fireEvent.click(screen.getByTitle('Mark as resolved'));

    await waitFor(() => {
      expect(mocks.updateCalls).toEqual(expect.arrayContaining([
        expect.objectContaining({
          table: 'support_tickets',
          payload: expect.objectContaining({
            status: 'resolved',
            resolved_by: 'admin-user-id',
            resolved_at: expect.any(String),
          }),
          eqs: [{ field: 'id', value: 'ticket-12345678' }],
        }),
      ]));
    });
    expect(await screen.findByText('This ticket is closed. Reopen it before replying.')).toBeInTheDocument();
  });

  it('marks ignored tickets with closure metadata', async () => {
    seedTicket('open');

    render(<SupportPage />);

    fireEvent.click(await screen.findByText('Payment issue', {}, { timeout: 3000 }));
    fireEvent.click(screen.getByTitle('Mark as ignored'));

    await waitFor(() => {
      expect(mocks.updateCalls).toEqual(expect.arrayContaining([
        expect.objectContaining({
          table: 'support_tickets',
          payload: expect.objectContaining({
            status: 'ignored',
            resolved_by: 'admin-user-id',
            resolved_at: expect.any(String),
          }),
          eqs: [{ field: 'id', value: 'ticket-12345678' }],
        }),
      ]));
    });
    expect(await screen.findByText('This ticket is closed. Reopen it before replying.')).toBeInTheDocument();
  });
});
