import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import InfoCard from './InfoCard';

describe('InfoCard', () => {
  it('renders label and value', () => {
    render(
      <InfoCard
        icon={<span data-testid="icon">Icon</span>}
        label="Label"
        value="Value text"
      />
    );
    expect(screen.getByText('Label')).toBeInTheDocument();
    expect(screen.getByText('Value text')).toBeInTheDocument();
    expect(screen.getByTestId('icon')).toBeInTheDocument();
  });

  it('renders React node as value', () => {
    render(
      <InfoCard
        icon={<span />}
        label="Count"
        value={<strong>42</strong>}
      />
    );
    expect(screen.getByText('42')).toBeInTheDocument();
  });

  it('applies custom className', () => {
    const { container } = render(
      <InfoCard icon={<span />} label="L" value="V" className="my-class" />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper.className).toContain('my-class');
  });

  it('uses empty string className when not provided', () => {
    const { container } = render(
      <InfoCard icon={<span />} label="L" value="V" />
    );
    const wrapper = container.firstChild as HTMLElement;
    expect(wrapper.className).toMatch(/theme-bg-secondary/);
  });
});
