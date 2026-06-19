import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { TrustBadgeControls } from './TrustBadgeControls';

const { mockToast, mockSetTrustBadge, mockOnChange } = vi.hoisted(() => ({
  mockToast: vi.fn(),
  mockSetTrustBadge: vi.fn(() => Promise.resolve({ success: true })),
  mockOnChange: vi.fn(),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

vi.mock('@/app/actions/user-actions', () => ({
  setTrustBadge: mockSetTrustBadge,
}));

const baseUser = {
  id: 'user-1',
  full_name: 'Driver User',
  avatar_url: null,
  phone_number: null,
  account_type: 'individual' as const,
  traveler_status: 'approved' as const,
  is_driver: true,
  is_trusted: false,
  is_featured: false,
  trust_badge: null,
  created_at: '2026-01-01T00:00:00.000Z',
};

describe('TrustBadgeControls', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockSetTrustBadge.mockClear();
    mockOnChange.mockClear();
  });

  it('keeps featured driver badge tier and flags in sync', async () => {
    render(<TrustBadgeControls user={baseUser} onChange={mockOnChange} />);

    fireEvent.click(screen.getByRole('button', { name: 'Feature' }));

    await waitFor(() => expect(mockSetTrustBadge).toHaveBeenCalled());
    expect(mockSetTrustBadge).toHaveBeenCalledWith('user-1', {
      trust_badge: 'featured_driver',
      is_trusted: false,
      is_featured: true,
    });
    expect(mockOnChange).toHaveBeenCalledWith({
      trust_badge: 'featured_driver',
      is_trusted: false,
      is_featured: true,
    });
  });

  it('clears tier and flags when selecting none', async () => {
    render(
      <TrustBadgeControls
        user={{
          ...baseUser,
          is_featured: true,
          trust_badge: 'featured_driver',
        }}
        onChange={mockOnChange}
      />
    );

    fireEvent.click(screen.getByRole('button', { name: 'None' }));

    await waitFor(() => expect(mockSetTrustBadge).toHaveBeenCalled());
    expect(mockSetTrustBadge).toHaveBeenCalledWith('user-1', {
      trust_badge: null,
      is_trusted: false,
      is_featured: false,
    });
  });
});
