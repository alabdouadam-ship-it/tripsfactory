import { beforeEach, describe, expect, it, vi } from 'vitest';
import { getPaginatedBookings } from './ux-actions';

const mocks = vi.hoisted(() => {
  const state = {
    rangeResult: { data: [], count: 0, error: null as any },
  };
  const selectCalls: Array<{ table: string; columns: string; options?: any }> = [];

  const query: any = {
    or: vi.fn(() => query),
    eq: vi.fn(() => query),
    ilike: vi.fn(() => query),
    gte: vi.fn(() => query),
    lte: vi.fn(() => query),
    order: vi.fn(() => query),
    range: vi.fn(() => Promise.resolve(state.rangeResult)),
  };

  return {
    state,
    selectCalls,
    query,
    mockFrom: vi.fn((table: string) => ({
      select: vi.fn((columns: string, options?: any) => {
        selectCalls.push({ table, columns, options });
        return query;
      }),
    })),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
  };
});

vi.mock('@/lib/supabase', () => ({
  supabase: {
    from: mocks.mockFrom,
    auth: { getUser: vi.fn() },
  },
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: mocks.mockLogAdminAction,
}));

describe('getPaginatedBookings', () => {
  beforeEach(() => {
    mocks.state.rangeResult = { data: [], count: 0, error: null };
    mocks.selectCalls.length = 0;
    mocks.mockFrom.mockClear();
    Object.values(mocks.query).forEach((fn) => {
      if (typeof fn === 'function' && 'mockClear' in fn) fn.mockClear();
    });
  });

  it('loads bookings through the trip reservation profile joins', async () => {
    const result = await getPaginatedBookings({ page: 1, pageSize: 25 });

    expect(result.success).toBe(true);
    const select = mocks.selectCalls[0];
    expect(select.table).toBe('bookings');
    expect(select.columns).toContain('requester_profile:profiles!bookings_requester_id_profiles_fkey');
    expect(select.columns).toContain('driver_profile:profiles!bookings_traveler_id_fkey');
    expect(select.columns).not.toContain('requester_profile:profiles!bookings_requester_id_fkey');
    expect(select.columns).not.toContain('shipments');
  });

  it('returns the Supabase error message instead of Unknown error', async () => {
    mocks.state.rangeResult = {
      data: null,
      count: null,
      error: { message: 'Could not find a relationship between bookings and profiles' },
    };

    const result = await getPaginatedBookings({ page: 1, pageSize: 25 });

    expect(result.success).toBe(false);
    expect(result.error).toBe('Could not find a relationship between bookings and profiles');
  });
});
