# Yoked Church

A cross-platform Flutter church app: a public site, a member portal, and
a staff dashboard that runs the church without anyone touching code.

**One app, many churches.** A member opens it, picks their church, and
the app becomes that church's — its name, its colours, its content, its
features. Switching church re-themes and re-reads everything without a
restart. Every collection lives under `churches/{churchId}`, and the
security rules answer every role question against *that* church, so
being staff at one is not being staff at any other.

The whole app — including every admin screen — runs with **no backend at
all**, on bundled sample content: three demo churches with genuinely
different branding, so the picker demonstrates the real thing. Connect
Firebase when you are ready and the same build serves live data. Nothing
is recompiled to switch.

```bash
flutter pub get
flutter run -d chrome
```

That's the zero-backend mode. Press **Start your church site**, name a
church, and you are its admin thirty seconds later — the whole signup
works with no backend at all. Or open one of the sample churches and
sign in from the demo panel as a member, staff, or admin.

## Every church has an address

`/#/c/grace-chapel` is a church's site. Send that link to anyone and it
opens *their* church — its name, its colours, its sermons — whichever
church the recipient looked at last. Signing up mints the address from
the church's name and shows it while you type, because it is permanent:
it goes on the noticeboard and in the newsletter, and renaming it would
break every link already shared.

The product's own pages are the three that are not a church: `/` (what
this is), `/start` (make one), `/choose-church` (find one).

## Setting up a church

Nobody has to do anything in a console. **Start your church site** asks
for four things — the church's name, and someone to run it — and lands
you in your own dashboard, as its admin, with a checklist of what is
still missing: service times, where you meet, a welcome, colours, a
first sermon. Each row goes to the screen that fixes it, and the list
disappears when there is nothing left.

Creating a church is the one write the security rules refuse outright.
`churches/{churchId}` keeps `allow create: if false`, because creating a
church means writing yourself in as its admin in the same breath, and a
rule permissive enough to allow that lets anyone mint admin rights over
a church they have just invented. The `createChurch` Cloud Function
holds the only path — which also lets it allocate the address inside a
transaction, so two people naming their church the same thing at the
same moment cannot both win it.

## Customizing for a church

**Almost nothing lives in code.** A church's name, tagline, brand colors,
logo, About copy, service times, contact details, social and giving
links, and every feature switch are edited in the app itself at
`/admin/settings` — including a gallery of ready-made looks, for the
many churches that have a logo but no brand guide and were otherwise
left staring at `#RRGGBB`. Picking one fills in the same three hex
fields, so there is no second place branding is stored. All of it saves
to that church's document (`churches/{churchId}`) and applies
immediately — including the `ThemeData` the whole app is built from.

That one document does double duty: it is the church's settings *and*
its entry in the public directory the picker lists, so choosing a church
has already fetched everything needed to theme the app as them.

Without Firebase, the churches come from
[`assets/data/churches.json`](assets/data/churches.json) — three of them,
deliberately unalike — falling back to
[`assets/data/church_settings.json`](assets/data/church_settings.json)
for anything not listed there. Editing either customizes the
zero-backend build.

The shape of all of it is
[`lib/core/config/church_settings.dart`](lib/core/config/church_settings.dart).

### Feature flags

Fifteen switches on the settings screen: `sermons`, `events`, `giving`,
`connect`, `groups`, `volunteering`, `prayerWall`, `readingPlans`,
`devotionals`, `resources`, `kidsCheckIn`, `roomBooking`, `attendance`,
`forms`, `appDownloads`.

Turning one off **closes its routes**, not just its nav link — the page
stops answering for anyone holding the URL, and for search engines that
already indexed it. `test/features/feature_flags_test.dart` fails if a
new flag is ever added without a route guard behind it.

### App icons

The launcher icons for Android, macOS, Windows and the web are generated
from the same mark the site's wordmark uses — `Icons.church` in the
church's own primary and accent colours — so they cannot drift from the
app when a brand colour changes:

```bash
flutter test tool/generate_app_icons.dart
```

That rewrites the icon files in `android/`, `macos/`, `windows/` and
`web/`, including Android adaptive icons and a multi-size Windows `.ico`.
The output is committed, so nobody has to run it to build the app — only
after changing the colours in
[`lib/core/config/church_settings.dart`](lib/core/config/church_settings.dart),
or swapping the glyph in the generator for a church's own artwork.

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

### The first admin

Nothing to do: whoever creates a church is its admin, written in by
`createChurch` in the same transaction that creates the church. After
that, admins promote and demote everyone else from `/admin/members`.

Roles are per church — being an admin at one says nothing about any
other — so someone joining an existing church starts as a `member`, and
that church's admins decide the rest.

Deploy the function before anyone signs up, or `/start` has nothing to
call:

```bash
firebase deploy --only functions --project <your-project-id>
```

### Going live automatically from YouTube

Paste a church's YouTube channel id into **Settings → Live streaming**
and the home page raises a "Live now" banner by itself whenever that
channel starts streaming, then files the finished stream as an
**unpublished** sermon for staff to review. A church that leaves the
field blank is never polled and costs nothing.

This is the one part of the app that needs a server. Setting it up:

1. **Move the Firebase project to the pay-as-you-go (Blaze) plan.** Cloud
   Scheduler will not run on Spark. At this scale the bill is pennies,
   but it is the first thing here that needs a card.
2. In the [Google Cloud console](https://console.cloud.google.com/apis/library/youtube.googleapis.com),
   enable the **YouTube Data API v3** on the same project, then create an
   API key under *APIs & Services → Credentials*. Restrict it to that one
   API.
3. Give the key to Firebase — it lives server-side and must never reach
   the client bundle, because anything shipped to a browser is public:
   ```bash
   firebase functions:secrets:set YOUTUBE_API_KEY --project <your-project-id>
   firebase deploy --only functions --project <your-project-id>
   ```
4. Find the channel id in YouTube Studio under *Settings → Channel →
   Advanced settings*. It starts with `UC` — a handle like `@yokedchurch`
   or a channel URL will not work.

`/admin/settings` shows when the poller last looked, which is how you
tell a wrong channel id from a quiet week.

**How it stays inside the quota.** The obvious call, `search.list` with
`eventType=live`, costs 100 units against a 10,000/day default: polling
one church every five minutes would be 28,800 units and the feature would
die on its first day. Instead each poll reads the channel's RSS feed
(free) and makes one `videos.list` call on the ids it returns (1 unit) —
about 300 units a day for one church, so a few dozen churches share one
key comfortably.

**What it writes.** `churches/{churchId}/live/current` holds whether they
are streaming, and is world-readable and writable by nobody: whether a
church is live is a fact about YouTube, not a claim the church gets to
make from a browser console. Finished streams become
`churches/{churchId}/sermons/yt-<videoId>` with `source: youtubeAuto`
and `published: false` — keyed by video id, so the next poll five minutes
later creates nothing and never overwrites an edit a staff member has
already made to the draft.

The code is in [`functions/`](functions/); the decisions it makes are
pure functions in `functions/youtube.js`, covered by `npm test` there.

### Firestore collections

Everything below lives **under a church**, as
`churches/{churchId}/<collection>`:

`users`, `sermons`, `events`, `submissions` (connect cards), `groups`,
`groupMemberships`, `eventRsvps`, `givingRecords`, `volunteerPositions`,
`volunteerAssignments`, `notifications`, `announcements`, `auditLog`,
`devotionals`, `readingPlans`, `planProgress`, `sermonNotes`,
`resources`, `prayerPosts`, `prayerIntercessions`, `rooms`,
`roomBookings`, `checkIns`, `attendanceRecords`, `formDefinitions`,
`formSubmissions`, `live`.

The only top-level collection is `churches` itself, which is
world-readable — that is how the picker lists them and how the app
themes itself before anyone signs in — and writable only by that
church's own admins.

Scoping happens in exactly one place,
`FirestoreCrudRepository.collection` in
[`lib/core/firestore/crud_repository.dart`](lib/core/firestore/crud_repository.dart);
the thirty repositories above declare a bare collection name and never
learn there is more than one church.

Field shapes are the `fromMap`/`toMap` pairs in each feature's `domain/`.

### Storage

Two prefixes, both under the church: `churches/{churchId}/resources/`
(files staff attach to the resource library) and
`churches/{churchId}/formUploads/{formId}/` (files members attach to a
form response). Callers pass the bare path; the church prefix is added
in `FirebaseFileStorage`, for the same reason it is added in the
Firestore base repository.

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

**Public** — home with a live banner that appears only when the
church is actually streaming, sermons with series and
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
functions/     the scheduled YouTube poller - the only server-side code
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
codes, and form responses. They have their own suite — 121 assertions
across every collection, each with at least one *denied* case — run
against the Firebase emulator:

```bash
cd test_rules && ./run.sh
```

That starts the emulator, runs the suite, and shuts it down. Re-run it
whenever `firestore.rules` changes.

### The scheduled function

```bash
npm --prefix functions test
```

No install needed: what is worth testing there — what counts as live,
what gets imported, what a second poll does — is pure functions over the
shapes YouTube returns, so none of it needs the network or the Firebase
SDKs.

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

## Download the app

The same app also installs on a desktop or an Android phone. Every
release publishes four artifacts, and the in-app `/download` page links
straight to the newest one:

| Platform | File | Link |
|---|---|---|
| Windows | `yoked-church-windows.zip` | [Download](https://github.com/natehale05-gif/Yoked-Church-Web-App/releases/latest/download/yoked-church-windows.zip) |
| macOS | `yoked-church-macos.zip` | [Download](https://github.com/natehale05-gif/Yoked-Church-Web-App/releases/latest/download/yoked-church-macos.zip) |
| Android | `yoked-church-android.apk` | [Download](https://github.com/natehale05-gif/Yoked-Church-Web-App/releases/latest/download/yoked-church-android.apk) |
| Linux | `yoked-church-linux.tar.gz` | [Download](https://github.com/natehale05-gif/Yoked-Church-Web-App/releases/latest/download/yoked-church-linux.tar.gz) |

These are `releases/latest/download/...` URLs, so they keep working
across every future release without editing anything.

### Cutting a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

That runs [`.github/workflows/release.yml`](.github/workflows/release.yml),
which builds all four and attaches them to a GitHub release.
`workflow_dispatch` runs the same builds without publishing, if you want
to exercise the pipeline without spending a version number.

### For your own fork

The download page reads the repository from **church settings →
Releases repository** (`releasesRepo`, as `owner/repo`). Point it at
your own fork, or the buttons will hand your members somebody else's
builds. Leave it blank and the page, its route and its links all
disappear.

### Sign the Android build before your second release

Android refuses to install an APK over one signed with a different key —
the member sees "App not installed" and has to uninstall first. Without
an upload key configured, the build falls back to Gradle's debug
keystore, and CI generates a fresh one on every run, so **no release
would ever install as an update over the previous one**.

Fixing it is a one-time setup. Generate a key and keep it somewhere
safe — losing it means never being able to update the app again:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks    # macOS: base64 -i upload-keystore.jks
```

Add three repository secrets (**Settings → Secrets and variables →
Actions**):

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the base64 output above |
| `ANDROID_KEYSTORE_PASSWORD` | the password you chose |
| `ANDROID_KEY_ALIAS` | `upload` |

The release workflow picks them up automatically. With none set it still
builds, and logs a warning saying the APK cannot be installed as an
update. To build a signed release locally instead, put the same values
in `android/key.properties` — `storeFile` (an **absolute** path to the
`.jks`, since a relative one resolves against `android/app`),
`storePassword`, `keyAlias`, `keyPassword`. That file and `*.jks` are
both gitignored.

### Nothing here is code-signed

Signing needs an Apple Developer account (~$99/yr) and a Windows
certificate (~$200/yr), so these builds carry neither, and every
platform says so on first launch:

- **macOS** — "cannot be opened because the developer cannot be
  verified". Right-click the app → Open → Open.
- **Windows** — SmartScreen: "Windows protected your PC" → More info →
  Run anyway.
- **Android** — asks permission to install from an unknown source.

The `/download` page carries each of these next to its button, so a
member is warned before they click rather than alarmed after. Adding
signing later means adding secrets to the workflow, not restructuring
it.

### Two limits worth knowing

- **The Linux build cannot sign in.** No Firebase plugin supports Linux
  desktop — `firebase_core`, `cloud_firestore`, `firebase_auth` and
  `firebase_storage` all declare android, iOS, macOS, web and Windows
  only. `main.dart` falls back to the bundled content instead of
  crashing, so the Linux app is a working demo, not a live client.
- **There is no iOS download.** Apple has no sideloading; an iOS build
  can only reach a phone through the App Store or TestFlight, both of
  which need a paid account and a review. iPhone visitors are pointed at
  "Add to Home Screen" instead.

## What is and isn't verified per platform

`android/`, `ios/`, `linux/`, `macos/`, `web/` and `windows/` scaffolds
are all present, and the code is platform-clean: the only web-specific
API in the app (the CSV download in `lib/core/export/`) sits behind a
conditional import, so non-web builds get a clipboard fallback instead
of a compile error.

- **Web** — deployed and exercised in a browser.
- **Linux** — `flutter build linux --release` built and the resulting
  binary launched; it renders the demo.
- **Android, Windows, macOS** — built by CI, not run on a device. Icons
  and store metadata are still default, and nothing is signed.

Two release-only defects were fixed while wiring this up, both worth
knowing about if you re-scaffold: Flutter's template declares the
Android `INTERNET` permission and the macOS `network.client` entitlement
in the *debug* configuration only, so a release build works while you
develop it and cannot reach its backend once shipped. Both now live in
`android/app/src/main/AndroidManifest.xml` and
`macos/Runner/Release.entitlements`.
