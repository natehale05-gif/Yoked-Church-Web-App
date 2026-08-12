import { describe, expect, it } from 'vitest';

import { defaultFeatureFlags, featureFlagsSchema } from '../core/features';
import { adminNavigation, type NavItem } from './navigation';

const flatten = (flags = defaultFeatureFlags, isAdmin = true): NavItem[] =>
  adminNavigation(flags, { isAdmin }).flatMap((section) => section.items);

const paths = (flags = defaultFeatureFlags, isAdmin = true) => flatten(flags, isAdmin).map((i) => i.path);

describe('the sidebar is Shopify\'s, with church nouns', () => {
  it('opens with Home and then the thing you check daily', () => {
    // Shopify's order, and the reason for it: Orders sits directly under
    // Home because it is what a merchant opens the admin to look at.
    // Giving is the same for a church treasurer.
    expect(paths().slice(0, 2)).toEqual(['/admin', '/admin/giving']);
  });

  it('pins Settings to the bottom on its own', () => {
    const sections = adminNavigation(defaultFeatureFlags, { isAdmin: true });
    const last = sections.at(-1)!;

    expect(last.fill).toBe(true);
    expect(last.items.map((i) => i.path)).toEqual(['/admin/settings']);
  });

  it('groups what a shop has no word for under Ministry', () => {
    const ministry = adminNavigation(defaultFeatureFlags, { isAdmin: true }).find(
      (s) => s.title === 'Ministry',
    );

    expect(ministry).toBeDefined();
    expect(ministry!.items.map((i) => i.label)).toContain('Kids');
  });

  it('gives no two destinations the same icon', () => {
    // Shopify's sidebar is scanned by shape as much as by word, and two
    // identical glyphs in one column defeats that. Caught Kids and
    // Prayer both holding the heart on the first draft.
    const icons = flatten().map((i) => i.icon);

    expect(new Set(icons).size).toBe(icons.length);
  });

  it('gives no two destinations the same path', () => {
    const all = paths();

    expect(new Set(all).size).toBe(all.length);
  });
});

describe('feature flags close destinations', () => {
  it('drops Giving entirely when a church does not take it', () => {
    const flags = featureFlagsSchema.parse({ giving: false });

    expect(paths(flags)).not.toContain('/admin/giving');
  });

  it('drops the Ministry section when every ministry feature is off', () => {
    const flags = featureFlagsSchema.parse({
      events: false,
      groups: false,
      volunteering: false,
      kidsCheckIn: false,
      attendance: false,
      roomBooking: false,
      forms: false,
      prayerWall: false,
    });

    // Not an empty titled section. A heading with nothing under it is
    // the same defect the home page had before M18 - it reads as a
    // broken page rather than an unused feature.
    expect(adminNavigation(flags, { isAdmin: true }).some((s) => s.title === 'Ministry')).toBe(false);
  });

  it('drops a sub-item without dropping its parent', () => {
    const flags = featureFlagsSchema.parse({ connect: false });
    const outreach = flatten(flags).find((i) => i.path === '/admin/outreach')!;

    expect(outreach.subNavigationItems?.map((s) => s.label)).toEqual(['Announcements']);
  });
});

describe('staff see less than admins', () => {
  it('hides the four destinations that can reshape the church', () => {
    // The same set as `_adminOnlyPaths` in lib/app/router.dart. The
    // guard is what enforces it; this only keeps the sidebar from
    // advertising a door that is locked.
    const staff = paths(defaultFeatureFlags, false);

    expect(staff).not.toContain('/admin/people');
    expect(staff).not.toContain('/admin/campuses');
    expect(staff).not.toContain('/admin/reports');
    expect(staff).not.toContain('/admin/settings');
  });

  it('still gives staff the content tools', () => {
    const staff = paths(defaultFeatureFlags, false);

    expect(staff).toContain('/admin/giving');
    expect(staff).toContain('/admin/sermons');
    expect(staff).toContain('/admin/events');
  });
});
