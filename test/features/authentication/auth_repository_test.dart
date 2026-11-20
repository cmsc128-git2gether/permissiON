import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/errors/auth_failure.dart';
import 'package:permission_app/features/authentication/data/auth_repository.dart';
import 'package:permission_app/features/authentication/domain/auth_state.dart';
import 'package:permission_app/features/authentication/domain/user_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('AuthRepository Unit Tests', () {
    test(
      'authStateStream emits loading then signedOut when signed out',
      () async {
        final mockAuth = MockFirebaseAuth(signedIn: false);
        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.authStateStream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthSignedOut>()]),
        );
      },
    );

    test(
      'authStateStream emits signedIn with admin access_level on admin login',
      () async {
        const uid = 'admin_user_01';
        const email = 'admin@school.edu';

        await fakeFirestore.collection('users').doc(uid).set({
          'access_level': 'admin',
        });

        final mockUser = MockUser(uid: uid, email: email);
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.authStateStream,
          emitsThrough(
            isA<AuthSignedIn>().having(
              (state) => state.user,
              'user',
              isA<AppUser>()
                  .having((u) => u.uid, 'uid', uid)
                  .having((u) => u.accessLevel, 'accessLevel', 'admin')
                  .having((u) => u.isAdmin, 'isAdmin', true),
            ),
          ),
        );
      },
    );

    test(
      'authStateStream emits signedIn with end_user access_level on student login',
      () async {
        const uid = 'student_user_01';
        const email = 'student@school.edu';

        await fakeFirestore.collection('users').doc(uid).set({
          'access_level': 'end_user',
        });

        final mockUser = MockUser(uid: uid, email: email);
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.authStateStream,
          emitsThrough(
            isA<AuthSignedIn>().having(
              (state) => state.user,
              'user',
              isA<AppUser>()
                  .having((u) => u.uid, 'uid', uid)
                  .having((u) => u.accessLevel, 'accessLevel', 'end_user')
                  .having((u) => u.isAdmin, 'isAdmin', false),
            ),
          ),
        );
      },
    );

    test(
      'authStateStream emits notSetUp when users/{uid} is missing',
      () async {
        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'not_set_up', email: 'test@test.com'),
          signedIn: true,
        );
        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.authStateStream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthNotSetUp>()]),
        );
      },
    );

        test(
      'authStateStream emits notSetUp when access_level is missing',
      () async {
        const uid = 'no_role';
        await fakeFirestore.collection('users').doc(uid).set({
          'email': 'norole@school.edu',
        });

        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(uid: uid, email: 'norole@school.edu'),
          signedIn: true,
        );
        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.authStateStream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthNotSetUp>()]),
        );
      },
    );

    test(
      'authStateStream emits notSetUp when access_level is not a known role',
      () async {
        const uid = 'bad_role';
        await fakeFirestore.collection('users').doc(uid).set({
          'access_level': 'superuser',
        });

        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(uid: uid, email: 'badrole@school.edu'),
          signedIn: true,
        );
        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.authStateStream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthNotSetUp>()]),
        );
      },
    );
    test(
      'authStateStream emits notSetUp when loading users/{uid} fails',
      () async {
        final mockAuth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'read_failure', email: 'test@test.com'),
          signedIn: true,
        );
        final repository = AuthRepository(
          auth: mockAuth,
          firestore: _ThrowingFirestore(),
        );

        await expectLater(
          repository.authStateStream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthNotSetUp>()]),
        );
      },
    );

    test('signOut causes authStateStream to emit signedOut', () async {
      final mockUser = MockUser(uid: 'uid_123', email: 'test@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      final repository = AuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await repository.signOut();

      await expectLater(
        repository.authStateStream,
        emitsThrough(isA<AuthSignedOut>()),
      );
    });

    test('signIn signs the user in', () async {
      final mockUser = MockUser(uid: 'user_123', email: 'test@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final repository = AuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await repository.signIn(email: 'test@test.com', password: 'anypassword');

      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.email, 'test@test.com');
    });

    final signInErrors = {
      'invalid-credential': 'Incorrect email or password.',
      'wrong-password': 'Incorrect email or password.',
      'user-not-found': 'Incorrect email or password.',
      'invalid-email': 'That email address is not valid.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'network-request-failed': 'No internet connection.',
      'unexpected-code': 'Something went wrong. Please try again.',
    };
    for (final entry in signInErrors.entries) {
      test('signIn maps ${entry.key} to a friendly AuthFailure', () async {
        final mockAuth = _ThrowingAuth(
          FirebaseAuthException(
            code: entry.key,
            message: 'Raw Firebase message that user should not see',
          ),
        );
        final repository = AuthRepository(
          auth: mockAuth,
          firestore: fakeFirestore,
        );

        await expectLater(
          repository.signIn(email: 'test@test.com', password: 'wrong'),
          throwsA(
            isA<AuthFailure>()
                .having((e) => e.code, 'code', entry.key)
                .having((e) => e.message, 'message', entry.value),
          ),
        );
      });
    }

    // createAdminAccount guard paths (these throw before any static
    // Firebase.initializeApp call, so the mocks are sufficient)
    test('createAdminAccount throws unauthenticated when signed out', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final repository = AuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await expectLater(
        repository.createAdminAccount(
          email: 'new@admin.edu',
          password: 'password123',
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (e) => e.code,
            'code',
            'unauthenticated',
          ),
        ),
      );
    });

    test('createAdminAccount throws permission-denied for end_user', () async {
      const uid = 'student_user_01';
      await fakeFirestore.collection('users').doc(uid).set({
        'access_level': 'end_user',
      });

      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: 'student@school.edu'),
        signedIn: true,
      );
      final repository = AuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await expectLater(
        repository.createAdminAccount(
          email: 'new@admin.edu',
          password: 'password123',
        ),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'permission-denied')
              .having(
                (e) => e.message,
                'message',
                'Only admins can create admin accounts.',
              ),
        ),
      );

      // No new profile should have been created.
      final users = await fakeFirestore.collection('users').get();
      expect(users.docs.length, 1);
    });
  });
}

class _ThrowingAuth extends MockFirebaseAuth {
  _ThrowingAuth(this._error);
  final FirebaseAuthException _error;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw _error;
}

class _ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    throw StateError('Firestore read failed');
  }
}
