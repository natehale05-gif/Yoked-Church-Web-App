import { useCallback, useState } from 'react';
import { Frame, Navigation, TopBar } from '@shopify/polaris';
import { ArrowLeftIcon } from '@shopify/polaris-icons';
import { Outlet, useLocation, useNavigate, useParams } from 'react-router-dom';

import { churchPath, subPathOf } from '../core/tenant';
import { adminNavigation } from './navigation';
import type { NavItem } from './navigation';
import { useChurch } from '../core/church-context';
import { useSession } from '../features/auth/session';


/**
 * The Shopify admin, as chrome.
 *
 * Polaris' `Frame` is the whole thing: a fixed sidebar on the left, a
 * dark bar across the top, and the page in the remaining space. Below
 * ~768px `Frame` collapses the sidebar into a drawer behind the top-left
 * button on its own, which is why there is no phone branch here — the
 * Flutter app needed a hand-written bottom bar and a separate mobile nav
 * to get the same behaviour.
 */
export function AdminFrame() {
  const navigate = useNavigate();
  const location = useLocation();
  const { churchId = '' } = useParams();
  const church = useChurch();
  const session = useSession();

  const [mobileNavigationActive, setMobileNavigationActive] = useState(false);
  const [userMenuActive, setUserMenuActive] = useState(false);
  const [searchValue, setSearchValue] = useState('');

  const toggleMobileNavigation = useCallback(
    () => setMobileNavigationActive((active) => !active),
    [],
  );

  const here = subPathOf(location.pathname);
  const go = useCallback(
    (subPath: string) => navigate(churchPath(churchId, subPath)),
    [navigate, churchId],
  );

  // `url` carries the church prefix but *not* the deploy's base path:
  // these render through `PolarisLink`, and React Router's `Link` adds
  // the basename itself. Adding it here as well would double it.
  //
  // `onClick` only closes the drawer. Navigation is the link's job, and
  // doing both meant every tap on a phone navigated twice.
  const toNavItem = (item: NavItem) => ({
    label: item.label,
    icon: item.icon,
    url: churchPath(churchId, item.path),
    selected: here === item.path,
    onClick: () => setMobileNavigationActive(false),
    subNavigationItems: item.subNavigationItems?.map((sub) => ({
      label: sub.label,
      url: churchPath(churchId, sub.path),
      selected: here === sub.path,
      onClick: () => setMobileNavigationActive(false),
    })),
  });

  const navigationMarkup = (
    <Navigation location={location.pathname}>
      {adminNavigation(church.settings.features, { isAdmin: session.isAdmin }).map(
        (section, index) => (
          <Navigation.Section
            // Sections are positional and have no id of their own; the
            // title is not unique either, since the primary section has
            // none at all.
            key={section.title ?? `section-${index}`}
            title={section.title}
            separator={section.separator}
            fill={section.fill}
            items={section.items.map(toNavItem)}
          />
        ),
      )}
    </Navigation>
  );

  const userMenuMarkup = (
    <TopBar.UserMenu
      name={session.name}
      detail={church.settings.churchName}
      initials={session.initials}
      open={userMenuActive}
      onToggle={() => setUserMenuActive((open) => !open)}
      actions={[
        {
          items: [
            { content: 'View website', onAction: () => go('/') },
            { content: 'Switch church', icon: ArrowLeftIcon, onAction: () => navigate('/choose-church?switch=1') },
          ],
        },
        {
          items: [{ content: 'Sign out', onAction: () => void session.signOut() }],
        },
      ]}
    />
  );

  const searchFieldMarkup = (
    <TopBar.SearchField
      onChange={setSearchValue}
      value={searchValue}
      placeholder={`Search ${church.settings.churchName}`}
      showFocusBorder
    />
  );

  const topBarMarkup = (
    <TopBar
      showNavigationToggle
      userMenu={userMenuMarkup}
      searchField={searchFieldMarkup}
      // No `searchResultsVisible` yet, deliberately. Search across
      // people, giving and sermons needs the data layer, which is P2;
      // passing the prop now would open an empty panel over the page
      // every time somebody typed, which is worse than a field that
      // visibly does nothing yet.
      onNavigationToggle={toggleMobileNavigation}
    />
  );

  return (
    <Frame
      topBar={topBarMarkup}
      navigation={navigationMarkup}
      showMobileNavigation={mobileNavigationActive}
      onNavigationDismiss={toggleMobileNavigation}
    >
      <Outlet />
    </Frame>
  );
}
