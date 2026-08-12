import '@testing-library/jest-dom/vitest';

// jsdom has no media queries, and Polaris reads `matchMedia` while its
// breakpoints module is *loading* - before any `beforeEach` could run.
// So the stub goes here, in the setup file, which vitest evaluates
// before the module graph.
//
// `matches: false` means every test sees the desktop layout unless it
// says otherwise. That is the honest default: a component that only
// works because a test forced a breakpoint is a component nobody has
// checked at the width people actually use.
// Same gap, different API: jsdom has no `ResizeObserver`, and Polaris'
// `Popover` - which is inside every `Select` and the user menu -
// constructs one on mount. Without this the component throws, React
// Router catches it, and the test sees an error page instead of the
// screen, which reads as "the page is broken" rather than "the test
// environment is missing a browser API".
if (typeof globalThis.ResizeObserver === 'undefined') {
  globalThis.ResizeObserver = class {
    observe() {}
    unobserve() {}
    disconnect() {}
  } as unknown as typeof ResizeObserver;
}

if (typeof window !== 'undefined' && window.matchMedia === undefined) {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: (query: string): MediaQueryList =>
      ({
        matches: false,
        media: query,
        onchange: null,
        addListener: () => {},
        removeListener: () => {},
        addEventListener: () => {},
        removeEventListener: () => {},
        dispatchEvent: () => false,
      }) as unknown as MediaQueryList,
  });
}
