import { describe, expect, it } from 'vitest';

import { churchIdFromLocation, churchPath, churchUrl, subPathOf } from './tenant';

const https = { origin: 'https://natehale05-gif.github.io', protocol: 'https:' };

describe('churchPath', () => {
  it('names a church home without a trailing slash', () => {
    expect(churchPath('riverside')).toBe('/c/riverside');
  });

  it('puts a sub path after the church', () => {
    expect(churchPath('riverside', '/giving')).toBe('/c/riverside/giving');
  });
});

describe('churchIdFromLocation', () => {
  it('reads the church out of a scoped path', () => {
    expect(churchIdFromLocation('/c/riverside/giving')).toBe('riverside');
  });

  it('reads it from the church home', () => {
    expect(churchIdFromLocation('/c/riverside')).toBe('riverside');
  });

  it('is null where no church is named', () => {
    expect(churchIdFromLocation('/sign-in')).toBeNull();
    expect(churchIdFromLocation('/')).toBeNull();
    expect(churchIdFromLocation('/c')).toBeNull();
  });

  it('does not mistake another single-letter first segment for the prefix', () => {
    expect(churchIdFromLocation('/x/riverside')).toBeNull();
  });

  it('ignores a query string and a fragment', () => {
    expect(churchIdFromLocation('/c/riverside?switch=1')).toBe('riverside');
    expect(churchIdFromLocation('/c/riverside#top')).toBe('riverside');
  });
});

describe('subPathOf', () => {
  it('strips the prefix so guards keep reading bare paths', () => {
    expect(subPathOf('/c/riverside/admin/settings')).toBe('/admin/settings');
  });

  it('calls a bare church home the root', () => {
    expect(subPathOf('/c/riverside')).toBe('/');
  });

  it('leaves an unscoped path alone', () => {
    expect(subPathOf('/sign-in')).toBe('/sign-in');
  });
});

describe('churchUrl', () => {
  it('includes the deploy base path', () => {
    expect(churchUrl('riverside', https, '/Yoked-Church-Web-App/')).toBe(
      'https://natehale05-gif.github.io/Yoked-Church-Web-App/c/riverside',
    );
  });

  it('works for a fork served from a domain root', () => {
    expect(churchUrl('riverside', { origin: 'https://riverside.org', protocol: 'https:' }, '/')).toBe(
      'https://riverside.org/c/riverside',
    );
  });

  it('has no hash in it', () => {
    // The Flutter build had to carry one, because it routed on the
    // fragment and a server never sees that. Real paths are the whole
    // reason the address is worth printing on a card.
    expect(churchUrl('riverside', https, '/Yoked-Church-Web-App/')).not.toContain('#');
  });

  it('does not repeat the church when read from inside that church', () => {
    // The Dart version derived the base path from the current pathname,
    // which was safe only because hash routing kept the pathname pinned
    // to the base. Under real paths an admin opening this from
    // `/c/riverside/settings` would have been handed
    // `.../c/riverside/c/riverside` to hand out.
    //
    // The base is now what Vite was built with, so where the reader
    // happens to be standing cannot leak into it.
    const url = churchUrl('riverside', https, '/Yoked-Church-Web-App/');
    expect(url.match(/\/c\/riverside/g)).toHaveLength(1);
  });

  it('gives nothing rather than a dead link off the web', () => {
    expect(churchUrl('riverside', { origin: 'null', protocol: 'file:' }, '/')).toBe('');
  });
});
