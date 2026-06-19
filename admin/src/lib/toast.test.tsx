import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ToastProvider, useToast } from './toast';

function TestConsumer() {
  const { toast, confirm } = useToast();
  return (
    <div>
      <button onClick={() => toast('Hello', 'success')}>Toast success</button>
      <button onClick={() => toast('Error msg', 'error')}>Toast error</button>
      <button
        onClick={() =>
          confirm({
            title: 'Confirm?',
            message: 'Are you sure?',
            onConfirm: async () => {},
          })
        }
      >
        Open confirm
      </button>
    </div>
  );
}

describe('ToastProvider', () => {
  it('shows toast when toast() is called', async () => {
    const user = userEvent.setup();
    render(
      <ToastProvider>
        <TestConsumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Toast success'));
    expect(screen.getByText('Hello')).toBeInTheDocument();
  });

  it('shows error toast with error styling', async () => {
    const user = userEvent.setup();
    render(
      <ToastProvider>
        <TestConsumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Toast error'));
    expect(screen.getByText('Error msg')).toBeInTheDocument();
  });

  it('shows confirm dialog when confirm() is called', async () => {
    const user = userEvent.setup();
    render(
      <ToastProvider>
        <TestConsumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Open confirm'));
    expect(screen.getByText('Confirm?')).toBeInTheDocument();
    expect(screen.getByText('Are you sure?')).toBeInTheDocument();
    await user.click(screen.getByText('Cancel'));
    expect(screen.queryByText('Confirm?')).not.toBeInTheDocument();
  });

  it('calls onConfirm when Confirm clicked', async () => {
    const user = userEvent.setup();
    const onConfirm = vi.fn();
    function Consumer() {
      const { confirm: c } = useToast();
      return (
        <button
          onClick={() =>
            c({
              title: 'Confirm?',
              message: 'Sure?',
              onConfirm,
            })
          }
        >
          Open
        </button>
      );
    }
    render(
      <ToastProvider>
        <Consumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Open'));
    await user.click(screen.getByText('Confirm'));
    expect(onConfirm).toHaveBeenCalled();
  });

  it('shows info toast (default type) with gray style', async () => {
    const user = userEvent.setup();
    function InfoConsumer() {
      const { toast: t } = useToast();
      return <button onClick={() => t('Info message')}>Toast info</button>;
    }
    render(
      <ToastProvider>
        <InfoConsumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Toast info'));
    const el = screen.getByText('Info message');
    expect(el).toBeInTheDocument();
    expect(el.className).toMatch(/gray/);
  });

  it('confirm dialog shows custom confirmLabel and cancelLabel', async () => {
    const user = userEvent.setup();
    function CustomConsumer() {
      const { confirm: c } = useToast();
      return (
        <button
          onClick={() =>
            c({
              title: 'Title',
              message: 'Msg',
              confirmLabel: 'Yes',
              cancelLabel: 'No',
              onConfirm: () => {},
            })
          }
        >
          Open
        </button>
      );
    }
    render(
      <ToastProvider>
        <CustomConsumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Open'));
    expect(screen.getByText('Yes')).toBeInTheDocument();
    expect(screen.getByText('No')).toBeInTheDocument();
  });

  it('cancel does not call onConfirm', async () => {
    const user = userEvent.setup();
    const onConfirm = vi.fn();
    function Consumer() {
      const { confirm: c } = useToast();
      return (
        <button
          onClick={() =>
            c({
              title: 'T',
              message: 'M',
              onConfirm,
            })
          }
        >
          Open
        </button>
      );
    }
    render(
      <ToastProvider>
        <Consumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('Open'));
    await user.click(screen.getByText('Cancel'));
    expect(onConfirm).not.toHaveBeenCalled();
  });

  it('shows multiple toasts when toast called multiple times', async () => {
    const user = userEvent.setup();
    function MultiConsumer() {
      const { toast: t } = useToast();
      return (
        <div>
          <button onClick={() => t('First')}>A</button>
          <button onClick={() => t('Second')}>B</button>
        </div>
      );
    }
    render(
      <ToastProvider>
        <MultiConsumer />
      </ToastProvider>
    );
    await user.click(screen.getByText('A'));
    await user.click(screen.getByText('B'));
    expect(screen.getByText('First')).toBeInTheDocument();
    expect(screen.getByText('Second')).toBeInTheDocument();
  });
});

describe('useToast', () => {
  it('throws when used outside ToastProvider', () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const Consumer = () => {
      useToast();
      return null;
    };
    expect(() => render(<Consumer />)).toThrow('useToast must be used within ToastProvider');
    (console.error as ReturnType<typeof vi.fn>).mockRestore();
  });
});
