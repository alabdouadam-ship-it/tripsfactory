import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import Loading from './loading';
import { I18nProvider } from '@/lib/i18n';

function renderWithI18n(ui: React.ReactElement) {
  return render(<I18nProvider>{ui}</I18nProvider>);
}

describe('Loading', () => {
  it('renders loading message', () => {
    renderWithI18n(<Loading />);
    expect(screen.getByText('Loading data...')).toBeInTheDocument();
  });

  it('renders spinner element', () => {
    const { container } = renderWithI18n(<Loading />);
    const spinner = container.querySelector('.animate-spin');
    expect(spinner).toBeInTheDocument();
  });

  it('has accessible structure with min height', () => {
    const { container } = renderWithI18n(<Loading />);
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper.className).toMatch(/min-h/);
  });

  it('renders custom message when provided', () => {
    renderWithI18n(<Loading message="Fetching users..." />);
    expect(screen.getByText('Fetching users...')).toBeInTheDocument();
  });
});
