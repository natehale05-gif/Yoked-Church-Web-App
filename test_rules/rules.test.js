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
      setDoc(doc(db, 'users', uid), {
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

      setDoc(doc(db, 'sermons', 's1'), { title: 'A sermon', published: true }),
      setDoc(doc(db, 'events', 'e1'), { title: 'An event' }),
      setDoc(doc(db, 'devotionals', 'd1'), { title: 'A devotional', published: true }),
      setDoc(doc(db, 'readingPlans', 'p1'), { title: 'A plan', published: true }),

      setDoc(doc(db, 'resources', 'public1'), { title: 'Bulletin', membersOnly: false }),
      setDoc(doc(db, 'resources', 'internal1'), { title: 'Directory', membersOnly: true }),

      setDoc(doc(db, 'planProgress', 'p1__member1'), { uid: 'member1', planId: 'p1', completedDays: [1] }),
      setDoc(doc(db, 'sermonNotes', 's1__member1'), { uid: 'member1', sermonId: 's1', body: 'private' }),

      setDoc(doc(db, 'groups', 'g1'), { name: 'Young Adults', leaderUid: 'leader1' }),
      setDoc(doc(db, 'groups', 'g2'), { name: "Men's Breakfast", leaderUid: '' }),
      setDoc(doc(db, 'groupMemberships', 'gm1'), { groupId: 'g1', uid: 'member1', status: 'approved' }),

      setDoc(doc(db, 'eventRsvps', 'e1__member1'), { eventId: 'e1', uid: 'member1', partySize: 2 }),
      setDoc(doc(db, 'givingRecords', 'gr1'), { uid: 'member1', amount: 50, date: '2026-01-05' }),

      setDoc(doc(db, 'volunteerPositions', 'vp1'), { title: 'Greeter', slots: 2 }),
      setDoc(doc(db, 'volunteerAssignments', 'va1'), {
        positionId: 'vp1',
        uid: 'member1',
        status: 'pending',
      }),

      setDoc(doc(db, 'notifications', 'n1'), { uid: 'member1', title: 'Hi', read: false }),
      setDoc(doc(db, 'submissions', 'c1'), { name: 'Visitor', email: 'v@x.org', status: 'open' }),
      setDoc(doc(db, 'announcements', 'an1'), { title: 'Sent', body: 'Body', sentAt: '2026-07-01' }),
      setDoc(doc(db, 'auditLog', 'al1'), { actorUid: 'staff1', action: 'deleted', entity: 'sermon' }),

      setDoc(doc(db, 'rooms', 'r1'), { name: 'Fellowship Hall', bookable: true }),
      setDoc(doc(db, 'roomBookings', 'rb1'), {
        roomId: 'r1',
        requestedByUid: 'member1',
        status: 'pending',
        purpose: 'Study',
      }),

      setDoc(doc(db, 'checkIns', 'ci1'), {
        childName: 'Sam',
        guardianUid: 'member1',
        pickupCode: 'K4TP',
        roomId: 'r1',
      }),

      setDoc(doc(db, 'prayerPosts', 'pp1'), { uid: 'member1', body: 'Please pray', status: 'pending' }),
      setDoc(doc(db, 'prayerIntercessions', 'pp1__member1'), { postId: 'pp1', uid: 'member1' }),

      setDoc(doc(db, 'attendanceRecords', 'group__g1__2026-07-23'), {
        gatheringType: 'group',
        gatheringId: 'g1',
        presentUids: ['member1'],
      }),
      setDoc(doc(db, 'attendanceRecords', 'service__sun__2026-07-26'), {
        gatheringType: 'service',
        gatheringId: 'sun',
        headcount: 118,
      }),

      setDoc(doc(db, 'formDefinitions', 'f-public'), {
        title: 'Camp',
        slug: 'camp',
        published: true,
        membersOnly: false,
      }),
      setDoc(doc(db, 'formDefinitions', 'f-members'), {
        title: 'Serve Team',
        slug: 'serve',
        published: true,
        membersOnly: true,
      }),
      setDoc(doc(db, 'formDefinitions', 'f-draft'), {
        title: 'Draft',
        slug: 'draft',
        published: false,
        membersOnly: false,
      }),
      setDoc(doc(db, 'formSubmissions', 'fs1'), {
        formId: 'f-public',
        answers: { f1: 'Peanut allergy' },
        submittedAt: '2026-07-26',
      }),
    ]);
  });

  const visitor = testEnv.unauthenticatedContext().firestore();
  const member = testEnv.authenticatedContext('member1').firestore();
  const other = testEnv.authenticatedContext('member2').firestore();
  const leader = testEnv.authenticatedContext('leader1').firestore();
  const staff = testEnv.authenticatedContext('staff1').firestore();
  const admin = testEnv.authenticatedContext('admin1').firestore();

  const read = (db, coll, id) => getDoc(doc(db, coll, id));
  const list = (db, coll) => getDocs(collection(db, coll));

  // ------------------------------------------------------ public content
  section('public content');
  await check('a visitor reads a sermon', () => assertSucceeds(read(visitor, 'sermons', 's1')));
  await check('a visitor reads an event', () => assertSucceeds(read(visitor, 'events', 'e1')));
  await check('a visitor reads a devotional', () => assertSucceeds(read(visitor, 'devotionals', 'd1')));
  await check('a visitor reads a reading plan', () => assertSucceeds(read(visitor, 'readingPlans', 'p1')));
  await check('a visitor cannot write a sermon', () =>
    assertFails(setDoc(doc(visitor, 'sermons', 'x'), { title: 'Mine' })));
  await check('a member cannot write a sermon', () =>
    assertFails(setDoc(doc(member, 'sermons', 'x'), { title: 'Mine' })));
  await check('staff can write a sermon', () =>
    assertSucceeds(setDoc(doc(staff, 'sermons', 's2'), { title: 'New', published: true })));

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
    assertFails(setDoc(doc(member, 'planProgress', 'p1__member2'), { uid: 'member2', planId: 'p1' })));

  // --------------------------------------------------------------- users
  section('member profiles');
  await check('a member reads their own profile', () => assertSucceeds(read(member, 'users', 'member1')));
  await check('a member cannot read a profile that opted out', () =>
    assertFails(read(member, 'users', 'member2')));
  await check('a member reads a profile that opted into the directory', () =>
    assertSucceeds(read(member, 'users', 'listed')));
  await check('staff read any profile', () => assertSucceeds(read(staff, 'users', 'member2')));
  await check('a member cannot promote themselves', () =>
    assertFails(updateDoc(doc(member, 'users', 'member1'), { role: 'admin' })));
  await check('an admin can change a role', () =>
    assertSucceeds(updateDoc(doc(admin, 'users', 'promotable'), { role: 'staff' })));
  await check('staff cannot change a role', () =>
    assertFails(updateDoc(doc(staff, 'users', 'member1'), { role: 'staff' })));

  // -------------------------------------------------------------- groups
  section('groups');
  await check('a member reads groups', () => assertSucceeds(read(member, 'groups', 'g1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'groups', 'g1')));
  await check('a member requests to join as pending', () =>
    assertSucceeds(setDoc(doc(member, 'groupMemberships', 'gm2'), {
      groupId: 'g2',
      uid: 'member1',
      status: 'pending',
    })));
  await check('a member cannot join themselves as approved', () =>
    assertFails(setDoc(doc(member, 'groupMemberships', 'gm3'), {
      groupId: 'g2',
      uid: 'member1',
      status: 'approved',
    })));
  await check('a member cannot approve their own membership', () =>
    assertFails(updateDoc(doc(member, 'groupMemberships', 'gm1'), { status: 'approved' })));
  await check('staff approve a membership', () =>
    assertSucceeds(updateDoc(doc(staff, 'groupMemberships', 'gm1'), { status: 'approved' })));

  // ---------------------------------------------------------------- rsvp
  section('event RSVPs');
  await check('a member RSVPs for themselves', () =>
    assertSucceeds(setDoc(doc(member, 'eventRsvps', 'e1__member1_new'), {
      eventId: 'e1',
      uid: 'member1',
      partySize: 1,
    })));
  await check('a member cannot RSVP as someone else', () =>
    assertFails(setDoc(doc(member, 'eventRsvps', 'e1__member2'), {
      eventId: 'e1',
      uid: 'member2',
      partySize: 1,
    })));
  await check('an RSVP cannot be edited after the fact', () =>
    assertFails(updateDoc(doc(member, 'eventRsvps', 'e1__member1'), { partySize: 9 })));

  // -------------------------------------------------------------- giving
  section('giving');
  await check('a member reads their own gift', () => assertSucceeds(read(member, 'givingRecords', 'gr1')));
  await check('another member cannot', () => assertFails(read(other, 'givingRecords', 'gr1')));
  await check('staff read gifts', () => assertSucceeds(read(staff, 'givingRecords', 'gr1')));
  await check('a member cannot record a gift', () =>
    assertFails(setDoc(doc(member, 'givingRecords', 'gr2'), { uid: 'member1', amount: 1000 })));

  // -------------------------------------------------------- volunteering
  section('volunteering');
  await check('a member signs themselves up as pending', () =>
    assertSucceeds(setDoc(doc(member, 'volunteerAssignments', 'va2'), {
      positionId: 'vp1',
      uid: 'member1',
      status: 'pending',
    })));
  await check('a member cannot self-approve on create', () =>
    assertFails(setDoc(doc(member, 'volunteerAssignments', 'va3'), {
      positionId: 'vp1',
      uid: 'member1',
      status: 'approved',
    })));
  await check('a member cannot approve their pending assignment', () =>
    assertFails(updateDoc(doc(member, 'volunteerAssignments', 'va1'), { status: 'approved' })));
  await check('staff approve it', () =>
    assertSucceeds(updateDoc(doc(staff, 'volunteerAssignments', 'va1'), { status: 'approved' })));

  // ------------------------------------------------------- notifications
  section('notifications');
  await check('a member reads their own', () => assertSucceeds(read(member, 'notifications', 'n1')));
  await check('another member cannot', () => assertFails(read(other, 'notifications', 'n1')));
  await check('a member cannot forge one', () =>
    assertFails(setDoc(doc(member, 'notifications', 'n2'), { uid: 'member2', title: 'Fake' })));
  await check('staff send one', () =>
    assertSucceeds(setDoc(doc(staff, 'notifications', 'n3'), { uid: 'member1', title: 'Real' })));

  // ------------------------------------------------------------- connect
  section('connect inbox');
  await check('a visitor submits a connect card', () =>
    assertSucceeds(setDoc(doc(visitor, 'submissions', 'c2'), { name: 'V', email: 'v@x.org' })));
  await check('a visitor cannot read the inbox', () => assertFails(read(visitor, 'submissions', 'c1')));
  await check('a member cannot read the inbox', () => assertFails(read(member, 'submissions', 'c1')));
  await check('staff read the inbox', () => assertSucceeds(read(staff, 'submissions', 'c1')));

  // ------------------------------------------------------- announcements
  section('announcements');
  await check('a member reads a sent announcement', () =>
    assertSucceeds(read(member, 'announcements', 'an1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'announcements', 'an1')));
  await check('staff send one', () =>
    assertSucceeds(setDoc(doc(staff, 'announcements', 'an2'), { title: 'New', body: 'B' })));
  await check('nobody rewrites what was sent', () =>
    assertFails(updateDoc(doc(admin, 'announcements', 'an1'), { body: 'Edited' })));
  await check('nobody deletes it either', () =>
    assertFails(deleteDoc(doc(admin, 'announcements', 'an1'))));

  // ----------------------------------------------------------- audit log
  section('audit log');
  await check('an admin reads it', () => assertSucceeds(read(admin, 'auditLog', 'al1')));
  await check('staff cannot read it', () => assertFails(read(staff, 'auditLog', 'al1')));
  await check('staff append to it', () =>
    assertSucceeds(setDoc(doc(staff, 'auditLog', 'al2'), { actorUid: 'staff1', action: 'created' })));
  await check('staff cannot append under someone else', () =>
    assertFails(setDoc(doc(staff, 'auditLog', 'al3'), { actorUid: 'admin1', action: 'created' })));
  await check('history cannot be rewritten, even by an admin', () =>
    assertFails(updateDoc(doc(admin, 'auditLog', 'al1'), { action: 'nothing' })));
  await check('history cannot be erased, even by an admin', () =>
    assertFails(deleteDoc(doc(admin, 'auditLog', 'al1'))));

  // --------------------------------------------------------- prayer wall
  section('prayer wall');
  await check('a visitor cannot read the wall', () => assertFails(read(visitor, 'prayerPosts', 'pp1')));
  await check('a member reads the wall', () => assertSucceeds(read(member, 'prayerPosts', 'pp1')));
  await check('a member posts as pending', () =>
    assertSucceeds(setDoc(doc(member, 'prayerPosts', 'pp2'), {
      uid: 'member1',
      body: 'Please pray',
      status: 'pending',
    })));
  await check('a member cannot post pre-approved', () =>
    assertFails(setDoc(doc(member, 'prayerPosts', 'pp3'), {
      uid: 'member1',
      body: 'Mine',
      status: 'approved',
    })));
  await check('a member cannot approve their own post', () =>
    assertFails(updateDoc(doc(member, 'prayerPosts', 'pp1'), { status: 'approved' })));
  await check('staff approve it', () =>
    assertSucceeds(updateDoc(doc(staff, 'prayerPosts', 'pp1'), { status: 'approved' })));
  await check('a member records their own intercession', () =>
    assertSucceeds(setDoc(doc(member, 'prayerIntercessions', 'pp2__member1'), {
      postId: 'pp2',
      uid: 'member1',
    })));
  await check('a member cannot pray on someone else\'s behalf', () =>
    assertFails(setDoc(doc(member, 'prayerIntercessions', 'pp2__member2'), {
      postId: 'pp2',
      uid: 'member2',
    })));
  await check('an intercession cannot be edited', () =>
    assertFails(updateDoc(doc(member, 'prayerIntercessions', 'pp1__member1'), { uid: 'member2' })));
  await check('a member withdraws their own', () =>
    assertSucceeds(deleteDoc(doc(member, 'prayerIntercessions', 'pp1__member1'))));

  // --------------------------------------------------------------- rooms
  section('rooms & bookings');
  await check('a member reads rooms', () => assertSucceeds(read(member, 'rooms', 'r1')));
  await check('a visitor cannot', () => assertFails(read(visitor, 'rooms', 'r1')));
  await check('a member requests a room as pending', () =>
    assertSucceeds(setDoc(doc(member, 'roomBookings', 'rb2'), {
      roomId: 'r1',
      requestedByUid: 'member1',
      status: 'pending',
      purpose: 'Study',
    })));
  await check('a member cannot book themselves in as approved', () =>
    assertFails(setDoc(doc(member, 'roomBookings', 'rb3'), {
      roomId: 'r1',
      requestedByUid: 'member1',
      status: 'approved',
      purpose: 'Study',
    })));
  await check('a member cannot approve their own request', () =>
    assertFails(updateDoc(doc(member, 'roomBookings', 'rb1'), { status: 'approved' })));
  await check('a member withdraws their own request', () =>
    assertSucceeds(updateDoc(doc(member, 'roomBookings', 'rb1'), { status: 'cancelled' })));
  await check('staff approve a booking', () =>
    assertSucceeds(updateDoc(doc(staff, 'roomBookings', 'rb2'), { status: 'approved' })));

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
    assertFails(updateDoc(doc(member, 'checkIns', 'ci1'), { codeUsed: true })));
  await check('staff release a child', () =>
    assertSucceeds(updateDoc(doc(staff, 'checkIns', 'ci1'), { codeUsed: true })));

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
    assertFails(updateDoc(doc(leader, 'attendanceRecords', 'group__g1__2026-07-23'), { headcount: 99 })));
  await check('staff record attendance', () =>
    assertSucceeds(setDoc(doc(staff, 'attendanceRecords', 'service__sun__2026-08-02'), {
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
    assertFails(setDoc(doc(member, 'formDefinitions', 'f-mine'), { title: 'Mine', published: true })));
  await check('staff build one', () =>
    assertSucceeds(setDoc(doc(staff, 'formDefinitions', 'f-new'), { title: 'New', slug: 'new' })));

  await check('a visitor submits a response', () =>
    assertSucceeds(setDoc(doc(visitor, 'formSubmissions', 'fs2'), {
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
    assertFails(updateDoc(doc(member, 'formSubmissions', 'fs1'), { answers: { f1: 'Changed' } })));

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
