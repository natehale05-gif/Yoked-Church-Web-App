import { fileURLToPath } from 'node:url';
// `vitest/config` rather than `vite`: it is the same `defineConfig` with
// the `test` key added to the type. Importing from `vite` type-errors on
// that key while still working at runtime, which is the worst of both.
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

// GitHub Pages serves this repository from a subdirectory, not the root
// of the domain, so every asset URL needs that prefix baked in at build
// time. The deploy workflow passes the repository name; a local `npm run
// dev` gets `/`, which is what a dev server actually serves from.
//
// This is the same problem the Flutter build solved with `--base-href`,
// and it has the same answer.
const base = process.env.PUBLIC_BASE_PATH ?? '/';

export default defineConfig({
  base,
  plugins: [react()],
  resolve: {
    // Mirrors the `~/*` path in tsconfig.json. Both are needed: one
    // teaches the type checker, the other teaches the bundler, and a
    // change to either alone produces an app that only half resolves.
    alias: { '~': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  build: {
    // Not `build/`: that is Flutter's output directory and it is already
    // in .gitignore for that reason. Keeping them apart means either
    // toolchain can be run without clobbering the other's artifacts,
    // which matters while both apps are still in this repository.
    outDir: 'dist',
    sourcemap: true,
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    globals: true,
    // Only this app's tests. `functions/` and `test_rules/` are Node
    // suites with their own runners - one needs the Firebase emulator,
    // the other calls `process.exit` - and vitest's default glob
    // swallows both, reporting a red suite for code it never ran.
    //
    // They are still run, by `functions/package.json` and by the rules
    // job in CI. This only says they are not vitest's.
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
  },
});
