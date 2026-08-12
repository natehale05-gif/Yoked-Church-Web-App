import { createBrowserRouter, Navigate } from 'react-router-dom';
import type { RouteObject } from 'react-router-dom';

import { ChurchLayout } from './ChurchLayout';
import { NotFoundPage } from './NotFoundPage';
import { AdminFrame } from '../shell/AdminFrame';
import { ComingSoon } from '../shell/ComingSoon';
import { AdminHomePage } from '../features/admin/AdminHomePage';
import { SignInPage } from '../features/auth/SignInPage';
import { SessionProvider } from '../features/auth/session';
import { GivingDetailPage } from '../features/giving/GivingDetailPage';
import { GivingIndexPage } from '../features/giving/GivingIndexPage';
import { DEMO_CHURCH_ID, churchPath } from '../core/tenant';

/** Everything the sidebar offers that this phase has not built. */
const notBuiltYet: Array<{ path: string; title: string; phase: string }> = [
  { path: 'giving/recurring', title: 'Recurring gifts', phase: 'P4' },
  { path: 'giving/campaigns', title: 'Campaigns', phase: 'P4' },
  { path: 'giving/funds', title: 'Funds', phase: 'P4' },
  { path: 'sermons', title: 'Sermons', phase: 'P3' },
  { path: 'sermons/series', title: 'Series', phase: 'P3' },
  { path: 'people', title: 'People', phase: 'P4' },
  { path: 'people/households', title: 'Households', phase: 'P4' },
  { path: 'people/segments', title: 'Segments', phase: 'P4' },
  { path: 'outreach', title: 'Outreach', phase: 'P3' },
  { path: 'outreach/announcements', title: 'Announcements', phase: 'P3' },
  { path: 'outreach/inbox', title: 'Inbox', phase: 'P3' },
  { path: 'content', title: 'Content', phase: 'P3' },
  { path: 'content/devotionals', title: 'Devotionals', phase: 'P3' },
  { path: 'content/reading-plans', title: 'Reading plans', phase: 'P3' },
  { path: 'content/files', title: 'Files', phase: 'P3' },
  { path: 'campuses', title: 'Campuses', phase: 'P4' },
  { path: 'reports', title: 'Reports', phase: 'P4' },
  { path: 'events', title: 'Events', phase: 'P3' },
  { path: 'groups', title: 'Groups', phase: 'P3' },
  { path: 'volunteering', title: 'Serving', phase: 'P3' },
  { path: 'kids', title: 'Kids', phase: 'P3' },
  { path: 'attendance', title: 'Attendance', phase: 'P3' },
  { path: 'rooms', title: 'Rooms', phase: 'P3' },
  { path: 'forms', title: 'Forms', phase: 'P3' },
  { path: 'prayer', title: 'Prayer', phase: 'P3' },
  { path: 'website', title: 'Website', phase: 'P5' },
  { path: 'website/themes', title: 'Themes', phase: 'P5' },
  { path: 'website/pages', title: 'Pages', phase: 'P5' },
  { path: 'website/navigation', title: 'Navigation', phase: 'P5' },
  { path: 'settings', title: 'Settings', phase: 'P3' },
];

/**
 * Real paths, no `#`.
 *
 * `basename` is the directory the deploy is served from, which Vite
 * bakes in. `public/404.html` bounces a deep link back through the SPA
 * so GitHub Pages does not 404 on a URL it has no file for.
 */
export const routes: RouteObject[] = [
  {
    element: (
      <SessionProvider>
        <ChurchLayout />
      </SessionProvider>
    ),
    path: '/c/:churchId',
    children: [
      { path: 'sign-in', element: <SignInPage /> },
      {
        path: 'admin',
        element: <AdminFrame />,
        children: [
          { index: true, element: <AdminHomePage /> },
          { path: 'giving', element: <GivingIndexPage /> },
          { path: 'giving/:giftId', element: <GivingDetailPage /> },
          ...notBuiltYet.map(({ path, title, phase }) => ({
            path,
            element: <ComingSoon title={title} phase={phase} />,
          })),
        ],
      },
    ],
  },

  // The product's own pages are P6 work. Until they exist, the root goes
  // to the demo church rather than to a blank screen - which is also
  // what a single-church deployment wants permanently.
  { path: '/', element: <Navigate to={churchPath(DEMO_CHURCH_ID, '/admin')} replace /> },
  { path: '*', element: <NotFoundPage /> },
];

export const router = createBrowserRouter(routes, { basename: import.meta.env.BASE_URL });
