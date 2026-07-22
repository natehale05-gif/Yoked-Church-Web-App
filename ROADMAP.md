# Feature Roadmap: Visitor / Member / Staff / Admin

## Context

The app currently serves visitors only: Home, Sermons, Events, Give, and
Connect (prayer request/connect card) — all built on bundled sample data
or an optional Firestore read/write, with no accounts, roles, or
in-app content management. Since this is sold as a resellable template
to different churches, the next stage of growth is turning it into a
real platform: visitors browse publicly, members get a portal behind
login, and staff/admin get an in-app CMS to run the church's content
without touching code or the Firebase console.

This is a planning document — a comprehensive, phased feature roadmap
across all four roles. Nothing below is built yet; each phase is sized
to be its own implementation pass.

Decisions already made for this roadmap:
- In-app admin dashboard (not external tools) for staff/admin content management.
- Firebase Auth with email/password + Google + Apple sign-in.
- Member portal priorities: directory & profile, small groups, event RSVP/volunteering, giving history.

## Role model

Four tiers, each a superset of the one before:

| Role | Access |
|---|---|
| **Visitor** | No account. Public pages only (current app). |
| **Member** | Logged-in church attendee. Visitor pages + personal portal. |
| **Staff** | Logged-in team member. Member access + content CMS for their area. |
| **Admin** | Logged-in church leadership. Staff access + org-wide settings, roles, reports. |

Implementation: a `role` field (`visitor` is the unauthenticated default;
`member` / `staff` / `admin` for authenticated users) stored on a
`users/{uid}` Firestore doc and mirrored into a Firebase Auth **custom
claim** so both client-side route guards and Firestore security rules
can check it cheaply.

## Feature breakdown by role

### Visitor (public, unauthenticated) — mostly built, gaps below

Already built: Home, Sermons + detail, Events, Give, Connect (prayer/connect card).

Gaps worth adding:
- **About / Staff / Locations page** — mission statement, pastor & staff bios, service times, campus map/directions (currently only a snippet on Home).
- **Plan a Visit** flow — dedicated page: what to expect, parking, kids check-in info for first-time families, not just a button linking to Events.
- **Sermon series & search** — filter by series/speaker, not just a flat list.
- **FAQ page**.
- **Automatic "We're Live Now" homepage banner** — driven by the YouTube channel connection described under Admin below, replacing the always-visible static "Watch Live" button with one that only appears (prominently) when the channel is actually live.
- Everything else (multi-campus picker, podcast/audio feed) — flag as later/optional, only relevant if a customer church needs it.

### Member (logged in)

- **Account**: sign up / log in (email+password, Google, Apple), email verification, password reset, delete-my-account.
- **Profile & household**: name, photo, contact info, household/family members.
- **Small groups**: browse/search groups by category or day, request to join, see "my groups."
- **Event RSVP**: mark attending, see upcoming RSVP'd events.
- ✅ **Volunteering**: browse open serving positions and self-signup (pending admin approval), or get assigned directly by an admin (instantly confirmed); see my assignments, decline one if needed.
- **Giving history**: view past gifts, download annual tax statement (numbers synced in from the giving provider — see Open Questions).
- **Member directory**: opt-in searchable directory of other members/households.
- **Prayer wall** (stretch): opt in to share a request publicly to the church, others can mark "praying," see responses.
- ✅🟡 **Notifications**: a bell icon + unread badge in the nav shows in-app notifications (currently only fired when a volunteer assignment is made/approved - see Staff/Admin's `NotificationService`). *Real push/email notifications and per-category preferences are still future work (Phase 6) - what exists today is in-app only, and is intentionally written generically so other actions (new sermon posted, event reminders, etc.) can start firing into the same inbox later without new infrastructure.*

### Staff (logged in, elevated)

All in an in-app `/admin` dashboard, gated to `staff`/`admin` roles:

- ✅ **Sermon CMS**: create/edit/delete sermons, series, speaker, video URL, thumbnail.
- ✅ **Events CMS**: create/edit/delete events. *(Day-of check-in / RSVP export not built yet - the RSVP data exists in `eventRsvps` but there's no attendee-list view yet.)*
- ✅ **Connect/Prayer inbox**: view submissions from the Connect page, mark followed-up. *(No per-submission assignment to a specific team member or internal notes field yet - `staffNote` exists on the model but isn't editable in the UI yet.)*
- ✅ **Groups management**: create/edit/delete groups, approve join requests, view/remove roster members.
- ✅ **Volunteer scheduling**: create positions, assign a specific member directly (instantly confirmed) or approve a member's self-signup (starts pending until approved), remove an assignment. *(No reminder-sending yet - see Announcements below.)*
- **Member list**: view/search members, edit basic info, deactivate an account. *(Not built - deferred alongside Phase 4's deeper role/account management.)*
- **Announcements**: compose and send a push/email notification to all members or a segment. *(Not built - depends on push notification infra from Phase 6. Note: a lighter-weight **in-app** notification inbox now exists - see "Notifications" below - and could plausibly grow into this instead of waiting on push.)*
- **Auto-imported sermon review queue**: sermons pulled in automatically from the connected YouTube channel (see Admin below) land with a "needs review" flag until a staff member assigns series/speaker/description and publishes — keeps auto-import from bypassing quality control. *(Not built yet - part of Phase 5.)*

### Admin (logged in, full control)

Staff access, plus:

- ✅ **Roles**: promote/demote member ↔ staff ↔ admin from `/admin/members` (admin-only). *Invite-by-email isn't built - new staff/admin still have to sign up as a regular member first, then get promoted.*
- **Church settings UI**: edit everything currently hardcoded in `lib/config/church_config.dart` — name, tagline, colors, logo, service times, social/giving links, feature toggles — from a settings screen backed by Firestore instead of a code file. This is the single highest-leverage item for the "resell to other churches" business model: today, customizing for a new church means editing Dart and redeploying; this makes it a no-code settings page. *Deliberately deferred - a bigger architectural change than the rest of Phase 4, since it touches how nearly every screen reads branding/config, not just one admin screen. Worth its own dedicated pass.*
- **Reports & analytics**: giving totals/trends, form submission volume, popular sermons, basic site engagement.
- **Audit log**: who changed what (settings, roles, content) and when.
- **Data export / account deletion tools** (privacy compliance).
- **YouTube channel connection**: admin links their church's YouTube channel (channel ID/handle) once from a settings screen. From then on:
  - When that channel goes live, the **homepage automatically shows a "We're Live Now" banner/player** — no manual step, replacing today's hardcoded `ChurchConfig.liveStreamUrl`.
  - When the livestream ends, the video **automatically saves into the Sermon library** (title, thumbnail, and date pulled from YouTube; series/speaker left for staff to fill in via the review queue above).

Out of scope for this roadmap (flagged, not planned): a *platform-level*
admin for managing multiple churches' subscriptions/billing if this
becomes a multi-tenant SaaS product rather than "one deploy per
church." Worth a separate conversation if/when that business model
firms up.

## Cross-cutting infrastructure this unlocks

1. **Auth** — Firebase Auth wired into the existing `useFirebase` flag pattern in `church_config.dart`; email/password + Google + Apple providers; verification & reset flows.
2. **Roles & route guards** — `role` on `users/{uid}` + custom claim; `go_router` redirect logic in `lib/router/app_router.dart` (extend the existing `ShellRoute` pattern with a second `AdminShell` branch for `/admin/*`, and a member-portal branch for `/account/*`).
3. **Firestore data model additions** (building on the existing `sermons`, `events`, `submissions` collections):
   - `users/{uid}` — role, profile, household
   - `groups/{id}`, `groupMemberships/{id}`
   - ✅ `volunteerPositions/{id}`, `volunteerAssignments/{id}`
   - `eventRsvps/{id}`
   - `churchSettings/{singleton}` — replaces hardcoded `ChurchConfig` values
   - `givingRecords/{id}` (synced or manually entered — see Open Questions)
   - `auditLog/{id}`
4. **Firestore security rules** — role-based read/write per collection (visitor-readable content vs. member-only vs. staff/admin-write).
5. 🟡 **Notifications** — ✅ in-app inbox exists (`notifications/{id}`, `lib/services/notification_service.dart`, bell icon in `lib/widgets/nav_bar.dart`), staff-write-only so it can't be spoofed by a member. Real push (Firebase Cloud Messaging + web push permission UX) is still future work, but the in-app inbox is written generically enough that FCM could later just be a second delivery channel triggered from the same `NotificationService.create(...)` call sites rather than a rebuild.
6. **Admin dashboard shell** — new layout (sidebar nav) distinct from the public `AppShell` in `lib/widgets/app_shell.dart`, reusing the same `SectionContainer`/theme patterns already established.
7. **YouTube live/VOD sync** — a scheduled backend job (Cloud Function, e.g. every 5 minutes) checks the admin-connected channel via the YouTube Data API v3:
   - Polls for an active live broadcast on that channel; writes live status + embed/video ID to a `liveStream/{singleton}` Firestore doc, which the Home page (`lib/screens/home_screen.dart`) reads instead of the static `liveStreamUrl` today.
   - Detects when a previously-live video has ended and creates a new `sermons` doc (`source: 'youtube-auto'`, `needsReview: true`) from that video's metadata, extending `SermonService`/`Sermon` (`lib/services/sermon_service.dart`, `lib/models/sermon.dart`).
   - Runs server-side (not client-side) so the YouTube API key never ships to the browser and syncing doesn't depend on someone having the site open.

## Suggested phasing

Each phase is independently shippable and builds on the last:

1. ✅ **Auth foundation** — sign up/login/reset, `users/{uid}` + role field, route guards, baseline Firestore rules. *Done: email/password + Google/Apple sign-in, role-checked security rules (tested against the Firebase emulator), auth-aware route guards.*
2. ✅ **Member portal MVP** — profile/household, event RSVP, groups browse/join, directory opt-in. *Done: `/account` area with profile+household editing, group browse/join-request, event RSVP (also on the public Events page), opt-in directory, and a display-only giving history page. See the README's "Accounts & member portal" section.*
3. 🟡 **Staff CMS MVP** — sermon & events CMS, Connect/prayer inbox, groups & volunteer management. *Mostly done: `/admin` dashboard (gated to staff/admin) with sermon, event, group, and volunteer-position CRUD plus a Connect inbox - 53 passing security-rule scenarios verified against the emulator across the session. A member list and announcements are the remaining pieces (see the Staff section above for specifics).*
4. 🟡 **Admin controls** — role management, **church settings UI** (replacing hardcoded config — high priority for resale), reports/audit log. *Role management done (`/admin/members`, admin-only, 6 more passing rule scenarios). Settings UI, reports, and audit log remain - settings UI in particular deserves its own pass given its size.*
5. **YouTube live/VOD sync** — channel connection UI, scheduled Cloud Function, homepage live banner, auto-import into the sermon review queue. Depends on Phase 3 (sermon CMS) existing so imported sermons have somewhere to land, and Phase 4 (settings UI) as the natural home for the "connect channel" control.
6. **Polish & advanced** — push notifications, giving history sync, prayer wall, kids check-in, multi-campus support — pull items forward from here as needs surface.

## Open questions

- ✅ **Giving history** — resolved for now: display-only, populated by staff manual entry (Phase 3) rather than a payment-provider API sync. Revisit if/when a specific provider integration becomes worth building.
- ✅ **Directory opt-in default** — resolved: opt-in, off by default.
- **Kids check-in / safety**: is a check-in/security system in scope at all, or does the church already use a dedicated kids-check-in product (e.g., Church Community Builder, Planning Center) that this app should just link out to?
- **YouTube auto-import behavior**: should newly-ended livestreams auto-publish to the public sermon library immediately, or always sit in the staff review queue first (recommended, to avoid an unedited/mistitled stream going live on the site unattended)?
- **YouTube API key management**: needs a Google Cloud project with the YouTube Data API v3 enabled and an API key stored server-side (Cloud Functions config/secret) — confirm you're OK provisioning that per-deployment (it's a one-time setup step per church, similar to the Firebase project setup already documented in the README).

## Verification approach (once a phase is implemented)

- `flutter analyze` + `flutter test` clean, as done for the current codebase.
- Firestore security rules tested with the Firebase emulator (rules unit tests) before relying on them for real member data.
- Manual pass in a real browser per role: log in as a seeded member/staff/admin account and walk the golden path for that phase's features, screenshot-verified the same way the current visitor pages were.
