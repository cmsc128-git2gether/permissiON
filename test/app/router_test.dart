import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/app/router.dart';
import 'package:permission_app/features/presentation/auth_notifier.dart';

void main() {
  test('signed-out goes to login', () {
    expect(redirectFor(AuthStatus.signedOut, '/home'), '/login');
    expect(redirectFor(AuthStatus.signedOut, '/admin'), '/login');
  });

  test('not-set-up goes to login', () {
    expect(redirectFor(AuthStatus.notSetUp, '/home'), '/login');
  });

  test('user goes to user home', () {
    expect(redirectFor(AuthStatus.user, '/login'), '/home');
    expect(redirectFor(AuthStatus.user, '/splash'), '/home');
  });

  test('admin goes to admin home', () {
    expect(redirectFor(AuthStatus.admin, '/login'), '/admin');
    expect(redirectFor(AuthStatus.admin, '/splash'), '/admin');
  });
}
