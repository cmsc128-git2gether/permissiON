import { readFileSync } from 'fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, serverTimestamp } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-test', // "demo-" prefix to ensure demo test
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const inOneHour = new Date(Date.now() + 3600_000);
    const oneHourAgo = new Date(Date.now() - 3600_000);

    // users (pre-made)
    await setDoc(doc(db, 'users/admin1'), { access_level: 'admin' });
    await setDoc(doc(db, 'users/student1'), { access_level: 'end_user' });
    await setDoc(doc(db, 'users/student2'), { access_level: 'end_user' });

    // profiles
    await setDoc(doc(db, 'admin_profiles/admin1'), { name: 'Admin One' });
    await setDoc(doc(db, 'end_user_profiles/student1'), { name: 'Student One' });
    await setDoc(doc(db, 'end_user_profiles/student2'), { name: 'Student Two' });

    // permit p1 belongs to student1
    await setDoc(doc(db, 'permits/p1'), {
      user_id: 'student1', type: 'LATE', status: 'PENDING',
    });

    // active, unexpired QR for p1
    await setDoc(doc(db, 'qr/q1'), {
      permit_id: 'p1', admin_id: 'admin1', status: 'ACTIVE',
      created_at: new Date(), expires_at: inOneHour,
      scanned_at: null, scanned_by: null,
    });

    // expired QR for p1
    await setDoc(doc(db, 'qr/qExpired'), {
      permit_id: 'p1', admin_id: 'admin1', status: 'ACTIVE',
      created_at: new Date(Date.now() - 7200_000), expires_at: oneHourAgo,
      scanned_at: null, scanned_by: null,
    });

    // delinquency log for student1
    await setDoc(doc(db, 'delinquency_logs/d1'), { user_id: 'student1' });
  });
});

// helpers
const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

//=== SIGNED-OUT ===
test('signed-out user cannot read a permit', async () => {
  await assertFails(getDoc(doc(anon(), 'permits/p1')));
});

//=== USERS ===
test('user can read own user doc, not another\'s', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'users/student1')));
  await assertFails(getDoc(doc(as('student1'), 'users/student2')));
});

test('admin can read any user doc', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'users/student1')));
});

test('student cannot make themselves admin', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'users/student1'), { access_level: 'admin' })
  );
});

//=== PROFILES ===
test('student can read and update own profile', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'end_user_profiles/student1')));
  await assertSucceeds(
    updateDoc(doc(as('student1'), 'end_user_profiles/student1'), { name: 'New Name' })
  );
});

test('student cannot update another student\'s profile', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'end_user_profiles/student2'), { name: 'Hacked' })
  );
});

test('admin can read a student profile', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'end_user_profiles/student1')));
});

//=== PERMITS ===
test('student can create own PENDING permit', async () => {
  await assertSucceeds(
    setDoc(doc(as('student1'), 'permits/p2'), {
      user_id: 'student1', type: 'OVERNIGHT', status: 'PENDING',
    })
  );
});

test('student cannot create an ACTIVE permit', async () => {
  await assertFails(
    setDoc(doc(as('student1'), 'permits/p2'), {
      user_id: 'student1', type: 'LATE', status: 'ACTIVE',
    })
  );
});

test('student cannot create a permit with an invalid type', async () => {
  await assertFails(
    setDoc(doc(as('student1'), 'permits/p2'), {
      user_id: 'student1', type: 'HOLIDAY', status: 'PENDING',
    })
  );
});

test('student cannot create a permit for someone else', async () => {
  await assertFails(
    setDoc(doc(as('student1'), 'permits/p2'), {
      user_id: 'student2', type: 'LATE', status: 'PENDING',
    })
  );
});

test('admin cannot create a permit (end users only)', async () => {
  await assertFails(
    setDoc(doc(as('admin1'), 'permits/p2'), {
      user_id: 'admin1', type: 'LATE', status: 'PENDING',
    })
  );
});

test('student reads own permit but not another student\'s', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'permits/p1')));
  await assertFails(getDoc(doc(as('student2'), 'permits/p1')));
});

test('admin can read and update any permit', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'permits/p1')));
  await assertSucceeds(
    updateDoc(doc(as('admin1'), 'permits/p1'), { status: 'ACTIVE' })
  );
});

test('admin cannot change a permit\'s owner', async () => {
  await assertFails(
    updateDoc(doc(as('admin1'), 'permits/p1'), { user_id: 'student2' })
  );
});

test('admin cannot set an invalid status', async () => {
  await assertFails(
    updateDoc(doc(as('admin1'), 'permits/p1'), { status: 'MAYBE' })
  );
});

test('student cannot update a permit', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'permits/p1'), { status: 'ACTIVE' })
  );
});

//=== QR: READ ===
test('student reads own QR, not another student\'s', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'qr/q1')));
  await assertFails(getDoc(doc(as('student2'), 'qr/q1')));
});

test('admin can read any QR', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'qr/q1')));
});

//=== QR: CREATE ===
test('admin can create a fresh ACTIVE QR', async () => {
  await assertSucceeds(
    setDoc(doc(as('admin1'), 'qr/q2'), {
      permit_id: 'p1', admin_id: 'admin1', status: 'ACTIVE',
      created_at: new Date(), expires_at: new Date(Date.now() + 3600_000),
      scanned_at: null, scanned_by: null,
    })
  );
});

test('admin cannot create a QR that is already expired', async () => {
  await assertFails(
    setDoc(doc(as('admin1'), 'qr/q2'), {
      permit_id: 'p1', admin_id: 'admin1', status: 'ACTIVE',
      created_at: new Date(), expires_at: new Date(Date.now() - 3600_000),
      scanned_at: null, scanned_by: null,
    })
  );
});

test('admin cannot create a QR under another admin\'s id', async () => {
  await assertFails(
    setDoc(doc(as('admin1'), 'qr/q2'), {
      permit_id: 'p1', admin_id: 'someoneElse', status: 'ACTIVE',
      created_at: new Date(), expires_at: new Date(Date.now() + 3600_000),
      scanned_at: null, scanned_by: null,
    })
  );
});

test('student cannot create a QR', async () => {
  await assertFails(
    setDoc(doc(as('student1'), 'qr/q2'), {
      permit_id: 'p1', admin_id: 'student1', status: 'ACTIVE',
      created_at: new Date(), expires_at: new Date(Date.now() + 3600_000),
      scanned_at: null, scanned_by: null,
    })
  );
});

//=== QR: SCAN / CANCEL ===
test('owner can scan an active QR', async () => {
  await assertSucceeds(
    updateDoc(doc(as('student1'), 'qr/q1'), {
      status: 'SCANNED', scanned_by: 'student1', scanned_at: serverTimestamp(),
    })
  );
});

test('other student cannot scan it', async () => {
  await assertFails(
    updateDoc(doc(as('student2'), 'qr/q1'), {
      status: 'SCANNED', scanned_by: 'student2', scanned_at: serverTimestamp(),
    })
  );
});

test('cannot scan an expired QR', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'qr/qExpired'), {
      status: 'SCANNED', scanned_by: 'student1', scanned_at: serverTimestamp(),
    })
  );
});

test('scan must use the server timestamp, not a client date', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'qr/q1'), {
      status: 'SCANNED', scanned_by: 'student1', scanned_at: new Date(),
    })
  );
});

test('scan cannot also change other fields', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'qr/q1'), {
      status: 'SCANNED', scanned_by: 'student1', scanned_at: serverTimestamp(),
      expires_at: new Date(Date.now() + 86_400_000),
    })
  );
});

test('a scanned QR cannot be scanned again', async () => {
  await assertSucceeds(
    updateDoc(doc(as('student1'), 'qr/q1'), {
      status: 'SCANNED', scanned_by: 'student1', scanned_at: serverTimestamp(),
    })
  );
  await assertFails(
    updateDoc(doc(as('student1'), 'qr/q1'), {
      status: 'SCANNED', scanned_by: 'student1', scanned_at: serverTimestamp(),
    })
  );
});

test('student cannot cancel a QR', async () => {
  await assertFails(
    updateDoc(doc(as('student1'), 'qr/q1'), { status: 'CANCELLED' })
  );
});

test('admin can cancel but not edit other fields', async () => {
  await assertSucceeds(
    updateDoc(doc(as('admin1'), 'qr/q1'), { status: 'CANCELLED' })
  );
  await assertFails(
    updateDoc(doc(as('admin1'), 'qr/qExpired'), { permit_id: 'p9' })
  );
});

//=== DELINQUENCY LOGS ===
test('student reads own delinquency log, not others\'', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'delinquency_logs/d1')));
  await assertFails(getDoc(doc(as('student2'), 'delinquency_logs/d1')));
});

test('admin reads and writes delinquency logs', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'delinquency_logs/d1')));
  await assertSucceeds(
    setDoc(doc(as('admin1'), 'delinquency_logs/d2'), { user_id: 'student2' })
  );
});

test('student cannot write a delinquency log', async () => {
  await assertFails(
    setDoc(doc(as('student1'), 'delinquency_logs/d2'), { user_id: 'student1' })
  );
});