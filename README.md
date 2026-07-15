# Yoked Church Web App

A premium, cross-platform church website and app built with **Flutter**. It is
designed to be simple and intuitive to navigate, easy to read, and photo-first —
with generous, well-composed space for real photos of people throughout.

The demo content is for a fictional "Grace City Church." Everything is easy to
rebrand for any church from a single configuration file.

## Highlights

- **Premium design** — warm navy + gold + ivory palette, elegant serif
  (Cormorant Garamond) paired with a highly legible sans-serif (Inter).
- **Simple & intuitive** — short, clear navigation and obvious calls to action.
- **Easy to read** — large type, high contrast, and lots of whitespace.
- **Photo-first** — reusable `PhotoFrame` gives every people section beautiful,
  ready-to-fill photo space.
- **Fully responsive** — looks great on phones, tablets, and desktops.
- **One codebase** — Flutter can target web today and mobile apps later.

## Pages

Home · I'm New (Plan a Visit) · Messages · Events · Ministries · About · Give ·
Contact

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel).

```bash
flutter pub get

# Run locally in Chrome
flutter run -d chrome

# Build a production web bundle (output in build/web)
flutter build web --release
```

## Customizing for a new church

Almost everything a church needs to change lives in one file:

```
lib/config/site_config.dart
```

There you can edit the church name, tagline, contact info, service times,
ministries, staff, sermons, and events — no design knowledge required.

To adjust the look and feel:

- `lib/theme/app_colors.dart` — brand colors
- `lib/theme/app_theme.dart` — fonts and text sizes

### Adding real photos

Anywhere you see a `PhotoFrame`, provide an image and it renders automatically:

- Network image: set `imageUrl: 'https://…'`
- Bundled asset: add the file under `assets/`, register it in `pubspec.yaml`,
  and set `imageUrl: 'assets/your_photo.jpg'`

When no image is provided, a tasteful placeholder is shown so the layout always
looks intentional.

## Deploying to GitHub Pages

This repo includes a workflow at `.github/workflows/deploy-pages.yml` that builds
the web app and publishes it to GitHub Pages automatically.

One-time setup:

1. In the repository, go to **Settings → Pages**.
2. Under **Build and deployment → Source**, choose **GitHub Actions**.

After that, every push to the `main` branch builds and deploys the site. You can
also trigger it manually from the **Actions** tab → *Deploy to GitHub Pages* →
**Run workflow**.

The site will be available at:

```
https://<your-username>.github.io/<repository-name>/
```

The workflow sets the correct `--base-href` automatically from the repository
name, so assets load correctly from the project subpath.

## Project structure

```
lib/
  config/      # site_config.dart — all editable content
  theme/       # colors, typography, responsive helpers
  router/      # app routes (go_router)
  widgets/     # nav, footer, hero, cards, photo frames, buttons
  pages/       # one file per page
```

## Notes

- Navigation uses hash-based routing so the built site works on any static host
  without extra server configuration.
- The contact form composes a pre-filled email (`mailto:`); connect it to a
  backend endpoint when one is available.
