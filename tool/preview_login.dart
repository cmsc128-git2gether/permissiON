import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:permission_app/features/authentication/data/auth_repository.dart';
import 'package:permission_app/features/presentation/login_screen.dart';

// Runs only the login screen with fake Firebase, so no setup is needed.
void main() {
  final repo = AuthRepository(
    auth: MockFirebaseAuth(),
    firestore: FakeFirebaseFirestore(),
  );
  runApp(MaterialApp(home: LoginScreen(authRepository: repo)));
}
