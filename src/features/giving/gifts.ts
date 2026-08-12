import { z } from 'zod';

import rawGifts from '../../../assets/data/giving.json';
import rawMembers from '../../../assets/data/members.json';

/**
 * A gift, which is this app's order.
 *
 * Ported from `GivingRecord` in
 * `lib/features/giving/domain/giving_record.dart`. The keys are those of
 * documents under `churches/{id}/giving`, so they are fixed.
 */
export const giftSchema = z.object({
  uid: z.string(),
  amount: z.number(),
  /** `YYYY-MM-DD`. Stored as a plain date because a gift has no clock. */
  date: z.string(),
  fund: z.string().default('General Fund'),
  method: z.string().default('Online'),
  note: z.string().default(''),
});

export type Gift = z.infer<typeof giftSchema>;

/** A gift with the things a table row needs that the document lacks. */
export interface GiftRow extends Gift {
  /** Stable, and derived from the document rather than its position. */
  id: string;
  donorName: string;
}

const memberSchema = z.object({
  displayName: z.string().default(''),
  email: z.string().default(''),
});

/**
 * Who gave, by uid.
 *
 * The sample members file carries no ids: `LocalCrudRepository` assigned
 * them `local-0`, `local-1` … in read order, and the giving file refers
 * to those. That coupling is exactly what M19 was spent on, so the
 * derivation is written down here rather than assumed - and the test
 * beside this file fails if the two files stop lining up.
 */
export function donorNames(): Map<string, string> {
  const members = z.array(memberSchema).parse(rawMembers);
  const names = new Map<string, string>();

  members.forEach((member, index) => {
    names.set(`local-${index}`, member.displayName || member.email);
  });
  // The demo account is not in the members file; it is whoever is
  // signed in when the app runs with no backend.
  names.set('demo-member', 'Demo Member');

  return names;
}

/**
 * Every gift, newest first, with donor names attached.
 *
 * P2 replaces this with a Firestore query behind the same signature.
 */
export function allGifts(): GiftRow[] {
  const names = donorNames();

  return z
    .array(giftSchema)
    .parse(rawGifts)
    .map((gift, index) => ({
      ...gift,
      // Positional only because the bundled file has no ids to use.
      // Firestore documents do, and P2 uses them.
      id: `gift-${index}`,
      donorName: names.get(gift.uid) ?? 'Unknown',
    }))
    .sort((a, b) => b.date.localeCompare(a.date));
}

/** Money, the way a giving statement writes it. */
export function formatAmount(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: amount % 1 === 0 ? 0 : 2,
  }).format(amount);
}

/** `2026-07-26` as `26 Jul 2026`, which is what a table column has room for. */
export function formatDate(iso: string): string {
  const parts = iso.split('-').map(Number);
  // Length *and* finiteness. `Number('not')` is `NaN`, which is neither
  // undefined nor caught by a truthiness test, and `Intl` throws on an
  // invalid date rather than returning something odd - so one malformed
  // date in Firestore would blank the whole table.
  if (parts.length !== 3 || parts.some((n) => !Number.isFinite(n))) return iso;
  const [year, month, day] = parts as [number, number, number];
  // Constructed as UTC and read back as UTC. `new Date('2026-07-26')`
  // parses as midnight UTC and then prints in local time, so west of
  // Greenwich every gift in the table showed the previous day.
  const date = new Date(Date.UTC(year, month - 1, day));
  return new Intl.DateTimeFormat('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(date);
}
