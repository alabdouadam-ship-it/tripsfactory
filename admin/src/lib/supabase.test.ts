import { describe, it, expect } from 'vitest';
import { requirePublicEnv } from './supabase';

describe('requirePublicEnv', () => {
  it('returns value when env is set', () => {
    process.env.REQUIRE_ENV_TEST_VAR = 'value123';
    expect(requirePublicEnv('REQUIRE_ENV_TEST_VAR', process.env.REQUIRE_ENV_TEST_VAR)).toBe('value123');
  });

  it('throws when env is missing', () => {
    const key = 'REQUIRE_ENV_MISSING_XYZ';
    delete process.env[key];
    expect(() => requirePublicEnv(key, process.env[key])).toThrow(
      `Missing or empty environment variable: ${key}. Set it in your admin build environment.`
    );
  });

  it('throws when env is empty string', () => {
    const key = 'REQUIRE_ENV_EMPTY_XYZ';
    process.env[key] = '';
    expect(() => requirePublicEnv(key, process.env[key])).toThrow(
      `Missing or empty environment variable: ${key}. Set it in your admin build environment.`
    );
  });

  it('throws when env key is deleted', () => {
    const key = 'REQUIRE_ENV_NONEXISTENT_KEY_ABC';
    delete process.env[key];
    expect(() => requirePublicEnv(key, process.env[key])).toThrow(
      `Missing or empty environment variable: ${key}. Set it in your admin build environment.`
    );
  });
});
