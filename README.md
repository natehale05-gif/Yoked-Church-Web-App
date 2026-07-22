# Yoked Church

A cross-platform Flutter church app/website, built to be resold as a customizable template: sermons & livestream, events, online giving, and prayer requests / connect cards - deployed as a static site on GitHub Pages.

See [`ROADMAP.md`](ROADMAP.md) for the planned staff/admin dashboard and
YouTube live-sync features not yet built (accounts and the member portal
below are done).

## Quick start

```bash
flutter pub get
flutter run -d chrome
```

## Customizing for a church

Almost everything a customer needs to change lives in one file:
[`lib/config/church_config.dart`](lib/config/church_config.dart) - church name, tagline, brand colors, service times, contact info, social links, giving URL, and feature toggles (`showSermons`, `showEvents`, `showGiving`, `showConnect`).

Sample content (used out of the box, no backend required) lives in:
- [`assets/data/sermons.json`](assets/data/sermons.json)
- [`assets/data/events.json`](assets/data/events.json)

## Connecting a real backend (optional)

By default the app runs entirely on the bundled sample data above - no
backend needed. To pull live sermons/events and collect prayer request /
connect card submissions in Firestore instead:

1. Create a project at the [Firebase console](https://console.firebase.google.com) and enable Firestore.
2. `dart pub global activate flutterfire_cli`
3. `flutterfire configure` (overwrites `lib/firebase_options.dart` with your project's real values)
4. Set `useFirebase = true` in `lib/config/church_config.dart`

Expected Firestore collections: `sermons`, `events`, `submissions` (see the `fromMap`/`toMap` methods in `lib/models/` for the exact field shapes).

## Accounts & member portal

With `useFirebase = true`, the site gains a "Sign In" link and a
protected `/account` area: sign up with email/password, Google, or
Apple; edit your profile and household; browse and request to join
small groups; RSVP to events (also shown right on the public Events
page); opt into the member directory; and view giving history.

New accounts default to the `member` role. To make someone `staff` or
`admin` (which unlocks the `/admin` dashboard below), edit their `role`
field directly on their `users/{uid}` document in the Firebase console
for now - there's no in-app role management yet (that's Phase 4 of the
roadmap).

## Staff dashboard

Signed-in `staff`/`admin` users get a "Staff Dashboard" link (in the
account menu) to `/admin`: create/edit/delete sermons and events,
review and mark Connect-page submissions as followed up, and manage
small groups (including approving pending join requests from each
group's roster). Everything here is backed by the same Firestore
collections and rules as the member portal above.

**Deploy the security rules** (required before going live with
accounts - Firestore defaults to fully locked-down otherwise):

```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes --project <your-firebase-project-id>
```

### Local development with the Firebase emulator

Test the whole accounts/member-portal flow without touching your real
Firebase project:

```bash
firebase emulators:start --project demo-yoked-church --only auth,firestore
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATOR=true
```

(with `useFirebase = true` in `church_config.dart` for that run). The
emulator UI is at `http://127.0.0.1:4000`. The security rules
themselves are also covered by an automated test suite using
`@firebase/rules-unit-testing` against this same emulator - ask your
AI assistant to regenerate it from `firestore.rules` if the rules ever
change.

## Project structure

```
lib/
  config/     church_config.dart - single source of truth for branding/content
  models/     Sermon, ChurchEvent, ConnectSubmission, AppUser, ChurchGroup, GroupMembership, EventRsvp, GivingRecord
  services/   data loading (bundled JSON, or Firestore when enabled)
  providers/  AuthProvider - session/role state, only active when useFirebase is true
  screens/    home, sermons, events, giving, connect, auth/ (sign in/up), account/ (member portal)
  widgets/    shared nav bar, footer, account sub-nav, responsive layout helpers
  theme/      colors, typography (Lora + Work Sans, bundled locally), breakpoints
  router/     go_router route table + auth-aware redirects
assets/
  data/       sample sermons.json / events.json
  fonts/      Lora + Work Sans (OFL licensed, bundled so text never depends on a CDN)
firestore.rules, firestore.indexes.json, firebase.json - Firestore security rules and emulator config
```

## Deploying to GitHub Pages

Pushing to `main` triggers [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which builds the Flutter web app and publishes `build/web` via GitHub Pages.

One-time setup: in the repo's **Settings > Pages**, set **Source** to **GitHub Actions**. The site will then be live at `https://<your-username>.github.io/<repo-name>/`.

## Adding iOS/Android later

This template currently targets web only. To add mobile targets:

```bash
flutter create --platforms=ios,android .
```

## Testing

```bash
flutter analyze
flutter test
flutter build web --release
```
