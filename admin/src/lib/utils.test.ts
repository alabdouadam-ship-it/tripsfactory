import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { cn, exportToCSV, getCityLabel } from './utils';

describe('cn', () => {
  it('merges class names', () => {
    expect(cn('a', 'b')).toBe('a b');
  });

  it('handles conditional classes', () => {
    expect(cn('base', false && 'hidden', 'visible')).toContain('base');
    expect(cn('base', true && 'visible')).toContain('visible');
  });

  it('handles tailwind merge (later overrides)', () => {
    expect(cn('p-4', 'p-2')).toBe('p-2');
  });

  it('handles empty and undefined', () => {
    expect(cn('a', undefined, null, '')).toBe('a');
  });

  it('handles array of classes', () => {
    expect(cn(['a', 'b'])).toBe('a b');
  });
});

describe('getCityLabel', () => {
  it('returns N/A for null', () => {
    expect(getCityLabel(null)).toBe('N/A');
  });

  it('returns N/A for undefined', () => {
    expect(getCityLabel(undefined)).toBe('N/A');
  });

  it('prefers city_name_en', () => {
    expect(getCityLabel({ city_name_en: 'Riyadh', city_name_ar: 'الرياض' })).toBe('Riyadh');
  });

  it('falls back to city_name_ar when en is null', () => {
    expect(getCityLabel({ city_name_en: null, city_name_ar: 'الرياض' })).toBe('الرياض');
  });

  it('falls back to city_name_ar when en is empty string', () => {
    expect(getCityLabel({ city_name_en: '', city_name_ar: 'جدة' })).toBe('جدة');
  });

  it('falls back to N/A when both missing', () => {
    expect(getCityLabel({})).toBe('N/A');
  });

  it('returns N/A when both are null', () => {
    expect(getCityLabel({ city_name_en: null, city_name_ar: null })).toBe('N/A');
  });
});

describe('exportToCSV', () => {
  const createObjectURL = URL.createObjectURL;
  const revokeObjectURL = URL.revokeObjectURL;
  const createElement = document.createElement.bind(document);

  beforeEach(() => {
    URL.createObjectURL = vi.fn(() => 'blob:mock-url');
    URL.revokeObjectURL = vi.fn();
    // Prevent jsdom navigation when link.click() is called
    document.createElement = ((tagName: string) => {
      const el = createElement(tagName) as HTMLAnchorElement;
      if (tagName.toLowerCase() === 'a') el.click = vi.fn();
      return el;
    }) as typeof document.createElement;
  });

  afterEach(() => {
    URL.createObjectURL = createObjectURL;
    URL.revokeObjectURL = revokeObjectURL;
    document.createElement = createElement;
  });

  it('calls onNoData when data is empty', () => {
    const onNoData = vi.fn();
    exportToCSV([], 'test', onNoData);
    expect(onNoData).toHaveBeenCalledWith('No data to export');
  });

  it('calls onNoData when data is null', () => {
    const onNoData = vi.fn();
    exportToCSV(null as unknown as any[], 'test', onNoData);
    expect(onNoData).toHaveBeenCalledWith('No data to export');
  });

  it('creates a link and triggers download when data provided', () => {
    const appendChild = vi.spyOn(document.body, 'appendChild');
    const removeChild = vi.spyOn(document.body, 'removeChild');
    exportToCSV([{ id: 1, name: 'A' }], 'export');
    const link = appendChild.mock.calls[0][0] as HTMLAnchorElement;
    expect(link.download).toBe('export.csv');
    expect(link.href).toContain('blob:');
    expect(URL.createObjectURL).toHaveBeenCalled();
    expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:mock-url');
    expect(removeChild).toHaveBeenCalledWith(link);
    appendChild.mockRestore();
    removeChild.mockRestore();
  });

  it('flattens nested objects in CSV', () => {
    const appendChild = vi.spyOn(document.body, 'appendChild');
    exportToCSV([{ id: 1, profile: { name: 'John' } }], 'flat');
    const link = appendChild.mock.calls[0][0] as HTMLAnchorElement;
    expect(link.href).toContain('blob:');
    appendChild.mockRestore();
  });

  it('calls alert when data is empty and onNoData not provided', () => {
    const alertSpy = vi.spyOn(global, 'alert').mockImplementation(() => {});
    exportToCSV([], 'test');
    expect(alertSpy).toHaveBeenCalledWith('No data to export');
    alertSpy.mockRestore();
  });

  it('escapes quotes in string values and wraps strings with comma', async () => {
    exportToCSV([{ a: 'hello "world"', b: 'x, y' }], 'q');
    const blob = (URL.createObjectURL as ReturnType<typeof vi.fn>).mock.calls[0][0] as Blob;
    const text = await new Promise<string>((res, rej) => {
      const r = new FileReader();
      r.onload = () => res(r.result as string);
      r.onerror = rej;
      r.readAsText(blob);
    });
    expect(text).toContain('""');
    expect(text).toContain('"x, y"');
  });

  it('includes non-string values in CSV as-is', async () => {
    exportToCSV([{ id: 42, flag: true, empty: null }], 'n');
    const blob = (URL.createObjectURL as ReturnType<typeof vi.fn>).mock.calls[0][0] as Blob;
    const text = await new Promise<string>((res, rej) => {
      const r = new FileReader();
      r.onload = () => res(r.result as string);
      r.onerror = rej;
      r.readAsText(blob);
    });
    expect(text).toMatch(/42/);
    expect(text).toMatch(/true/);
  });
});
