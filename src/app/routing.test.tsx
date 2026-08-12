import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RouterProvider, createMemoryRouter } from 'react-router-dom';
import { afterEach, describe, expect, it } from 'vitest';

import { AppProviders } from './AppProviders';
import { routes } from './router';

/**
 * The guard and the shell, rendered rather than reasoned about.
 *
 * `guard.test.ts` checks the arithmetic; this checks that the arithmetic
 * is actually wired to the router, which is a different thing and the
 * one that broke twice in the Flutter build.
 */
function renderAt(path: string) {
  const router = createMemoryRouter(routes, { initialEntries: [path] });
  // `AppProviders`, not a hand-rolled `AppProvider`. Building the
  // wrapper here meant the test supplied `linkComponent` itself, so it
  // could never notice the app failing to.
  render(
    <AppProviders>
      <RouterProvider router={router} />
    </AppProviders>,
  );
  return router;
}

const CHURCH = '/c/yoked-demo';

// The demo session persists to sessionStorage, which jsdom shares across
// tests in a file - so without this every test after the first starts
// signed in as whoever the last one signed in as.
afterEach(() => {
  sessionStorage.clear();
});

describe('signing in', () => {
  it('sends a signed-out visitor asking for the admin to sign in', async () => {
    const router = renderAt(`${CHURCH}/admin`);

    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/sign-in`));
  });

  it('takes an admin to the dashboard, not back to the sign-in page', async () => {
    // The Flutter build shipped this bug twice: the screen navigated
    // itself the moment the call returned, a beat before the guard saw
    // the new user, so the guard sent them straight back. Where signing
    // in lands is the guard's decision and nobody else's.
    const router = renderAt(`${CHURCH}/admin`);
    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/sign-in`));

    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Admin' }));

    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/admin`));
  });

  it('takes a member to their account rather than the staff dashboard', async () => {
    const router = renderAt(`${CHURCH}/admin`);
    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Member' }));

    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/account`));
  });
});

describe('what staff may reach', () => {
  it('turns staff away from the admin-only screens', async () => {
    const router = renderAt(`${CHURCH}/admin`);
    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Staff' }));
    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/admin`));

    router.navigate(`${CHURCH}/admin/reports`);

    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/admin`));
  });

  it('lets staff into the content tools', async () => {
    const router = renderAt(`${CHURCH}/admin`);
    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Staff' }));
    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/admin`));

    router.navigate(`${CHURCH}/admin/giving`);

    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/admin/giving`));
  });
});

describe('the session survives a reload', () => {
  it('is restored on the first render, not after a redirect', async () => {
    // Restoring in an effect would let the guard decide "signed out"
    // first, bouncing a refreshing admin to the sign-in page and only
    // then signing them back in - landing them somewhere they did not
    // ask for. Caught by reloading the page in a browser, not by a test.
    const first = renderAt(`${CHURCH}/admin`);
    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Admin' }));
    await waitFor(() => expect(first.state.location.pathname).toBe(`${CHURCH}/admin`));

    // A fresh render is what a browser reload amounts to: new component
    // tree, same sessionStorage.
    const second = renderAt(`${CHURCH}/admin/giving`);

    await waitFor(() => expect(second.state.location.pathname).toBe(`${CHURCH}/admin/giving`));
  });
});

describe('the sidebar', () => {
  it('addresses every destination inside the church', async () => {
    // A link without the `/c/{churchId}` prefix leaves the tenant, and
    // the church in the URL is the authority for everything below it.
    renderAt(`${CHURCH}/admin`);
    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Admin' }));

    const giving = await screen.findByRole('link', { name: 'Giving' });

    expect(giving).toHaveAttribute('href', `${CHURCH}/admin/giving`);
  });

  it('navigates with the router rather than reloading the page', async () => {
    // Polaris renders `url` as a plain `<a href>` unless `AppProvider`
    // is given a `linkComponent`. It looks identical either way, the
    // href above is identical either way, and it type-checks either way
    // - but a click then reloads the whole app and drops the router's
    // basename, which on GitHub Pages navigates out of the deployment.
    //
    // Clicking is the only thing that tells the two apart: a real
    // anchor does not move a memory router.
    const router = renderAt(`${CHURCH}/admin`);
    await userEvent.click(await screen.findByRole('button', { name: 'Sign in as Admin' }));

    await userEvent.click(await screen.findByRole('link', { name: 'Giving' }));

    await waitFor(() => expect(router.state.location.pathname).toBe(`${CHURCH}/admin/giving`));
  });
});
