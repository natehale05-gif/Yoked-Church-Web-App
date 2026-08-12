import { z } from 'zod';

/**
 * Which parts of the app a church runs.
 *
 * Ported field-for-field from `FeatureFlags` in
 * `lib/core/config/church_settings.dart`. The names are not a free
 * choice: they are keys in `churches/{id}/settings` documents that
 * already exist, and `firestore.rules` reads some of them.
 *
 * Every flag defaults to on. A church that has never opened settings
 * gets the whole app, which is the right default for a product somebody
 * is evaluating.
 */
export const featureFlagsSchema = z.object({
  sermons: z.boolean().default(true),
  events: z.boolean().default(true),
  giving: z.boolean().default(true),
  connect: z.boolean().default(true),
  groups: z.boolean().default(true),
  volunteering: z.boolean().default(true),
  prayerWall: z.boolean().default(true),
  readingPlans: z.boolean().default(true),
  devotionals: z.boolean().default(true),
  resources: z.boolean().default(true),
  kidsCheckIn: z.boolean().default(true),
  roomBooking: z.boolean().default(true),
  attendance: z.boolean().default(true),
  forms: z.boolean().default(true),

  /**
   * The download page for the installable desktop and Android builds.
   *
   * Retained because live `settings` documents carry it, but nothing
   * reads it any more: those builds were Flutter's, and the rebuild
   * ships a web app and an installable PWA instead. It stays in the
   * schema so a round-trip through the settings form does not silently
   * drop a field, and it will go when the Flutter app does.
   */
  appDownloads: z.boolean().default(true),
});

export type FeatureFlags = z.infer<typeof featureFlagsSchema>;

/** Every flag on — what a church gets before anyone changes anything. */
export const defaultFeatureFlags: FeatureFlags = featureFlagsSchema.parse({});
