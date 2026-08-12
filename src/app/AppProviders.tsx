import { AppProvider } from '@shopify/polaris';
import enTranslations from '@shopify/polaris/locales/en.json';
import type { ReactNode } from 'react';

import { PolarisLink } from './PolarisLink';

/**
 * Everything that must wrap the router, in one place.
 *
 * Separate from `App` so the tests can mount the *same* wiring around a
 * memory router. When the test built its own `AppProvider` instead, it
 * passed `linkComponent` itself - so it proved `PolarisLink` worked
 * while proving nothing about whether the app used it, and deleting the
 * prop from `App` left the whole suite green.
 */
export function AppProviders({ children }: { children: ReactNode }) {
  return (
    // `linkComponent` is not optional polish. Without it every Polaris
    // `url` is a plain anchor, so a click reloads the app and navigates
    // to the raw path with the deploy's base path missing. See
    // PolarisLink.
    <AppProvider i18n={enTranslations} linkComponent={PolarisLink}>
      {children}
    </AppProvider>
  );
}
