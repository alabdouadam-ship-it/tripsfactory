import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Sidebar } from './Sidebar';

const mockPush = vi.fn();
const mockRefresh = vi.fn();
const mockGetUser = vi.fn();
const mockSignOut = vi.fn();

vi.mock('next/navigation', () => ({
  usePathname: vi.fn(() => '/'),
  useRouter: () => ({ push: mockPush, refresh: mockRefresh }),
}));

vi.mock('next/link', () => ({
  default: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock('@/lib/supabase', () => ({
  supabase: {
    auth: {
      getUser: () => mockGetUser(),
      signOut: () => mockSignOut(),
    },
  },
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({ dir: 'ltr' as const }),
  useT: () => (key: string, fallback?: string) => {
    if (key === 'nav.drivers') return 'Travelers';
    if (key === 'nav.section.accounts') return 'Accounts';
    if (key === 'nav.section.operations') return 'Operations';
    if (key === 'nav.section.supportContent') return 'Support & Content';
    if (key === 'nav.section.platform') return 'Platform';
    if (key === 'nav.offers') return 'Offers';
    return fallback ?? key;
  },
}));

describe('Sidebar', () => {
  beforeEach(() => {
    mockPush.mockClear();
    mockRefresh.mockClear();
    mockGetUser.mockResolvedValue({ data: { user: { email: 'admin@test.com' } }, error: null });
    mockSignOut.mockResolvedValue(undefined);
  });

  it('renders title', async () => {
    render(<Sidebar />);
    await expect(screen.findByText('TripShip Admin', {}, { timeout: 2000 })).resolves.toBeInTheDocument();
  });

  it('renders nav links for dashboard, users, travelers', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });
    expect(screen.getByRole('link', { name: /dashboard/i })).toHaveAttribute('href', '/');
    expect(screen.getByRole('link', { name: /users/i })).toHaveAttribute('href', '/users');
    expect(screen.getByRole('link', { name: /travelers/i })).toHaveAttribute('href', '/drivers');
  });

  it('places Reports immediately after Moderation', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });
    const links = screen.getAllByRole('link');
    const moderationIndex = links.findIndex(link => link.getAttribute('href') === '/moderation');
    const reportsIndex = links.findIndex(link => link.getAttribute('href') === '/reports');

    expect(moderationIndex).toBeGreaterThanOrEqual(0);
    expect(reportsIndex).toBe(moderationIndex + 1);
  });

  it('groups Risk Overview, Moderation, and Reports under Trust & Risk', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });

    expect(screen.getByText('nav.section.trustRisk')).toBeInTheDocument();

    const links = screen.getAllByRole('link');
    const riskGroup = links.slice(
      links.findIndex(link => link.getAttribute('href') === '/founder'),
      links.findIndex(link => link.getAttribute('href') === '/users')
    );

    expect(riskGroup.map(link => link.getAttribute('href'))).toEqual([
      '/founder',
      '/moderation',
      '/reports',
    ]);
  });

  it('groups user capability screens under Accounts', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });

    expect(screen.getByText('Accounts')).toBeInTheDocument();

    const links = screen.getAllByRole('link');
    const accountGroup = links.slice(
      links.findIndex(link => link.getAttribute('href') === '/users'),
      links.findIndex(link => link.getAttribute('href') === '/trips')
    );

    expect(accountGroup.map(link => link.getAttribute('href'))).toEqual([
      '/users',
      '/drivers',
      '/companies',
      '/verification',
      '/documents',
    ]);
  });

  it('groups logistics workflow screens under Operations in the requested order', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });

    expect(screen.getByText('Operations')).toBeInTheDocument();
    expect(screen.getByText('Support & Content')).toBeInTheDocument();

    const links = screen.getAllByRole('link');
    const operationsGroup = links.slice(
      links.findIndex(link => link.getAttribute('href') === '/trips'),
      links.findIndex(link => link.getAttribute('href') === '/reviews')
    );

    expect(operationsGroup.map(link => link.getAttribute('href'))).toEqual([
      '/trips',
      '/bookings',
      '/shipments',
      '/offers',
    ]);
  });

  it('groups support, content, and platform tools separately', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });

    expect(screen.getByText('Support & Content')).toBeInTheDocument();
    expect(screen.getByText('Platform')).toBeInTheDocument();

    const links = screen.getAllByRole('link');
    const supportContentGroup = links.slice(
      links.findIndex(link => link.getAttribute('href') === '/reviews'),
      links.findIndex(link => link.getAttribute('href') === '/locations')
    );
    const platformGroup = links.slice(
      links.findIndex(link => link.getAttribute('href') === '/locations')
    );

    expect(supportContentGroup.map(link => link.getAttribute('href'))).toEqual([
      '/reviews',
      '/support',
      '/notifications',
      '/ads',
      '/in-app-messages',
    ]);
    expect(platformGroup.map(link => link.getAttribute('href'))).toEqual([
      '/locations',
      '/map',
      '/audit-log',
      '/settings',
    ]);
  });

  it('shows admin user email when loaded', async () => {
    render(<Sidebar />);
    await expect(screen.findByText('admin@test.com', {}, { timeout: 2000 })).resolves.toBeInTheDocument();
  });

  it('shows loading when user not yet loaded', () => {
    mockGetUser.mockImplementation(() => new Promise(() => {}));
    render(<Sidebar />);
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('renders Log out button', async () => {
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });
    expect(screen.getByRole('button', { name: /log out/i })).toBeInTheDocument();
  });

  it('calls signOut and pushes to /login when Log out is clicked', async () => {
    const user = userEvent.setup();
    render(<Sidebar />);
    await screen.findByText('TripShip Admin', {}, { timeout: 2000 });
    await user.click(screen.getByRole('button', { name: /log out/i }));
    expect(mockSignOut).toHaveBeenCalledTimes(1);
    expect(mockPush).toHaveBeenCalledWith('/login');
    expect(mockRefresh).toHaveBeenCalled();
  });
});
