import React from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import ReviewsPage from './page';

const mocks = vi.hoisted(() => {
  const state = {
    ratings: [] as any[],
    selectError: null as any,
    updateError: null as any,
  };
  const selectCalls: string[] = [];
  const updateCalls: any[] = [];

  const mockDelete = vi.fn(() => ({
    eq: vi.fn(() => Promise.resolve({ error: null })),
  }));

  const makeSelectQuery = () => {
    const query: any = {
      gte: vi.fn(() => query),
      lte: vi.fn(() => query),
      order: vi.fn(() => Promise.resolve({
        data: state.ratings,
        error: state.selectError,
      })),
    };
    return query;
  };

  const mockFrom = vi.fn(() => ({
    select: vi.fn((columns: string) => {
      selectCalls.push(columns);
      return makeSelectQuery();
    }),
    update: vi.fn((payload: any) => ({
      eq: vi.fn((field: string, value: string) => {
        updateCalls.push({ payload, field, value });
        return Promise.resolve({ error: state.updateError });
      }),
    })),
    delete: mockDelete,
  }));

  return {
    state,
    selectCalls,
    updateCalls,
    mockFrom,
    mockDelete,
    mockToast: vi.fn(),
    mockConfirm: vi.fn(({ onConfirm }: { onConfirm: () => void }) => onConfirm()),
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
    t: vi.fn((key: string, fallback?: string) => fallback ?? key),
  };
});

vi.mock('next/link', () => ({
  default: ({ children, href, className }: { children: React.ReactNode; href: string; className?: string }) => (
    <a href={href} className={className}>{children}</a>
  ),
}));

vi.mock('@/app/loading', () => ({
  default: () => <div>Loading</div>,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mocks.mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast, confirm: mocks.mockConfirm }),
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

describe('ReviewsPage', () => {
  beforeEach(() => {
    mocks.state.ratings = [];
    mocks.state.selectError = null;
    mocks.state.updateError = null;
    mocks.selectCalls.length = 0;
    mocks.updateCalls.length = 0;
    mocks.mockFrom.mockClear();
    mocks.mockDelete.mockClear();
    mocks.mockToast.mockClear();
    mocks.mockConfirm.mockClear();
    mocks.mockLogAdminAction.mockClear();
    mocks.t.mockClear();
  });

  it('keeps no-comment ratings visible when search is empty', async () => {
    mocks.state.ratings = [{
      id: 'rating-empty',
      rater_id: 'rater-1',
      rated_id: 'rated-1',
      role_rated: 'client',
      rating: 4,
      comment: null,
      comment_status: null,
      booking_id: null,
      offer_id: null,
      created_at: '2026-05-01T10:00:00.000Z',
    }];

    render(<ReviewsPage />);

    await expect(screen.findByText('No comment', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(screen.getByText('Sender / Company')).toBeInTheDocument();
    expect(screen.getByText('No linked trip or shipment')).toBeInTheDocument();
  });

  it('filters pending comment moderation without treating commentless ratings as pending comments', async () => {
    mocks.state.ratings = [
      {
        id: 'rating-commentless',
        rater_id: 'rater-1',
        rated_id: 'rated-1',
        role_rated: 'client',
        rating: 5,
        comment: null,
        comment_status: null,
        booking_id: null,
        offer_id: null,
        created_at: '2026-05-01T10:00:00.000Z',
      },
      {
        id: 'rating-pending',
        rater_id: 'rater-2',
        rated_id: 'rated-2',
        role_rated: 'driver',
        rating: 2,
        comment: 'Needs review',
        comment_status: 'pending',
        booking_id: null,
        offer_id: null,
        created_at: '2026-05-02T10:00:00.000Z',
      },
    ];

    render(<ReviewsPage />);

    await screen.findByText('Needs review', {}, { timeout: 3000 });
    fireEvent.click(screen.getByRole('button', { name: 'Pending' }));

    expect(screen.getByText('Needs review')).toBeInTheDocument();
    expect(screen.queryByText('No comment')).not.toBeInTheDocument();
  });

  it('deletes only the comment text and preserves the rating row', async () => {
    mocks.state.ratings = [{
      id: 'rating-delete-comment',
      rater_id: 'rater-1',
      rated_id: 'rated-1',
      role_rated: 'driver',
      rating: 1,
      comment: 'Abusive comment',
      comment_status: 'pending',
      booking_id: null,
      offer_id: null,
      created_at: '2026-05-01T10:00:00.000Z',
    }];

    render(<ReviewsPage />);

    await screen.findByText('Abusive comment', {}, { timeout: 3000 });
    fireEvent.click(screen.getByTitle('Delete comment'));

    await waitFor(() => {
      expect(mocks.updateCalls).toContainEqual({
        payload: { comment: null, comment_status: 'rejected' },
        field: 'id',
        value: 'rating-delete-comment',
      });
    });
    expect(mocks.mockDelete).not.toHaveBeenCalled();
    expect(mocks.mockLogAdminAction).toHaveBeenCalledWith('delete_rating_comment', 'rating', 'rating-delete-comment');
    expect(mocks.mockToast).toHaveBeenCalledWith('Comment deleted', 'success');
    expect(screen.getByText('No comment')).toBeInTheDocument();
  });

  it('renders booking and shipment-offer context links', async () => {
    mocks.state.ratings = [
      {
        id: 'rating-booking',
        rater_id: 'rater-1',
        rated_id: 'rated-1',
        role_rated: 'driver',
        rating: 5,
        comment: 'Trip was good',
        comment_status: 'approved',
        booking_id: 'booking-12345678',
        offer_id: null,
        created_at: '2026-05-01T10:00:00.000Z',
      },
      {
        id: 'rating-offer',
        rater_id: 'rater-2',
        rated_id: 'rated-2',
        role_rated: 'client',
        rating: 4,
        comment: 'Shipment was good',
        comment_status: 'approved',
        booking_id: null,
        offer_id: 'offer-12345678',
        offer: {
          id: 'offer-12345678',
          shipment_id: 'shipment-12345678',
          shipment: {
            id: 'shipment-12345678',
            pickup: { city_name_en: 'Damascus' },
            dropoff: { city_name_en: 'Aleppo' },
          },
        },
        created_at: '2026-05-02T10:00:00.000Z',
      },
    ];

    render(<ReviewsPage />);

    await screen.findByText('Trip was good', {}, { timeout: 3000 });
    expect(mocks.selectCalls[0]).toContain('booking:bookings');
    expect(mocks.selectCalls[0]).toContain('offer:offers');
    expect(screen.getByRole('link', { name: /Trip booking #booking-/ })).toHaveAttribute(
      'href',
      '/bookings/booking-12345678',
    );
    expect(screen.getByRole('link', { name: /Shipment offer - Damascus - Aleppo/ })).toHaveAttribute(
      'href',
      '/shipments/shipment-12345678',
    );
  });

  it('shows a visible retry state when reviews fail to load', async () => {
    mocks.state.selectError = { message: 'permission denied' };

    render(<ReviewsPage />);

    await expect(screen.findByText('Failed to load reviews.', {}, { timeout: 3000 })).resolves.toBeInTheDocument();
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
    expect(mocks.mockToast).toHaveBeenCalledWith('Failed to load reviews.', 'error');
  });
});
