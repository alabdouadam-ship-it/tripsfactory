'use client';

import React from 'react';
import { ToastProvider } from '@/lib/toast';
import { AuthGuard } from '@/components/AuthGuard';
import { I18nProvider } from '@/lib/i18n';
import { ThemeProvider } from '@/lib/theme';
import { CommandPalette } from '@/components/CommandPalette';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider>
      <I18nProvider>
        <ToastProvider>
          <AuthGuard>
            {children}
            <CommandPalette />
          </AuthGuard>
        </ToastProvider>
      </I18nProvider>
    </ThemeProvider>
  );
}

