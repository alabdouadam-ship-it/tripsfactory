import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ThemeProvider, useTheme } from './theme';

function TestConsumer() {
  const { theme, setTheme, themes } = useTheme();
  return (
    <div>
      <span data-testid="current">{theme}</span>
      <button onClick={() => setTheme('dark')}>Set Dark</button>
      <button onClick={() => setTheme('light')}>Set Light</button>
      <span data-testid="count">{themes.length}</span>
    </div>
  );
}

describe('ThemeProvider', () => {
  beforeEach(() => {
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn(() => null),
        setItem: vi.fn(),
        removeItem: vi.fn(),
      },
      writable: true,
    });
  });

  it('provides default theme and setTheme', async () => {
    render(
      <ThemeProvider>
        <TestConsumer />
      </ThemeProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    expect(screen.getByTestId('current').textContent).toBe('light');
    expect(screen.getByTestId('count').textContent).toBe('10');
  });

  it('updates theme when setTheme is called', async () => {
    const user = userEvent.setup();
    render(
      <ThemeProvider>
        <TestConsumer />
      </ThemeProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    await user.click(screen.getByText('Set Dark'));
    expect(screen.getByTestId('current').textContent).toBe('dark');
    await user.click(screen.getByText('Set Light'));
    expect(screen.getByTestId('current').textContent).toBe('light');
  });

  it('reads valid theme from localStorage on mount', async () => {
    const getItem = vi.fn(() => 'dark');
    Object.defineProperty(window, 'localStorage', {
      value: { getItem, setItem: vi.fn(), removeItem: vi.fn() },
      writable: true,
    });
    render(
      <ThemeProvider>
        <TestConsumer />
      </ThemeProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    expect(screen.getByTestId('current').textContent).toBe('dark');
  });

  it('falls back to light when localStorage has invalid theme', async () => {
    const getItem = vi.fn(() => 'invalid_theme');
    Object.defineProperty(window, 'localStorage', {
      value: { getItem, setItem: vi.fn(), removeItem: vi.fn() },
      writable: true,
    });
    render(
      <ThemeProvider>
        <TestConsumer />
      </ThemeProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    expect(screen.getByTestId('current').textContent).toBe('light');
  });

  it('supports all theme ids', async () => {
    const user = userEvent.setup();
    function AllThemes() {
      const { theme, setTheme, themes } = useTheme();
      return (
        <div>
          <span data-testid="current">{theme}</span>
          {themes.map((t) => (
            <button key={t.id} onClick={() => setTheme(t.id)}>
              {t.id}
            </button>
          ))}
        </div>
      );
    }
    render(
      <ThemeProvider>
        <AllThemes />
      </ThemeProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    const ids = ['midnight', 'dark', 'dim', 'light', 'bright', 'crimson', 'forest', 'ocean', 'amber', 'violet'];
    for (const id of ids) {
      await user.click(screen.getByText(id));
      expect(screen.getByTestId('current').textContent).toBe(id);
    }
  });
});

describe('useTheme', () => {
  it('throws when used outside ThemeProvider', () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => render(<TestConsumer />)).toThrow('useTheme must be used within ThemeProvider');
    (console.error as ReturnType<typeof vi.fn>).mockRestore();
  });
});
