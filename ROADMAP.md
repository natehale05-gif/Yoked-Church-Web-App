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

**M7 — Phones.** One of roughly forty feature screens referenced a
breakpoint before this; the rest were desktop layouts that a phone
rendered at desktop proportions. Admin list rows, dialogs and detail
pages now branch on width, and `test/features/responsive_test.dart`
walks every route at phone and tablet size and reports every offender
rather than dying on the first.

**M8 — A demo that does not expire.** Every date in `assets/data/` was
hand-written, so the zero-backend build had a hard shelf life: the
sign-up form was three days from closing, the events page three weeks
from empty, the reports three months from zero. Sample dates are now
read as relative to the day they were authored and rolled forward in
whole weeks on load - whole weeks because the Sunday service has to stay
on a Sunday. Thirteen empty collections were filled in at the same time,
because "0 responses" reads as broken rather than unconfigured.

**M9 — Installable apps.** macOS, Windows and Linux scaffolds, a release
workflow that builds all four platforms on a version tag and attaches
them to a GitHub release, and a `/download` page whose buttons point at
`releases/latest/download/...` so they keep working across releases. Two
release-only defects fixed on the way: the Android release build had no
`INTERNET` permission and the macOS release build had no network
entitlement, both because Flutter's template declares them for debug
only. A third had been breaking every Android build outright - see
`android/build.gradle.kts`.

**M10 — one app, many churches, and a phone that behaves like one.**
Every collection moved under `churches/{churchId}`, which took one
getter in the repository base class and a rewrite of the security rules;
roles moved with it, because being staff at one church should not make
you staff at all of them. The app now opens on a church picker and
becomes whichever church you choose - name, colours, content, features -
and switching re-themes without a restart. Eleven rule assertions cover
cross-tenant isolation specifically, verified by resolving a role
against the wrong church and watching them go red.

Phones got navigation that reaches: a bottom bar built from the
church's feature flags, replacing the hamburger that opened a flat sheet
of every destination in the app.

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
- **Signed builds, and iOS at all.** The desktop and Android artifacts
  are real and installable, but none are code-signed - macOS, Windows
  and Android each warn on first launch, and the download page says so.
  Signing needs an Apple Developer account and a Windows certificate.
  iOS has no download at all and cannot: Apple allows no sideloading, so
  it would take an App Store listing. Icons and store metadata are still
  the Flutter defaults everywhere.
- **Live data on Linux.** No Firebase plugin supports Linux desktop, so
  that build runs on the bundled demo content and cannot sign in. The
  app falls back rather than crashing, and the download page states it.
- **Billing and subscriptions.** Many churches now share one backend,
  but nothing charges any of them. A church exists because a document
  exists. That is the actual Shopify part, and it is its own project.
- **Church self-signup.** Creating a church is an operator action, not a
  form a pastor fills in. Cheap to add now that tenancy exists.
- **Custom domains.** One app serves every church from one URL. A church
  wanting `gracechapel.org` needs hosting that supports per-tenant
  domains; GitHub Pages does not.
- **Per-tab navigation stacks.** The bottom bar returns to a tab's root
  rather than where you left it. Doing it properly means restructuring
  every route into `StatefulShellRoute` branches.

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
