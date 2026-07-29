# Yoked Church

A cross-platform Flutter church app and website, built to be resold as a
customizable template: a public site, a member portal, and a staff
dashboard that runs the church without anyone touching code.

The whole app — including every admin screen — runs with **no backend at
all**, on bundled sample content. Connect Firebase when a church is ready
and the same build serves live data. Nothing is recompiled to switch.

```bash
flutter pub get
flutter run -d chrome
```

That's the zero-backend mode. Sign in from the demo panel as a member,
staff, or admin and click through everything.

## Customizing for a church

**Almost nothing lives in code.** A church's name, tagline, brand colors,
logo, About copy, service times, contact details, social and giving
links, and every feature switch are edited in the app itself at
`/admin/settings`, saved to a single Firestore document
(`churchSettings/main`), and applied to the live site immediately —
including the `ThemeData` the whole app is built from.

Without Firebase, the same settings come from
[`assets/data/church_settings.json`](assets/data/church_settings.json),
which is also the fallback if Firestore is unreachable. Editing that file
customizes the zero-backend build.

The shape of all of it is
[`lib/core/config/church_settings.dart`](lib/core/config/church_settings.dart).

### Feature flags

Fourteen switches on the settings screen: `sermons`, `events`, `giving`,
`connect`, `groups`, `volunteering`, `prayerWall`, `readingPlans`,
`devotionals`, `resources`, `kidsCheckIn`, `roomBooking`, `attendance`,
`forms`.

Turning one off **closes its routes**, not just its nav link — the page
stops answering for anyone holding the URL, and for search engines that
already indexed it. `test/features/feature_flags_test.dart` fails if a
new flag is ever added without a route guard behind it.

### Sample content

Everything in [`assets/data/`](assets/data): sermons, series, events,
groups and memberships, staff, locations, FAQs, devotionals, reading
plans, resources, prayer posts, rooms and bookings, attendance, and two
worked example forms. Replace these to reshape the demo.

## Connecting Firebase

The app decides once, at startup, based on whether
`lib/firebase_options.dart` has been filled in
([`lib/main.dart`](lib/main.dart)) — there is no flag to set:

1. Create a project at the [Firebase console](https://console.firebase.google.com); enable **Firestore**, **Authentication** (Email/Password, Google, Apple), and **Storage**.
2. `dart pub global activate flutterfire_cli`
3. `flutterfire configure` — overwrites `lib/firebase_options.dart` with real values.
4. Deploy the rules (**required** — Firestore and Storage are locked down until you do):

```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes,storage --project <your-project-id>
```

If Firebase is configured but fails to initialize, the app falls back to
bundled content rather than showing a broken site. A backend outage
should still leave service times and directions on screen.

### Bootstrapping the first admin

New accounts default to `member`, and there is nobody to promote you yet.
Sign up normally, then set that account's `role` to `admin` on its
`users/{uid}` document in the Firebase console. After that, admins
promote and demote everyone else from `/admin/members`.

### Firestore collections

`users`, `sermons`, `events`, `submissions` (connect cards), `groups`,
`groupMemberships`, `eventRsvps`, `givingRecords`, `volunteerPositions`,
`volunteerAssignments`, `notifications`, `announcements`, `auditLog`,
`devotionals`, `readingPlans`, `planProgress`, `sermonNotes`,
`resources`, `prayerPosts`, `prayerIntercessions`, `rooms`,
`roomBookings`, `checkIns`, `attendanceRecords`, `formDefinitions`,
`formSubmissions`.

Field shapes are the `fromMap`/`toMap` pairs in each feature's `domain/`.

### Storage

Two prefixes: `resources/` (files staff attach to the resource library)
and `formUploads/{formId}/` (files members attach to a form response).

One limit worth knowing before you rely on it: **an uploaded
members-only resource is protected by an unguessable URL, not by a
rule.** A resource's `membersOnly` flag lives on its Firestore document,
and a Storage rule cannot map a blob back to the document pointing at it.
The document — and therefore the link — stays hidden from signed-out
visitors, but the blob URL itself works for anyone who has it, the same
way a "anyone with the link" share does. If a church needs a genuinely
restricted document, link it from a service that enforces access.
`formUploads/` has no such caveat: staff-read only.

## What's in it

**Public** — home with live-stream banner, sermons with series and
search, events, giving, connect cards, about, staff, visit, FAQ,
locations, devotionals, reading plans, resource library, and public form
sign-ups.

**Members** (`/account`) — profile and household, small groups, event
RSVPs, volunteering, reading-plan progress, private sermon notes, prayer
wall, room bookings, kids check-in codes, directory, giving history,
notifications.

**Staff** (`/admin`) — CMS for sermons, events, groups, volunteering,
devotionals, reading plans, resources; prayer moderation; room booking
approval; the kids check-in desk; attendance; a form builder with
conditional logic and CSV export; the connect inbox; announcements.

**Admins** additionally — church settings, member roles, reports, and an
append-only audit log.

## Project structure

```
lib/
  app/          router, theme, and the one place the backend is chosen (backend.dart)
  core/
    config/     ChurchSettings - the runtime branding/feature document
    firestore/  CrudRepository + Firestore and in-memory base classes
    storage/    FileStorage seam (Firebase Storage, or "not available")
    export/     platform-split file download (browser Blob, clipboard elsewhere)
    widgets/    app shell, nav, page scaffolding, async/empty states
  features/<feature>/
    domain/       models and pure logic - no Flutter, no Firebase
    data/         repository interface + Firestore and local implementations
    application/  Riverpod providers and controllers
    presentation/ screens and widgets
assets/
  data/         sample content, incl. church_settings.json
  fonts/        Lora + Work Sans, bundled so text never depends on a CDN
firestore.rules, storage.rules, firestore.indexes.json, firebase.json
test/           Flutter tests
test_rules/     Firestore security-rule tests (Node, emulator)
```

Each feature owns its whole vertical slice. `domain/` never imports
Flutter or Firebase, which is what keeps the rules of the app testable
without either.

## Testing

```bash
flutter analyze
flutter test
flutter build web --release
```

### Security rules

The rules are the only thing protecting giving history, kids' pickup
codes, and form responses. They have their own suite — 104 assertions
across every collection, each with at least one *denied* case — run
against the Firebase emulator:

```bash
cd test_rules && ./run.sh
```

That starts the emulator, runs the suite, and shuts it down. Re-run it
whenever `firestore.rules` changes.

### Running against the emulator

```bash
firebase emulators:start --project demo-yoked-church --only auth,firestore,storage
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=true
```

(with `lib/firebase_options.dart` configured, so the app picks the
Firestore backend). The emulator UI is at `http://127.0.0.1:4000`.

## Deploying

Pushing to `main` runs
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which
analyzes, tests, builds the web app, and publishes `build/web` to GitHub
Pages.

One-time setup: **Settings → Pages → Source: GitHub Actions**. The site
lands at `https://<user>.github.io/<repo>/`.

## iOS and Android

`android/` and `ios/` scaffolds are present and the code is
platform-clean: the only web-specific API in the app (the CSV download in
`lib/core/export/`) sits behind a conditional import, so mobile builds
get a clipboard fallback instead of a compile error.

Beyond that, the mobile targets are **unverified** — no build has been
run on a device or simulator, and neither store's signing, icons, or
permissions have been set up. CI builds a debug APK on every push, so a
break is caught, but treat "runs on a phone" as work still to do rather
than a claim this template makes.
