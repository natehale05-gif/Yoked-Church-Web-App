import {
  CalendarIcon,
  ChartVerticalFilledIcon,
  ClipboardChecklistIcon,
  ContentIcon,
  FormsIcon,
  HeartIcon,
  HomeIcon,
  LocationIcon,
  MarketsIcon,
  MegaphoneIcon,
  OrderIcon,
  PersonIcon,
  ProductIcon,
  SettingsIcon,
  SmileyHappyIcon,
  StoreOnlineIcon,
  TeamIcon,
  WorkIcon,
} from '@shopify/polaris-icons';
import type { IconSource } from '@shopify/polaris';

import type { FeatureFlags } from '../core/features';

export interface NavSubItem {
  label: string;
  path: string;
}

export interface NavItem {
  label: string;
  /** Bare sub-path, without the `/c/{churchId}` prefix. */
  path: string;
  icon: IconSource;
  /**
   * Staff can reach content tools; only an admin can reshape the church.
   * Matches `_adminOnlyPaths` in `lib/app/router.dart` — the guard, not
   * this list, is what actually enforces it.
   */
  adminOnly?: boolean;
  subNavigationItems?: NavSubItem[];
}

/** Drops the entries a switched-off feature left behind. */
const present = (item: NavItem | null): item is NavItem => item !== null;

export interface NavSection {
  title?: string;
  items: NavItem[];
  separator?: boolean;
  /** Pushes the section to the bottom of the sidebar, as Settings is. */
  fill?: boolean;
}

/**
 * The Shopify admin sidebar, with the commerce nouns replaced.
 *
 * The mapping is deliberate and is the point of the rebuild:
 *
 * | Shopify   | here     | why                                     |
 * |-----------|----------|-----------------------------------------|
 * | Orders    | Giving   | money arriving, one row per transaction |
 * | Products  | Sermons  | the catalogue of things people consume  |
 * | Customers | People   | the person record everything hangs off  |
 * | Marketing | Outreach | messages sent out to reach people       |
 * | Markets   | Campuses | the same thing in another place         |
 * | Analytics | Reports  | —                                       |
 * | Online Store | Website | the public site and its theme        |
 *
 * Church operations that Shopify has no analogue for — events, groups,
 * kids, rotas — go in a **Ministry** section rather than being forced
 * into a commerce noun that does not fit. Shopify does the same thing
 * with its "Sales channels" section: a titled group below the main list.
 *
 * Order matters and is Shopify's: the thing you check daily first
 * (Orders/Giving), then the catalogue, then the people.
 */
export function adminNavigation(
  flags: FeatureFlags,
  { isAdmin }: { isAdmin: boolean },
): NavSection[] {
  // Annotated, and filtered on the next statement rather than chained.
  // A bare literal widens to a union of anonymous shapes, and an
  // annotation on `[...].filter(...)` describes the *result*, leaving
  // the literal - and so the predicate - still inferred.
  const primarySlots: (NavItem | null)[] = [
    { label: 'Home', path: '/admin', icon: HomeIcon },

    flags.giving
      ? {
          label: 'Giving',
          path: '/admin/giving',
          icon: OrderIcon,
          subNavigationItems: [
            { label: 'Recurring', path: '/admin/giving/recurring' },
            { label: 'Campaigns', path: '/admin/giving/campaigns' },
            { label: 'Funds', path: '/admin/giving/funds' },
          ],
        }
      : null,

    flags.sermons
      ? {
          label: 'Sermons',
          path: '/admin/sermons',
          icon: ProductIcon,
          subNavigationItems: [{ label: 'Series', path: '/admin/sermons/series' }],
        }
      : null,

    {
      label: 'People',
      path: '/admin/people',
      icon: PersonIcon,
      adminOnly: true,
      subNavigationItems: [
        { label: 'Households', path: '/admin/people/households' },
        { label: 'Segments', path: '/admin/people/segments' },
      ],
    },

    {
      label: 'Outreach',
      path: '/admin/outreach',
      icon: MegaphoneIcon,
      subNavigationItems: [
        { label: 'Announcements', path: '/admin/outreach/announcements' },
        ...(flags.connect ? [{ label: 'Inbox', path: '/admin/outreach/inbox' }] : []),
      ],
    },

    {
      label: 'Content',
      path: '/admin/content',
      icon: ContentIcon,
      subNavigationItems: [
        ...(flags.devotionals ? [{ label: 'Devotionals', path: '/admin/content/devotionals' }] : []),
        ...(flags.readingPlans ? [{ label: 'Reading plans', path: '/admin/content/reading-plans' }] : []),
        ...(flags.resources ? [{ label: 'Files', path: '/admin/content/files' }] : []),
      ],
    },

    { label: 'Campuses', path: '/admin/campuses', icon: MarketsIcon, adminOnly: true },
    { label: 'Reports', path: '/admin/reports', icon: ChartVerticalFilledIcon, adminOnly: true },
  ];
  const primary = primarySlots.filter(present);

  // Everything a church does that a shop does not. Titled rather than
  // folded into the list above, so the commerce mapping stays legible
  // instead of accumulating exceptions.
  const ministrySlots: (NavItem | null)[] = [
    flags.events ? { label: 'Events', path: '/admin/events', icon: CalendarIcon } : null,
    flags.groups ? { label: 'Groups', path: '/admin/groups', icon: TeamIcon } : null,
    flags.volunteering ? { label: 'Serving', path: '/admin/volunteering', icon: WorkIcon } : null,
    flags.kidsCheckIn ? { label: 'Kids', path: '/admin/kids', icon: SmileyHappyIcon } : null,
    flags.attendance
      ? { label: 'Attendance', path: '/admin/attendance', icon: ClipboardChecklistIcon }
      : null,
    flags.roomBooking ? { label: 'Rooms', path: '/admin/rooms', icon: LocationIcon } : null,
    flags.forms ? { label: 'Forms', path: '/admin/forms', icon: FormsIcon } : null,
    flags.prayerWall ? { label: 'Prayer', path: '/admin/prayer', icon: HeartIcon } : null,
  ];
  const ministry = ministrySlots.filter(present);

  const sections: NavSection[] = [{ items: primary }];

  if (ministry.length > 0) {
    sections.push({ title: 'Ministry', items: ministry, separator: true });
  }

  // Shopify's "Sales channels" slot: separated from the main list, because
  // the public site is a different surface from the records above it. No
  // section title - there is one item, and "Website / Website" reads as a
  // mistake.
  sections.push({
    separator: true,
    items: [
      {
        label: 'Website',
        path: '/admin/website',
        icon: StoreOnlineIcon,
        subNavigationItems: [
          { label: 'Themes', path: '/admin/website/themes' },
          { label: 'Pages', path: '/admin/website/pages' },
          { label: 'Navigation', path: '/admin/website/navigation' },
        ],
      },
    ],
  });

  // Where Shopify keeps it: pinned to the bottom, on its own, below
  // everything else in the sidebar.
  sections.push({
    fill: true,
    separator: true,
    items: [{ label: 'Settings', path: '/admin/settings', icon: SettingsIcon, adminOnly: true }],
  });

  return sections.map((section) => ({
    ...section,
    items: section.items.filter((item) => isAdmin || item.adminOnly !== true),
  }));
}
