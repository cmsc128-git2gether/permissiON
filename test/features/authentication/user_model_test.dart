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

    test('defaults access_level to end_user if field is missing or null', () {
      final user = AppUser.fromFirestore(null, 'uid_789', 'user@test.com');

      expect(user.accessLevel, 'end_user');
      expect(user.isAdmin, isFalse);
    });
  });
}
