import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ErrorComponent from './error';

// Mock i18n so Error never calls real useI18n/useContext — avoids duplicate-React hook errors in this worker.
vi.mock('@/lib/i18n', () => ({
  useT: () => (key: string, fallback?: string) => fallback ?? key,
}));

let consoleErrorSpy: ReturnType<typeof vi.spyOn>;

beforeEach(() => {
  consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  consoleErrorSpy?.mockRestore();
});

function renderError(props: { error: Error; reset: () => void }) {
  return render(<ErrorComponent {...props} />);
}

describe('Error', () => {
  it('renders title and description', () => {
    renderError({
      error: new Error('Test error'),
      reset: () => {},
    });
    expect(screen.getByText('Something went wrong')).toBeInTheDocument();
    expect(screen.getByText(/unexpected error occurred/)).toBeInTheDocument();
  });

  it('renders Go Home and Try Again buttons', () => {
    renderError({ error: new Error('Test'), reset: () => {} });
    expect(screen.getByText('Go Home')).toBeInTheDocument();
    expect(screen.getByText('Try Again')).toBeInTheDocument();
  });

  it('calls reset when Try Again is clicked', async () => {
    const reset = vi.fn();
    const user = userEvent.setup();
    renderError({ error: new Error('Test'), reset });
    await user.click(screen.getByText('Try Again'));
    expect(reset).toHaveBeenCalledTimes(1);
  });

  it('does not call reset when Go Home is clicked', async () => {
    const reset = vi.fn();
    const user = userEvent.setup();
    const originalLocation = window.location;
    Object.defineProperty(window, 'location', {
      value: { ...originalLocation, href: '' },
      writable: true,
    });
    renderError({ error: new Error('Test'), reset });
    await user.click(screen.getByText('Go Home'));
    expect(reset).not.toHaveBeenCalled();
    Object.defineProperty(window, 'location', { value: originalLocation, writable: true });
  });

  it('renders error name and message in development', () => {
    const err = new Error('Test error');
    err.name = 'CustomError';
    const env = process.env as NodeJS.ProcessEnv & { NODE_ENV: string };
    const prev = env.NODE_ENV;
    env.NODE_ENV = 'development';
    try {
      renderError({ error: err, reset: () => {} });
      // Text appears in both the <p> (name: message) and the <pre> (stack)
      expect(screen.getAllByText(/CustomError: Test error/).length).toBeGreaterThanOrEqual(1);
    } finally {
      env.NODE_ENV = prev;
    }
  });
});
