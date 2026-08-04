/**
 * Creating a church, decided with no network and no Firestore.
 *
 * The slug rules are duplicated from
 * lib/features/churches/domain/church_slug.dart on purpose, not by
 * accident: the client copy exists so a person can watch their address
 * appear as they type, and the server copy exists because a client that
 * chooses its own document id is a client that can be edited. The tests
 * below pin the two to the same answers.
 */

const MAX_LENGTH = 40;
const MIN_LENGTH = 3;

/** How many churches one account may create. */
const MAX_PER_ACCOUNT = 3;

/** Ids the routing or the platform needs for itself. */
const RESERVED = new Set([
  'c', 'start', 'choose-church', 'admin', 'api', 'app', 'assets', 'yoked',
  'www', 'help', 'support', 'about', 'new', 'signup', 'sign-up', 'login',
  'sign-in',
]);

function tidy(slug) {
  let out = slug;
  while (out.includes('--')) out = out.replace(/--/g, '-');
  out = out.replace(/^-+|-+$/g, '');
  return out.length > MAX_LENGTH ? tidy(out.slice(0, MAX_LENGTH)) : out;
}

/** "St. Mary's Church, Riverside" -> "st-marys-church-riverside". */
function slugify(name) {
  if (typeof name !== 'string') return '';
  let out = '';
  for (const char of name.toLowerCase().trim()) {
    if (/[a-z0-9]/.test(char)) out += char;
    else if (' -_.,'.includes(char)) out += '-';
    // Apostrophes and everything else are dropped rather than
    // hyphenated, so "St Mary's" is `st-marys`, not `st-mary-s`.
  }
  return tidy(out);
}

/** Why a slug cannot be used, or null if it can. */
function slugProblem(slug) {
  if (typeof slug !== 'string' || slug.length < MIN_LENGTH) {
    return `Your address needs at least ${MIN_LENGTH} letters. Try adding your town.`;
  }
  if (slug.length > MAX_LENGTH) return 'That is too long for a web address.';
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(slug)) return 'Use letters and numbers only.';
  if (RESERVED.has(slug)) return 'That address is taken. Try adding your town.';
  return null;
}

/**
 * The next free variant of a slug.
 *
 * Two churches called Grace Chapel is not an edge case, it is Tuesday.
 * The second becomes `grace-chapel-2` rather than being turned away,
 * because a signup that fails on somebody else's name is a signup that
 * does not happen.
 */
function availableSlug(desired, taken) {
  const isFree = (s) => !taken.has(s) && !RESERVED.has(s);
  if (isFree(desired)) return desired;
  for (let n = 2; n < 1000; n++) {
    const candidate = `${desired}-${n}`;
    if (isFree(candidate)) return candidate;
  }
  return `${desired}-${Date.now()}`;
}

/**
 * The church document a brand-new church starts life as.
 *
 * Shaped to match ChurchSettings.toMap in
 * lib/core/config/church_settings.dart. Deliberately close to empty: the
 * setup checklist in the dashboard is what fills it in, and inventing a
 * fake address or a service time nobody asked for would be worse than a
 * blank a person can see needs filling.
 */
function newChurchDocument(name, ownerUid, now = new Date()) {
  return {
    churchName: name,
    tagline: '',
    logoUrl: '',
    aboutHeadline: `Welcome to ${name}`,
    aboutBody: '',
    beliefs: '',
    visitInfo: '',
    releasesRepo: '',
    colors: { primary: '#1B3A4B', accent: '#C79A3C', background: '#F7F5F0' },
    contact: { address: '', phone: '', email: '', mapUrl: '' },
    social: {
      facebook: '',
      instagram: '',
      youtube: '',
      givingUrl: '',
      liveStreamUrl: '',
      youtubeChannelId: '',
      podcastUrl: '',
    },
    serviceTimes: [],
    features: {},
    createdAt: now.toISOString(),
    createdBy: ownerUid,
  };
}

/** The founder's membership document: an admin of their own church. */
function ownerMembership(uid, email, displayName, now = new Date()) {
  return {
    uid,
    email: email || '',
    displayName: displayName || email || 'Admin',
    photoUrl: '',
    role: 'admin',
    directoryOptIn: false,
    createdAt: now.toISOString(),
  };
}

module.exports = {
  MAX_PER_ACCOUNT,
  RESERVED,
  slugify,
  slugProblem,
  availableSlug,
  newChurchDocument,
  ownerMembership,
};
