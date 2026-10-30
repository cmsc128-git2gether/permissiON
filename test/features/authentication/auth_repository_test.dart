import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/authentication/data/auth_repository.dart';
import 'package:permission_app/features/authentication/domain/user_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('AuthRepository Unit Tests', () {
    test('authStateStream emits null when signed out', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final repository = AuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await expectLater(repository.authStateStream, emits(isNull));
    });

    test(
      'authStateStream emits AppUser with admin access_level on admin login',
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
            isA<AppUser>()
                .having((u) => u.uid, 'uid', uid)
                .having((u) => u.accessLevel, 'accessLevel', 'admin')
                .having((u) => u.isAdmin, 'isAdmin', true),
          ),
        );
      },
    );

    test(
      'authStateStream emits AppUser with end_user access_level on student login',
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
            isA<AppUser>()
                .having((u) => u.uid, 'uid', uid)
                .having((u) => u.accessLevel, 'accessLevel', 'end_user')
                .having((u) => u.isAdmin, 'isAdmin', false),
          ),
        );
      },
    );

    test('signOut causes authStateStream to emit null', () async {
      final mockUser = MockUser(uid: 'uid_123', email: 'test@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      final repository = AuthRepository(
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await repository.signOut();

      await expectLater(repository.authStateStream, emitsThrough(isNull));
    });

    // Sign Up and Sign In success
    test('signUp creates users/{uid} doc with end_user access_level', () async {
      final mockAuth = MockFirebaseAuth();
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

      await repository.signUp(email: 'new@student.edu', password: 'password123');

      final currentUser = mockAuth.currentUser;
      expect(currentUser, isNotNull);
      expect(currentUser!.email, 'new@student.edu');

      final docSnapshot = await fakeFirestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      expect(docSnapshot.exists, isTrue);
      expect(docSnapshot.data()?['access_level'], 'end_user');
      expect(docSnapshot.data()?['email'], 'new@student.edu');
    });

    test('signIn signs the user in', () async {
      final mockUser = MockUser(uid: 'user_123', email: 'test@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

      await repository.signIn(email: 'test@test.com', password: 'anypassword');

      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.email, 'test@test.com');
    });

    test('signIn throws mapped FirebaseAuthException on wrong password', () async {
      final mockAuth = _ThrowingAuth(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'Raw Firebase message that user should not see',
        ),
      );
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

      await expectLater(
        repository.signIn(email: 'test@test.com', password: 'wrong'),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'wrong-password')
              .having((e) => e.message, 'message', 'Incorrect email or password.'),
        ),
      );
    });

    test('signUp throws mapped FirebaseAuthException on email-already-in-use', () async {
      final mockAuth = _ThrowingAuth(
        FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Raw message',
        ),
      );
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

      await expectLater(
        repository.signUp(email: 'test@test.com', password: 'password123'),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'email-already-in-use')
              .having((e) => e.message, 'message', 'That email is already registered.'),
        ),
      );
    });

    // createAdminAccount guard paths (these throw before any static
    // Firebase.initializeApp call, so the mocks are sufficient)
    test('createAdminAccount throws unauthenticated when signed out', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

      await expectLater(
        repository.createAdminAccount(
          email: 'new@admin.edu',
          password: 'password123',
        ),
        throwsA(
          isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'unauthenticated'),
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
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

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

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw _error;
}
