import { Navigate, Outlet, useLocation, useParams } from 'react-router-dom';

import { ChurchProvider, useChurch } from '../core/church-context';
import { churchPath, subPathOf } from '../core/tenant';
import { useSession } from '../features/auth/session';
import { AUTH_PATHS, flagAllows, isAdminOnly } from './guard';

/**
 * Everything under `/c/:churchId`.
 *
 * The provider has to sit above the guard, because the guard's first
 * question — is this feature switched on — is answered out of the
 * church's own settings.
 */
export function ChurchLayout() {
  const { churchId } = useParams();

  if (churchId === undefined || churchId.trim() === '') {
    return <Navigate to="/choose-church" replace />;
  }

  return (
    <ChurchProvider churchId={churchId}>
      <ChurchGuard />
    </ChurchProvider>
  );
}

/**
 * The redirect from `lib/app/router.dart`, as a component.
 *
 * The Riverpod version had a hazard this one does not: it ran inside a
 * change notification, so it had to read auth and settings *at source*
 * or it would decide against the previous values — which is how a cold
 * link to `/download` used to bounce to the church home, and how signing
 * in used to leave you on the sign-in page. Two milestones went on that.
 *
 * Rendering is not a notification. This reads the same context every
 * other component reads, and React re-renders it when that context
 * changes, so there is no stale-read version of the bug to reintroduce.
 */
function ChurchGuard() {
  const location = useLocation();
  const church = useChurch();
  const session = useSession();

  const path = subPathOf(location.pathname);
  const at = (subPath: string) => churchPath(church.churchId, subPath);

  // Nothing is decided while the session is still resolving. Guessing
  // "signed out" for a beat is what sends a signed-in admin to the
  // sign-in page on every cold load.
  if (session.loading) return null;

  if (!flagAllows(church.settings.features, path)) return <Navigate to={at('/')} replace />;

  if (path.startsWith('/account') && !session.signedIn) return <Navigate to={at('/sign-in')} replace />;

  if (path.startsWith('/admin')) {
    if (!session.signedIn) return <Navigate to={at('/sign-in')} replace />;
    if (!session.isStaff) return <Navigate to={at('/account')} replace />;
    if (isAdminOnly(path) && !session.isAdmin) return <Navigate to={at('/admin')} replace />;
  }

  // Where signing in takes you is decided here and nowhere else. The
  // screens used to navigate themselves the moment the call returned,
  // which raced this guard and undid the sign-in that had just
  // succeeded.
  if (AUTH_PATHS.has(path) && session.signedIn) {
    return <Navigate to={at(session.isStaff ? '/admin' : '/account')} replace />;
  }

  return <Outlet />;
}
