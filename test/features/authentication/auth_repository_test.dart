import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
  });
}
