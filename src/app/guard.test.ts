import { describe, expect, it } from 'vitest';

import { defaultFeatureFlags, featureFlagsSchema } from '../core/features';
import { flagAllows, isAdminOnly } from './guard';
import { adminNavigation } from '../shell/navigation';

describe('a switched-off feature closes its routes', () => {
  it('closes the giving admin, not just the sidebar link', () => {
    const flags = featureFlagsSchema.parse({ giving: false });

    expect(flagAllows(flags, '/admin/giving')).toBe(false);
    expect(flagAllows(flags, '/admin/giving/campaigns')).toBe(false);
  });

  it('leaves unowned routes alone', () => {
    expect(flagAllows(featureFlagsSchema.parse({ giving: false }), '/admin')).toBe(true);
  });

  it('does not let a prefix swallow a longer name', () => {
    // `/admin/eventsomething` is not under `/admin/events`.
    const flags = featureFlagsSchema.parse({ events: false });

    expect(flagAllows(flags, '/admin/eventsomething')).toBe(true);
  });
});

describe('the guard covers the addresses the sidebar offers', () => {
  it('closes every destination whose feature is off', () => {
    // The IA rewrite moved several routes - `/admin/resources` became
    // `/admin/content/files`, `/admin/announcements` became
    // `/admin/outreach/announcements`. A guard still naming the old
    // paths would pass its own tests and leave every renamed page open.
    const owners = [
      ['giving', '/admin/giving'],
      ['sermons', '/admin/sermons'],
      ['events', '/admin/events'],
      ['groups', '/admin/groups'],
      ['volunteering', '/admin/volunteering'],
      ['kidsCheckIn', '/admin/kids'],
      ['attendance', '/admin/attendance'],
      ['roomBooking', '/admin/rooms'],
      ['forms', '/admin/forms'],
      ['prayerWall', '/admin/prayer'],
      ['devotionals', '/admin/content/devotionals'],
      ['readingPlans', '/admin/content/reading-plans'],
      ['resources', '/admin/content/files'],
      ['connect', '/admin/outreach/inbox'],
    ] as const;

    for (const [flag, path] of owners) {
      const off = featureFlagsSchema.parse({ [flag]: false });
      expect(flagAllows(off, path), `${flag} should close ${path}`).toBe(false);
      expect(flagAllows(defaultFeatureFlags, path), `${path} should be open by default`).toBe(true);
    }
  });

  it('leaves no flagged sidebar destination ungoverned', () => {
    // Walks the sidebar rather than a list written by hand: with every
    // feature off, nothing a flag owns may still be reachable.
    const shown = adminNavigation(defaultFeatureFlags, { isAdmin: true })
      .flatMap((s) => s.items)
      .flatMap((i) => [i.path, ...(i.subNavigationItems ?? []).map((s) => s.path)]);

    const everythingOff = featureFlagsSchema.parse({
      sermons: false,
      events: false,
      giving: false,
      connect: false,
      groups: false,
      volunteering: false,
      prayerWall: false,
      readingPlans: false,
      devotionals: false,
      resources: false,
      kidsCheckIn: false,
      roomBooking: false,
      attendance: false,
      forms: false,
    });

    // Home, People, Campuses, Reports and the rest belong to no flag -
    // they are the church itself, and a church with every feature off
    // still has staff, a website and a bill.
    const unowned = new Set([
      '/admin',
      '/admin/people',
      '/admin/people/households',
      '/admin/people/segments',
      '/admin/campuses',
      '/admin/reports',
      '/admin/content',
      '/admin/outreach',
      '/admin/outreach/announcements',
      '/admin/website',
      '/admin/website/themes',
      '/admin/website/pages',
      '/admin/website/navigation',
      '/admin/settings',
    ]);

    for (const path of shown) {
      if (unowned.has(path)) continue;
      expect(flagAllows(everythingOff, path), `${path} stays open with every feature off`).toBe(false);
    }
  });
});

describe('admin-only', () => {
  it('covers the four that can reshape the church', () => {
    expect(isAdminOnly('/admin/people')).toBe(true);
    expect(isAdminOnly('/admin/campuses')).toBe(true);
    expect(isAdminOnly('/admin/reports')).toBe(true);
    expect(isAdminOnly('/admin/settings')).toBe(true);
  });

  it('covers what is under them, not just the landing page', () => {
    // `_adminOnlyPaths` in the Dart guard was an exact-match set, so
    // `/admin/settings/audit` - a page that did not exist yet - would
    // have been staff-reachable on the day it was added.
    expect(isAdminOnly('/admin/people/households')).toBe(true);
    expect(isAdminOnly('/admin/settings/audit')).toBe(true);
  });

  it('leaves the content tools to staff', () => {
    expect(isAdminOnly('/admin/sermons')).toBe(false);
    expect(isAdminOnly('/admin/giving')).toBe(false);
  });

  it('matches what the sidebar hides from staff', () => {
    const staffPaths = adminNavigation(defaultFeatureFlags, { isAdmin: false })
      .flatMap((s) => s.items)
      .map((i) => i.path);

    for (const path of staffPaths) {
      expect(isAdminOnly(path), `${path} is offered to staff but the guard blocks it`).toBe(false);
    }
  });
});
