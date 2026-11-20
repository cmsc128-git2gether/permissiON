import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/authentication/domain/user_model.dart';

void main() {
  group('AppUser Model Tests', () {
    test('isAdmin returns true when access_level is admin', () {
      final data = {'access_level': 'admin'};
      final user = AppUser.fromFirestore(data, 'uid_123', 'admin@test.com');

      expect(user.accessLevel, 'admin');
      expect(user.isAdmin, isTrue);
    });

    test('isAdmin returns false when access_level is end_user', () {
      final data = {'access_level': 'end_user'};
      final user = AppUser.fromFirestore(data, 'uid_456', 'user@test.com');

      expect(user.accessLevel, 'end_user');
      expect(user.isAdmin, isFalse);
    });

    // A missing or bad role must never silently become end_user.
    // AuthRepository catches this error and emits AuthState.notSetUp.
    test('throws when access_level is missing or null', () {
      expect(
        () => AppUser.fromFirestore(null, 'uid_789', 'user@test.com'),
        throwsArgumentError,
      );
      expect(
        () => AppUser.fromFirestore({}, 'uid_789', 'user@test.com'),
        throwsArgumentError,
      );
      expect(
        () => AppUser.fromFirestore(
            {'access_level': null}, 'uid_789', 'user@test.com'),
        throwsArgumentError,
      );
    });

    test('throws when access_level is not a known role', () {
      expect(
        () => AppUser.fromFirestore(
            {'access_level': 'superuser'}, 'uid_789', 'user@test.com'),
        throwsArgumentError,
      );
    });
  });
}