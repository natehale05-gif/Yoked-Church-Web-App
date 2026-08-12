import { z } from 'zod';

import { featureFlagsSchema } from './features';

/**
 * Everything a church says about itself.
 *
 * Ported field-for-field from `ChurchSettings` in
 * `lib/core/config/church_settings.dart`. The names are the keys of
 * `churches/{id}` documents that already exist in Firestore and of
 * `assets/data/church_settings.json`, so they are a contract, not a
 * naming choice.
 *
 * Every string defaults to empty rather than being required. A church
 * part-way through setup is the normal case — the setup guide on the
 * admin home exists precisely to work through these — and a schema that
 * rejected a half-filled church would lock its staff out of the screen
 * where they would finish it.
 */

const hex = z.string().regex(/^#[0-9a-fA-F]{6}$/, 'expected a #rrggbb colour');

export const brandColorsSchema = z.object({
  primary: hex.default('#1B3A4B'),
  accent: hex.default('#C9A24B'),
  background: hex.default('#F7F5F0'),
});

export const contactInfoSchema = z.object({
  address: z.string().default(''),
  phone: z.string().default(''),
  email: z.string().default(''),
  mapUrl: z.string().default(''),
});

export const socialLinksSchema = z.object({
  facebook: z.string().default(''),
  instagram: z.string().default(''),
  youtube: z.string().default(''),
  givingUrl: z.string().default(''),
  liveStreamUrl: z.string().default(''),
  youtubeChannelId: z.string().default(''),
  podcastUrl: z.string().default(''),
});

export const serviceTimeSchema = z.object({
  day: z.string().default(''),
  time: z.string().default(''),
  label: z.string().default(''),
});

export const churchSettingsSchema = z.object({
  churchName: z.string().default('Your Church'),
  tagline: z.string().default(''),
  logoUrl: z.string().default(''),
  aboutHeadline: z.string().default(''),
  aboutBody: z.string().default(''),
  beliefs: z.string().default(''),
  visitInfo: z.string().default(''),

  /**
   * Retained for the same reason `appDownloads` is: live documents carry
   * it and a settings round-trip should not drop fields. Nothing reads
   * it now that the installable builds are the PWA rather than GitHub
   * releases of a Flutter binary.
   */
  releasesRepo: z.string().default(''),

  colors: brandColorsSchema.default({}),
  contact: contactInfoSchema.default({}),
  social: socialLinksSchema.default({}),
  serviceTimes: z.array(serviceTimeSchema).default([]),
  features: featureFlagsSchema.default({}),
});

export type BrandColors = z.infer<typeof brandColorsSchema>;
export type ContactInfo = z.infer<typeof contactInfoSchema>;
export type SocialLinks = z.infer<typeof socialLinksSchema>;
export type ServiceTime = z.infer<typeof serviceTimeSchema>;
export type ChurchSettings = z.infer<typeof churchSettingsSchema>;

/** A church nobody has configured yet. */
export const fallbackChurchSettings: ChurchSettings = churchSettingsSchema.parse({});
