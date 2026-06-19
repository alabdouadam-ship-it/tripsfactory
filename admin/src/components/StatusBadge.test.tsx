import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { StatusBadge } from './StatusBadge';

describe('StatusBadge', () => {
  it('renders status text with underscores as spaces', () => {
    render(<StatusBadge status="in_transit" />);
    expect(screen.getByText('in transit')).toBeInTheDocument();
  });

  it('applies known status styles', () => {
    const { container } = render(<StatusBadge status="pending" />);
    const span = container.querySelector('span');
    expect(span?.className).toMatch(/amber/);
  });

  it('applies default style for unknown status', () => {
    const { container } = render(<StatusBadge status="unknown_status" />);
    const span = container.querySelector('span');
    expect(span?.className).toMatch(/theme-bg-secondary/);
  });

  it('merges custom className', () => {
    const { container } = render(<StatusBadge status="completed" className="custom" />);
    const span = container.querySelector('span');
    expect(span?.className).toContain('custom');
  });

  it('normalizes status to lowercase for style lookup', () => {
    const { container } = render(<StatusBadge status="CANCELLED" />);
    const span = container.querySelector('span');
    expect(span?.className).toMatch(/red/);
  });

  it('renders empty string status with default style', () => {
    const { container } = render(<StatusBadge status="" />);
    const span = container.querySelector('span');
    expect(span?.className).toMatch(/theme-bg-secondary/);
    expect(span?.textContent).toBe('unknown');
  });

  it.each([
    ['pending', /amber/],
    ['cancelled', /red/],
    ['rejected', /red/],
    ['completed', /green/],
    ['available', /emerald/],
    ['booked', /blue/],
    ['in_transit', /orange/],
    ['full', /purple/],
    ['in_communication', /yellow/],
    ['accepted', /blue/],
    ['delivered', /teal/],
  ] as const)('applies correct style for status %s', (status, styleMatch) => {
    const { container } = render(<StatusBadge status={status} />);
    const span = container.querySelector('span');
    expect(span?.className).toMatch(styleMatch);
    expect(span?.textContent).toBe(status.replace(/_/g, ' '));
  });
});
