/**
 * The cases that decide whether a church's home page tells the truth on a
 * Sunday morning. No network: every one of these is a pure function of a
 * shape YouTube returns.
 *
 * Run with `npm test` in this directory.
 */
const test = require('node:test');
const assert = require('node:assert');

const {
  videoIdsFromFeed,
  findLive,
  findFinished,
  liveDocument,
  sermonIdFor,
  sermonFromVideo,
} = require('../youtube');

const feed = `<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015">
  <entry><yt:videoId>aaa111</yt:videoId><title>Newest</title></entry>
  <entry><yt:videoId>bbb222</yt:videoId><title>Older</title></entry>
</feed>`;

const streaming = {
  id: 'aaa111',
  snippet: { title: 'Sunday Morning Service', description: 'Join us.' },
  liveStreamingDetails: { actualStartTime: '2026-08-02T14:00:00Z' },
};

const finished = {
  id: 'bbb222',
  snippet: { title: 'Last Sunday', thumbnails: { high: { url: 'https://img/high.jpg' } } },
  liveStreamingDetails: {
    actualStartTime: '2026-07-26T14:00:00Z',
    actualEndTime: '2026-07-26T15:30:00Z',
  },
};

/** Scheduled, but nobody has pressed go. */
const scheduled = {
  id: 'ccc333',
  snippet: { title: 'Next Sunday' },
  liveStreamingDetails: { scheduledStartTime: '2026-08-09T14:00:00Z' },
};

const upload = { id: 'ddd444', snippet: { title: 'A normal upload' } };

test('the feed yields video ids, newest first', () => {
  assert.deepStrictEqual(videoIdsFromFeed(feed), ['aaa111', 'bbb222']);
});

test('a feed that will not parse reads as no videos, not as an outage', () => {
  // One church's broken feed must not take the poll down for every other
  // church in the deployment.
  assert.deepStrictEqual(videoIdsFromFeed('<html>404</html>'), []);
  assert.deepStrictEqual(videoIdsFromFeed(null), []);
});

test('a started, unended broadcast is the live one', () => {
  assert.strictEqual(findLive([upload, streaming, finished]).id, 'aaa111');
});

test('a scheduled broadcast is not live', () => {
  // Otherwise a church that schedules next Sunday on Monday shows
  // "Live now" all week, which is the exact failure this replaced.
  assert.strictEqual(findLive([scheduled, upload]), null);
});

test('an ordinary upload is not live', () => {
  assert.strictEqual(findLive([upload]), null);
});

test('nothing live is null rather than an error', () => {
  assert.strictEqual(findLive([]), null);
  assert.strictEqual(findLive(undefined), null);
});

test('a finished stream is offered for import', () => {
  const now = new Date('2026-07-27T00:00:00Z');
  assert.deepStrictEqual(
    findFinished([streaming, finished, upload], { now }).map((v) => v.id),
    ['bbb222'],
  );
});

test('back catalogue is left alone', () => {
  // A channel's feed carries its last fifteen uploads. Without the age
  // bound, pointing this at an established church would file a fortnight
  // of streams as drafts on the first run.
  const now = new Date('2026-09-01T00:00:00Z');
  assert.deepStrictEqual(findFinished([finished], { now }), []);
});

test('the live document says who and when', () => {
  const now = new Date('2026-08-02T14:05:00Z');
  assert.deepStrictEqual(liveDocument(streaming, now), {
    live: true,
    videoId: 'aaa111',
    title: 'Sunday Morning Service',
    startedAt: '2026-08-02T14:00:00Z',
    checkedAt: '2026-08-02T14:05:00.000Z',
  });
});

test('not being live still records that we looked', () => {
  // The difference between "we checked, they are not streaming" and
  // "nothing has ever checked" is the only way an admin can tell whether
  // the channel id they pasted was right.
  const now = new Date('2026-08-02T14:05:00Z');
  const doc = liveDocument(null, now);

  assert.strictEqual(doc.live, false);
  assert.strictEqual(doc.videoId, '', 'never leave a stale id behind to link to');
  assert.strictEqual(doc.checkedAt, '2026-08-02T14:05:00.000Z');
});

test('an imported sermon is keyed by video, so a second poll imports nothing', () => {
  assert.strictEqual(sermonIdFor('bbb222'), 'yt-bbb222');
  assert.strictEqual(sermonIdFor('bbb222'), sermonIdFor('bbb222'));
});

test('an imported sermon lands unpublished', () => {
  const sermon = sermonFromVideo(finished);

  assert.strictEqual(sermon.published, false, 'a human reviews it before anyone else sees it');
  assert.strictEqual(sermon.source, 'youtubeAuto');
  assert.strictEqual(sermon.title, 'Last Sunday');
  assert.strictEqual(sermon.speaker, '', 'a blank reads as "fill this in"; the church name reads as a fact');
  assert.strictEqual(sermon.videoUrl, 'https://www.youtube.com/watch?v=bbb222');
  assert.strictEqual(sermon.thumbnailUrl, 'https://img/high.jpg');
  assert.strictEqual(sermon.date, '2026-07-26T14:00:00Z');
});

test('a stream with nothing filled in still produces a readable draft', () => {
  const sermon = sermonFromVideo({ id: 'eee555', liveStreamingDetails: {} });

  assert.strictEqual(sermon.title, 'Untitled stream');
  assert.strictEqual(sermon.thumbnailUrl, '');
  assert.ok(Date.parse(sermon.date), 'a sermon with no date sorts to nowhere');
});

test('the sermon document matches the fields the app reads', () => {
  // Shaped by hand to match Sermon.toMap; a field renamed on one side
  // and not the other would show up as an empty column in the admin list.
  assert.deepStrictEqual(Object.keys(sermonFromVideo(finished)).sort(), [
    'audioUrl',
    'date',
    'description',
    'notes',
    'published',
    'scripture',
    'seriesId',
    'seriesName',
    'source',
    'speaker',
    'thumbnailUrl',
    'title',
    'videoUrl',
  ]);
});
