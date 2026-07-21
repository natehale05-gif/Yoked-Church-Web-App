# Yoked Church

A cross-platform Flutter church app/website, built to be resold as a customizable template: sermons & livestream, events, online giving, and prayer requests / connect cards - deployed as a static site on GitHub Pages.

See [`ROADMAP.md`](ROADMAP.md) for the planned member portal, staff/admin
dashboard, and YouTube live-sync features not yet built.

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

## Project structure

```
lib/
  config/     church_config.dart - single source of truth for branding/content
  models/     Sermon, ChurchEvent, ConnectSubmission
  services/   data loading (bundled JSON, or Firestore when enabled)
  screens/    one file per page (home, sermons, events, giving, connect)
  widgets/    shared nav bar, footer, responsive layout helpers
  theme/      colors, typography (Lora + Work Sans, bundled locally), breakpoints
  router/     go_router route table
assets/
  data/       sample sermons.json / events.json
  fonts/      Lora + Work Sans (OFL licensed, bundled so text never depends on a CDN)
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
