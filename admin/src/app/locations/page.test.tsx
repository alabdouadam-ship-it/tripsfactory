import React from 'react';
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import LocationsPage from './page';

type QueryRecord = {
  table: string;
  columns?: string;
  options?: any;
  filters: Array<{ method: string; args: unknown[] }>;
};

const labels = vi.hoisted((): Record<string, string> => ({
  'common.importing': 'Importing...',
  'common.na': 'N/A',
  'common.saving': 'Saving...',
  'common.unknown': 'Unknown',
  'locations.action.delete': 'Delete location',
  'locations.action.edit': 'Edit location',
  'locations.action.toggleActive': 'Toggle active',
  'locations.add': 'Add Location',
  'locations.count': 'locations',
  'locations.dialog.deleteLabel': 'Delete',
  'locations.dialog.deleteMessage': 'Delete "{name}"? This cannot be undone.',
  'locations.dialog.deleteTitle': 'Delete Location',
  'locations.empty': 'No locations found.',
  'locations.export': 'Export',
  'locations.filter.all': 'All',
  'locations.filter.country': 'Country',
  'locations.filter.province': 'Province',
  'locations.form.active': 'Active',
  'locations.form.addTitle': 'Add Location',
  'locations.form.cancel': 'Cancel',
  'locations.form.cityAr': 'City (AR)',
  'locations.form.cityEn': 'City (EN)',
  'locations.form.countryAr': 'Country (AR)',
  'locations.form.countryCode': 'Country Code',
  'locations.form.countryEn': 'Country (EN)',
  'locations.form.latitude': 'Latitude',
  'locations.form.longitude': 'Longitude',
  'locations.form.provinceAr': 'Province (AR)',
  'locations.form.provinceEn': 'Province (EN)',
  'locations.form.save': 'Save',
  'locations.form.townAr': 'Town (AR)',
  'locations.form.townEn': 'Town (EN)',
  'locations.importCsv': 'Import CSV',
  'locations.search.placeholder': 'Search by city, province, or town...',
  'locations.subtitle': 'Manage cities, provinces, and pickup/dropoff points',
  'locations.table.active': 'Active',
  'locations.table.actions': 'Actions',
  'locations.table.city': 'City (EN / AR)',
  'locations.table.coords': 'Coords',
  'locations.table.country': 'Country',
  'locations.table.province': 'Province',
  'locations.table.town': 'Town',
  'locations.title': 'Location Management',
  'locations.toast.cannotDeleteTrips': 'Cannot delete: Location used in {count} trip(s). Deactivate it instead.',
  'locations.toast.csvInvalid': 'CSV must have headers + data rows',
  'locations.toast.csvRowInvalid': 'Row {row}: {message}',
  'locations.toast.importedCount': 'Imported {count} locations',
  'locations.toast.importFailed': 'Import failed: {message}',
  'locations.toast.invalidLatitude': 'Latitude must be between -90 and 90.',
  'locations.toast.locationCreated': 'Location created',
  'locations.toast.referenceCheckFailed': 'Could not verify whether this location is in use.',
  'locations.toast.requiredFields': 'Country, province, and city names are required in English and Arabic.',
}));

const sampleLocation = {
  id: 'loc-1',
  country_code: 'AE',
  country_name_ar: 'الإمارات العربية المتحدة',
  country_name_en: 'United Arab Emirates',
  province_name_ar: 'دبي',
  province_name_en: 'Dubai',
  city_name_ar: 'ديرة',
  city_name_en: 'Deira',
  town_name_ar: 'البلدة القديمة',
  town_name_en: 'Old Town',
  latitude: 0,
  longitude: 0,
  is_active: true,
  created_at: '2026-05-07T08:00:00.000Z',
};

const mocks = vi.hoisted(() => {
  const state = {
    locations: [] as any[],
    locationsError: null as any,
    tripCount: 0,
    tripCountError: null as any,
    insertError: null as any,
    updateError: null as any,
    deleteError: null as any,
  };
  const queries: QueryRecord[] = [];
  const insertCalls: Array<{ table: string; payload: any }> = [];
  const updateCalls: Array<{ table: string; payload: any; filters: Array<{ method: string; args: unknown[] }> }> = [];
  const deleteCalls: Array<{ table: string; filters: Array<{ method: string; args: unknown[] }> }> = [];

  const resultFor = (record: QueryRecord) => {
    if (record.table === 'locations') {
      return { data: state.locations, error: state.locationsError };
    }
    if (record.table === 'trips') {
      return { count: state.tripCount, error: state.tripCountError };
    }
    return { data: [], error: null };
  };

  const makeQuery = (record: QueryRecord): any => {
    const query: any = {
      order: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'order', args });
        return query;
      }),
      or: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'or', args });
        return query;
      }),
      eq: vi.fn((...args: unknown[]) => {
        record.filters.push({ method: 'eq', args });
        return query;
      }),
      then: (onFulfilled: any, onRejected: any) => Promise.resolve(resultFor(record)).then(onFulfilled, onRejected),
    };
    return query;
  };

  const mockFrom = vi.fn((table: string) => ({
    select: vi.fn((columns?: string, options?: any) => {
      const record = { table, columns, options, filters: [] };
      queries.push(record);
      return makeQuery(record);
    }),
    insert: vi.fn((payload: any) => {
      insertCalls.push({ table, payload });
      return Promise.resolve({ error: state.insertError });
    }),
    update: vi.fn((payload: any) => {
      const call = { table, payload, filters: [] as Array<{ method: string; args: unknown[] }> };
      updateCalls.push(call);
      return {
        eq: vi.fn((...args: unknown[]) => {
          call.filters.push({ method: 'eq', args });
          return Promise.resolve({ error: state.updateError });
        }),
      };
    }),
    delete: vi.fn(() => {
      const call = { table, filters: [] as Array<{ method: string; args: unknown[] }> };
      return {
        eq: vi.fn((...args: unknown[]) => {
          call.filters.push({ method: 'eq', args });
          deleteCalls.push(call);
          return Promise.resolve({ error: state.deleteError });
        }),
      };
    }),
  }));

  return {
    state,
    queries,
    insertCalls,
    updateCalls,
    deleteCalls,
    mockConfirm: vi.fn(),
    mockFrom,
    mockLogAdminAction: vi.fn(() => Promise.resolve()),
    mockToast: vi.fn(),
  };
});

vi.mock('@/app/loading', () => ({
  default: () => <div>Loading</div>,
}));

vi.mock('@/lib/audit', () => ({
  logAdminAction: mocks.mockLogAdminAction,
}));

vi.mock('@/lib/i18n', () => ({
  useI18n: () => ({ dir: 'ltr', language: 'en' }),
  useT: () => (key: string, fallback?: string) => labels[key] ?? fallback ?? key,
}));

vi.mock('@/lib/supabase', () => ({
  supabase: { from: mocks.mockFrom },
}));

vi.mock('@/lib/toast', () => ({
  useToast: () => ({ toast: mocks.mockToast, confirm: mocks.mockConfirm }),
}));

vi.mock('@/lib/utils', () => ({
  exportToCSV: vi.fn(),
}));

describe('LocationsPage', () => {
  beforeEach(() => {
    mocks.state.locations = [sampleLocation];
    mocks.state.locationsError = null;
    mocks.state.tripCount = 0;
    mocks.state.tripCountError = null;
    mocks.state.insertError = null;
    mocks.state.updateError = null;
    mocks.state.deleteError = null;
    mocks.queries.length = 0;
    mocks.insertCalls.length = 0;
    mocks.updateCalls.length = 0;
    mocks.deleteCalls.length = 0;
    mocks.mockConfirm.mockClear();
    mocks.mockFrom.mockClear();
    mocks.mockLogAdminAction.mockClear();
    mocks.mockToast.mockClear();
  });

  it('renders country code and zero coordinates, and searches Arabic fields', async () => {
    render(<LocationsPage />);

    await expect(screen.findByText('Deira')).resolves.toBeInTheDocument();
    expect(screen.getByText('AE')).toBeInTheDocument();
    expect(screen.getByText('0.0000, 0.0000')).toBeInTheDocument();

    fireEvent.change(screen.getByPlaceholderText('Search by city, province, or town...'), {
      target: { value: 'البلدة' },
    });

    expect(screen.getByText('Deira')).toBeInTheDocument();

    fireEvent.change(screen.getByPlaceholderText('Search by city, province, or town...'), {
      target: { value: 'Aleppo' },
    });

    expect(screen.getByText('No locations found.')).toBeInTheDocument();
  });

  it('validates required fields and preserves zero coordinates while deriving the home country code', async () => {
    mocks.state.locations = [];
    render(<LocationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: /add location/i }));
    fireEvent.click(screen.getByRole('button', { name: 'Save' }));

    expect(mocks.mockToast).toHaveBeenCalledWith(
      'Country, province, and city names are required in English and Arabic.',
      'error',
    );
    expect(mocks.insertCalls).toHaveLength(0);

    fireEvent.change(screen.getByLabelText('Country (EN)'), { target: { value: 'United Arab Emirates' } });
    fireEvent.change(screen.getByLabelText('Country (AR)'), { target: { value: 'الإمارات العربية المتحدة' } });
    fireEvent.change(screen.getByLabelText('Province (EN)'), { target: { value: 'Dubai' } });
    fireEvent.change(screen.getByLabelText('Province (AR)'), { target: { value: 'دبي' } });
    fireEvent.change(screen.getByLabelText('City (EN)'), { target: { value: 'Dubai' } });
    fireEvent.change(screen.getByLabelText('City (AR)'), { target: { value: 'دبي' } });
    fireEvent.change(screen.getByLabelText('Latitude'), { target: { value: '0' } });
    fireEvent.change(screen.getByLabelText('Longitude'), { target: { value: '0' } });
    fireEvent.click(screen.getByRole('button', { name: 'Save' }));

    await waitFor(() => {
      expect(mocks.insertCalls).toHaveLength(1);
    });
    expect(mocks.insertCalls[0].payload).toMatchObject({
      country_code: 'AE',
      latitude: 0,
      longitude: 0,
    });
  });

  it('blocks deletion when any trip references the location', async () => {
    mocks.state.tripCount = 1;
    render(<LocationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: 'Delete location' }));
    await act(async () => {
      await mocks.mockConfirm.mock.calls[0][0].onConfirm();
    });

    expect(mocks.mockToast).toHaveBeenCalledWith(
      'Cannot delete: Location used in 1 trip(s). Deactivate it instead.',
      'error',
    );
    expect(mocks.deleteCalls).toHaveLength(0);
    const tripQuery = mocks.queries.find(query => query.table === 'trips');
    expect(tripQuery?.filters).toEqual(expect.arrayContaining([
      { method: 'or', args: ['origin_location_id.eq.loc-1,dest_location_id.eq.loc-1'] },
    ]));
    expect(tripQuery?.filters.some(filter => filter.method === 'not')).toBe(false);
  });

  it('surfaces reference check errors before attempting delete', async () => {
    mocks.state.tripCountError = { message: 'permission denied' };
    render(<LocationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: 'Delete location' }));
    await act(async () => {
      await mocks.mockConfirm.mock.calls[0][0].onConfirm();
    });

    expect(mocks.mockToast).toHaveBeenCalledWith(
      'Could not verify whether this location is in use.',
      'error',
    );
    expect(mocks.deleteCalls).toHaveLength(0);
  });

  it('toggles active state through an explicit update', async () => {
    render(<LocationsPage />);

    fireEvent.click(await screen.findByRole('button', { name: 'Toggle active' }));

    await waitFor(() => {
      expect(mocks.updateCalls).toContainEqual(expect.objectContaining({
        table: 'locations',
        payload: { is_active: false },
      }));
    });
  });

  it('imports quote-aware CSV rows with validation and country code derivation', async () => {
    mocks.state.locations = [];
    const { container } = render(<LocationsPage />);
    await screen.findByText('No locations found.');

    const input = container.querySelector('input[type="file"]') as HTMLInputElement;
    const csv = [
      'country_name_en,country_name_ar,province_name_en,province_name_ar,city_name_en,city_name_ar,town_name_en,town_name_ar,latitude,longitude\n',
      'United Arab Emirates,الإمارات العربية المتحدة,Dubai,دبي,"Down, town",وسط المدينة,Center,المركز,0,0\n',
    ].join('');
    const file = new File([csv], 'locations.csv', { type: 'text/csv' });
    Object.defineProperty(file, 'text', { value: () => Promise.resolve(csv) });

    await act(async () => {
      fireEvent.change(input, { target: { files: [file] } });
    });

    await waitFor(() => {
      expect(mocks.insertCalls).toHaveLength(1);
    });
    expect(mocks.insertCalls[0].payload[0]).toMatchObject({
      country_code: 'AE',
      city_name_en: 'Down, town',
      latitude: 0,
      longitude: 0,
    });
  });
});
