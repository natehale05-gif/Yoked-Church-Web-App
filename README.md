# Yoked — Customizable Church Website & App

Yoked is a cross-platform **Flutter/Dart** app that is designed to be **sold as a
white-label church website and app**. One codebase powers a beautiful public
site (web) and a native-feeling mobile app (iOS/Android), and everything — brand,
colors, typography, copy, and content — is **fully customizable by an admin
account**, with no code changes required.

It ships with a complete demo church, **"Circle Church"**, so buyers can see the
finished product immediately and then re-brand it for their own congregation.

## How the "sell it from another website" model works

Every church is defined by a single JSON document (`SiteData`) containing its
branding config plus all content. This makes provisioning easy:

1. A seller's storefront (the "other website") collects a church's details and
   produces a `SiteData` JSON — the same format you see under
   **Admin → Provisioning & Data → Export**. A ready-made template lives in
   [`assets/seed/example_provisioning.json`](assets/seed/example_provisioning.json).
2. That JSON is handed to the church's app instance (pasted into
   **Admin → Provisioning & Data → Import**, or wired into your backend).
3. The app instantly re-themes and re-populates from the imported config.

Because the whole app is data-driven, the admin panel doubles as a live editor:
every change saves locally and updates the running app immediately.

## Features

**Public app / site**
- Responsive layout: top navigation on desktop/web, drawer + bottom bar on mobile.
- Home with a branded hero, service times, welcome, "this week" highlights, and a giving banner.
- About (mission, story, statements of belief, staff/leaders).
- Messages/Sermons with search, series filtering, and a live-stream banner.
- Events with dates, categories, locations, and RSVP links.
- Ministries directory.
- Giving page with multiple funds and secure external links.
- Contact (address/phone/email/map + social links).

**Admin console (white-label customization)**
- Branding: church name, logo/monogram, primary/secondary/accent colors (with presets), Google font, corner roundness, dark mode.
- Editable copy for hero, welcome, about, mission, beliefs, giving, and footer.
- Feature toggles to enable/disable whole sections per church.
- Content managers for sermons, events, ministries, staff, service times, giving funds, and social links.
- Provisioning tools: export/import the full config as JSON, reset to demo, or start blank.
- Admin account with editable credentials.

## Tech

- Flutter (Material 3), `provider` for state, `shared_preferences` for local persistence.
- `google_fonts` for typography, `url_launcher` for external links, `intl` for dates.
- Theme is generated at runtime from the church config, so re-branding is instant.

## Getting started

```bash
flutter pub get

# Run on web
flutter run -d chrome

# Run on a mobile device/emulator
flutter run

# Analyze & test
flutter analyze
flutter test

# Production web build
flutter build web --release
```

### Admin sign-in (demo)

Tap the **admin icon** in the app bar.

- Username: `admin`
- Password: `yoked-admin`

Change these under **Admin → Admin Account**.

> **Security note:** the bundled admin auth is a local, client-side gate suitable
> for demos and single-tenant deployments. For a real multi-tenant "sell from a
> storefront" flow, verify admins against a backend and provision each church's
> config server-side — the `SiteData` import/export hooks are built for exactly
> that integration.

## Project layout

```
lib/
  models/        # ChurchConfig, Sermon, ChurchEvent, Ministry, StaffMember, SiteData …
  data/          # DefaultSiteData (the "Circle Church" demo)
  state/         # SiteController (content + persistence), AuthController (admin)
  theme/         # AppTheme.fromConfig — config → Material 3 ThemeData
  navigation/    # AppShell + section definitions
  screens/       # public pages + screens/admin/* customization console
  widgets/       # shared UI (logo, footer, section header, responsive helpers)
  utils/         # color/icon/url helpers
```
