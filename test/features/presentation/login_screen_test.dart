import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:permission_app/features/presentation/login_screen.dart';
import '../authentication/fake_auth_repository_test.dart';

// Puts the screen inside a MaterialApp, which widgets need to render
Widget wrap(Widget child) => MaterialApp(home: child);

// Types valid credentials and taps the login button
Future<void> fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'secret1');
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pump();
}

void main() {
  // validation
  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(
      wrap(LoginScreen(authRepository: FakeAuthRepository())),
    );

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('rejects invalid email and short password', (tester) async {
    await tester.pumpWidget(
      wrap(LoginScreen(authRepository: FakeAuthRepository())),
    );

    await tester.enterText(find.byKey(const Key('email_field')), 'nope');
    await tester.enterText(find.byKey(const Key('password_field')), '123');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  // Loading state
  testWidgets('shows loading spinner while signing in', (tester) async {
    // A Completer lets us hold the sign-in "in progress" until we choose
    final completer = Completer<void>();
    final repo = FakeAuthRepository(onSignIn: (_, __) => completer.future);

    await tester.pumpWidget(wrap(LoginScreen(authRepository: repo)));
    await fillAndSubmit(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Finish the sign-in, and the spinner should disappear
    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // Errors
  testWidgets('shows friendly message on wrong password', (tester) async {
    final repo = FakeAuthRepository(
      onSignIn: (_, __) async =>
          throw FirebaseAuthException(code: 'wrong-password'),
    );

    await tester.pumpWidget(wrap(LoginScreen(authRepository: repo)));
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('user-not-found shows the same message as wrong password', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      onSignIn: (_, __) async =>
          throw FirebaseAuthException(code: 'user-not-found'),
    );

    await tester.pumpWidget(wrap(LoginScreen(authRepository: repo)));
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('shows generic message on unexpected error', (tester) async {
    final repo = FakeAuthRepository(
      onSignIn: (_, __) async => throw UnimplementedError('signIn'),
    );

    await tester.pumpWidget(wrap(LoginScreen(authRepository: repo)));
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  // Successful login
  testWidgets('successful sign-in with MockFirebaseAuth', (tester) async {
    final auth = MockFirebaseAuth();
    var succeeded = false;

    final repo = FakeAuthRepository(
      auth: auth,
      onSignIn: (e, p) =>
          auth.signInWithEmailAndPassword(email: e, password: p),
    );

    await tester.pumpWidget(
      wrap(
        LoginScreen(authRepository: repo, onSuccess: () => succeeded = true),
      ),
    );
    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull); // someone is now signed in
    expect(succeeded, isTrue);
    expect(find.byKey(const Key('error_message')), findsNothing);
  });
}
