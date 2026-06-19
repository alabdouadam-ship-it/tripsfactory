import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { TimelineStep, TimelineConnector } from './Timeline';
import { I18nProvider } from '@/lib/i18n';

function renderWithI18n(ui: React.ReactElement) {
  return render(<I18nProvider>{ui}</I18nProvider>);
}

describe('TimelineStep', () => {
  it('renders label', () => {
    renderWithI18n(<TimelineStep done={false} label="Step 1" />);
    expect(screen.getByText('Step 1')).toBeInTheDocument();
  });

  it('shows done styling when done is true', () => {
    const { container } = renderWithI18n(<TimelineStep done={true} label="Done" />);
    const dot = container.querySelector('.bg-blue-600');
    expect(dot).toBeInTheDocument();
  });

  it('shows incomplete styling when done is false', () => {
    const { container } = renderWithI18n(<TimelineStep done={false} label="Todo" />);
    const dot = container.querySelector('.theme-bg-secondary');
    expect(dot).toBeInTheDocument();
  });

  it('uses ts for title when provided', () => {
    renderWithI18n(<TimelineStep done={true} label="Step" ts="2024-01-15T10:00:00Z" />);
    const step = screen.getByText('Step').closest('div');
    expect(step).toHaveAttribute('title');
  });

  it('uses "Not yet" title when ts is null', () => {
    renderWithI18n(<TimelineStep done={false} label="Step" ts={null} />);
    const step = screen.getByText('Step').closest('div');
    expect(step).toHaveAttribute('title');
    expect(step?.getAttribute('title')).toBeTruthy();
  });

  it('uses "Not yet" title when ts is undefined', () => {
    renderWithI18n(<TimelineStep done={false} label="Step" />);
    const step = screen.getByText('Step').closest('div');
    expect(step).toHaveAttribute('title');
    expect(step?.getAttribute('title')).toBeTruthy();
  });
});

describe('TimelineConnector', () => {
  it('renders a connector element', () => {
    const { container } = renderWithI18n(<TimelineConnector />);
    const connector = container.firstChild as HTMLElement;
    expect(connector).toBeInTheDocument();
    expect(connector.className).toMatch(/flex-1/);
  });

  it('applies done style when done is true', () => {
    const { container } = renderWithI18n(<TimelineConnector done={true} />);
    expect(container.querySelector('.bg-blue-500\\/30')).toBeInTheDocument();
  });

  it('applies incomplete style when done is false or omitted', () => {
    const { container } = renderWithI18n(<TimelineConnector done={false} />);
    expect(container.querySelector('.theme-bg-secondary')).toBeInTheDocument();
  });

  it('applies incomplete style when done is omitted', () => {
    const { container } = renderWithI18n(<TimelineConnector />);
    expect(container.querySelector('.theme-bg-secondary')).toBeInTheDocument();
  });
});
