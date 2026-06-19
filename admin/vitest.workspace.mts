import { defineWorkspace } from 'vitest/config';

// Run main suite (excluding error) + error tests in isolation to avoid double-React.
export default defineWorkspace([
  {
    extends: './vitest.config.mts',
    test: {
      name: 'main',
      exclude: ['src/app/error.test.tsx'],
    },
  },
  './vitest.error.mts',
]);
