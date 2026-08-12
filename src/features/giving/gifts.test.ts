import { describe, expect, it } from 'vitest';

import { allGifts, donorNames, formatAmount, formatDate } from './gifts';

describe('the bundled giving data still lines up with the members', () => {
  it('names a donor for every gift', () => {
    // The sample members file has no ids in it. The Flutter repository
    // assigned `local-0`, `local-1` … in read order, and giving.json
    // refers to those - so inserting a member at the top of the members
    // file silently re-points every gift at the wrong person.
    //
    // M19 was spent finding exactly this class of coupling. It cannot be
    // removed while the demo data has no ids, so it is checked instead.
    const unknown = allGifts().filter((gift) => gift.donorName === 'Unknown');

    expect(unknown.map((g) => g.uid)).toEqual([]);
  });

  it('resolves the positional ids the giving data uses', () => {
    const names = donorNames();

    expect(names.get('local-0')).toBeTruthy();
    expect(names.get('demo-member')).toBe('Demo Member');
  });

  it('has gifts to show at all', () => {
    expect(allGifts().length).toBeGreaterThan(0);
  });

  it('orders them newest first', () => {
    const dates = allGifts().map((g) => g.date);

    expect(dates).toEqual([...dates].sort((a, b) => b.localeCompare(a)));
  });
});

describe('formatting', () => {
  it('writes whole amounts without stray cents', () => {
    expect(formatAmount(150)).toBe('$150');
  });

  it('keeps cents where there are any', () => {
    expect(formatAmount(150.5)).toBe('$150.50');
  });

  it('does not shift a date backwards west of Greenwich', () => {
    // `new Date('2026-07-26')` is midnight UTC, and printing it in a
    // local timezone behind UTC gives the 25th. Every gift in the table
    // would have shown the day before it was given, for every user in
    // the Americas - which is most of them.
    const original = process.env.TZ;
    process.env.TZ = 'America/Los_Angeles';
    try {
      expect(formatDate('2026-07-26')).toBe('26 Jul 2026');
    } finally {
      process.env.TZ = original;
    }
  });

  it('leaves a malformed date alone rather than inventing one', () => {
    expect(formatDate('not-a-date')).toBe('not-a-date');
  });
});
