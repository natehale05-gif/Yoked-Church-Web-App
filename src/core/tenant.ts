/**
 * Which church the app is acting as.
 *
 * One value turns one bundle into any church's app: every repository is
 * built from it, so changing it re-reads the whole data layer and
 * re-themes the storefront without a reload.
 *
 * Ported from `lib/core/config/tenant.dart` with one deliberate change,
 * noted on `churchUrl` below.
 */

/** The church the bundled sample content describes. */
export const DEMO_CHURCH_ID = 'yoked-demo';

/**
 * The prefix every church-scoped route carries.
 *
 * Short on purpose: it sits in front of every URL a church will ever
 * print on a card or read out from the front.
 */
export const CHURCH_PATH_PREFIX = '/c';

/**
 * The address of a page within a church.
 *
 * `churchPath('riverside', '/giving')` is `/c/riverside/giving`. The one
 * place that shape is written down, so moving the prefix stays a
 * one-line change rather than a search across the app.
 */
export function churchPath(churchId: string, subPath = '/'): string {
  const rest = subPath === '/' ? '' : subPath;
  return `${CHURCH_PATH_PREFIX}/${churchId}${rest}`;
}

/**
 * A church's whole address, as somebody would write it on a card.
 *
 * **No `#`.** The Flutter build had to include one — it routed on the
 * fragment, so `example.com/c/riverside` reached the server as
 * `example.com` and the church was lost. React Router uses real paths,
 * and `public/404.html` bounces a deep link back through the SPA with
 * the path intact, so the address a church hands out is now the address
 * a browser shows.
 *
 * The deploy's base path comes from `import.meta.env.BASE_URL`, which is
 * the `base` Vite was built with — `/Yoked-Church-Web-App/` here, `/`
 * for a fork on its own domain.
 *
 * Deriving it from the current pathname instead, which is what the Dart
 * version did, is wrong now and was only ever right by accident. Under
 * hash routing the pathname was always the base; under real paths it is
 * the page you are standing on, so an admin who opened this from
 * `/c/riverside/settings` would have been handed
 * `example.com/c/riverside/c/riverside` to print on a card.
 *
 * Returns empty where there is no web address to give, rather than
 * inventing one and putting a dead URL behind a copy button.
 */
export function churchUrl(
  churchId: string,
  from: { origin: string; protocol: string } = window.location,
  basePath: string = import.meta.env.BASE_URL,
): string {
  if (from.protocol !== 'http:' && from.protocol !== 'https:') return '';

  // `BASE_URL` always carries a trailing slash; `churchPath` always
  // leads with one, and two would give `//c/riverside`.
  const dir = basePath.endsWith('/') ? basePath.slice(0, -1) : basePath;

  return `${from.origin}${dir}${churchPath(churchId)}`;
}

/** The church a location names, or null if it names none. */
export function churchIdFromLocation(location: string): string | null {
  const segments = location.split('?')[0]!.split('#')[0]!.split('/').filter(Boolean);
  if (segments.length < 2 || `/${segments[0]}` !== CHURCH_PATH_PREFIX) return null;
  const id = segments[1]!.trim();
  return id === '' ? null : id;
}

/**
 * Strips the church prefix, leaving the path the app reasons about.
 *
 * Every guard, feature flag and role check is written against bare paths
 * like `/admin/settings` and stays that way; only this function knows
 * the difference.
 */
export function subPathOf(location: string): string {
  const id = churchIdFromLocation(location);
  if (id === null) return location;
  const rest = location.slice(`${CHURCH_PATH_PREFIX}/${id}`.length);
  return rest === '' ? '/' : rest;
}
