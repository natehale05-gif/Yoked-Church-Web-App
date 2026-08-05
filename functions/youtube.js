/**
 * The decisions this feature makes, with no network and no Firestore.
 *
 * Everything here is a pure function of data that came back from YouTube,
 * so the interesting cases - a stream that just ended, a document written
 * twice for the same video, a channel that has never streamed - are unit
 * tests rather than something you find out about on a Sunday morning.
 */

/**
 * Video ids from a channel's RSS feed, newest first.
 *
 * The feed is the reason this feature is affordable. `search.list` with
 * `eventType=live` is the obvious call and costs 100 quota units against
 * a 10,000/day default: polling one church every five minutes would be
 * 28,800 units, so the feature would die on its first day. The feed costs
 * nothing, and `videos.list` on the ids it returns costs 1.
 *
 * Tolerant of malformed XML on purpose - a feed that fails to parse must
 * read as "no videos", not take the whole poll down for every church.
 */
function videoIdsFromFeed(xml) {
  if (typeof xml !== 'string') return [];
  const ids = [];
  const pattern = /<yt:videoId>([^<]+)<\/yt:videoId>/g;
  let match;
  while ((match = pattern.exec(xml)) !== null) {
    const id = match[1].trim();
    if (id && !ids.includes(id)) ids.push(id);
  }
  return ids;
}

/**
 * The stream that is live right now, or null.
 *
 * YouTube marks a broadcast live by giving it an `actualStartTime` and no
 * `actualEndTime`. A scheduled-but-not-started broadcast has neither, and
 * must not raise the banner - a church that schedules next Sunday's
 * service on Monday would otherwise show "Live now" all week.
 */
function findLive(videos) {
  return (videos || []).find((video) => {
    const details = video.liveStreamingDetails;
    return Boolean(details && details.actualStartTime && !details.actualEndTime);
  }) || null;
}

/**
 * Broadcasts that have finished, and are recent enough to be worth
 * importing.
 *
 * Bounded by age because a channel's feed carries its last fifteen
 * uploads: without this, pointing the poller at an established church
 * would file a fortnight of back catalogue as drafts on day one.
 */
function findFinished(videos, { now = new Date(), maxAgeDays = 7 } = {}) {
  const cutoff = now.getTime() - maxAgeDays * 24 * 60 * 60 * 1000;

  return (videos || []).filter((video) => {
    const ended = video.liveStreamingDetails && video.liveStreamingDetails.actualEndTime;
    if (!ended) return false;
    const endedAt = Date.parse(ended);
    return Number.isFinite(endedAt) && endedAt >= cutoff;
  });
}

/** What gets written to `churches/{id}/live/current`. */
function liveDocument(live, now = new Date()) {
  if (!live) {
    return {
      live: false,
      videoId: '',
      title: '',
      startedAt: null,
      checkedAt: now.toISOString(),
    };
  }

  return {
    live: true,
    videoId: live.id,
    title: (live.snippet && live.snippet.title) || '',
    startedAt: live.liveStreamingDetails.actualStartTime,
    checkedAt: now.toISOString(),
  };
}

/**
 * The document id an imported sermon gets.
 *
 * Derived from the video id rather than auto-generated, which is the
 * whole of the idempotency story: the next poll five minutes later sees
 * the same finished stream, writes to the same id, and creates nothing.
 */
function sermonIdFor(videoId) {
  return `yt-${videoId}`;
}

/**
 * A finished broadcast as a sermon document.
 *
 * Unpublished, always. An automatic import is a draft for a human to
 * look at - a title like "Sunday Service 8/2 (2)" belongs nowhere near a
 * church's public sermon list until someone has read it.
 *
 * The speaker is deliberately left blank rather than filled with the
 * channel's name: a sermon's speaker is a person, and "Yoked Church"
 * sitting in that field reads as a fact instead of as the gap it is.
 *
 * Shaped to match Sermon.toMap in lib/features/sermons/domain/sermon.dart.
 */
function sermonFromVideo(video) {
  const snippet = video.snippet || {};
  const details = video.liveStreamingDetails || {};
  const thumbnails = snippet.thumbnails || {};
  const best = thumbnails.maxres || thumbnails.high || thumbnails.medium || thumbnails.default;

  return {
    title: snippet.title || 'Untitled stream',
    speaker: '',
    date: details.actualStartTime || snippet.publishedAt || new Date().toISOString(),
    seriesId: '',
    seriesName: '',
    scripture: '',
    videoUrl: `https://www.youtube.com/watch?v=${video.id}`,
    audioUrl: '',
    thumbnailUrl: (best && best.url) || '',
    description: snippet.description || '',
    notes: '',
    source: 'youtubeAuto',
    published: false,
  };
}

module.exports = {
  videoIdsFromFeed,
  findLive,
  findFinished,
  liveDocument,
  sermonIdFor,
  sermonFromVideo,
};
