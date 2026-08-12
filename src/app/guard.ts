import type { FeatureFlags } from '../core/features';

/**
 * Route prefixes owned by a feature flag.
 *
 * Turning a feature off has to close the route as well as hide the nav
 * link, or the page stays live for anyone holding the URL. Ported from
 * `_flagAllows` in `lib/app/router.dart`, re-pointed at the new admin
 * addresses — Shopify's IA moved several of these (`/admin/resources`
 * became `/admin/content/files`, `/admin/announcements` became
 * `/admin/outreach/announcements`), and a guard that still named the old
 * paths would silently allow the new ones.
 */
export function flagAllows(flags: FeatureFlags, path: string): boolean {
  const owns = (prefix: string) => path === prefix || path.startsWith(`${prefix}/`);

  if (owns('/sermons') || owns('/admin/sermons') || owns('/account/notes')) return flags.sermons;
  if (owns('/events') || owns('/admin/events')) return flags.events;
  if (owns('/give') || owns('/admin/giving')) return flags.giving;
  if (owns('/connect') || owns('/admin/outreach/inbox')) return flags.connect;
  if (owns('/devotionals') || owns('/admin/content/devotionals')) return flags.devotionals;
  if (owns('/reading-plans') || owns('/admin/content/reading-plans') || owns('/account/reading')) {
    return flags.readingPlans;
  }
  if (owns('/resources') || owns('/admin/content/files')) return flags.resources;
  if (owns('/account/prayer') || owns('/admin/prayer')) return flags.prayerWall;
  if (owns('/account/bookings') || owns('/admin/rooms')) return flags.roomBooking;
  if (owns('/account/kids') || owns('/admin/kids')) return flags.kidsCheckIn;
  if (owns('/admin/attendance')) return flags.attendance;
  if (owns('/admin/groups')) return flags.groups;
  if (owns('/admin/volunteering')) return flags.volunteering;
  if (owns('/forms') || owns('/admin/forms')) return flags.forms;
  return true;
}

/**
 * The four that can reshape a church, so admin-only even among staff.
 *
 * Same set as `_adminOnlyPaths` in `lib/app/router.dart` with the two
 * that Shopify's IA renamed: members became People, and the audit log
 * moved under Settings where Shopify keeps it.
 */
const ADMIN_ONLY_PREFIXES = [
  '/admin/people',
  '/admin/campuses',
  '/admin/reports',
  '/admin/settings',
];

export function isAdminOnly(path: string): boolean {
  return ADMIN_ONLY_PREFIXES.some((prefix) => path === prefix || path.startsWith(`${prefix}/`));
}

/** Routes that belong to the product rather than to any church. */
export const GLOBAL_PATHS = new Set(['/', '/start', '/choose-church']);

export const AUTH_PATHS = new Set(['/sign-in', '/sign-up', '/forgot-password']);
