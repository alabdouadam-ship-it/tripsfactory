import React from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { Providers } from './Providers';

vi.mock('@/components/AuthGuard', () => ({
  AuthGuard: ({ children }: { children: React.ReactNode }) => <div data-testid="auth-guard">{children}</div>,
}));
vi.mock('@/components/CommandPalette', () => ({
  CommandPalette: () => <div data-testid="command-palette">Palette</div>,
}));

describe('Providers', () => {
  it('renders children inside provider stack', () => {
    render(
      <Providers>
        <span>Child content</span>
      </Providers>
    );
    expect(screen.getByTestId('auth-guard')).toBeInTheDocument();
    expect(screen.getByText('Child content')).toBeInTheDocument();
    expect(screen.getByTestId('command-palette')).toBeInTheDocument();
  });

  it('applies theme to document (ThemeProvider in tree)', async () => {
    render(
      <Providers>
        <span>Child</span>
      </Providers>
    );
    await waitFor(() => {
      const theme = document.documentElement.getAttribute('data-theme');
      expect(theme).toBeDefined();
      expect(typeof theme).toBe('string');
    }, { timeout: 2000 });
  });
});
