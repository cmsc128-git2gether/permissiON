import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // added another import
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
      // MockFirebaseAuth automatically creates a MockUser when you call createUser
      final mockAuth = MockFirebaseAuth();
      final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

      await repository.signUp(email: 'new@student.edu', password: 'password123');

      // Check Firebase Auth
      final currentUser = mockAuth.currentUser;
      expect(currentUser, isNotNull);
      expect(currentUser!.email, 'new@student.edu');

      // Check Firestore
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
        // Start signed out
        final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: false);
        final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

        // Act
        await repository.signIn(email: 'test@test.com', password: 'anypassword');

        // Assert
        expect(mockAuth.currentUser, isNotNull);
        expect(mockAuth.currentUser!.email, 'test@test.com');
    });

    test('signIn throws mapped FirebaseAuthException on wrong password', () async {
        final mockAuth = MockFirebaseAuth(
            exceptions: {
                'signInWithEmailAndPassword': FirebaseAuthException(
                    code: 'wrong-password',
                    message: 'Raw Firebase message that user should not see',
              ),
            },
          );

        final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

         expect(
            () => repository.signIn(email: 'test@test.com', password: 'wrong'),
            throwsA(
              isA<FirebaseAuthException>()
                  .having((e) => e.code, 'code', 'wrong-password')
                  .having((e) => e.message, 'message', 'Incorrect email or password.'),
            ),
          );
        });

    test('signUp throws mapped FirebaseAuthException on email-already-in-use', () async {
              final mockAuth = MockFirebaseAuth(
                exceptions: {
                  'createUserWithEmailAndPassword': FirebaseAuthException(
                    code: 'email-already-in-use',
                    message: 'Raw message',
                  ),
                },
              );

              final repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);

              expect(
                () => repository.signUp(email: 'test@test.com', password: 'password123'),
                throwsA(
                  isA<FirebaseAuthException>()
                      .having((e) => e.code, 'code', 'email-already-in-use')
                      .having((e) => e.message, 'message', 'That email is already registered.'),
                ),
              );
            }); //
  });
}