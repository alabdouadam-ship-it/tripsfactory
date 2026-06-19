import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { I18nProvider, useI18n, useT } from './i18n';

function TestConsumer() {
  const { language, setLanguage, t, dir } = useI18n();
  return (
    <div>
      <span data-testid="lang">{language}</span>
      <span data-testid="dir">{dir}</span>
      <span data-testid="nav">{t('nav.dashboard')}</span>
      <span data-testid="unknown">{t('unknown.key', 'fallback')}</span>
      <button onClick={() => setLanguage('ar')}>AR</button>
      <button onClick={() => setLanguage('en')}>EN</button>
    </div>
  );
}

function TOnlyConsumer() {
  const t = useT();
  return <span data-testid="t">{t('common.loading')}</span>;
}

describe('I18nProvider', () => {
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

  it('provides default language and t', () => {
    render(
      <I18nProvider>
        <TestConsumer />
      </I18nProvider>
    );
    expect(screen.getByTestId('lang').textContent).toBe('en');
    expect(screen.getByTestId('dir').textContent).toBe('ltr');
    expect(screen.getByTestId('nav').textContent).toBe('Dashboard');
    expect(screen.getByTestId('unknown').textContent).toBe('fallback');
  });

  it('returns key when no fallback and key missing', () => {
    function W() {
      const t = useT();
      return <span data-testid="missing">{t('missing.key')}</span>;
    }
    render(
      <I18nProvider>
        <W />
      </I18nProvider>
    );
    expect(screen.getByTestId('missing').textContent).toBe('missing.key');
  });

  it('updates language and dir when setLanguage called', async () => {
    const user = userEvent.setup();
    render(
      <I18nProvider>
        <TestConsumer />
      </I18nProvider>
    );
    await user.click(screen.getByText('AR'));
    expect(screen.getByTestId('lang').textContent).toBe('ar');
    expect(screen.getByTestId('dir').textContent).toBe('rtl');
    expect(screen.getByTestId('nav').textContent).toBe('لوحة التحكم');
    await user.click(screen.getByText('EN'));
    expect(screen.getByTestId('lang').textContent).toBe('en');
    expect(screen.getByTestId('dir').textContent).toBe('ltr');
  });

  it('initializes with ar when localStorage has "ar"', async () => {
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn(() => 'ar'),
        setItem: vi.fn(),
        removeItem: vi.fn(),
      },
      writable: true,
    });
    render(
      <I18nProvider>
        <TestConsumer />
      </I18nProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    expect(screen.getByTestId('lang').textContent).toBe('ar');
    expect(screen.getByTestId('dir').textContent).toBe('rtl');
  });

  it('initializes with en when localStorage has invalid value', async () => {
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn(() => 'fr'),
        setItem: vi.fn(),
        removeItem: vi.fn(),
      },
      writable: true,
    });
    render(
      <I18nProvider>
        <TestConsumer />
      </I18nProvider>
    );
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    expect(screen.getByTestId('lang').textContent).toBe('en');
  });

  it('persists language to localStorage when setLanguage called', async () => {
    const setItem = vi.fn();
    Object.defineProperty(window, 'localStorage', {
      value: { getItem: vi.fn(() => null), setItem, removeItem: vi.fn() },
      writable: true,
    });
    const user = userEvent.setup();
    render(
      <I18nProvider>
        <TestConsumer />
      </I18nProvider>
    );
    await user.click(screen.getByText('AR'));
    expect(setItem).toHaveBeenCalledWith('tripship_admin_language', 'ar');
  });
});

describe('useT', () => {
  it('returns translation function', () => {
    render(
      <I18nProvider>
        <TOnlyConsumer />
      </I18nProvider>
    );
    expect(screen.getByTestId('t').textContent).toBe('Loading...');
  });
});

describe('useI18n', () => {
  it('throws when used outside I18nProvider', () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const Consumer = () => {
      useI18n();
      return null;
    };
    expect(() => render(<Consumer />)).toThrow('useI18n must be used within I18nProvider');
    (console.error as ReturnType<typeof vi.fn>).mockRestore();
  });
});
