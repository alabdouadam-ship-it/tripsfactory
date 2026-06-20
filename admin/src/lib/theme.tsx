'use client';

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

export type ThemeId = 'midnight' | 'dark' | 'dim' | 'light' | 'bright' | 'crimson' | 'forest' | 'ocean' | 'amber' | 'violet';
export type FontSize = 'small' | 'normal' | 'large' | 'xl' | 'xxl';

const STORAGE_KEY = 'tripsfactory_admin_theme';
const FONT_SIZE_KEY = 'tripsfactory_admin_font_size';

const THEMES: { id: ThemeId; label: string; labelAr?: string }[] = [
  { id: 'midnight', label: 'Midnight', labelAr: 'منتصف الليل' },
  { id: 'dark', label: 'Dark', labelAr: 'داكن' },
  { id: 'dim', label: 'Dim', labelAr: 'باهت' },
  { id: 'light', label: 'Light', labelAr: 'فاتح' },
  { id: 'bright', label: 'Bright', labelAr: 'ساطع' },
  { id: 'crimson', label: 'Crimson', labelAr: 'قرمزي' },
  { id: 'forest', label: 'Forest', labelAr: 'أخضر غامق' },
  { id: 'ocean', label: 'Ocean', labelAr: 'أزرق محيط' },
  { id: 'amber', label: 'Amber', labelAr: 'كهرماني' },
  { id: 'violet', label: 'Violet', labelAr: 'بنفسجي' },
];

const FONT_SIZES: { id: FontSize; label: string; labelAr: string }[] = [
  { id: 'small', label: 'Compact', labelAr: 'مضغوط' },
  { id: 'normal', label: 'Standard', labelAr: 'قياسي' },
  { id: 'large', label: 'Medium', labelAr: 'متوسط' },
  { id: 'xl', label: 'Large', labelAr: 'كبير' },
  { id: 'xxl', label: 'Extra Large', labelAr: 'كبير جداً' },
];

type ThemeContextValue = {
  theme: ThemeId;
  setTheme: (id: ThemeId) => void;
  themes: typeof THEMES;
  fontSize: FontSize;
  setFontSize: (size: FontSize) => void;
  fontSizes: typeof FONT_SIZES;
};

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

function readStoredTheme(): ThemeId {
  if (typeof window === 'undefined') return 'light';
  const raw = localStorage.getItem(STORAGE_KEY);
  if (raw && THEMES.some(t => t.id === raw)) return raw as ThemeId;
  return 'light';
}

function readStoredFontSize(): FontSize {
  if (typeof window === 'undefined') return 'normal';
  const raw = localStorage.getItem(FONT_SIZE_KEY);
  if (raw && FONT_SIZES.some(f => f.id === raw)) return raw as FontSize;
  return 'normal';
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<ThemeId>('light');
  const [fontSize, setFontSizeState] = useState<FontSize>('normal');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setThemeState(readStoredTheme());
    setFontSizeState(readStoredFontSize());
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted || typeof document === 'undefined') return;
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(STORAGE_KEY, theme);
  }, [theme, mounted]);

  useEffect(() => {
    if (!mounted || typeof document === 'undefined') return;
    document.documentElement.setAttribute('data-font-size', fontSize);
    localStorage.setItem(FONT_SIZE_KEY, fontSize);
  }, [fontSize, mounted]);

  const setTheme = useCallback((id: ThemeId) => {
    setThemeState(id);
  }, []);

  const setFontSize = useCallback((size: FontSize) => {
    setFontSizeState(size);
  }, []);

  const value = useMemo(
    () => ({ theme, setTheme, themes: THEMES, fontSize, setFontSize, fontSizes: FONT_SIZES }),
    [theme, setTheme, fontSize, setFontSize]
  );

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (ctx === undefined) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
