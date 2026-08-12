import { createContext, useContext, useMemo, type ReactNode } from 'react';

import sampleSettings from '../../assets/data/church_settings.json';
import { churchSettingsSchema, type ChurchSettings } from './church-settings';
import { DEMO_CHURCH_ID } from './tenant';

export interface Church {
  churchId: string;
  settings: ChurchSettings;
}

const ChurchContext = createContext<Church | null>(null);

/**
 * The church every screen below this reads from.
 *
 * The URL is the authority — `/c/:churchId` — and this is what makes the
 * rest of the app agree with it. Same job as `ChurchScope` in the
 * Flutter build, and the same reason it exists: without one place
 * holding the answer, a deep link into one church could render another
 * church's content for a frame.
 *
 * P2 replaces the body of this with a Firestore subscription. Everything
 * above and below it — the shape, the hook, the screens — is written
 * against the interface and does not change when it does.
 */
export function ChurchProvider({ churchId, children }: { churchId: string; children: ReactNode }) {
  const value = useMemo<Church>(
    () => ({
      churchId,
      // Parsed rather than cast. The bundled JSON is the zero-backend
      // demo's data and is edited by hand, so it is exactly as capable
      // of drifting from the schema as a Firestore document is - and
      // M19 was spent on a bug where this file's contents had drifted
      // and nothing checked.
      settings: churchSettingsSchema.parse(sampleSettings),
    }),
    [churchId],
  );

  return <ChurchContext.Provider value={value}>{children}</ChurchContext.Provider>;
}

export function useChurch(): Church {
  const church = useContext(ChurchContext);
  if (church === null) {
    throw new Error('useChurch outside a ChurchProvider — the route is missing its /c/:churchId parent');
  }
  return church;
}

export { DEMO_CHURCH_ID };
