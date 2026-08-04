/**
 * Security-rule tests for firestore.rules, run against the Firebase
 * emulator.
 *
 * These rules are the only thing standing between a member and someone
 * else's giving history, a child's pickup code, or the medical note a
 * parent attached to a camp registration. Until they are executed they
 * are assertions, not protection.
 *
 * Every collection gets at least one *denied* case. A suite that only
 * checks the happy path proves nothing about a security rule - `allow
 * read: if true` passes all of those.
 *
 * Run with `./run.sh` from this directory.
 */
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  updateDoc,
  deleteDoc,
  setLogLevel,
} = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

setLogLevel('error');

let passed = 0;
const failures = [];

async function check(name, fn) {
  try {
    await fn();
    passed++;
    process.stdout.write('.');
  } catch (error) {
    failures.push(`${name}\n    ${error.message.split('\n')[0]}`);
    process.stdout.write('F');
  }
}

function section(title) {
  process.stdout.write(`\n${title.padEnd(28)} `);
}

(async () => {
  const testEnv = await initializeTestEnvironment({
    projectId: 'demo-yoked-church',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  // ---------------------------------------------------------------- seed
  // Written with rules disabled so the fixtures themselves aren't a test.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const user = (uid, role, extra = {}) =>
      setDoc(doc(db, 'churches/church1/users', uid), {
        role,
        email: `${uid}@example.org`,
        displayName: uid,
        directoryOptIn: false,
        household: [],
        createdAt: '2026-01-01',
        ...extra,
      });

    await Promise.all([
      user('member1', 'member'),
      user('member2', 'member'),
      user('listed', 'member', { directoryOptIn: true }),
      // Only ever used by the role-change test. Promoting one of the
      // members the rest of the suite asserts against would silently turn
      // every later "another member cannot" into a staff read.
      user('promotable', 'member'),
      user('leader1', 'member'),
      user('staff1', 'staff'),
      user('admin1', 'admin'),

      setDoc(doc(db, 'churches/church1/sermons', 's1'), { title: 'A sermon', published: true }),
      setDoc(doc(db, 'churches/church1/events', 'e1'), { title: 'An event' }),
      setDoc(doc(db, 'churches/church1/devotionals', 'd1'), { title: 'A devotional', published: true }),
      setDoc(doc(db, 'churches/church1/readingPlans', 'p1'), { title: 'A plan', published: true }),

      // Written in real life by the scheduled poller via the Admin SDK,
      // which bypasses rules; seeded here so the read cases have a
      // document to read.
      setDoc(doc(db, 'churches/church1/live', 'current'), { live: true, videoId: 'abc123' }),

      setDoc(doc(db, 'churches/church1/resources', 'public1'), { title: 'Bulletin', membersOnly: false }),
      setDoc(doc(db, 'churches/church1/resources', 'internal1'), { title: 'Directory', membersOnly: true }),

      setDoc(doc(db, 'churches/church1/planProgress', 'p1__member1'), { uid: 'member1', planId: 'p1', completedDays: [1] }),
      setDoc(doc(db, 'churches/church1/sermonNotes', 's1__member1'), { uid: 'member1', sermonId: 's1', body: 'private' }),

      setDoc(doc(db, 'churches/church1/groups', 'g1'), { name: 'Young Adults', leaderUid: 'leader1' }),
      setDoc(doc(db, 'churches/church1/groups', 'g2'), { name: "Men's Breakfast", leaderUid: '' }),
      setDoc(doc(db, 'churches/church1/groupMemberships', 'gm1'), { groupId: 'g1', uid: 'member1', status: 'approved' }),

      setDoc(doc(db, 'churches/church1/eventRsvps', 'e1__member1'), { eventId: 'e1', uid: 'member1', partySize: 2 }),
      setDoc(doc(db, 'churches/church1/givingRecords', 'gr1'), { uid: 'member1', amount: 50, date: '2026-01-05' }),

      setDoc(doc(db, 'churches/church1/volunteerPositions', 'vp1'), { title: 'Greeter', slots: 2 }),
      setDoc(doc(db, 'churches/church1/volunteerAssignments', 'va1'), {
        positionId: 'vp1',
        uid: 'member1',
        status: 'pending',
      }),

      setDoc(doc(db, 'churches/church1/notifications', 'n1'), { uid: 'member1', title: 'Hi', read: false }),
      setDoc(doc(db, 'churches/church1/submissions', 'c1'), { name: 'Visitor', email: 'v@x.org', status: 'open' }),
      setDoc(doc(db, 'churches/church1/announcements', 'an1'), { title: 'Sent', body: 'Body', sentAt: '2026-07-01' }),
      setDoc(doc(db, 'churches/church1/auditLog', 'al1'), { actorUid: 'staff1', action: 'deleted', entity: 'sermon' }),

      setDoc(doc(db, 'churches/church1/rooms', 'r1'), { name: 'Fellowship Hall', bookable: true }),
      setDoc(doc(db, 'churches/church1/roomBookings', 'rb1'), {
        roomId: 'r1',
        requestedByUid: 'member1',
        status: 'pending',
        purpose: 'Study',
      }),

      setDoc(doc(db, 'churches/church1/checkIns', 'ci1'), {
        childName: 'Sam',
        guardianUid: 'member1',
        pickupCode: 'K4TP',
        roomId: 'r1',
      }),

      setDoc(doc(db, 'churches/church1/prayerPosts', 'pp1'), { uid: 'member1', body: 'Please pray', status: 'pending' }),
      setDoc(doc(db, 'churches/church1/prayerIntercessions', 'pp1__member1'), { postId: 'pp1', uid: 'member1' }),

      setDoc(doc(db, 'churches/church1/attendanceRecords', 'group__g1__2026-07-23'), {
        gatheringType: 'group',
        gatheringId: 'g1',
        presentUids: ['member1'],
      }),
      setDoc(doc(db, 'churches/church1/attendanceRecords', 'service__sun__2026-07-26'), {
        gatheringType: 'service',
        gatheringId: 'sun',
        headcount: 118,
      }),

      setDoc(doc(db, 'churches/church1/formDefinitions', 'f-public'), {
        title: 'Camp',
        slug: 'camp',
        published: true,
        membersOnly: false,
      }),
      setDoc(doc(db, 'churches/church1/formDefinitions', 'f-members'), {
        title: 'Serve Team',
        slug: 'serve',
        published: true,
        membersOnly: true,
      }),
      setDoc(doc(db, 'churches/church1/formDefinitions', 'f-draft'), {
        title: 'Draft',
        slug: 'draft',
        published: false,
        membersOnly: false,
      }),
      setDoc(doc(db, 'churches/church1/formSubmissions', 'fs1'), {
        formId: 'f-public',
        answers: { f1: 'Peanut allergy' },
        submittedAt: '2026-07-26',
      }),

      // A second church, so the suite can prove one cannot see the
      // other. Everything above this line would pass just as happily on
      // a single-tenant database.
      setDoc(doc(db, 'churches', 'church1'), { churchName: 'First Church' }),
      setDoc(doc(db, 'churches', 'church2'), { churchName: 'Second Church' }),
      setDoc(doc(db, 'churches/church2/users', 'outsider'), {
        role: 'admin',
        email: 'outsider@example.org',
        displayName: 'outsider',
        directoryOptIn: false,
        household: [],
        createdAt: '2026-01-01',
      }),
      setDoc(doc(db, 'churches/church2/givingRecords', 'gr2'), {
        uid: 'outsider',
        amount: 500,
        date: '2026-01-05',
      }),
      setDoc(doc(db, 'churches/church2/checkIns', 'ci2'), {
        childName: 'Ana',
        guardianUid: 'outsider',
        pickupCode: 'Z9QQ',
        roomId: 'r1',
      }),
      setDoc(doc(db, 'churches/church2/prayerPosts', 'pp2'), {
        uid: 'outsider',
        body: 'Private to church two',
        status: 'pending',
      }),
    ]);
  });

  const visitor = testEnv.unauthenticatedContext().firestore();
  const member = testEnv.authenticatedContext('member1').firestore();
  const other = testEnv.authenticatedContext('member2').firestore();
  const leader = testEnv.authenticatedContext('leader1').firestore();
  const staff = testEnv.authenticatedContext('staff1').firestore();
  const admin = testEnv.authenticatedContext('admin1').firestore();

  // Collection names are church-relative by default, so the assertions
  // below read as they always did. The isolation section passes a full
  // `churches/church2/...` path to reach across the boundary on purpose.
  const at = (coll) =>
    coll === 'churches' || coll.startsWith('churches/') ? coll : `churches/church1/${coll}`;
  const read = (db, coll, id) => getDoc(doc(db, at(coll), id));
  const list = (db, coll) => getDocs(collection(db, at(coll)));

  // ------------------------------------------------------ public content
  section('public content');
  await check('a visitor reads a sermon', () => assertSucceeds(read(visitor, 'sermons', 's1')));
  await check('a visitor reads an event', () => assertSucceeds(read(visitor, 'events', 'e1')));
  await check('a visitor reads a devotional', () => assertSucceeds(read(visitor, 'devotionals', 'd1')));
  await check('a visitor reads a reading plan', () => assertSucceeds(read(visitor, 'readingPlans', 'p1')));
  await check('a visitor cannot write a sermon', () =>
    assertFails(setDoc(doc(visitor, 'churches/church1/sermons', 'x'), { title: 'Mine' })));
  await check('a member cannot write a sermon', () =>
    assertFails(setDoc(doc(member, 'churches/church1/sermons', 'x'), { title: 'Mine' })));
  await check('staff can write a sermon', () =>
    assertSucceeds(setDoc(doc(staff, 'churches/church1/sermons', 's2'), { title: 'New', published: true })));

  // ------------------------------------------------------ church signup
  section('church signup');
  // Creating a church means writing yourself in as its admin in the same
  // breath. A rule permissive enough to allow that lets anyone mint
  // admin rights, so there is no such rule - the createChurch function
  // holds the only path, and bypasses these with the Admin SDK.
  await check('a signed-in person cannot create a church directly', () =>
    assertFails(setDoc(doc(member, 'churches', 'brand-new'), { churchName: 'Mine' })));
  await check('an admin cannot create another church directly', () =>
    assertFails(setDoc(doc(admin, 'churches', 'brand-new'), { churchName: 'Mine' })));
  await check('an admin cannot delete their own church', () =>
    assertFails(deleteDoc(doc(admin, 'churches', 'church1'))));
  await check('an admin can still edit their own church', () =>
    assertSucceeds(updateDoc(doc(admin, 'churches', 'church1'), { tagline: 'New tagline' })));
  // The signup cap. A cap you can read is a cap you can plan around.
  await check('nobody can read the signup counter', () =>
    assertFails(getDoc(doc(member, 'signups', 'member1'))));
  await check('nobody can raise their own signup counter', () =>
    assertFails(setDoc(doc(member, 'signups', 'member1'), { churches: 0 })));

  // --------------------------------------------------------- live status
  section('live status');
  await check('a visitor sees that the church is live', () =>
    assertSucceeds(read(visitor, 'live', 'current')));
  // Nobody may claim a service is happening. This is the one collection
  // an admin is locked out of, because "are they streaming" is a fact
  // about YouTube rather than a decision the church gets to make.
  await check('a visitor cannot announce a stream', () =>
    assertFails(setDoc(doc(visitor, 'churches/church1/live', 'current'), { live: true })));
  await check('a member cannot announce a stream', () =>
    assertFails(setDoc(doc(member, 'churches/church1/live', 'current'), { live: true })));
  await check('staff cannot announce a stream', () =>
    assertFails(setDoc(doc(staff, 'churches/church1/live', 'current'), { live: true })));
  await check('an admin cannot announce a stream either', () =>
    assertFails(setDoc(doc(admin, 'churches/church1/live', 'current'), { live: true })));
  await check('an admin cannot take one down', () =>
    assertFails(deleteDoc(doc(admin, 'churches/church1/live', 'current'))));

  // ----------------------------------------------------------- resources
  section('resources');
  await check('a visitor reads a public resource', () =>
    assertSucceeds(read(visitor, 'resources', 'public1')));
  await check('a visitor cannot read a members-only resource', () =>
    assertFails(read(visitor, 'resources', 'internal1')));
  await check('a visitor cannot sweep the collection for one', () =>
    assertFails(list(visitor, 'resources')));
  await check('a member reads a members-only resource', () =>
    assertSucceeds(read(member, 'resources', 'internal1')));

  // -------------------------------------------------------- private data
  // The most private things the app holds. Staff are deliberately shut
  // out: how far someone got in their Bible reading, and what they wrote
  // down during a sermon, are between them and God.
  section('private to the member');
  await check('a member reads their own plan progress', () =>
    assertSucceeds(read(member, 'planProgress', 'p1__member1')));
  await check('another member cannot', () =>
    assertFails(read(other, 'planProgress', 'p1__member1')));
  await check('staff cannot read plan progress', () =>
    assertFails(read(staff, 'planProgress', 'p1__member1')));
  await check('an admin cannot read plan progress either', () =>
    assertFails(read(admin, 'planProgress', 'p1__member1')));
  await check('a member reads their own sermon notes', () =>
    assertSucceeds(read(member, 'sermonNotes', 's1__member1')));
  await check('staff cannot read sermon notes', () =>
    assertFails(read(staff, 'sermonNotes', 's1__member1')));
  await check('a member cannot file progress under another uid', () =>
    assertFails(setDoc(doc(member, 'churches/church1/planProgress', 'p1__member2'), { uid: 'member2', planId: 'p1' })));

  // --------------------------------------------------------------- users
  section('member profiles');
  await check('a member reads their own profile', () => assertSucceeds(read(member, 'users', 'member1')));
  await check('a member cannot read a profile that opted out', () =>
    assertFails(read(member, 'users', 'member2')));
  await check('a member reads a profile that opted into the directory', () =>
    assertSucceeds(read(member, 'users', 'listed')));
  await check('staff read any profile', () => assertSucceeds(read(staff, 'users', 'member2')));
  await check('a member cannot promote themselves', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/users', 'member1'), { role: 'admin' })));
  await check('an admin can change a role', () =>
    assertSucceeds(updateDoc(doc(admin, 'churches/church1/users', 'promotable'), { role: 'staff' })));
  await check('staff cannot change a role', () =>
    assertFails(updateDoc(doc(staff, 'churches/church1/users', 'member1'), { role: 'staff' })));

  // -------------------------------------------------------------- groups
  section('groups');
  await check('a member reads groups', () => assertSucceeds(read(member, 'groups', 'g1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'groups', 'g1')));
  await check('a member requests to join as pending', () =>
    assertSucceeds(setDoc(doc(member, 'churches/church1/groupMemberships', 'gm2'), {
      groupId: 'g2',
      uid: 'member1',
      status: 'pending',
    })));
  await check('a member cannot join themselves as approved', () =>
    assertFails(setDoc(doc(member, 'churches/church1/groupMemberships', 'gm3'), {
      groupId: 'g2',
      uid: 'member1',
      status: 'approved',
    })));
  await check('a member cannot approve their own membership', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/groupMemberships', 'gm1'), { status: 'approved' })));
  await check('staff approve a membership', () =>
    assertSucceeds(updateDoc(doc(staff, 'churches/church1/groupMemberships', 'gm1'), { status: 'approved' })));

  // ---------------------------------------------------------------- rsvp
  section('event RSVPs');
  await check('a member RSVPs for themselves', () =>
    assertSucceeds(setDoc(doc(member, 'churches/church1/eventRsvps', 'e1__member1_new'), {
      eventId: 'e1',
      uid: 'member1',
      partySize: 1,
    })));
  await check('a member cannot RSVP as someone else', () =>
    assertFails(setDoc(doc(member, 'churches/church1/eventRsvps', 'e1__member2'), {
      eventId: 'e1',
      uid: 'member2',
      partySize: 1,
    })));
  await check('an RSVP cannot be edited after the fact', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/eventRsvps', 'e1__member1'), { partySize: 9 })));

  // -------------------------------------------------------------- giving
  section('giving');
  await check('a member reads their own gift', () => assertSucceeds(read(member, 'givingRecords', 'gr1')));
  await check('another member cannot', () => assertFails(read(other, 'givingRecords', 'gr1')));
  await check('staff read gifts', () => assertSucceeds(read(staff, 'givingRecords', 'gr1')));
  await check('a member cannot record a gift', () =>
    assertFails(setDoc(doc(member, 'churches/church1/givingRecords', 'gr2'), { uid: 'member1', amount: 1000 })));

  // -------------------------------------------------------- volunteering
  section('volunteering');
  await check('a member signs themselves up as pending', () =>
    assertSucceeds(setDoc(doc(member, 'churches/church1/volunteerAssignments', 'va2'), {
      positionId: 'vp1',
      uid: 'member1',
      status: 'pending',
    })));
  await check('a member cannot self-approve on create', () =>
    assertFails(setDoc(doc(member, 'churches/church1/volunteerAssignments', 'va3'), {
      positionId: 'vp1',
      uid: 'member1',
      status: 'approved',
    })));
  await check('a member cannot approve their pending assignment', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/volunteerAssignments', 'va1'), { status: 'approved' })));
  await check('staff approve it', () =>
    assertSucceeds(updateDoc(doc(staff, 'churches/church1/volunteerAssignments', 'va1'), { status: 'approved' })));

  // ------------------------------------------------------- notifications
  section('notifications');
  await check('a member reads their own', () => assertSucceeds(read(member, 'notifications', 'n1')));
  await check('another member cannot', () => assertFails(read(other, 'notifications', 'n1')));
  await check('a member cannot forge one', () =>
    assertFails(setDoc(doc(member, 'churches/church1/notifications', 'n2'), { uid: 'member2', title: 'Fake' })));
  await check('staff send one', () =>
    assertSucceeds(setDoc(doc(staff, 'churches/church1/notifications', 'n3'), { uid: 'member1', title: 'Real' })));

  // ------------------------------------------------------------- connect
  section('connect inbox');
  await check('a visitor submits a connect card', () =>
    assertSucceeds(setDoc(doc(visitor, 'churches/church1/submissions', 'c2'), { name: 'V', email: 'v@x.org' })));
  await check('a visitor cannot read the inbox', () => assertFails(read(visitor, 'submissions', 'c1')));
  await check('a member cannot read the inbox', () => assertFails(read(member, 'submissions', 'c1')));
  await check('staff read the inbox', () => assertSucceeds(read(staff, 'submissions', 'c1')));

  // ------------------------------------------------------- announcements
  section('announcements');
  await check('a member reads a sent announcement', () =>
    assertSucceeds(read(member, 'announcements', 'an1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'announcements', 'an1')));
  await check('staff send one', () =>
    assertSucceeds(setDoc(doc(staff, 'churches/church1/announcements', 'an2'), { title: 'New', body: 'B' })));
  await check('nobody rewrites what was sent', () =>
    assertFails(updateDoc(doc(admin, 'churches/church1/announcements', 'an1'), { body: 'Edited' })));
  await check('nobody deletes it either', () =>
    assertFails(deleteDoc(doc(admin, 'churches/church1/announcements', 'an1'))));

  // ----------------------------------------------------------- audit log
  section('audit log');
  await check('an admin reads it', () => assertSucceeds(read(admin, 'auditLog', 'al1')));
  await check('staff cannot read it', () => assertFails(read(staff, 'auditLog', 'al1')));
  await check('staff append to it', () =>
    assertSucceeds(setDoc(doc(staff, 'churches/church1/auditLog', 'al2'), { actorUid: 'staff1', action: 'created' })));
  await check('staff cannot append under someone else', () =>
    assertFails(setDoc(doc(staff, 'churches/church1/auditLog', 'al3'), { actorUid: 'admin1', action: 'created' })));
  await check('history cannot be rewritten, even by an admin', () =>
    assertFails(updateDoc(doc(admin, 'churches/church1/auditLog', 'al1'), { action: 'nothing' })));
  await check('history cannot be erased, even by an admin', () =>
    assertFails(deleteDoc(doc(admin, 'churches/church1/auditLog', 'al1'))));

  // --------------------------------------------------------- prayer wall
  section('prayer wall');
  await check('a visitor cannot read the wall', () => assertFails(read(visitor, 'prayerPosts', 'pp1')));
  await check('a member reads the wall', () => assertSucceeds(read(member, 'prayerPosts', 'pp1')));
  await check('a member posts as pending', () =>
    assertSucceeds(setDoc(doc(member, 'churches/church1/prayerPosts', 'pp2'), {
      uid: 'member1',
      body: 'Please pray',
      status: 'pending',
    })));
  await check('a member cannot post pre-approved', () =>
    assertFails(setDoc(doc(member, 'churches/church1/prayerPosts', 'pp3'), {
      uid: 'member1',
      body: 'Mine',
      status: 'approved',
    })));
  await check('a member cannot approve their own post', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/prayerPosts', 'pp1'), { status: 'approved' })));
  await check('staff approve it', () =>
    assertSucceeds(updateDoc(doc(staff, 'churches/church1/prayerPosts', 'pp1'), { status: 'approved' })));
  await check('a member records their own intercession', () =>
    assertSucceeds(setDoc(doc(member, 'churches/church1/prayerIntercessions', 'pp2__member1'), {
      postId: 'pp2',
      uid: 'member1',
    })));
  await check('a member cannot pray on someone else\'s behalf', () =>
    assertFails(setDoc(doc(member, 'churches/church1/prayerIntercessions', 'pp2__member2'), {
      postId: 'pp2',
      uid: 'member2',
    })));
  await check('an intercession cannot be edited', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/prayerIntercessions', 'pp1__member1'), { uid: 'member2' })));
  await check('a member withdraws their own', () =>
    assertSucceeds(deleteDoc(doc(member, 'churches/church1/prayerIntercessions', 'pp1__member1'))));

  // --------------------------------------------------------------- rooms
  section('rooms & bookings');
  await check('a member reads rooms', () => assertSucceeds(read(member, 'rooms', 'r1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'rooms', 'r1')));
  await check('a member requests a room as pending', () =>
    assertSucceeds(setDoc(doc(member, 'churches/church1/roomBookings', 'rb2'), {
      roomId: 'r1',
      requestedByUid: 'member1',
      status: 'pending',
      purpose: 'Study',
    })));
  await check('a member cannot book themselves in as approved', () =>
    assertFails(setDoc(doc(member, 'churches/church1/roomBookings', 'rb3'), {
      roomId: 'r1',
      requestedByUid: 'member1',
      status: 'approved',
      purpose: 'Study',
    })));
  await check('a member cannot approve their own request', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/roomBookings', 'rb1'), { status: 'approved' })));
  await check('a member withdraws their own request', () =>
    assertSucceeds(updateDoc(doc(member, 'churches/church1/roomBookings', 'rb1'), { status: 'cancelled' })));
  await check('staff approve a booking', () =>
    assertSucceeds(updateDoc(doc(staff, 'churches/church1/roomBookings', 'rb2'), { status: 'approved' })));

  // ------------------------------------------------------- kids check-in
  // The pickup code lives on this document. A guardian sees their own
  // child's, and nobody else's.
  section('kids check-in');
  await check('a guardian reads their own child\'s session', () =>
    assertSucceeds(read(member, 'checkIns', 'ci1')));
  await check('another member cannot', () => assertFails(read(other, 'checkIns', 'ci1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'checkIns', 'ci1')));
  await check('staff at the desk can', () => assertSucceeds(read(staff, 'checkIns', 'ci1')));
  await check('a guardian cannot release their own child', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/checkIns', 'ci1'), { codeUsed: true })));
  await check('staff release a child', () =>
    assertSucceeds(updateDoc(doc(staff, 'churches/church1/checkIns', 'ci1'), { codeUsed: true })));

  // ---------------------------------------------------------- attendance
  section('attendance');
  await check('staff read attendance', () =>
    assertSucceeds(read(staff, 'attendanceRecords', 'service__sun__2026-07-26')));
  await check('a member cannot read attendance', () =>
    assertFails(read(member, 'attendanceRecords', 'service__sun__2026-07-26')));
  await check('a group leader reads their own group\'s record', () =>
    assertSucceeds(read(leader, 'attendanceRecords', 'group__g1__2026-07-23')));
  await check('a leader cannot read a service headcount', () =>
    assertFails(read(leader, 'attendanceRecords', 'service__sun__2026-07-26')));
  await check('a member who leads nothing cannot read a group record', () =>
    assertFails(read(other, 'attendanceRecords', 'group__g1__2026-07-23')));
  await check('a leader cannot record attendance', () =>
    assertFails(updateDoc(doc(leader, 'churches/church1/attendanceRecords', 'group__g1__2026-07-23'), { headcount: 99 })));
  await check('staff record attendance', () =>
    assertSucceeds(setDoc(doc(staff, 'churches/church1/attendanceRecords', 'service__sun__2026-08-02'), {
      gatheringType: 'service',
      gatheringId: 'sun',
      headcount: 121,
    })));

  // --------------------------------------------------------------- forms
  section('forms');
  await check('a visitor reads a published public form', () =>
    assertSucceeds(read(visitor, 'formDefinitions', 'f-public')));
  await check('a visitor cannot read a members-only form', () =>
    assertFails(read(visitor, 'formDefinitions', 'f-members')));
  await check('a visitor cannot read a draft', () =>
    assertFails(read(visitor, 'formDefinitions', 'f-draft')));
  await check('a visitor cannot sweep the collection for one', () =>
    assertFails(list(visitor, 'formDefinitions')));
  await check('a member reads a members-only form', () =>
    assertSucceeds(read(member, 'formDefinitions', 'f-members')));
  await check('a member cannot read a draft', () =>
    assertFails(read(member, 'formDefinitions', 'f-draft')));
  await check('a member cannot build a form', () =>
    assertFails(setDoc(doc(member, 'churches/church1/formDefinitions', 'f-mine'), { title: 'Mine', published: true })));
  await check('staff build one', () =>
    assertSucceeds(setDoc(doc(staff, 'churches/church1/formDefinitions', 'f-new'), { title: 'New', slug: 'new' })));

  await check('a visitor submits a response', () =>
    assertSucceeds(setDoc(doc(visitor, 'churches/church1/formSubmissions', 'fs2'), {
      formId: 'f-public',
      answers: { f1: 'Yes' },
    })));
  await check('a visitor cannot read the responses', () =>
    assertFails(read(visitor, 'formSubmissions', 'fs1')));
  await check('a member cannot read the responses', () =>
    assertFails(read(member, 'formSubmissions', 'fs1')));
  await check('staff read the responses', () =>
    assertSucceeds(read(staff, 'formSubmissions', 'fs1')));
  await check('a member cannot alter a submitted response', () =>
    assertFails(updateDoc(doc(member, 'churches/church1/formSubmissions', 'fs1'), { answers: { f1: 'Changed' } })));

  // ------------------------------------------------- tenant isolation
  // The whole point of nesting every collection under its church.
  //
  // What these catch is a rule resolving membership or role against the
  // wrong church - the copy-paste of `isStaff('church1')` into a rule
  // reached as church2. Nothing errors, no request is rejected, and one
  // church's staff quietly hold another church's pickup codes. Verified
  // by making exactly that change and watching two of these go red.
  //
  // A repository left on a top-level path is a different, louder bug:
  // there is no rule at `/sermons/{id}` any more, so it is denied
  // outright rather than leaking.
  //
  // Every case below is a *denial* on purpose. A suite that only proved
  // church1 can read church1 would pass unchanged on a database with no
  // tenancy at all.
  section('tenant isolation');

  await check("church one's admin cannot read church two's giving", () =>
    assertFails(read(admin, 'churches/church2/givingRecords', 'gr2')));
  await check("church one's staff cannot read church two's pickup codes", () =>
    assertFails(read(staff, 'churches/church2/checkIns', 'ci2')));
  await check("church one's staff cannot read church two's prayer requests", () =>
    assertFails(read(staff, 'churches/church2/prayerPosts', 'pp2')));
  await check("church one's member cannot read church two's roll", () =>
    assertFails(read(member, 'churches/church2/users', 'outsider')));
  await check("church one's staff cannot list church two's giving", () =>
    assertFails(list(staff, 'churches/church2/givingRecords')));

  // Being an admin somewhere is not being an admin everywhere. This is
  // the reason roles live in churches/{id}/users rather than a global
  // users collection.
  await check("church one's admin cannot write to church two", () =>
    assertFails(setDoc(doc(admin, 'churches/church2/sermons', 'x'), { title: 'Mine' })));
  await check("church one's admin cannot edit church two's settings", () =>
    assertFails(updateDoc(doc(admin, 'churches', 'church2'), { churchName: 'Taken over' })));
  await check("church two's admin cannot write to church one", () => {
    const outsider = testEnv.authenticatedContext('outsider').firestore();
    return assertFails(setDoc(doc(outsider, 'churches/church1/sermons', 'x'), { title: 'Mine' }));
  });

  // The directory has to stay public: that is how the picker lists
  // churches, and how the app themes itself before anyone signs in.
  await check('a visitor can read any church card', () =>
    assertSucceeds(read(visitor, 'churches', 'church2')));
  await check('a visitor cannot invent a church', () =>
    assertFails(setDoc(doc(visitor, 'churches', 'church3'), { churchName: 'Fake' })));
  await check('an admin cannot delete their church', () =>
    assertFails(deleteDoc(doc(admin, 'churches', 'church1'))));

  await testEnv.cleanup();

  console.log(`\n\n${passed} passed, ${failures.length} failed`);
  if (failures.length > 0) {
    console.log('\nFailures:');
    for (const failure of failures) console.log(`  - ${failure}`);
    process.exit(1);
  }
})().catch((error) => {
  console.error('\nSuite crashed:', error);
  process.exit(1);
});
