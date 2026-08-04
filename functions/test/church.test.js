/**
 * The rules that decide what address a church gets, and what a brand-new
 * church looks like on its first morning.
 *
 * The slug rules live twice - here and in
 * lib/features/churches/domain/church_slug.dart - because the client
 * shows a person their address as they type while the server is the one
 * that may be trusted with it. These cases are the contract between the
 * two; if either side drifts, this file is where it shows.
 */
const test = require('node:test');
const assert = require('node:assert');

const {
  MAX_PER_ACCOUNT,
  slugify,
  slugProblem,
  availableSlug,
  newChurchDocument,
  ownerMembership,
} = require('../church');

test('a church name becomes an address', () => {
  assert.strictEqual(slugify('Grace Chapel'), 'grace-chapel');
  assert.strictEqual(slugify('Riverside Fellowship'), 'riverside-fellowship');
  assert.strictEqual(slugify('  Spaced   Out  '), 'spaced-out');
});

test('punctuation people actually use', () => {
  // "St Mary's", not "St Mary S": an apostrophe is dropped rather than
  // hyphenated, or every possessive would grow a stray letter.
  assert.strictEqual(slugify("St Mary's"), 'st-marys');
  assert.strictEqual(slugify('St. Mary’s Church, Riverside'), 'st-marys-church-riverside');
  assert.strictEqual(slugify('Hope & Anchor'), 'hope-anchor');
  assert.strictEqual(slugify('The 99'), 'the-99');
});

test('a name that cannot make an address says so, in words', () => {
  // Shown under the field a person is typing in, so it has to read like
  // a sentence rather than a validation code.
  assert.match(slugProblem(''), /at least/);
  assert.match(slugProblem('ab'), /at least/);
  assert.strictEqual(slugProblem('grace-chapel'), null);
});

test('the platform keeps a few addresses for itself', () => {
  // `c` would collide with the route prefix every church address uses.
  assert.match(slugProblem('c'), /at least|taken/);
  assert.match(slugProblem('admin'), /taken/);
  assert.match(slugProblem('start'), /taken/);
  assert.strictEqual(slugProblem('administration'), null);
});

test('a very long name is cut without leaving a trailing hyphen', () => {
  const slug = slugify('The Very Long Name Of A Church That Goes On And On And On Forever');
  assert.ok(slug.length <= 40, slug);
  assert.ok(!slug.endsWith('-'), slug);
  assert.strictEqual(slugProblem(slug), null);
});

test('the second Grace Chapel still gets in', () => {
  // Two churches with the same name is not an edge case, it is Tuesday.
  // Turning the second one away at signup is losing a customer over
  // somebody else's name.
  assert.strictEqual(availableSlug('grace-chapel', new Set()), 'grace-chapel');
  assert.strictEqual(availableSlug('grace-chapel', new Set(['grace-chapel'])), 'grace-chapel-2');
  assert.strictEqual(
    availableSlug('grace-chapel', new Set(['grace-chapel', 'grace-chapel-2'])),
    'grace-chapel-3',
  );
});

test('a reserved id is never handed out, even as a first choice', () => {
  assert.strictEqual(availableSlug('admin', new Set()), 'admin-2');
});

test('a new church starts nearly empty, and honestly so', () => {
  const doc = newChurchDocument('Grace Chapel', 'uid1', new Date('2026-08-04T10:00:00Z'));

  assert.strictEqual(doc.churchName, 'Grace Chapel');
  assert.strictEqual(doc.aboutHeadline, 'Welcome to Grace Chapel');
  assert.deepStrictEqual(doc.serviceTimes, [], 'inventing a service time nobody asked for is worse than a blank');
  assert.strictEqual(doc.contact.address, '');
  assert.strictEqual(doc.createdBy, 'uid1');
  assert.strictEqual(doc.createdAt, '2026-08-04T10:00:00.000Z');
});

test('a new church has colours, so it does not open unstyled', () => {
  const doc = newChurchDocument('Grace Chapel', 'uid1');
  assert.match(doc.colors.primary, /^#[0-9A-Fa-f]{6}$/);
  assert.match(doc.colors.accent, /^#[0-9A-Fa-f]{6}$/);
  assert.match(doc.colors.background, /^#[0-9A-Fa-f]{6}$/);
});

test('features are left unset so every flag defaults on', () => {
  // FeatureFlags.fromMap treats a missing key as true. A church that has
  // just signed up should see everything and switch off what it does not
  // use, rather than hunt for why its sermons page is missing.
  assert.deepStrictEqual(newChurchDocument('Grace Chapel', 'uid1').features, {});
});

test('whoever creates a church runs it', () => {
  const member = ownerMembership('uid1', 'pastor@grace.org', 'Pat Reyes');

  assert.strictEqual(member.role, 'admin', 'nobody else exists yet to promote them');
  assert.strictEqual(member.uid, 'uid1');
  assert.strictEqual(member.displayName, 'Pat Reyes');
  assert.strictEqual(member.directoryOptIn, false, 'opting people into a directory is theirs to choose');
});

test('an account with no name still gets a usable one', () => {
  assert.strictEqual(ownerMembership('uid1', 'pastor@grace.org', '').displayName, 'pastor@grace.org');
  assert.strictEqual(ownerMembership('uid1', '', '').displayName, 'Admin');
});

test('one account cannot mint churches without limit', () => {
  assert.ok(MAX_PER_ACCOUNT >= 1 && MAX_PER_ACCOUNT <= 10, 'a cap that is not a cap is not a cap');
});
