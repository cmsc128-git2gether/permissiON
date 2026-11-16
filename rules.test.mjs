import { readFileSync } from 'fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc,
  serverTimestamp, Timestamp, setLogLevel,
} from 'firebase/firestore';

setLogLevel('silent'); // hides the noisy PERMISSION_DENIED logs from expected failures

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-test',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080, // must match firebase.json (use 8085 if that's what you set)
    },
  });
});

after(async () => {
  await env.cleanup();
});

const hours = (n) => new Date(Date.now() + n * 3600_000);
const TIME_IN = new Date(Date.now() - 3600_000);
TIME_IN.setMilliseconds(0);

beforeEach(async () => {
  await env.clearFirestore();

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    // users
    await setDoc(doc(db, 'users/admin1'), { access_level: 'admin' });
    await setDoc(doc(db, 'users/admin2'), { access_level: 'admin' });
    await setDoc(doc(db, 'users/admin3'), { access_level: 'admin' });   // no profile yet
    await setDoc(doc(db, 'users/student1'), { access_level: 'end_user' });
    await setDoc(doc(db, 'users/student2'), { access_level: 'end_user' });
    await setDoc(doc(db, 'users/student3'), { access_level: 'end_user' }); // no profile yet

    // profiles
    await setDoc(doc(db, 'admin_profiles/admin1'), { name: 'Admin One' });
    await setDoc(doc(db, 'admin_profiles/admin2'), { name: 'Admin Two' });
    await setDoc(doc(db, 'end_user_profiles/student1'), {
      name: 'Student One', phone_num: '111', display_photo: 'a.png',
    });
    await setDoc(doc(db, 'end_user_profiles/student2'), {
      name: 'Student Two', phone_num: '222', display_photo: 'b.png',
    });

    // permits (all belong to student1 unless noted)
    await setDoc(doc(db, 'permits/pPending'), {
      user_id: 'student1', type: 'LATE', permit_status: 'PENDING', actual_time_in: null,
    });
    await setDoc(doc(db, 'permits/pActive'), {
      user_id: 'student1', type: 'LATE', permit_status: 'ACTIVE', actual_time_in: null,
    });
    await setDoc(doc(db, 'permits/pActiveNoCode'), {
      user_id: 'student1', type: 'OVERNIGHT', permit_status: 'ACTIVE', actual_time_in: null,
    });
    await setDoc(doc(db, 'permits/pExpired'), {
      user_id: 'student1', type: 'LATE', permit_status: 'ACTIVE', actual_time_in: null,
    });
    await setDoc(doc(db, 'permits/pDone'), {
      user_id: 'student1', type: 'LATE', permit_status: 'ACTIVE',
      actual_time_in: Timestamp.fromDate(TIME_IN),
    });
    await setDoc(doc(db, 'permits/pCompleted'), {
      user_id: 'student1', type: 'LATE', permit_status: 'COMPLETED', actual_time_in: null,
    });

    // check-in codes (doc id = permit id)
    await setDoc(doc(db, 'checkin_codes/pActive'), {
      code_status: null, checkin_at: null, checkin_by: null, expires_at: hours(1),
    });
    await setDoc(doc(db, 'checkin_codes/pExpired'), {
      code_status: null, checkin_at: null, checkin_by: null, expires_at: hours(-1),
    });
    await setDoc(doc(db, 'checkin_codes/pDone'), {
      code_status: 'DONE', checkin_at: Timestamp.fromDate(TIME_IN),
      checkin_by: 'student1', expires_at: hours(1),
    });

    // delinquency log for student1
    await setDoc(doc(db, 'delinquency_logs/d1'), { user_id: 'student1' });
  });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

//=== SIGNED OUT ===
test('signed-out user cannot read a permit', async () => {
  await assertFails(getDoc(doc(anon(), 'permits/pPending')));
});

//=== USERS ===
test('user reads own user doc, not another\'s', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'users/student1')));
  await assertFails(getDoc(doc(as('student1'), 'users/student2')));
});

test('admin can read any user doc', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'users/student1')));
});

test('admin can create an end_user doc', async () => {
  await assertSucceeds(setDoc(doc(as('admin1'), 'users/new1'), { access_level: 'end_user' }));
});

test('admin can create an admin doc', async () => {
  await assertSucceeds(setDoc(doc(as('admin1'), 'users/new2'), { access_level: 'admin' }));
});

test('admin cannot create a user with an invalid access_level', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'users/new3'), { access_level: 'superuser' }));
});

test('student cannot create a user doc', async () => {
  await assertFails(setDoc(doc(as('student1'), 'users/new4'), { access_level: 'end_user' }));
});

test('student cannot make themselves admin', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'users/student1'), { access_level: 'admin' }));
});

test('admin cannot update a user doc (no update rule)', async () => {
  await assertFails(updateDoc(doc(as('admin1'), 'users/student1'), { access_level: 'admin' }));
});

test('admin can delete an end_user doc', async () => {
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'users/student2')));
});

test('admin cannot delete an admin user doc', async () => {
  await assertFails(deleteDoc(doc(as('admin1'), 'users/admin2')));
});

test('student cannot delete a user doc', async () => {
  await assertFails(deleteDoc(doc(as('student1'), 'users/student2')));
});

//=== ADMIN PROFILES ===
test('admin reads own and other admin profiles', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'admin_profiles/admin1')));
  await assertSucceeds(getDoc(doc(as('admin1'), 'admin_profiles/admin2')));
});

test('student cannot read an admin profile', async () => {
  await assertFails(getDoc(doc(as('student1'), 'admin_profiles/admin1')));
});

test('admin can create a profile for an existing admin user', async () => {
  await assertSucceeds(setDoc(doc(as('admin1'), 'admin_profiles/admin3'), { name: 'Admin Three' }));
});

test('admin cannot create an admin profile for an end_user', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'admin_profiles/student3'), { name: 'x' }));
});

test('admin cannot create an admin profile for a nonexistent user', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'admin_profiles/ghost'), { name: 'x' }));
});

test('admin can update own profile, not another admin\'s', async () => {
  await assertSucceeds(updateDoc(doc(as('admin1'), 'admin_profiles/admin1'), { name: 'New' }));
  await assertFails(updateDoc(doc(as('admin1'), 'admin_profiles/admin2'), { name: 'Hacked' }));
});

test('admin can delete another admin\'s profile but not their own', async () => {
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'admin_profiles/admin2')));
  await assertFails(deleteDoc(doc(as('admin1'), 'admin_profiles/admin1')));
});

test('student cannot delete an admin profile', async () => {
  await assertFails(deleteDoc(doc(as('student1'), 'admin_profiles/admin1')));
});

//=== END USER PROFILES ===
test('student reads own profile, not another student\'s', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'end_user_profiles/student1')));
  await assertFails(getDoc(doc(as('student1'), 'end_user_profiles/student2')));
});

test('admin can read any end user profile', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'end_user_profiles/student1')));
});

test('admin can create a profile for an existing end_user', async () => {
  await assertSucceeds(setDoc(doc(as('admin1'), 'end_user_profiles/student3'), { phone_num: '1' }));
});

test('admin cannot create an end user profile for an admin user', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'end_user_profiles/admin3'), { phone_num: '1' }));
});

test('admin cannot create an end user profile for a nonexistent user', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'end_user_profiles/ghost'), { phone_num: '1' }));
});

test('student cannot create a profile', async () => {
  await assertFails(setDoc(doc(as('student3'), 'end_user_profiles/student3'), { phone_num: '1' }));
});

test('student can update only display_photo and phone_num', async () => {
  await assertSucceeds(updateDoc(doc(as('student1'), 'end_user_profiles/student1'), { phone_num: '555' }));
  await assertSucceeds(updateDoc(doc(as('student1'), 'end_user_profiles/student1'), { display_photo: 'n.png' }));
  await assertFails(updateDoc(doc(as('student1'), 'end_user_profiles/student1'), { name: 'Other' }));
});

test('student cannot update another student\'s profile', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'end_user_profiles/student2'), { phone_num: '1' }));
});

test('admin cannot update a student profile', async () => {
  await assertFails(updateDoc(doc(as('admin1'), 'end_user_profiles/student1'), { phone_num: '999' }));
});

test('admin can delete a student profile; student cannot', async () => {
  await assertFails(deleteDoc(doc(as('student1'), 'end_user_profiles/student1')));
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'end_user_profiles/student1')));
});

//=== PERMITS: CREATE / READ ===
test('student can create own PENDING permit', async () => {
  await assertSucceeds(setDoc(doc(as('student1'), 'permits/new1'), {
    user_id: 'student1', type: 'WEEKEND', permit_status: 'PENDING',
  }));
});

test('student cannot create an ACTIVE permit', async () => {
  await assertFails(setDoc(doc(as('student1'), 'permits/new1'), {
    user_id: 'student1', type: 'LATE', permit_status: 'ACTIVE',
  }));
});

test('student cannot create a permit with an invalid type', async () => {
  await assertFails(setDoc(doc(as('student1'), 'permits/new1'), {
    user_id: 'student1', type: 'HOLIDAY', permit_status: 'PENDING',
  }));
});

test('student cannot create a permit for someone else', async () => {
  await assertFails(setDoc(doc(as('student1'), 'permits/new1'), {
    user_id: 'student2', type: 'LATE', permit_status: 'PENDING',
  }));
});

test('admin cannot create a permit', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'permits/new1'), {
    user_id: 'admin1', type: 'LATE', permit_status: 'PENDING',
  }));
});

test('student reads own permit, not another student\'s', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'permits/pPending')));
  await assertFails(getDoc(doc(as('student2'), 'permits/pPending')));
});

test('admin can read any permit', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'permits/pPending')));
});

//=== PERMITS: ADMIN UPDATE / DELETE ===
test('admin can change a permit status', async () => {
  await assertSucceeds(updateDoc(doc(as('admin1'), 'permits/pPending'), { permit_status: 'ACTIVE' }));
});

test('admin cannot set an invalid status', async () => {
  await assertFails(updateDoc(doc(as('admin1'), 'permits/pPending'), { permit_status: 'MAYBE' }));
});

test('admin cannot reassign a permit to another user', async () => {
  await assertFails(updateDoc(doc(as('admin1'), 'permits/pPending'), { user_id: 'student2' }));
});

test('admin can delete a permit; student cannot', async () => {
  await assertFails(deleteDoc(doc(as('student1'), 'permits/pPending')));
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'permits/pPending')));
});

//=== PERMITS: STUDENT CANCEL ===
test('student can cancel own PENDING permit', async () => {
  await assertSucceeds(updateDoc(doc(as('student1'), 'permits/pPending'), { permit_status: 'CANCELLED' }));
});

test('student can cancel own ACTIVE permit', async () => {
  await assertSucceeds(updateDoc(doc(as('student1'), 'permits/pActive'), { permit_status: 'CANCELLED' }));
});

test('student cannot cancel a COMPLETED permit', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'permits/pCompleted'), { permit_status: 'CANCELLED' }));
});

test('student cannot cancel someone else\'s permit', async () => {
  await assertFails(updateDoc(doc(as('student2'), 'permits/pPending'), { permit_status: 'CANCELLED' }));
});

test('student cannot set any status other than CANCELLED/COMPLETED', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'permits/pPending'), { permit_status: 'ACTIVE' }));
});

test('student cannot change other fields while cancelling', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'permits/pPending'), {
    permit_status: 'CANCELLED', type: 'WEEKEND',
  }));
});

//=== PERMITS: STUDENT COMPLETE ===
test('student completes an ACTIVE permit after a DONE code with matching time', async () => {
  await assertSucceeds(updateDoc(doc(as('student1'), 'permits/pDone'), { permit_status: 'COMPLETED' }));
});

test('student cannot complete when the code is not DONE', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'permits/pActive'), { permit_status: 'COMPLETED' }));
});

test('student cannot complete when actual_time_in does not match checkin_at', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'permits/pDone'), {
      actual_time_in: Timestamp.fromDate(new Date(TIME_IN.getTime() - 60_000)),
    });
  });
  await assertFails(updateDoc(doc(as('student1'), 'permits/pDone'), { permit_status: 'COMPLETED' }));
});

test('another student cannot complete the permit', async () => {
  await assertFails(updateDoc(doc(as('student2'), 'permits/pDone'), { permit_status: 'COMPLETED' }));
});

//=== CHECKIN CODES: READ / CREATE ===
test('admin can read a check-in code; student cannot', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'checkin_codes/pActive')));
  await assertFails(getDoc(doc(as('student1'), 'checkin_codes/pActive')));
});

test('admin can create a code for an ACTIVE permit', async () => {
  await assertSucceeds(setDoc(doc(as('admin1'), 'checkin_codes/pActiveNoCode'), {
    code_status: null, checkin_at: null, checkin_by: null, expires_at: hours(1),
  }));
});

test('admin cannot create a code for a non-ACTIVE permit', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'checkin_codes/pPending'), {
    code_status: null, checkin_at: null, checkin_by: null, expires_at: hours(1),
  }));
});

test('admin cannot create an already-expired code', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'checkin_codes/pActiveNoCode'), {
    code_status: null, checkin_at: null, checkin_by: null, expires_at: hours(-1),
  }));
});

test('admin cannot create a code that is pre-filled as used', async () => {
  await assertFails(setDoc(doc(as('admin1'), 'checkin_codes/pActiveNoCode'), {
    code_status: 'DONE', checkin_at: null, checkin_by: null, expires_at: hours(1),
  }));
});

test('student cannot create a code', async () => {
  await assertFails(setDoc(doc(as('student1'), 'checkin_codes/pActiveNoCode'), {
    code_status: null, checkin_at: null, checkin_by: null, expires_at: hours(1),
  }));
});

//=== CHECKIN CODES: SCAN ===
const scan = (uid, id = 'pActive') =>
  updateDoc(doc(as(uid), `checkin_codes/${id}`), {
    code_status: 'DONE', checkin_at: serverTimestamp(), checkin_by: uid,
  });

test('owner can scan an unused, unexpired code', async () => {
  await assertSucceeds(scan('student1'));
});

test('another student cannot scan it', async () => {
  await assertFails(scan('student2'));
});

test('cannot scan an expired code', async () => {
  await assertFails(scan('student1', 'pExpired'));
});

test('a code cannot be scanned twice', async () => {
  await assertSucceeds(scan('student1'));
  await assertFails(scan('student1'));
});

test('scan must use the server timestamp', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'checkin_codes/pActive'), {
    code_status: 'DONE', checkin_at: new Date(), checkin_by: 'student1',
  }));
});

test('scan cannot record someone else as checkin_by', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'checkin_codes/pActive'), {
    code_status: 'DONE', checkin_at: serverTimestamp(), checkin_by: 'student2',
  }));
});

test('scan cannot also change expires_at', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'checkin_codes/pActive'), {
    code_status: 'DONE', checkin_at: serverTimestamp(), checkin_by: 'student1',
    expires_at: hours(48),
  }));
});

test('cannot scan a code whose permit is no longer ACTIVE', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'permits/pActive'), { permit_status: 'CANCELLED' });
  });
  await assertFails(scan('student1'));
});

//=== CHECKIN CODES: CANCEL / DELETE ===
test('admin can cancel a code', async () => {
  await assertSucceeds(updateDoc(doc(as('admin1'), 'checkin_codes/pActive'), { code_status: 'CANCELLED' }));
});

test('admin cannot edit other code fields', async () => {
  await assertFails(updateDoc(doc(as('admin1'), 'checkin_codes/pActive'), { expires_at: hours(48) }));
});

test('student cannot cancel a code', async () => {
  await assertFails(updateDoc(doc(as('student1'), 'checkin_codes/pActive'), { code_status: 'CANCELLED' }));
});

test('nobody can delete a code', async () => {
  await assertFails(deleteDoc(doc(as('admin1'), 'checkin_codes/pActive')));
  await assertFails(deleteDoc(doc(as('student1'), 'checkin_codes/pActive')));
});

//=== DELINQUENCY LOGS ===
test('student reads own delinquency log, not others\'', async () => {
  await assertSucceeds(getDoc(doc(as('student1'), 'delinquency_logs/d1')));
  await assertFails(getDoc(doc(as('student2'), 'delinquency_logs/d1')));
});

test('admin can read and write delinquency logs', async () => {
  await assertSucceeds(getDoc(doc(as('admin1'), 'delinquency_logs/d1')));
  await assertSucceeds(setDoc(doc(as('admin1'), 'delinquency_logs/d2'), { user_id: 'student2' }));
  await assertSucceeds(deleteDoc(doc(as('admin1'), 'delinquency_logs/d1')));
});

test('student cannot write a delinquency log', async () => {
  await assertFails(setDoc(doc(as('student1'), 'delinquency_logs/d2'), { user_id: 'student1' }));
});