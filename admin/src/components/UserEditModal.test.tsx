import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { UserEditModal } from './UserEditModal';

const { mockToast, mockUpdateUserProfile, mockOnClose, mockOnSaved } = vi.hoisted(() => ({
  mockToast: vi.fn(),
  mockUpdateUserProfile: vi.fn(() => Promise.resolve({ success: true })),
  mockOnClose: vi.fn(),
  mockOnSaved: vi.fn(),
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mockToast }),
}));

vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

vi.mock('@/app/actions/user-actions', () => ({
  updateUserProfile: mockUpdateUserProfile,
}));

const baseUser = {
  id: 'user-1',
  full_name: 'Existing User',
  avatar_url: null,
  phone_number: '+966500000000',
  bio: 'Existing bio',
  identity_type: 'passport',
  traveler_type: 'with_vehicle' as const,
  is_available: true,
  created_at: '2026-01-01T00:00:00.000Z',
};

describe('UserEditModal', () => {
  beforeEach(() => {
    mockToast.mockClear();
    mockUpdateUserProfile.mockClear();
    mockOnClose.mockClear();
    mockOnSaved.mockClear();
  });

  it('edits profile fields without exposing role conversion controls', async () => {
    render(<UserEditModal user={baseUser} onClose={mockOnClose} onSaved={mockOnSaved} />);

    expect(screen.queryByText('Account Type')).not.toBeInTheDocument();

    fireEvent.change(screen.getByDisplayValue('+966500000000'), { target: { value: '' } });
    fireEvent.change(screen.getByDisplayValue('Existing bio'), { target: { value: '' } });
    fireEvent.change(screen.getAllByRole('combobox')[0], { target: { value: '' } });

    fireEvent.click(screen.getByRole('button', { name: /save/i }));

    await waitFor(() => expect(mockUpdateUserProfile).toHaveBeenCalled());
    expect(mockUpdateUserProfile).toHaveBeenCalledWith('user-1', expect.objectContaining({
      full_name: 'Existing User',
      phone_number: null,
      bio: null,
      identity_type: null,
      is_available: true,
    }));
    const callArgs = (mockUpdateUserProfile.mock.calls[0] as any[])[1];
    expect(callArgs).not.toHaveProperty('account_type');
    expect(callArgs).not.toHaveProperty('is_driver');
  });
});
