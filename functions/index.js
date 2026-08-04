/**
 * The first server-side code in this project.
 *
 * One scheduled function serves every church, which is only possible
 * because tenancy landed first: one deployment, one API key, one quota,
 * rather than per-church infrastructure. A church that has not pasted a
 * channel id is skipped entirely and costs nothing.
 */
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const logger = require('firebase-functions/logger');

const {
  MAX_PER_ACCOUNT,
  slugify,
  slugProblem,
  availableSlug,
  newChurchDocument,
  ownerMembership,
} = require('./church');

const {
  videoIdsFromFeed,
  findLive,
  findFinished,
  liveDocument,
  sermonIdFor,
  sermonFromVideo,
} = require('./youtube');

// Server-side only. The key must never reach the client bundle: anything
// shipped to a browser is public, and a leaked key is someone else's
// quota spent on your project.
const YOUTUBE_API_KEY = defineSecret('YOUTUBE_API_KEY');

initializeApp();

/** Zero quota, and a Cloud Function has no CORS to worry about. */
async function fetchFeed(channelId) {
  const url = `https://www.youtube.com/feeds/videos.xml?channel_id=${encodeURIComponent(channelId)}`;
  const response = await fetch(url);
  if (!response.ok) throw new Error(`feed ${response.status} for ${channelId}`);
  return response.text();
}

/** One unit, for up to 50 ids. */
async function fetchVideos(ids, apiKey) {
  if (ids.length === 0) return [];
  const url = new URL('https://www.googleapis.com/youtube/v3/videos');
  url.searchParams.set('part', 'snippet,liveStreamingDetails');
  url.searchParams.set('id', ids.slice(0, 50).join(','));
  url.searchParams.set('key', apiKey);

  const response = await fetch(url);
  if (!response.ok) throw new Error(`videos.list ${response.status}`);
  const body = await response.json();
  return body.items || [];
}

/**
 * Poll one church. Returns a short summary for the log, so a church whose
 * channel id is wrong is visible without turning on debug logging.
 */
async function pollChurch(db, church, apiKey) {
  const churchId = church.id;
  const data = church.data() || {};
  const channelId = ((data.social || {}).youtubeChannelId || '').trim();
  if (!channelId) return null;

  const ids = videoIdsFromFeed(await fetchFeed(channelId));
  const videos = await fetchVideos(ids, apiKey);
  const now = new Date();

  // Written every poll, not only when the answer changes, so `checkedAt`
  // stays true - that field is the only way an admin can tell a wrong
  // channel id from a quiet week. The cost is one write per church per
  // poll and a banner rebuild in open tabs, which is a fair price for a
  // setup screen that can say something more useful than nothing.
  const live = findLive(videos);
  await db.doc(`churches/${churchId}/live/current`).set(liveDocument(live, now));

  // A finished stream becomes a draft sermon rather than appearing on the
  // public site unreviewed. `create` rather than `set` so the next poll,
  // which will see the same finished stream, does not overwrite edits a
  // staff member has already made to the draft.
  let imported = 0;
  for (const video of findFinished(videos, { now })) {
    const ref = db.doc(`churches/${churchId}/sermons/${sermonIdFor(video.id)}`);
    try {
      await ref.create(sermonFromVideo(video));
      imported++;
    } catch (error) {
      // ALREADY_EXISTS is the expected path on every poll after the
      // first, and is not worth a log line.
      if (error.code !== 6) throw error;
    }
  }

  return { churchId, live: Boolean(live), imported };
}

exports.pollLiveStreams = onSchedule(
  {
    schedule: 'every 5 minutes',
    secrets: [YOUTUBE_API_KEY],
    timeoutSeconds: 120,
  },
  async () => {
    const db = getFirestore();
    const churches = await db.collection('churches').get();
    const apiKey = YOUTUBE_API_KEY.value();

    // Sequential on purpose. The whole point of the RSS-then-videos.list
    // shape is that each church costs one quota unit; running them in
    // parallel would buy nothing but a thundering herd against YouTube.
    for (const church of churches.docs) {
      try {
        const result = await pollChurch(db, church, apiKey);
        if (result && (result.live || result.imported)) logger.info('polled', result);
      } catch (error) {
        // One church's bad channel id must not stop the rest.
        logger.error(`poll failed for ${church.id}`, error);
      }
    }
  },
);

/**
 * Creates a church and makes the caller its admin.
 *
 * The only path there is. The Firestore rules keep
 * `allow create: if false` on `churches/{churchId}`, because creating a
 * church means writing yourself in as its admin in the same breath - and
 * a rule permissive enough to allow that is a rule that lets anyone mint
 * admin rights over a church they have just invented next to yours.
 *
 * Doing it here instead buys three things a rule could not: the id is
 * allocated inside a transaction so two people naming their church the
 * same thing at the same moment cannot both win it, one account cannot
 * create churches without limit, and the church document and the
 * membership either both exist or neither does.
 */
exports.createChurch = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in first, so we know who runs this church.');
  }

  const name = String((request.data && request.data.name) || '').trim();
  if (!name) throw new HttpsError('invalid-argument', 'What is your church called?');

  // Re-derived rather than trusted: the client sends a slug so the
  // person could see it while typing, not so it can choose its own id.
  const desired = slugify(request.data.slug || name);
  const problem = slugProblem(desired);
  if (problem) throw new HttpsError('invalid-argument', problem);

  const db = getFirestore();
  const churches = db.collection('churches');
  const counter = db.doc(`signups/${uid}`);

  const churchId = await db.runTransaction(async (tx) => {
    const counterSnap = await tx.get(counter);
    const created = counterSnap.exists ? (counterSnap.data().churches || 0) : 0;
    if (created >= MAX_PER_ACCOUNT) {
      throw new HttpsError(
        'resource-exhausted',
        `One account can set up ${MAX_PER_ACCOUNT} churches. Get in touch if you need more.`,
      );
    }

    // Only the handful of ids this name could produce need checking,
    // rather than the whole directory - which is what keeps signup a
    // constant-cost operation however many churches exist.
    const candidates = [desired];
    for (let n = 2; n <= MAX_PER_ACCOUNT + 8; n++) candidates.push(`${desired}-${n}`);
    const existing = await Promise.all(candidates.map((id) => tx.get(churches.doc(id))));
    const taken = new Set(candidates.filter((_, i) => existing[i].exists));

    const id = availableSlug(desired, taken);
    const now = new Date();

    tx.set(churches.doc(id), newChurchDocument(name, uid, now));
    tx.set(
      churches.doc(id).collection('users').doc(uid),
      ownerMembership(uid, request.auth.token.email, request.auth.token.name, now),
    );
    tx.set(counter, { churches: created + 1, updatedAt: now.toISOString() }, { merge: true });

    return id;
  });

  logger.info('church created', { churchId, uid });
  return { churchId };
});
