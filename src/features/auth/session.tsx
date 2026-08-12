import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { z } from 'zod';

/**
 * Who is signed in, and what they may do.
 *
 * Ported from `AppUser` in `lib/features/auth/domain/app_user.dart`. The
 * three roles and the two derived predicates are the same, because
 * `firestore.rules` reads `role` off the same documents and the two must
 * agree about what "staff" means.
 */
export const userRoleSchema = z.enum(['member', 'staff', 'admin']).catch('member');

export const appUserSchema = z.object({
  uid: z.string(),
  email: z.string().default(''),
  displayName: z.string().default(''),
  phone: z.string().default(''),
  photoUrl: z.string().default(''),
  role: userRoleSchema.default('member'),
  directoryOptIn: z.boolean().default(false),
});

export type AppUser = z.infer<typeof appUserSchema>;

export interface Session {
  user: AppUser | null;
  /** Still resolving. Nothing should be gated on a guess before this clears. */
  loading: boolean;
  signedIn: boolean;
  isStaff: boolean;
  isAdmin: boolean;
  /** What the user menu shows. Falls back through name, email, then a shrug. */
  name: string;
  initials: string;
  signIn: (as: 'member' | 'staff' | 'admin') => void;
  signOut: () => Promise<void>;
}

const SessionContext = createContext<Session | null>(null);

/** Display name, email local part, or nothing — in that order. */
export function displayNameOf(user: AppUser | null): string {
  if (user === null) return '';
  if (user.displayName !== '') return user.displayName;
  return user.email.split('@')[0] ?? '';
}

export function initialsOf(user: AppUser | null): string {
  const name = displayNameOf(user);
  if (name === '') return '?';
  // Two initials where there are two words, as Shopify's user menu
  // shows. `AppUser.initial` in the Flutter build took only the first,
  // which reads as a placeholder rather than a person.
  const parts = name.split(/\s+/).filter(Boolean);
  const first = parts[0]?.[0] ?? '';
  const last = parts.length > 1 ? (parts.at(-1)?.[0] ?? '') : '';
  return (first + last).toUpperCase();
}

/**
 * P1 signs in against the bundled demo users, exactly as the Flutter
 * build's preview cards did — the zero-backend demo is why this app can
 * be looked at without a Firebase project, and losing it in the rebuild
 * would mean nobody could see the rebuild.
 *
 * P2 replaces the body with Firebase Auth. The interface above is what
 * screens are written against and does not change.
 */
const STORAGE_KEY = 'yoked:demo-session';

/** The demo session as the last page left it, if it is still readable. */
function restore(): AppUser | null {
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (raw === null) return null;
    return appUserSchema.parse(JSON.parse(raw));
  } catch {
    // Storage disabled, or a stored shape from an older build. Either
    // way, signed out is the safe reading.
    return null;
  }
}

export function SessionProvider({ children }: { children: ReactNode }) {
  // Restored on the first render, not in an effect. An effect runs after
  // the guard has already decided, so a signed-in admin refreshing the
  // page would be bounced to sign-in and only then restored - landing
  // them somewhere they did not ask for.
  const [user, setUser] = useState<AppUser | null>(restore);

  const remember = useCallback((next: AppUser | null) => {
    setUser(next);
    try {
      if (next === null) sessionStorage.removeItem(STORAGE_KEY);
      else sessionStorage.setItem(STORAGE_KEY, JSON.stringify(next));
    } catch {
      // Private mode. The session still works for this page; it just
      // will not survive a refresh, which is the pre-existing behaviour.
    }
  }, []);

  const signIn = useCallback(
    (as: 'member' | 'staff' | 'admin') => {
      remember(
        appUserSchema.parse({
          uid: `demo-${as}`,
          email: `${as}@yokedchurch.org`,
          displayName: { member: 'Demo Member', staff: 'Demo Staff', admin: 'Demo Admin' }[as],
          role: as,
        }),
      );
    },
    [remember],
  );

  const signOut = useCallback(async () => {
    remember(null);
  }, [remember]);

  const value = useMemo<Session>(
    () => ({
      user,
      loading: false,
      signedIn: user !== null,
      isStaff: user?.role === 'staff' || user?.role === 'admin',
      isAdmin: user?.role === 'admin',
      name: displayNameOf(user),
      initials: initialsOf(user),
      signIn,
      signOut,
    }),
    [user, signIn, signOut],
  );

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): Session {
  const session = useContext(SessionContext);
  if (session === null) throw new Error('useSession outside a SessionProvider');
  return session;
}
