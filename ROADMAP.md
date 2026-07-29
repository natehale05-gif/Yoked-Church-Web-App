# Roadmap

What has been built, and what deliberately hasn't. The previous version
of this file was a pre-build planning document; everything it planned is
either done or listed below as explicitly not done.

## Built

**M0 — Foundation.** Riverpod, go_router, and a repository pattern where
every feature declares an interface and gets a Firestore *and* an
in-memory implementation from a shared base
(`lib/core/firestore/crud_repository.dart`). The backend is selected once
at startup by a single `ProviderScope` override
(`lib/app/backend.dart`) — which is what lets one build serve both a live
church and a zero-backend preview, and what makes the whole app testable
without Firebase.

**M1 — Public site.** Home with live-stream banner, sermons with series
and search, events, giving, connect cards, about, staff, visit, FAQ,
locations.

**M2 — Auth and the member portal.** Email/password, Google, Apple, plus
a demo sign-in for the zero-backend build. Profile and household, small
groups, event RSVPs, volunteering, opt-in directory, giving history,
notifications.

**M3 — Staff dashboard and church settings.** The CMS, and the settings
screen that moved branding, copy, service times, and feature flags out of
code and into a Firestore document. Announcements and an append-only
audit log.

**M4 — Discipleship and content.** Devotionals, reading plans with
per-member progress, private sermon notes, a resource library with a
storage seam, a moderated prayer wall, and an external podcast link.

M4 existed because four feature flags controlled nothing at all — an
admin could flip them and watch the site not change.
`test/features/feature_flags_test.dart` now fails if a flag is added
without a route guard, and as of M5 there are no exemptions left.

**M5 — Operations.** Rooms and bookings with the conflict caught at
approval; kids check-in with single-use pickup codes; attendance counted
two ways (headcount for services, per-person against the roster for
groups); a form builder with conditional logic, multi-page forms, file
uploads, CSV export and notification routing; and admin reports.

**M6 — Hardening.** Storage rules (there were none, while two features
wrote to the bucket), 104 security-rule assertions against the emulator
covering every collection, a README that matches the code, and CI that
runs analyze, tests, the rules suite, and an Android build.

## Not built

Listed because a buyer should know what they are not getting, not as a
commitment to build them.

- **YouTube live/VOD sync.** The homepage live banner is driven by a
  `liveStreamUrl` in settings, set by hand. Automatic detection — banner
  appears when the channel goes live, ended stream lands in the sermon
  library for review — needs a scheduled server-side job holding a
  YouTube Data API key, so it cannot be a static-site feature. It is the
  largest single item here.
- **Push and email notifications.** The in-app inbox is real and
  staff-write-only. Nothing leaves the app: no FCM, no email. Form
  notification routing deliberately targets staff *accounts* rather than
  typed email addresses for exactly this reason — offering an email field
  would promise delivery that never happens.
- **Giving provider sync.** Giving records are entered by staff. There is
  no Stripe/Tithe.ly/Pushpay integration, and the reports page says so
  where the number would otherwise look authoritative.
- **Sermon plays and site analytics.** Nothing records a view. The
  reports page states this rather than showing an invented figure.
- **Multi-campus.** Locations exist as content; nothing is scoped by
  campus.
- **Data export and account deletion tooling.** CSV export exists for
  form responses only. A member cannot delete their own account from the
  app, which matters for GDPR/CCPA compliance if a church is subject to
  either.
- **Verified mobile builds.** `android/` and `ios/` are present and the
  code is platform-clean, but nothing has run on a device: no signing,
  icons, permissions, or store setup. CI builds a debug APK so a
  compile break is caught; that is the whole of the claim.
- **Multi-tenant SaaS.** This is one deploy per church. Managing many
  churches' subscriptions and billing from one instance is a different
  product.

## Open questions

- **Giving provider integration.** Worth building only against a specific
  provider a customer already uses. Manual entry covers the reporting and
  annual-statement need in the meantime.
- **Members-only file uploads.** An uploaded members-only resource is
  protected by an unguessable URL rather than a rule (see the README).
  Making it a real restriction means either carrying the flag in the
  storage path or serving downloads through a function — both worth
  doing if a church stores something genuinely sensitive there, neither
  worth doing speculatively.
