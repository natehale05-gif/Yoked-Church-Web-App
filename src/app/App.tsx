import { useEffect } from 'react';
import { RouterProvider } from 'react-router-dom';

import { AppProviders } from './AppProviders';
import { router } from './router';

export function App() {
  // The boot placeholder in index.html covers the whole viewport, so
  // leaving it up hides the app rather than merely looking untidy.
  //
  // Here rather than beside `createRoot().render()`: that call only
  // *schedules* the first render, so removing the cover there is a race
  // against React committing, and losing it means a blank screen. An
  // effect runs after the commit, by which time there is something
  // underneath worth uncovering.
  useEffect(() => {
    document.getElementById('boot')?.remove();
  }, []);

  return (
    <AppProviders>
      <RouterProvider router={router} />
    </AppProviders>
  );
}
